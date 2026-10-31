import 'dart:async';

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/data/repositories/infra/time_providers.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/feed.dart';
import 'package:prosoche/domain/prayer/calc_settings.dart';
import 'package:prosoche/domain/prayer/country_defaults.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:prosoche/domain/prayer/prayer_schedule.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';

export 'package:prosoche/data/db/user_enums.dart' show PrayerStatus;

/// Ulozena poloha a nastavenia vypoctu (docs/02 0.7 `prayer.*`).
@immutable
final class PrayerConfig {
  PrayerConfig(this.location, this.settings)
    : schedule = _schedule(location, settings);

  final PrayerLocation location;
  final CalcSettings settings;

  /// Rozvrh pre polohu (zona `location.tz`).
  final PrayerSchedule schedule;

  static PrayerSchedule _schedule(PrayerLocation l, CalcSettings s) {
    ensureTimeZoneData();
    return PrayerSchedule.forLocation(l, s);
  }

  @override
  bool operator ==(Object other) =>
      other is PrayerConfig &&
      other.location == location &&
      other.settings == settings;

  @override
  int get hashCode => Object.hash(location, settings);
}

/// Callback po zmene polohy alebo nastaveni modlitieb: preplanovanie
/// notifikacii (`NotificationPlanner.reschedule()`, P-02). Default nic.
typedef PrayerSettingsChanged = Future<void> Function();

/// Casy modlitieb, nastavenia a tracker `prayer_log` (A7.1, A10.3, O3).
abstract interface class PrayerRepository {
  /// Poloha a nastavenia; null = poloha nie je nastavena.
  Future<PrayerConfig?> config();

  Stream<PrayerConfig?> watchConfig();

  /// Ulozi polohu (A7.3, O3). Pri automatickej metode (`prayer.method`
  /// null) zapise aj predvolbu asr krajiny ([CountryDefaults.asr]), ak asr
  /// este nie je ulozene alebo [resetAsr] (pouzivatel ho nepotvrdil).
  Future<void> saveLocation(PrayerLocation location, {bool resetAsr = false});

  /// null = predvolba podla krajiny.
  Future<void> setMethod(PrayerMethod? method);

  Future<void> setAsr(AsrMadhab asr);

  /// null = predvolba podla zemepisnej sirky.
  Future<void> setHighLatRule(HighLatRule? rule);

  /// Rucny posun -30..+30 min (A10.3); 0 posun zmaze.
  Future<void> setAdjust(Prayer prayer, int minutes);

  /// Zaznamy `prayer_log` dna (len 5 modlitieb, bez sunrise).
  Stream<Map<Prayer, PrayerStatus>> watchLog(LocalDate date);

  Future<void> setStatus(LocalDate date, Prayer prayer, PrayerStatus status);

  /// Zrusi zaznam (tap na vyplneny kruzok, Undo).
  Future<void> clearStatus(LocalDate date, Prayer prayer);
}

/// Pravidla trackera modlitieb (A7.1, docs/02 E2) - ciste funkcie.
abstract final class PrayerTracker {
  /// Den, ktory tracker ukazuje v okamihu [now]: po polnoci do fajr je to
  /// predosly den ("Isha time continues until Fajr"). Bez polohy datum
  /// z hodin.
  static LocalDate trackerDate(PrayerSchedule? schedule, DateTime now) {
    final today = LocalDate.fromDateTime(now);
    if (schedule == null) return today;
    final current = schedule.current(now);
    return current.prayer == Prayer.isha && current.day.isBefore(today)
        ? current.day
        : today;
  }

  /// Stav po tapnuti na prazdny kruzok modlitby [prayer] dna [date] v case
  /// [now]: `on_time` pred zaciatkom dalsieho casu (fajr konci vychodom,
  /// isha fajrom dalsieho dna), inak `late`. Buduca modlitba = null (kruzok
  /// je disabled). Bez polohy vzdy `on_time`.
  static PrayerStatus? statusForTap(
    PrayerSchedule? schedule,
    LocalDate date,
    Prayer prayer,
    DateTime now,
  ) {
    if (!prayer.isSalah) {
      throw ArgumentError.value(prayer, 'prayer', 'sunrise is not tracked');
    }
    if (schedule == null) return PrayerStatus.onTime;
    final day = schedule.day(date);
    if (day[prayer].isAfter(now)) return null;
    final end = switch (prayer) {
      Prayer.fajr => day[Prayer.sunrise],
      Prayer.dhuhr => day[Prayer.asr],
      Prayer.asr => day[Prayer.maghrib],
      Prayer.maghrib => day[Prayer.isha],
      Prayer.isha ||
      Prayer.sunrise => schedule.day(date.addDays(1))[Prayer.fajr],
    };
    return now.isBefore(end) ? PrayerStatus.onTime : PrayerStatus.late;
  }

  /// Hranice faz dna pre FeedGenerator (DayPhase) v lokalnom case
  /// zariadenia; null ked casy nejdu zoradit (polarny den).
  static DayBoundaries? dayBoundaries(PrayerSchedule schedule, LocalDate date) {
    final day = schedule.day(date);
    DateTime local(Prayer p) =>
        DateTime.fromMillisecondsSinceEpoch(day[p].millisecondsSinceEpoch);
    try {
      return DayBoundaries(
        fajr: local(Prayer.fajr),
        dhuhr: local(Prayer.dhuhr),
        asr: local(Prayer.asr),
        isha: local(Prayer.isha),
      );
      // DayBoundaries hadze ArgumentError pri neusporiadanych casoch.
      // ignore: avoid_catching_errors
    } on ArgumentError {
      return null;
    }
  }
}

