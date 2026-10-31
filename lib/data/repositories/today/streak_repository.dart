import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart'
    show
        BooleanExpressionOperators,
        ComparableExpr,
        OrderingTerm,
        TableUpdateQuery;
import 'package:meta/meta.dart';
import 'package:sakina/data/db/user_db.dart' as db;
import 'package:sakina/data/repositories/infra/time_providers.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/streak/streak.dart';
import 'package:timezone/timezone.dart' as tz;

/// Streak na zobrazenie (A2, A8.1). Pri `simple_mode` ho UI skryje.
@immutable
final class StreakSummary {
  const StreakSummary({required this.state, required this.todayDone});

  final StreakState state;

  /// Dnesok je uz splneny (dokoncena sada alebo aspon 1 quest).
  final bool todayDone;

  /// Streak vratane dneska, ak je splneny.
  int get current => state.displayCurrent(todayDone: todayDone);
  int get longest => current > state.longest ? current : state.longest;
  int get graceLeft => state.graceLeft;
}

/// Streak, grace days a `day_log` (plan 7.4, docs/02 D8).
abstract interface class StreakRepository {
  /// Vyhodnoti uzavrete dni (idempotentne, aj po niekolkych dnoch) a vrati
  /// stav pre den [today] (`localDate`).
  Future<StreakSummary> evaluate(LocalDate today);

  /// [evaluate] a potom kazda zmena (dokoncenie sady, quest).
  Stream<StreakSummary> watch(LocalDate today);

  /// `day_log` v rozsahu vratane (kalendar Moja cesta).
  Stream<List<DayLogEntry>> watchDayLog(LocalDate from, LocalDate to);
}

class DriftStreakRepository implements StreakRepository {
  DriftStreakRepository({
    required db.UserDb userDb,
    required this._clock,
    required this._timeZone,
    this._policy = const StreakPolicy(),
  }) : _db = userDb;

  final db.UserDb _db;
  final Clock _clock;
  final Future<String> Function() _timeZone;
  final StreakPolicy _policy;

  Future<StreakState> _loadState(LocalDate today) async {
    final row = await _db.streakDao.state();
    if (row?.lastEvaluatedDate case final last?) {
      return StreakState(
        current: row!.current,
        longest: row.longest,
        graceLeft: row.graceLeft,
        graceRefillAt: row.graceRefillAt,
        lastEvaluatedDate: last,
      );
    }
    return _policy.initialState(await _firstDay(today));
  }

  /// Prvy den s aktivitou (sada alebo quest), inak dnesok.
  Future<LocalDate> _firstDay(LocalDate today) async {
    final set =
        await (_db.select(_db.dailySets)
              ..orderBy([(t) => OrderingTerm.asc(t.date)])
              ..limit(1))
            .getSingleOrNull();
    final quest =
        await (_db.select(_db.questLogs)
              ..orderBy([(t) => OrderingTerm.asc(t.date)])
              ..limit(1))
            .getSingleOrNull();
    var first = today;
    for (final d in [?set?.date, ?quest?.date]) {
      if (d.isBefore(first)) first = d;
    }
    return first;
  }

  @override
  Future<StreakSummary> evaluate(LocalDate today) => _db.transaction(() async {
    final now = _clock.now();
    final state = await _loadState(today);
    final from = state.lastEvaluatedDate.addDays(1);
    final to = _policy.lastClosedDay(now);
    var result = state;
    if (!from.isAfter(to)) {
      final activity = await _activity(from, to);
      for (final d in await _travelSkipped(today, now)) {
        if (!d.isBefore(from) && !d.isAfter(to)) {
          final a = activity[d];
          activity[d] = DayActivity(
            setCompletedAt: a?.setCompletedAt,
            questsDoneAt: a?.questsDoneAt ?? const [],
            excused: a?.excused ?? false,
            skippedByTravel: true,
          );
        }
      }
      final eval = _policy.evaluate(state: state, now: now, activity: activity);
      result = eval.state;
      await _db.streakDao.saveEvaluation(
        current: result.current,
        longest: result.longest,
        graceLeft: result.graceLeft,
        lastEvaluatedDate: result.lastEvaluatedDate,
        graceRefillAt: result.graceRefillAt,
        days: [
          for (final e in eval.entries)
            db.DayLogRow(
              date: e.date,
              status: db.DayStatus.values.byName(e.status.wire),
              sources: e.sources.isEmpty
                  ? null
                  : jsonEncode([
                      for (final s in DaySource.values)
                        if (e.sources.contains(s)) s.wire,
                    ]),
            ),
        ],
      );
    }
    return StreakSummary(state: result, todayDone: await _done(today));
  });

