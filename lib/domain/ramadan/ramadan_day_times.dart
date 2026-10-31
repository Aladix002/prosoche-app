import 'package:prosoche/domain/common/local_date.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:prosoche/domain/prayer/prayer_schedule.dart';
import 'package:timezone/timezone.dart' as tz;

/// Hranice dna pre Ramadan: fajr (koniec suhuru), asr (otazky) a maghrib
/// (iftar, zaciatok islamskeho dna), docs/04 1.2-1.3.
///
/// S polohou ide o casy z [PrayerSchedule] (vratane metody, high latitude
/// a rucnych posunov). Bez polohy su to nahradne casy v zone [zone]
/// (05:00, 15:00, 18:00), aby sa stav sezony dal urcit; suhur a iftar
/// sa bez polohy nezobrazuju ([hasLocation]).
final class RamadanDayTimes {
  RamadanDayTimes({required this.zone, this.schedule});

  /// Casy podla rozvrhu v zone polohy.
  factory RamadanDayTimes.forSchedule(PrayerSchedule schedule) =>
      RamadanDayTimes(zone: schedule.zone, schedule: schedule);

  final tz.Location zone;
  final PrayerSchedule? schedule;

  final _days = <LocalDate, PrayerDay>{};

  bool get hasLocation => schedule != null;

  /// Kalendarny den okamihu [instant] v [zone].
  LocalDate dateOf(DateTime instant) =>
      LocalDate.fromDateTime(tz.TZDateTime.from(instant, zone));

  tz.TZDateTime fajr(LocalDate date) => _time(date, Prayer.fajr, 5);
  tz.TZDateTime asr(LocalDate date) => _time(date, Prayer.asr, 15);
  tz.TZDateTime maghrib(LocalDate date) => _time(date, Prayer.maghrib, 18);

  tz.TZDateTime _time(LocalDate date, Prayer prayer, int fallbackHour) {
    final s = schedule;
    if (s == null) {
      return tz.TZDateTime(zone, date.year, date.month, date.day, fallbackHour);
    }
    return (_days[date] ??= s.day(date))[prayer];
  }
}
