import 'package:prosoche/domain/calendar/islamic_calendar.dart';
import 'package:prosoche/domain/common/local_date.dart';
import 'package:prosoche/domain/ramadan/ramadan_season.dart';

/// Dni postu v okne [from] .. [from] + [days] (vstup
/// `NotificationPlanInput.fastingDays`, docs/04 1.10).
///
/// V tieto dni planner zluci rannu notifikaciu so suhur pripomienkou
/// a maghrib s iftarom, takze rozpocet ostava 6 notifikacii za den.
Set<LocalDate> ramadanFastingDays({
  required IslamicCalendar calendar,
  required LocalDate from,
  required int days,
  RamadanConfirmation? stored,
}) {
  final resolver = RamadanSeasonResolver(calendar);
  final seasons = <int, RamadanSeason?>{};
  RamadanSeason? seasonOf(LocalDate d) {
    final year = ramadanSeasonYearOf(calendar, d);
    if (year == null) return null;
    return seasons[year] ??= resolver.resolve(year, stored: stored);
  }

  return {
    for (var i = 0; i < days; i++)
      if (seasonOf(from.addDays(i))?.isFastingDay(from.addDays(i)) ?? false)
        from.addDays(i),
  };
}
