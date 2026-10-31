import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/core/logging/logger_provider.dart';
import 'package:prosoche/core/router/deep_link.dart';
import 'package:prosoche/core/router/routes.dart';
import 'package:prosoche/data/notifications/notifications.dart';
import 'package:prosoche/data/repositories/settings/settings_providers.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/onboarding/onboarding_platform.dart';
import 'package:workmanager/workmanager.dart';

/// Systemove notifikacie (`flutter_local_notifications`). Testy prepisu.
final Provider<NotificationPlatform> notificationPlatformProvider =
    Provider<NotificationPlatform>(
      (ref) => LocalNotificationsPlatform(),
      name: 'notificationPlatformProvider',
    );

/// Planovanie notifikacii (P-02) nad user.db nastaveniami.
final Provider<NotificationService> notificationServiceProvider =
    Provider<NotificationService>(
      (ref) => NotificationService(
        settings: ref.watch(settingsRepositoryProvider),
        platform: ref.watch(notificationPlatformProvider),
        deviceZone: currentDeviceZone,
        clock: ref.watch(appClockProvider),
        logger: ref.watch(appLoggerProvider),
      ),
      name: 'notificationServiceProvider',
    );

/// Jediny vstup na preplanovanie v hlavnom isolate: planuje len po
/// dokonceni onboardingu, inak vsetko zrusi (napr. po "Delete all my
/// data" by spustace z nastaveni, resume a startu znova naplanovali
/// rannu notifikaciu). Operacie idu za sebou.
final class NotificationScheduler {
  NotificationScheduler({
    required this.service,
    required this.settings,
    required this.platform,
  });

  final NotificationService service;
  final SettingsRepository settings;
  final NotificationPlatform platform;

  Future<void> _tail = Future.value();

  /// Preplanuje podla nastaveni (alebo zrusi vsetko pred onboardingom).
  Future<void> reschedule() => _serial(() async {
    if (await settings.get(SettingsKeys.onboardingCompleted)) {
      await service.reschedule();
    } else {
      await _cancelAll();
    }
  });

  /// Zrusi vsetky naplanovane notifikacie appky.
  Future<void> cancelAll() => _serial(_cancelAll);

  Future<void> _cancelAll() async {
    for (final p in await platform.pending()) {
      await platform.cancel(p.id);
    }
  }

  Future<void> _serial(Future<void> Function() task) {
    final result = _tail.then((_) => task());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}

final Provider<NotificationScheduler> notificationSchedulerProvider =
    Provider<NotificationScheduler>(
      (ref) => NotificationScheduler(
        service: ref.watch(notificationServiceProvider),
        settings: ref.watch(settingsRepositoryProvider),
        platform: ref.watch(notificationPlatformProvider),
      ),
      name: 'notificationSchedulerProvider',
    );

/// Hooky featur napojene na [notificationSchedulerProvider] (I-01).
List<Override> notificationOverrides() => [
  onboardingRescheduleProvider.overrideWith(
    (ref) =>
        () => _reschedule(ref),
  ),
  onboardingNotificationsProvider.overrideWith(
    (ref) => PlatformOnboardingNotifications(
      ref.watch(notificationPlatformProvider),
    ),
  ),
];

Future<void> _reschedule(Ref ref) =>
    ref.read(notificationSchedulerProvider).reschedule();

/// IANA zona zariadenia; zisti sa pri kazdom preplanovani (zmena zony).
Future<String> currentDeviceZone() async {
  try {
    return (await FlutterTimezone.getLocalTimezone()).identifier;
  } on Object {
    return 'UTC';
  }
}

/// Ciel kliknutej notifikacie (payload P-02 -> go_router cesta).
String notificationTarget(String? payload) {
  final link = NotificationService.deepLinkOf(payload);
  final uri = link == null ? null : Uri.tryParse(link);
  return (uri == null ? null : mapDeepLink(uri)) ?? AppRoutes.today;
}

/// Spustenie notifikacii v hlavnom isolate (bootstrap, po `runApp`):
/// plugin s deep linkom, preplanovanie pri starte/resume/zmene nastaveni
/// a periodicky workmanager job. Chyby sa len zaloguju. [router] vrati
/// aktualny router (po zmazani dat sa vytvori novy).
Future<NotificationTriggers?> startNotifications(
  ProviderContainer container, {
  required GoRouter Function() router,
  required void Function() dispatcher,
}) async {
  final logger = container.read(appLoggerProvider);
  Future<void> step(String what, Future<void> Function() run) async {
    try {
      await run();
    } on Object catch (e, st) {
      logger.error('notif', '$what failed', error: e, stack: st);
    }
  }

  await step('initialize', () async {
    await container
        .read(notificationPlatformProvider)
        .initialize(
          onTap: (payload) => router().go(notificationTarget(payload)),
        );
    // Studeny start z notifikacie: onTap sa nezavola.
    final launch = await FlutterLocalNotificationsPlugin()
        .getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      router().go(notificationTarget(launch!.notificationResponse?.payload));
    }
  });

  NotificationTriggers? triggers;
  await step('triggers', () async {
    final scheduler = container.read(notificationSchedulerProvider);
    triggers = NotificationTriggers(
      settings: container.read(settingsRepositoryProvider),
      reschedule: scheduler.reschedule,
      logger: logger,
    );
    await triggers!.start();
  });

  await step('workmanager', () async {
    final workmanager = Workmanager();
    await workmanager.initialize(dispatcher);
    await NotificationBackground.register(workmanager);
  });
  return triggers;
}
