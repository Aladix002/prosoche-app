import 'dart:ui';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/l10n/generated/app_localizations.dart';
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/data/notifications/notification_platform.dart';
import 'package:prosoche/data/notifications/notification_service.dart';
import 'package:prosoche/data/notifications/notification_texts.dart';
import 'package:prosoche/domain/common/local_date.dart';
import 'package:prosoche/domain/notifications/notifications.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../fakes/in_memory_settings_repository.dart';
import 'fake_notification_platform.dart';

void main() {
  NotificationService.ensureTimeZones();
  final ba = tz.getLocation('Europe/Bratislava');
  // Utorok 3. 11. 2026, 06:00 v Bratislave.
  final now = tz.TZDateTime(ba, 2026, 11, 3, 6);

  late InMemorySettingsRepository settings;
  late FakeNotificationPlatform platform;
  late String deviceZone;
  late RingBufferLog log;
  late NotificationService service;

  NotificationService build({Locale system = const Locale('en')}) =>
      NotificationService(
        settings: settings,
        platform: platform,
        deviceZone: () async => deviceZone,
        clock: Clock.fixed(now),
        logger: AppLogger(sinks: [log], echoToConsole: false),
        systemLocale: () async => system,
      );

  setUp(() async {
    settings = InMemorySettingsRepository();
    platform = FakeNotificationPlatform();
    deviceZone = 'Europe/Bratislava';
    log = RingBufferLog();
    service = build();
  });

  Iterable<ScheduledNotification> daily() => platform.scheduled.values.where(
    (n) => n.channel == NotificationChannel.daily,
  );

  group('reschedule', () {
    test('first run schedules the whole plan', () async {
      final r = await service.reschedule();
      expect(r.planned, platform.scheduled.length);
      expect(r.planned, 10);
      expect(r.scheduled, r.planned);
      expect(r.cancelled, 0);
      expect(r.exact, isTrue);
      expect(r.dropped, 0);
      expect(r.deviceZone, 'Europe/Bratislava');
      expect(daily(), hasLength(9));
      expect(platform.exactById.values.every((e) => e), isTrue);
      expect(log.entries.last.kv['status'], 'exact');
    });

    test('second run is a no-op (idempotent)', () async {
      await service.reschedule();
      platform.calls.clear();
      final r = await service.reschedule();
      expect(r.scheduled, 0);
      expect(r.cancelled, 0);
      expect(platform.calls, isEmpty);
    });

    test('parallel calls run one after another', () async {
      final results = await Future.wait([
        service.reschedule(),
        service.reschedule(),
      ]);
      expect(results.first.scheduled, greaterThan(0));
      expect(results.last.scheduled, 0);
    });

    test('immediate notifications outside the planned range survive', () async {
      platform.scheduled[2000000001] = ScheduledNotification(
        id: 2000000001,
        channel: NotificationChannel.system,
        channelName: 'x',
        channelDescription: 'x',
        at: now,
        title: 'Gate is paused',
        body: 'x',
        payload: '',
        private: false,
      );
      await service.reschedule();
      expect(platform.scheduled.containsKey(2000000001), isTrue);
    });

    test('changing morning time reschedules the mornings', () async {
      await service.reschedule();
      platform.calls.clear();
      await settings.set(SettingsKeys.notifMorningTime, '08:15');
      final r = await service.reschedule();
      expect(r.scheduled, greaterThan(0));
      final morning = daily().first;
      expect((morning.at.hour, morning.at.minute), (8, 15));
    });

    test('disabling the morning reminder cancels everything', () async {
      await service.reschedule();
      await settings.set(SettingsKeys.notifMorningEnabled, false);
      final r = await service.reschedule();
      expect(r.cancelled, 10);
      expect(platform.scheduled, isEmpty);
    });

    test('unknown device zone falls back to UTC and logs', () async {
      deviceZone = 'Mars/Olympus';
      final r = await service.reschedule();
      expect(r.planned, greaterThan(0));
      expect(log.entries.any((e) => e.kv['code'] == 'tz_unknown'), isTrue);
    });
  });

  group('exact alarms', () {
    test('inexact fallback when not allowed, exact after grant', () async {
      platform.exactAllowed = false;
      final inexact = await service.reschedule();
      expect(inexact.exact, isFalse);
      expect(platform.exactById.values.every((e) => !e), isTrue);
      expect(log.entries.last.kv['status'], 'inexact');

      platform.exactAllowed = true;
      final exact = await service.reschedule();
      expect(exact.exact, isTrue);
      expect(exact.scheduled, exact.planned);
      expect(platform.exactById.values.every((e) => e), isTrue);
    });

    test('permission revoked mid-run falls back to inexact', () async {
      platform.throwOnExact = true;
      final r = await service.reschedule();
      expect(r.exact, isFalse);
      expect(platform.scheduled, isNotEmpty);
      expect(platform.exactById.values.every((e) => !e), isTrue);
    });

    test('permission requests are logged without data', () async {
      expect(await service.requestExactAlarms(), isTrue);
      platform.grant = false;
      expect(await service.requestPermission(), isFalse);
      expect(await service.canScheduleExact(), isTrue);
      expect(await service.areEnabled(), isTrue);
      final kv = log.entries.map((e) => e.kv).toList();
      expect(
        kv,
        contains(equals({'permission': 'exact_alarm', 'granted': true})),
      );
      expect(
        kv,
        contains(equals({'permission': 'notifications', 'granted': false})),
      );
    });
  });

  group('texts', () {
    test('private mode (default) uses neutral text', () async {
      await service.reschedule();
      final morning = daily().first;
      expect(morning.title, 'Prosoche');
      expect(morning.body, 'Your daily reminder');
      expect(morning.private, isTrue);
    });

    test('standard mode shows the morning text', () async {
      await settings.set(SettingsKeys.notifPrivateLockscreen, false);
      await service.reschedule();
      final morning = daily().first;
      expect(morning.title, 'Good morning');
      expect(morning.body, "Today's cards are ready. About 10 minutes.");
      expect(morning.private, isFalse);
      expect(morning.channelName, 'Daily reminder');
      final open = platform.scheduled.values.singleWhere(
        (n) => n.channel == NotificationChannel.system,
      );
      expect(open.title, 'Reminders pause soon');
      expect(open.body, contains('Prosoche'));
    });

    test('switching private mode re-renders all notifications', () async {
      await service.reschedule();
      await settings.set(SettingsKeys.notifPrivateLockscreen, false);
      final r = await service.reschedule();
      expect(r.scheduled, r.planned);
    });

    test('payload carries the deep link', () async {
      await service.reschedule();
      final n = daily().first;
      expect(NotificationService.deepLinkOf(n.payload), 'prosoche://today');
      expect(NotificationService.deepLinkOf(null), isNull);
      expect(NotificationService.deepLinkOf(''), isNull);
      expect(NotificationService.deepLinkOf('not json'), isNull);
      expect(NotificationService.deepLinkOf('{"v":1}'), isNull);
    });

    test('ui.locale wins over system locale, unsupported falls back', () async {
      await settings.set(SettingsKeys.uiLocale, 'xx');
      service = build(system: const Locale('de'));
      await service.reschedule();
      expect(daily().first.body, 'Your daily reminder');
      await settings.reset(SettingsKeys.uiLocale);
      await service.reschedule();
      expect(platform.scheduled, isNotEmpty);
    });

    test('every kind and channel has texts in every locale', () async {
      final day = LocalDate(2026, 11, 6);
      final at = tz.TZDateTime(ba, 2026, 11, 6, 7, 30);
      final samples = [
        PlannedNotification(
          kind: NotificationKind.morning,
          day: day,
          at: at,
          cardMinutes: 1,
        ),
        PlannedNotification(kind: NotificationKind.openApp, day: day, at: at),
      ];
      for (final locale in AppLocalizations.supportedLocales) {
        final texts = await NotificationTexts.load(locale);
        expect(texts.localeName, locale.languageCode);
        for (final n in samples) {
          for (final private in [true, false]) {
            final (title, body) = texts.render(n, private: private);
            expect(title, isNotEmpty);
            expect(body, isNotEmpty);
          }
        }
        for (final c in NotificationChannel.values) {
          expect(texts.channelName(c), isNotEmpty);
          expect(texts.channelDescription(c), isNotEmpty);
        }
      }
    });
  });
}