  Future<Map<LocalDate, DayActivity>> _activity(
    LocalDate from,
    LocalDate to,
  ) async {
    final sets = await _db.dailySetDao.range(from, to);
    final quests =
        await (_db.select(_db.questLogs)..where(
              (t) =>
                  t.date.isBetweenValues(from.toString(), to.toString()) &
                  t.doneAt.isNotNull(),
            ))
            .get();
    final completed = {
      for (final s in sets)
        if (s.completedAt case final c?) s.date: c.toLocal(),
    };
    final questTimes = <LocalDate, List<DateTime>>{};
    for (final q in quests) {
      if (q.status == db.QuestStatus.done) {
        (questTimes[q.date] ??= []).add(q.doneAt!.toLocal());
      }
    }
    return {
      for (final d in {...completed.keys, ...questTimes.keys})
        d: DayActivity(
          setCompletedAt: completed[d],
          questsDoneAt: questTimes[d] ?? const [],
        ),
    };
  }

  /// Dni preskocene letom na vychod (rozhodnutie Wave 1): medzi poslednou
  /// aktivitou (sada dna d1 v zone `daily_set.tz`) a dneskom presiel
  /// kalendar o viac dni, nez by presiel v povodnej zone. Rozdiel sa
  /// pripise dnom tesne pred dneskom.
  Future<Set<LocalDate>> _travelSkipped(LocalDate today, DateTime now) async {
    final last =
        await (_db.select(_db.dailySets)
              ..where((t) => t.date.isSmallerThanValue(today.toString()))
              ..orderBy([(t) => OrderingTerm.desc(t.date)])
              ..limit(1))
            .getSingleOrNull();
    if (last == null) return const {};
    final zone = tryTimeZone(last.tz);
    final current = await _timeZone();
    if (zone == null || current == last.tz) return const {};
    final inOldZone = tz.TZDateTime.from(now, zone);
    final k = today.daysSince(LocalDate.fromDateTime(inOldZone));
    return {
      for (var i = 1; i <= k; i++)
        if (today.addDays(-i).isAfter(last.date)) today.addDays(-i),
    };
  }

  Future<bool> _done(LocalDate day) async {
    final set = await _db.dailySetDao.byDate(day);
    if (set?.completedAt != null) return true;
    final quests = await _db.questLogDao.forDate(day);
    return quests.any((q) => q.status == db.QuestStatus.done);
  }

  @override
  Stream<StreakSummary> watch(LocalDate today) async* {
    yield await evaluate(today);
    final changes = _db.tableUpdates(
      TableUpdateQuery.onAllTables([_db.dailySets, _db.questLogs]),
    );
    await for (final _ in changes) {
      yield await evaluate(today);
    }
  }

  @override
  Stream<List<DayLogEntry>> watchDayLog(LocalDate from, LocalDate to) => _db
      .streakDao
      .watchRange(from, to)
      .map(
        (rows) => [
          for (final r in rows)
            DayLogEntry(
              date: r.date,
              status: DayStatus.fromWire(r.status.wire)!,
              sources: {
                for (final w in _sourceWires(r.sources))
                  ...DaySource.values.where((s) => s.wire == w),
              },
            ),
        ],
      );

  /// `day_log.sources` je JSON pole (D-01); starsi tvar `set,quest` tiez.
  static List<String> _sourceWires(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final v = jsonDecode(raw);
      if (v is List<Object?>) return [for (final x in v) '$x'];
    } on FormatException {
      // nizsie
    }
    return raw.split(',');
  }
}
