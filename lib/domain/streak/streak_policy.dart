import 'package:meta/meta.dart';
import 'package:sakina/domain/common/common.dart';

/// Stav dna v `day_log.status` (docs/02 D8).
///
/// [excused] je navrh rozsirenia D8: ospravedlneny den streak nezlomi
/// a nemina grace day (docs/03 6.5), v kalendari je odliseny.
enum DayStatus {
  done('done'),
  grace('grace'),
  missed('missed'),
  excused('excused');

  DayStatus(this.wire);

  final String wire;

  static DayStatus? fromWire(String wire) {
    for (final s in values) {
      if (s.wire == wire) return s;
    }
    return null;
  }
}

/// Co den splnilo (`day_log.sources`).
enum DaySource {
  /// Dokoncena denna sada.
  set('set'),

  /// Aspon 1 splneny quest.
  quest('quest');

  DaySource(this.wire);

  final String wire;
}

/// Fakty o jednom dni pre vyhodnotenie (z `daily_set`, `quest_log`
/// a ospravedlnenych dni). Casy su lokalne (wall clock) z `Clock`.
@immutable
final class DayActivity {
  DayActivity({
    this.setCompletedAt,
    List<DateTime> questsDoneAt = const [],
    this.excused = false,
    this.skippedByTravel = false,
  }) : questsDoneAt = List.unmodifiable(questsDoneAt);

  /// `daily_set.completed_at` sady tohto dna.
  final DateTime? setCompletedAt;

  /// `quest_log.done_at` splnenych questov tohto dna (auto aj act).
  final List<DateTime> questsDoneAt;

  /// Den bol oznaceny ako ospravedlneny.
  final bool excused;

  /// Kalendarny den preskoceny letom na vychod cez datumovu hranicu (D-02):
  /// bez aktivity sa nerata ako vynechany, nemina grace day a nema riadok
  /// v `day_log`.
  final bool skippedByTravel;
}

/// Riadok `day_log` (docs/02 D8).
@immutable
final class DayLogEntry {
  DayLogEntry({
    required this.date,
    required this.status,
    Set<DaySource> sources = const {},
  }) : sources = Set.unmodifiable(sources);

  final LocalDate date;
  final DayStatus status;
  final Set<DaySource> sources;

  /// `sources` ako TEXT, napr. `set,quest` (prazdny retazec = nic).
  String get sourcesWire => [
    for (final s in DaySource.values)
      if (sources.contains(s)) s.wire,
  ].join(',');

  @override
  bool operator ==(Object other) =>
      other is DayLogEntry &&
      other.date == date &&
      other.status == status &&
      other.sourcesWire == sourcesWire;

  @override
  int get hashCode => Object.hash(date, status, sourcesWire);

  @override
  String toString() => 'DayLogEntry($date, ${status.wire}, $sourcesWire)';
}

/// `streak_state` vratane `last_evaluated_date` (docs/02 D8).
@immutable
final class StreakState {
  const StreakState({
    required this.current,
    required this.longest,
    required this.graceLeft,
    required this.lastEvaluatedDate,
    this.graceRefillAt,
  });

  /// Stav pred prvym dnom [firstDay] (napr. den instalacie).
  StreakState.initial(LocalDate firstDay, {int graceDays = 2})
    : this(
        current: 0,
        longest: 0,
        graceLeft: graceDays,
        lastEvaluatedDate: firstDay.addDays(-1),
      );

  final int current;
  final int longest;
  final int graceLeft;

  /// Den, od ktoreho su grace days znova plne; null = plne alebo bez
  /// pouzitia.
  final LocalDate? graceRefillAt;

  /// Posledny uzavrety a vyhodnoteny den.
  final LocalDate lastEvaluatedDate;

  /// Streak na zobrazenie dnes: [current] plus dnesok, ak je uz splneny.
  int displayCurrent({required bool todayDone}) =>
      todayDone ? current + 1 : current;

  StreakState copyWith({
    int? current,
    int? longest,
    int? graceLeft,
    LocalDate? lastEvaluatedDate,
    LocalDate? Function()? graceRefillAt,
  }) => StreakState(
    current: current ?? this.current,
    longest: longest ?? this.longest,
    graceLeft: graceLeft ?? this.graceLeft,
    lastEvaluatedDate: lastEvaluatedDate ?? this.lastEvaluatedDate,
    graceRefillAt: graceRefillAt == null ? this.graceRefillAt : graceRefillAt(),
  );

  @override
  bool operator ==(Object other) =>
      other is StreakState &&
      other.current == current &&
      other.longest == longest &&
      other.graceLeft == graceLeft &&
      other.graceRefillAt == graceRefillAt &&
      other.lastEvaluatedDate == lastEvaluatedDate;

  @override
  int get hashCode => Object.hash(
    current,
    longest,
    graceLeft,
    graceRefillAt,
    lastEvaluatedDate,
  );

  @override
  String toString() =>
      'StreakState(current: $current, longest: $longest, '
      'grace: $graceLeft, refill: $graceRefillAt, '
      'evaluated: $lastEvaluatedDate)';
}

/// Vysledok [StreakPolicy.evaluate]: novy stav a nove riadky `day_log`.
@immutable
final class StreakEvaluation {
  StreakEvaluation(this.state, List<DayLogEntry> entries)
    : entries = List.unmodifiable(entries);

