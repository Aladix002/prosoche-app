import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:clock/clock.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/data/notifications/notification_platform.dart';
import 'package:prosoche/data/notifications/notification_texts.dart';
import 'package:prosoche/domain/notifications/notifications.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Vysledok jedneho preplanovania.
@immutable
final class RescheduleResult {
  const RescheduleResult({
    required this.planned,
    required this.scheduled,
    required this.cancelled,
    required this.deviceZone,
    required this.dropped,
  });

  /// Pocet notifikacii v plane (<= 64).
  final int planned;

  /// Nove alebo zmenene.
  final int scheduled;
  final int cancelled;

  /// IANA zona zariadenia.
  final String deviceZone;

  /// Kolko sa neveslo do rozpoctu 64.
  final int dropped;
}

/// Preplanovanie notifikacii (TECHNICKY_PLAN 8.2).
///
/// Vola sa pri otvoreni appky, po zmene nastaveni, pri zmene casovej zony
/// a z workmanagera kazdych 12 h. Je idempotentne: zmeni len
/// notifikacie, ktore sa lisia od planu. Volania idu za sebou, nikdy
/// paralelne.
final class NotificationService {
  NotificationService({
    required this.settings,
    required this.platform,
    required this.deviceZone,
    this.clock = const Clock(),
    this.planner = const NotificationPlanner(),
    this.logger,
    Future<Locale> Function()? systemLocale,
  }) : _systemLocale = systemLocale ?? _platformLocale;

  final SettingsRepository settings;
  final NotificationPlatform platform;

  /// IANA zona zariadenia (`flutter_timezone`).
  final Future<String> Function() deviceZone;
  final Clock clock;
  final NotificationPlanner planner;
  final AppLogger? logger;
  final Future<Locale> Function() _systemLocale;

  static const _tag = 'notif';

  Future<void> _tail = Future.value();

  /// Nacita databazu casovych zon (raz na isolate).
  static void ensureTimeZones() {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    _tzReady = true;
  }

  static bool _tzReady = false;

  /// Zosuladi naplanovane notifikacie s planom.
  Future<RescheduleResult> reschedule() => _serial(_reschedule);

  /// Runtime povolenie notifikacii (onboarding O4).
  Future<bool> requestPermission() async {
    final granted = await platform.requestPermission();
    logger?.info(_tag, 'permission request', {
      'permission': 'notifications',
      'granted': granted,
    });
    return granted;
  }

  Future<bool> areEnabled() => platform.areEnabled();

  Future<T> _serial<T>(Future<T> Function() task) {
    final result = _tail.then((_) => task());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<RescheduleResult> _reschedule() async {
    ensureTimeZones();
    final started = clock.now();
    final zoneName = await deviceZone();
    final device = _location(zoneName) ?? tz.UTC;
    final private = await settings.get(SettingsKeys.notifPrivateLockscreen);
    final plan = planner.plan(
      NotificationPlanInput(
        now: started,
        deviceZone: device,
        morningEnabled: await settings.get(SettingsKeys.notifMorningEnabled),
        morningTime: TimeOfDayHm.parse(
          await settings.get(SettingsKeys.notifMorningTime),
        ),
        eveningEnabled: await settings.get(SettingsKeys.notifEveningEnabled),
        eveningTime: TimeOfDayHm.parse(
          await settings.get(SettingsKeys.notifEveningTime),
        ),
      ),
    );

    final texts = await NotificationTexts.load(await _locale());
    String payloadOf(PlannedNotification n) =>
        encodePayload(n, texts.render(n, private: private));

    final diff = diffNotifications(
      pending: await platform.pending(),
      planned: plan.items,
      payloadOf: payloadOf,
    );
    for (final id in diff.cancel) {
      await platform.cancel(id);
    }
    for (final n in diff.schedule) {
      await platform.schedule(_build(n, texts, private, payloadOf));
    }

    logger?.info(_tag, 'rescheduled', {
      'op': 'reschedule',
      'status': 'inexact',
      'ms': clock.now().difference(started).inMilliseconds,
    });
    return RescheduleResult(
      planned: plan.length,
      scheduled: diff.schedule.length,
      cancelled: diff.cancel.length,
      deviceZone: zoneName,
      dropped: plan.dropped,
    );
  }

  ScheduledNotification _build(
    PlannedNotification n,
    NotificationTexts texts,
    bool private,
    String Function(PlannedNotification) payloadOf,
  ) {
    final (title, body) = texts.render(n, private: private);
    return ScheduledNotification(
      id: n.id,
      channel: n.channel,
      channelName: texts.channelName(n.channel),
      channelDescription: texts.channelDescription(n.channel),
      at: n.at,
      title: title,
      body: body,
      payload: payloadOf(n),
      private: private,
    );
  }

  Future<Locale> _locale() async {
    final stored = await settings.get(SettingsKeys.uiLocale);
    if (stored == null || stored.isEmpty) return await _systemLocale();
    return Locale(stored.split(RegExp('[-_]')).first);
  }

  tz.Location? _location(String name) {
    try {
      return tz.getLocation(name);
    } on tz.LocationNotFoundException {
      logger?.warn(_tag, 'unknown time zone', {'code': 'tz_unknown'});
      return null;
    }
  }

  static Future<Locale> _platformLocale() async =>
      PlatformDispatcher.instance.locale;

  /// Payload: odtlacok planu, hash textu a deep link. Zmena ktorejkolvek
  /// casti = notifikacia sa naplanuje znova. `x` je vzdy 0 (inexact).
  static String encodePayload(PlannedNotification n, (String, String) text) {
    final hash = sha1.convert(utf8.encode('${text.$1}\n${text.$2}'));
    return jsonEncode({
      'v': 1,
      'f': n.fingerprint,
      'h': hash.toString().substring(0, 12),
      'x': 0,
      'link': n.deepLink,
    });
  }

  /// Deep link z payloadu kliknutej notifikacie, alebo null.
  static String? deepLinkOf(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final json = jsonDecode(payload);
      if (json case {'link': final String link}) return link;
    } on FormatException {
      return null;
    }
    return null;
  }
}
