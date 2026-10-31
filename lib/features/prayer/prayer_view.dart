import 'package:meta/meta.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/prayer/calc_settings.dart';
import 'package:sakina/domain/prayer/prayer.dart';
import 'package:sakina/domain/prayer/prayer_schedule.dart';
import 'package:sakina/ui/components/sk_prayer_row.dart';

/// Jeden riadok obrazovky casov (A7.1) - ciste data bez Fluttera.
@immutable
final class PrayerRowModel {
  const PrayerRowModel({
    required this.prayer,
    required this.state,
    required this.status,
    this.time,
    this.until,
    this.canLog = true,
    this.estimated = false,
    this.adjustMinutes = 0,
    this.notificationOff = false,
  });

  final Prayer prayer;

  /// Zaciatok v zone polohy; null bez polohy.
  final DateTime? time;
  final SkPrayerRowState state;

  /// Zaznam trackera; null = neoznacene (sunrise vzdy null).
  final PrayerStatus? status;

  /// Cas do zaciatku pre riadok `next`.
  final Duration? until;

  /// false = modlitba este nezacala (kruzok disabled, A7.1).
  final bool canLog;
  final bool estimated;
  final int adjustMinutes;
  final bool notificationOff;
}

/// Koniec casu modlitby podla trackera (A7.1): fajr vychodom slnka, isha
/// fajrom dalsieho dna, ostatne zaciatkom dalsieho casu.
DateTime prayerWindowEnd(PrayerSchedule schedule, LocalDate date, Prayer p) {
  final day = schedule.day(date);
  return switch (p) {
    Prayer.fajr => day[Prayer.sunrise],
    Prayer.sunrise => day[Prayer.dhuhr],
    Prayer.dhuhr => day[Prayer.asr],
    Prayer.asr => day[Prayer.maghrib],
    Prayer.maghrib => day[Prayer.isha],
    Prayer.isha => schedule.day(date.addDays(1))[Prayer.fajr],
  };
}

/// Riadky dna [date] v okamihu [now].
///
/// Bez polohy ([schedule] null) len 5 modlitieb bez casov, vsetky sa daju
/// oznacit (tap = `on_time`, A7.1 "bez polohy").
List<PrayerRowModel> buildPrayerRows({
  required LocalDate date,
  required DateTime now,
  required Map<Prayer, PrayerStatus> log,
  PrayerSchedule? schedule,
  Set<Prayer> estimated = const {},
  Set<Prayer> notificationsOff = const {},
}) {
  if (schedule == null) {
    return [
      for (final p in Prayer.salah)
        PrayerRowModel(
          prayer: p,
          state: SkPrayerRowState.upcoming,
          status: _logged(log[p]),
        ),
    ];
  }
  final day = schedule.day(date);
  final next = schedule.next(now);
  return [
    for (final p in Prayer.values)
      () {
        final start = day[p];
        final end = prayerWindowEnd(schedule, date, p);
        final future = start.isAfter(now);
        final isNext = next.prayer == p && next.day == date;
        final state = isNext
            ? SkPrayerRowState.next
            : future
            ? SkPrayerRowState.upcoming
            : now.isBefore(end) && p.isSalah
            ? SkPrayerRowState.current
            : SkPrayerRowState.passed;
        return PrayerRowModel(
          prayer: p,
          time: start,
          state: state,
          status: p.isSalah ? _logged(log[p]) : null,
          until: isNext ? start.difference(now) : null,
          canLog: !future,
          estimated: estimated.contains(p),
          adjustMinutes: schedule.settings.adjust[p] ?? 0,
          notificationOff: p.isSalah && notificationsOff.contains(p),
        );
      }(),
  ];
}

/// `excused` (docs/03 6.5) sa v trackeri neukazuje ako vyplneny kruzok.
PrayerStatus? _logged(PrayerStatus? s) => s == PrayerStatus.excused ? null : s;

SkPrayerStatus skStatus(PrayerStatus? s) => switch (s) {
  null || PrayerStatus.excused => SkPrayerStatus.unlogged,
  PrayerStatus.onTime => SkPrayerStatus.onTime,
  PrayerStatus.late => SkPrayerStatus.late,
  PrayerStatus.missed => SkPrayerStatus.missed,
  PrayerStatus.qada => SkPrayerStatus.qada,
};

/// Fajr a isha, ktorych cas v den [date] urcilo pravidlo vysokych sirok,
/// nie uhol slnka (docs/01 3.2 modifikator `estimated`).
///
/// Heuristika: pravidla `twilight_angle` a `middle_of_night` maju najvolnejsie
/// hranice noci; ked je cas podla uhla dosiahnutelny, obe vratia ten isty
/// cas. Ked sa lisia, uhol sa v tu noc nedosiahol a cas je odhad.
Set<Prayer> estimatedPrayers(PrayerSchedule schedule, LocalDate date) {
  PrayerDay dayWith(HighLatRule rule) => PrayerSchedule(
    lat: schedule.lat,
    lng: schedule.lng,
    zone: schedule.zone,
    settings: CalcSettings(
      method: schedule.settings.method,
      asr: schedule.settings.asr,
      highLatRule: rule,
    ),
  ).day(date);
  final a = dayWith(HighLatRule.twilightAngle);
  final b = dayWith(HighLatRule.middleOfNight);
  return {
    for (final p in const [Prayer.fajr, Prayer.isha])
      if (!a[p].isAtSameMomentAs(b[p])) p,
  };
}