/// [PrayerRepository] nad nastaveniami a `prayer_log` v user.db.
class DriftPrayerRepository implements PrayerRepository {
  DriftPrayerRepository({
    required this._db,
    required this._settings,
    required this._clock,
    this._onChanged,
  });

  final UserDb _db;
  final Clock _clock;
  final SettingsRepository _settings;
  final PrayerSettingsChanged? _onChanged;

  /// `prayer.asr` bez defaultu: null = este nikdy neulozene.
  static final SettingKey<String?> _storedAsr = SettingKey.optionalString(
    SettingsKeys.prayerAsr.name,
  );

  static final _keys = <SettingKey<Object?>>[
    SettingsKeys.prayerLocation,
    SettingsKeys.prayerMethod,
    SettingsKeys.prayerAsr,
    SettingsKeys.prayerHighLatRule,
    SettingsKeys.prayerAdjust,
  ];

  @override
  Future<PrayerConfig?> config() async {
    final loaded = await CalcSettings.load(_settings);
    return loaded == null ? null : PrayerConfig(loaded.$1, loaded.$2);
  }

  @override
  Stream<PrayerConfig?> watchConfig() {
    late StreamController<PrayerConfig?> controller;
    final subs = <StreamSubscription<Object?>>[];
    var emitted = false;
    PrayerConfig? last;
    Future<void> emit() async {
      final next = await config();
      if (!emitted || next != last) {
        emitted = true;
        last = next;
        if (!controller.isClosed) controller.add(next);
      }
    }

    controller = StreamController<PrayerConfig?>(
      onListen: () {
        for (final k in _keys) {
          subs.add(_settings.watch(k).listen((_) => emit()));
        }
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return controller.stream;
  }

  @override
  Future<void> saveLocation(
    PrayerLocation location, {
    bool resetAsr = false,
  }) async {
    await _settings.set(SettingsKeys.prayerLocation, location);
    final autoMethod = await _settings.get(SettingsKeys.prayerMethod) == null;
    final asrStored = await _settings.get(_storedAsr) != null;
    if (autoMethod && (!asrStored || resetAsr)) {
      await _settings.set(
        SettingsKeys.prayerAsr,
        CountryDefaults.forCountry(location.country).asr.key,
      );
    }
    await _changed();
  }

  @override
  Future<void> setMethod(PrayerMethod? method) async {
    if (method == null) {
      await _settings.reset(SettingsKeys.prayerMethod);
    } else {
      await _settings.set(SettingsKeys.prayerMethod, method.key);
    }
    await _changed();
  }

  @override
  Future<void> setAsr(AsrMadhab asr) async {
    await _settings.set(SettingsKeys.prayerAsr, asr.key);
    await _changed();
  }

  @override
  Future<void> setHighLatRule(HighLatRule? rule) async {
    if (rule == null) {
      await _settings.reset(SettingsKeys.prayerHighLatRule);
    } else {
      await _settings.set(SettingsKeys.prayerHighLatRule, rule.key);
    }
    await _changed();
  }

  @override
  Future<void> setAdjust(Prayer prayer, int minutes) async {
    if (!prayer.isSalah) {
      throw ArgumentError.value(prayer, 'prayer', 'sunrise has no adjust');
    }
    RangeError.checkValueInInterval(minutes, -30, 30, 'minutes');
    final current = {...await _settings.get(SettingsKeys.prayerAdjust)};
    if (minutes == 0) {
      current.remove(prayer.name);
    } else {
      current[prayer.name] = minutes;
    }
    await _settings.set(SettingsKeys.prayerAdjust, current);
    await _changed();
  }

  Future<void> _changed() async => await _onChanged?.call();

  @override
  Stream<Map<Prayer, PrayerStatus>> watchLog(LocalDate date) => _db.prayerLogDao
      .watchForDate(date)
      .map((rows) => {for (final r in rows) _prayer(r.prayer): r.status});

  @override
  Future<void> setStatus(LocalDate date, Prayer prayer, PrayerStatus status) =>
      _db.prayerLogDao.setStatus(
        date,
        _kind(prayer),
        status,
        _clock.now().toUtc(),
      );

  @override
  Future<void> clearStatus(LocalDate date, Prayer prayer) =>
      _db.prayerLogDao.clear(date, _kind(prayer));

  static PrayerKind _kind(Prayer p) => switch (p) {
    Prayer.fajr => PrayerKind.fajr,
    Prayer.dhuhr => PrayerKind.dhuhr,
    Prayer.asr => PrayerKind.asr,
    Prayer.maghrib => PrayerKind.maghrib,
    Prayer.isha => PrayerKind.isha,
    Prayer.sunrise => throw ArgumentError.value(p, 'prayer', 'not tracked'),
  };

  static Prayer _prayer(PrayerKind k) => switch (k) {
    PrayerKind.fajr => Prayer.fajr,
    PrayerKind.dhuhr => Prayer.dhuhr,
    PrayerKind.asr => Prayer.asr,
    PrayerKind.maghrib => Prayer.maghrib,
    PrayerKind.isha => Prayer.isha,
  };
}
