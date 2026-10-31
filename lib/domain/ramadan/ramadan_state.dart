import 'package:meta/meta.dart';
import 'package:sakina/domain/calendar/islamic_calendar.dart';
import 'package:sakina/domain/common/local_date.dart';
import 'package:sakina/domain/ramadan/ramadan_day_times.dart';
import 'package:sakina/domain/ramadan/ramadan_season.dart';

/// Faza sezony (zjednoduseny `RamadanSeasonState`, docs/04 1.2).
///
/// ```text
/// inactive -(25. Shaban)-> upcoming
/// upcoming -(29. Shaban po asre)-> awaitingConfirmation
/// awaitingConfirmation -(Zajtra/Pozajtra/Vypocet)-> confirmed
/// awaitingConfirmation -(bez odpovede do maghribu pred startom)-> active
/// confirmed -(maghrib dna pred startom)-> active
/// active -(29. den po asre, koniec nepotvrdeny)-> ending
/// ending -(Ano/Nie/bez odpovede)-> active alebo eid
/// active -(maghrib posledneho dna)-> eid -(maghrib dna Eid)-> inactive
/// ```
enum RamadanPhase {
  inactive,
  upcoming,
  awaitingConfirmation,
  confirmed,
  active,
  ending,
  eid;

  /// Ramadan prebieha (vratane otazky na koniec).
  bool get isActive => this == active || this == ending;
}

/// Ciel odpoctu na Dnes.
enum FastingMoment {
  /// Koniec suhuru = fajr (docs/04 1.3).
  suhurEnd,

  /// Iftar = maghrib.
  iftar,
}

/// Odpocet do konca suhuru alebo do iftaru.
@immutable
final class FastingCountdown {
  const FastingCountdown({
    required this.moment,
    required this.at,
    required this.left,
    required this.fastingDay,
    required this.dayNumber,
  });

  final FastingMoment moment;

  /// Okamih ciela (v zone polohy).
  final DateTime at;

  /// Zostavajuci cas (rozdiel okamihov, nezavisi od DST).
  final Duration left;

  /// Gregoriansky den postu, ku ktoremu ciel patri.
  final LocalDate fastingDay;

  /// Den Ramadanu (1..30) dna [fastingDay].
  final int dayNumber;

  @override
  bool operator ==(Object other) =>
      other is FastingCountdown &&
      other.moment == moment &&
      other.at.isAtSameMomentAs(at) &&
      other.left == left &&
      other.fastingDay == fastingDay &&
      other.dayNumber == dayNumber;

  @override
  int get hashCode => Object.hash(
    moment,
    at.millisecondsSinceEpoch,
    left,
    fastingDay,
    dayNumber,
  );

  @override
  String toString() =>
      'FastingCountdown(${moment.name}, $fastingDay #$dayNumber, $left)';
}

/// Stav Ramadanu v jednom okamihu.
@immutable
final class RamadanState {
  const RamadanState({
    required this.phase,
    this.season,
    this.night,
    this.isNight = false,
    this.countdown,
    this.trackerDay,
  });

  static const inactive = RamadanState(phase: RamadanPhase.inactive);

  final RamadanPhase phase;

  /// Sezona; null len pri [RamadanPhase.inactive].
  final RamadanSeason? season;

  /// Cislo islamskeho dna Ramadanu (noc N zacina maghribom dna N-1).
  final int? night;

  /// Je noc (od maghribu do fajr), inak den postu.
  final bool isNight;

  /// Odpocet suhur/iftar; null bez polohy alebo mimo Ramadanu.
  final FastingCountdown? countdown;

  /// Den postu, ktoreho zaznam sa ponuka (po iftare do dalsieho iftaru).
  final LocalDate? trackerDay;

  @override
  bool operator ==(Object other) =>
      other is RamadanState &&
      other.phase == phase &&
      other.season == season &&
      other.night == night &&
      other.isNight == isNight &&
      other.countdown == countdown &&
      other.trackerDay == trackerDay;

  @override
  int get hashCode =>
      Object.hash(phase, season, night, isNight, countdown, trackerDay);

  @override
  String toString() =>
      'RamadanState(${phase.name}, $season, night: $night, '
      'countdown: $countdown, tracker: $trackerDay)';
}

/// Vyhodnotenie stavu Ramadanu (cista funkcia, cas z `Clock`).
final class RamadanStateMachine {
  const RamadanStateMachine({required this.calendar});

  /// Umm al-Qura s globalnym `hijri.offset`.
  final IslamicCalendar calendar;

