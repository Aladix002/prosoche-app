import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:clock/clock.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/data/notifications/notification_platform.dart';
import 'package:prosoche/data/notifications/notification_texts.dart';
import 'package:prosoche/domain/common/local_date.dart';
import 'package:prosoche/domain/notifications/notifications.dart';
import 'package:prosoche/domain/prayer/calc_settings.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:prosoche/domain/prayer/prayer_schedule.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Posledna potvrdena casova zona zariadenia (docs/01 5.6).
abstract interface class TimeZoneStore {
  Future<String?> confirmedZone();
  Future<void> setConfirmedZone(String zone);
}

/// [TimeZoneStore] v SharedPreferences. Navrh: presunut do `settings`
/// ako kluc `notif.confirmed_tz` (handoff P-02).
final class SharedPrefsTimeZoneStore implements TimeZoneStore {
  SharedPrefsTimeZoneStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const key = 'notif.confirmed_tz';

  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> confirmedZone() => _prefs.getString(key);

  @override
  Future<void> setConfirmedZone(String zone) => _prefs.setString(key, zone);
}

/// Vysledok jedneho preplanovania.
@immutable
final class RescheduleResult {
  const RescheduleResult({
    required this.planned,
    required this.scheduled,
    required this.cancelled,
    required this.exact,
    required this.prayersPaused,
    required this.deviceZone,
    required this.dropped,
  });

  /// Pocet notifikacii v plane (<= 64).
  final int planned;

  /// Nove alebo zmenene.
  final int scheduled;
  final int cancelled;

  /// Presne alarmy; false = fallback s oneskorenim 10+ min (docs/08 A).
  final bool exact;

  /// Nova casova zona caka na potvrdenie polohy, modlitby su pozastavene.
  final bool prayersPaused;

  /// IANA zona zariadenia (pre banner "New time zone detected").
  final String deviceZone;

  /// Kolko sa neveslo do rozpoctu 64.
  final int dropped;
}

/// Preplanovanie notifikacii (TECHNICKY_PLAN 8.2).
///
/// Vola sa pri otvoreni appky, po zmene nastaveni alebo polohy, pri zmene
/// casovej zony a z workmanagera kazdych 12 h. Je idempotentne: zmeni len
/// notifikacie, ktore sa lisia od planu. Volania idu za sebou, nikdy
/// paralelne.
final class NotificationService {
  NotificationService({
    required this.settings,
    required this.platform,
    required this.timeZones,
    required this.deviceZone,
    this.clock = const Clock(),
    this.planner = const NotificationPlanner(),
    this.logger,
    Future<Locale> Function()? systemLocale,
    Future<Set<LocalDate>> Function()? excusedDays,
    Future<Set<LocalDate>> Function()? fastingDays,
  }) : _systemLocale = systemLocale ?? _platformLocale,
       _excusedDays = excusedDays ?? _noExcusedDays,
       _fastingDays = fastingDays ?? _noExcusedDays;

  final SettingsRepository settings;
  final NotificationPlatform platform;
  final TimeZoneStore timeZones;

  /// IANA zona zariadenia (`flutter_timezone`).
  final Future<String> Function() deviceZone;
  final Clock clock;
  final NotificationPlanner planner;
  final AppLogger? logger;
  final Future<Locale> Function() _systemLocale;
  final Future<Set<LocalDate>> Function() _excusedDays;

  /// Dni postu v Ramadane (F-08 `ramadanFastingDaysAhead`); default ziadne.
  final Future<Set<LocalDate>> Function() _fastingDays;

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

  /// Pouzivatel potvrdil polohu v novej zone ("Keep {city}", nove mesto):
  /// aktualna zona sa ulozi a modlitby sa znova naplanuju.
  Future<RescheduleResult> confirmTimeZone() => _serial(() async {
    await timeZones.setConfirmedZone(await deviceZone());
    return await _reschedule();
  });

  /// Presne alarmy povolene. UI pri false ukaze `notifInexactNote`.
  Future<bool> canScheduleExact() => platform.canScheduleExact();

  /// Otvori systemove nastavenie presnych alarmov. Po navrate (lifecycle
  /// resumed) treba zavolat [reschedule], plany sa prepisu na presne.
  Future<bool> requestExactAlarms() async {
    final granted = await platform.requestExactAlarms();
    logger?.info(_tag, 'exact alarm request', {
      'permission': 'exact_alarm',
      'granted': granted,
    });
    return granted;
  }

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

    final confirmed = await timeZones.confirmedZone();
    final status = checkTimeZone(
      confirmedZone: confirmed,
      deviceZone: zoneName,
      now: started,
    );
    if (status == TimeZoneStatus.firstRun) {
      await timeZones.setConfirmedZone(zoneName);
    }
    final paused = status == TimeZoneStatus.changed;

    final loaded = await CalcSettings.load(settings);
    PrayerSchedule? schedule;
    if (loaded != null && _location(loaded.$1.tz) != null) {
      schedule = PrayerSchedule.forLocation(loaded.$1, loaded.$2);
    }
    final enabled = {
      for (final p in Prayer.salah)
        if (await settings.get(SettingsKeys.notifPrayer(p.name))) p,
    };
    final private = await settings.get(SettingsKeys.notifPrivateLockscreen);
    final plan = planner.plan(
      NotificationPlanInput(
        now: started,
        deviceZone: device,
        schedule: schedule,
        enabledPrayers: enabled,
        prayersPaused: paused,
        excusedDays: await _excusedDays(),
        fastingDays: await _fastingDays(),
        morningEnabled: await settings.get(SettingsKeys.notifMorningEnabled),
        morningTime: TimeOfDayHm.parse(
          await settings.get(SettingsKeys.notifMorningTime),
        ),
      ),
    );

    final texts = await NotificationTexts.load(await _locale());
    var exact = await platform.canScheduleExact();
    String payloadOf(PlannedNotification n) =>
        encodePayload(n, texts.render(n, private: private), exact: exact);

    final diff = diffNotifications(
      pending: await platform.pending(),
      planned: plan.items,
      payloadOf: payloadOf,
    );
    for (final id in diff.cancel) {
      await platform.cancel(id);
    }
    for (final n in diff.schedule) {
      try {
        await platform.schedule(
          _build(n, texts, private, payloadOf),
          exact: exact,
        );
      } on ExactAlarmNotPermittedException {
        // Povolenie zobrali medzi kontrolou a planovanim: fallback.
        exact = false;
        await platform.schedule(
          _build(n, texts, private, payloadOf),
          exact: false,
        );
      }
    }

    logger?.info(_tag, 'rescheduled', {
      'op': 'reschedule',
      'status': paused ? 'tz_paused' : (exact ? 'exact' : 'inexact'),
      'ms': clock.now().difference(started).inMilliseconds,
    });
    return RescheduleResult(
      planned: plan.length,
      scheduled: diff.schedule.length,
      cancelled: diff.cancel.length,
      exact: exact,
      prayersPaused: paused,
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

  static Future<Set<LocalDate>> _noExcusedDays() async => const {};

  /// Payload: odtlacok planu, hash textu, rezim alarmu a deep link.
  /// Zmena ktorejkolvek casti = notifikacia sa naplanuje znova.
  static String encodePayload(
    PlannedNotification n,
    (String, String) text, {
    required bool exact,
  }) {
    final hash = sha1.convert(utf8.encode('${text.$1}\n${text.$2}'));
    return jsonEncode({
      'v': 1,
      'f': n.fingerprint,
      'h': hash.toString().substring(0, 12),
      'x': exact ? 1 : 0,
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