  final StreakState state;

  /// Nove dni v poradi datumu (prazdne = nic na vyhodnotenie).
  final List<DayLogEntry> entries;
}

/// Pravidla streaku (plan 7.4, docs/01 5.5 a D6, docs/02 D8, docs/03 6.5).
///
/// - Den je splneny, ked je hotova denna sada alebo aspon 1 quest.
/// - Hranica dna je lokalna polnoc; den D sa uzavrie az o
///   [lateCompletionHours] (03:00) dna D+1 a splnenie do tej doby sa rata.
/// - Vynechany den najprv minie grace day, az potom streak padne na 0.
/// - Grace days: [maxGraceDays]; [graceRefillDays] dni po prvom minuti sa
///   doplnia na maximum.
/// - Ospravedlneny den streak nezlomi a nemina grace day.
/// - Vyhodnotenie je idempotentne: kazdy den sa vyhodnoti prave raz
///   (`last_evaluated_date`), aj po niekolkych dnoch bez otvorenia.
final class StreakPolicy {
  const StreakPolicy({
    this.maxGraceDays = 2,
    this.graceRefillDays = 7,
    this.lateCompletionHours = 3,
  }) : assert(maxGraceDays >= 0, 'maxGraceDays'),
       assert(graceRefillDays >= 1, 'graceRefillDays'),
       assert(
         lateCompletionHours >= 0 && lateCompletionHours < 24,
         'lateCompletionHours',
       );

  final int maxGraceDays;
  final int graceRefillDays;

  /// Tolerancia na dokoncenie predosleho dna (docs/01 D6: 03:00).
  final int lateCompletionHours;

  StreakState initialState(LocalDate firstDay) =>
      StreakState.initial(firstDay, graceDays: maxGraceDays);

  /// Posledny den, ktory je v case [now] (lokalny wall clock) uzavrety.
  LocalDate lastClosedDay(DateTime now) {
    final today = LocalDate.fromDateTime(now);
    return today.addDays(now.hour < lateCompletionHours ? -2 : -1);
  }

  /// Ci [activity] splnila den [date] vcas, a cim.
  Set<DaySource> sources(LocalDate date, DayActivity? activity) {
    if (activity == null) return const {};
    final next = date.addDays(1);
    final deadline = DateTime.utc(
      next.year,
      next.month,
      next.day,
      lateCompletionHours,
    );
    bool inTime(DateTime t) => _wall(t).isBefore(deadline);
    final set = activity.setCompletedAt;
    return {
      if (set != null && inTime(set)) DaySource.set,
      if (activity.questsDoneAt.any(inTime)) DaySource.quest,
    };
  }

  /// Vyhodnoti vsetky uzavrete dni od `state.lastEvaluatedDate + 1`.
  ///
  /// [activity] staci pre tieto dni; chybajuci den = bez aktivity. Ked je
  /// [now] skor ako uz vyhodnotene dni (zmena casovej zony na zapad cez
  /// datumovu hranicu), vrati stav bez zmeny.
  StreakEvaluation evaluate({
    required StreakState state,
    required DateTime now,
    required Map<LocalDate, DayActivity> activity,
  }) {
    final last = lastClosedDay(now);
    var s = state;
    final entries = <DayLogEntry>[];
    for (
      var day = state.lastEvaluatedDate.addDays(1);
      !day.isAfter(last);
      day = day.addDays(1)
    ) {
      final dayActivity = activity[day];
      if ((dayActivity?.skippedByTravel ?? false) &&
          sources(day, dayActivity).isEmpty) {
        s = s.copyWith(lastEvaluatedDate: day);
        continue;
      }
      final (next, entry) = _evaluateDay(s, day, dayActivity);
      s = next;
      entries.add(entry);
    }
    return StreakEvaluation(s, entries);
  }

  (StreakState, DayLogEntry) _evaluateDay(
    StreakState state,
    LocalDate day,
    DayActivity? activity,
  ) {
    var s = state.copyWith(lastEvaluatedDate: day);
    final refillAt = s.graceRefillAt;
    if (refillAt != null && !day.isBefore(refillAt)) {
      s = s.copyWith(graceLeft: maxGraceDays, graceRefillAt: () => null);
    }
    final src = sources(day, activity);
    if (src.isNotEmpty) {
      final current = s.current + 1;
      s = s.copyWith(
        current: current,
        longest: current > s.longest ? current : s.longest,
      );
      return (s, DayLogEntry(date: day, status: DayStatus.done, sources: src));
    }
    if (activity?.excused ?? false) {
      return (s, DayLogEntry(date: day, status: DayStatus.excused));
    }
    if (s.graceLeft > 0) {
      final refill = s.graceRefillAt ?? day.addDays(graceRefillDays);
      s = s.copyWith(graceLeft: s.graceLeft - 1, graceRefillAt: () => refill);
      return (s, DayLogEntry(date: day, status: DayStatus.grace));
    }
    s = s.copyWith(current: 0);
    return (s, DayLogEntry(date: day, status: DayStatus.missed));
  }

  /// Wall clock ako UTC, aby porovnanie nezaviselo od DST.
  static DateTime _wall(DateTime t) => DateTime.utc(
    t.year,
    t.month,
    t.day,
    t.hour,
    t.minute,
    t.second,
    t.millisecond,
  );
}