  RamadanState resolve({
    required DateTime now,
    required RamadanDayTimes times,
    RamadanConfirmation? stored,
  }) {
    final today = times.dateOf(now);
    final resolver = RamadanSeasonResolver(calendar);
    final year = ramadanSeasonYearOf(calendar, today);
    if (year == null) return RamadanState.inactive;
    final season = resolver.resolve(year, stored: stored);
    bool reached(DateTime t) => !now.isBefore(t);

    if (reached(times.maghrib(season.eidDate))) return RamadanState.inactive;
    if (reached(times.maghrib(season.lastDay))) {
      return RamadanState(
        phase: RamadanPhase.eid,
        season: season,
        trackerDay: _trackerDay(season, today, now, times),
      );
    }
    if (reached(times.maghrib(season.startDate.addDays(-1)))) {
      final afterMaghrib = reached(times.maghrib(today));
      final night = season.nightOfDate(today, afterMaghrib: afterMaghrib);
      final ending =
          !season.lengthConfirmed &&
          season.dayOf(today) == 29 &&
          reached(times.asr(today)) &&
          !afterMaghrib;
      return RamadanState(
        phase: ending ? RamadanPhase.ending : RamadanPhase.active,
        season: season,
        night: night,
        isNight: afterMaghrib || now.isBefore(times.fajr(today)),
        countdown: times.hasLocation
            ? _countdown(season, today, now, times)
            : null,
        trackerDay: _trackerDay(season, today, now, times),
      );
    }
    final ownStored = stored != null && stored.hijriYear == year;
    if (ownStored) {
      return RamadanState(phase: RamadanPhase.confirmed, season: season);
    }
    if (reached(times.asr(resolver.questionDay(year)))) {
      return RamadanState(
        phase: RamadanPhase.awaitingConfirmation,
        season: season,
      );
    }
    if (!today.isBefore(resolver.upcomingFrom(year))) {
      return RamadanState(phase: RamadanPhase.upcoming, season: season);
    }
    return RamadanState.inactive;
  }

  /// Odpoved na "Kedy zacina Ramadan vo vasej komunite?" v den [answerDay]
  /// (29. Shaban): [daysAhead] 1 = zajtra, 2 = pozajtra, null = vypocet.
  RamadanConfirmation confirmStart({
    required int hijriYear,
    required LocalDate answerDay,
    int? daysAhead,
  }) {
    if (daysAhead == null) {
      return RamadanConfirmation(
        hijriYear: hijriYear,
        startDate: RamadanSeasonResolver(calendar).calcStart(hijriYear),
        source: SeasonSource.calc,
      );
    }
    RangeError.checkValueInInterval(daysAhead, 1, 2, 'daysAhead');
    return RamadanConfirmation(
      hijriYear: hijriYear,
      startDate: answerDay.addDays(daysAhead),
      source: SeasonSource.userConfirmed,
    );
  }

  /// Odpoved na "Je zajtra Eid?" 29. dna: ano = 29 dni, nie = 30,
  /// null = vypocet (dlzka podla Umm al-Qura).
  RamadanConfirmation confirmEnd({
    required RamadanSeason season,
    required bool? eidTomorrow,
  }) {
    final base = RamadanConfirmation(
      hijriYear: season.hijriYear,
      startDate: season.startDate,
      source: season.source,
    );
    return base.withLength(
      eidTomorrow == null
          ? calendar.monthLength(season.hijriYear, 9)
          : eidTomorrow
          ? 29
          : 30,
    );
  }

  static FastingCountdown? _countdown(
    RamadanSeason season,
    LocalDate today,
    DateTime now,
    RamadanDayTimes times,
  ) {
    FastingCountdown at(FastingMoment m, LocalDate day, DateTime t) =>
        FastingCountdown(
          moment: m,
          at: t,
          left: t.difference(now),
          fastingDay: day,
          dayNumber: season.dayOf(day)!,
        );
    if (season.isFastingDay(today)) {
      final fajr = times.fajr(today);
      if (now.isBefore(fajr)) return at(FastingMoment.suhurEnd, today, fajr);
      final maghrib = times.maghrib(today);
      if (now.isBefore(maghrib)) return at(FastingMoment.iftar, today, maghrib);
    }
    final tomorrow = today.addDays(1);
    if (season.isFastingDay(tomorrow)) {
      return at(FastingMoment.suhurEnd, tomorrow, times.fajr(tomorrow));
    }
    return null;
  }

  /// Posledny den postu, ktoreho iftar uz bol (do iftaru dalsieho dna).
  static LocalDate? _trackerDay(
    RamadanSeason season,
    LocalDate today,
    DateTime now,
    RamadanDayTimes times,
  ) {
    final day = !now.isBefore(times.maghrib(today)) ? today : today.addDays(-1);
    return season.isFastingDay(day) ? day : null;
  }
}
