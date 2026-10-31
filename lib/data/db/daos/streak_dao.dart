import 'package:drift/drift.dart';
import 'package:sakina/data/db/user_db.dart';
import 'package:sakina/domain/common/common.dart';

part 'streak_dao.g.dart';

/// `streak_state` a `day_log` (docs/02 D8, A2, A8.1).
@DriftAccessor(tables: [StreakStates, DayLogs])
class StreakDao extends DatabaseAccessor<UserDb> with _$StreakDaoMixin {
  StreakDao(super.attachedDatabase);

  SimpleSelectStatement<$StreakStatesTable, StreakStateRow> get _state =>
      select(streakStates)..where((t) => t.id.equals(1));

  /// Stav streaku; null pred prvym vyhodnotenim.
  Future<StreakStateRow?> state() => _state.getSingleOrNull();

  Stream<StreakStateRow?> watchState() => _state.watchSingleOrNull();

  /// Ulozi vysledok vyhodnotenia: nove dni do `day_log` a stav, atomicky
  /// (idempotentne vyhodnotenie po niekolkych dnoch, D8).
  Future<void> saveEvaluation({
    required int current,
    required int longest,
    required int graceLeft,
    required LocalDate lastEvaluatedDate,
    LocalDate? graceRefillAt,
    List<DayLogRow> days = const [],
  }) => transaction(() async {
    for (final d in days) {
      await into(dayLogs).insertOnConflictUpdate(d);
    }
    await into(streakStates).insertOnConflictUpdate(
      StreakStatesCompanion.insert(
        id: const Value(1),
        current: Value(current),
        longest: Value(longest),
        graceLeft: Value(graceLeft),
        graceRefillAt: Value(graceRefillAt),
        lastEvaluatedDate: Value(lastEvaluatedDate),
      ),
    );
  });

  Future<DayLogRow?> day(LocalDate date) => (select(
    dayLogs,
  )..where((t) => t.date.equalsValue(date))).getSingleOrNull();

  /// Dni v rozsahu [from]..[to] vratane (kalendar mesiaca A8.1).
  Future<List<DayLogRow>> range(LocalDate from, LocalDate to) =>
      _range(from, to).get();

  Stream<List<DayLogRow>> watchRange(LocalDate from, LocalDate to) =>
      _range(from, to).watch();

  SimpleSelectStatement<$DayLogsTable, DayLogRow> _range(
    LocalDate from,
    LocalDate to,
  ) => select(dayLogs)
    ..where((t) => t.date.isBetweenValues(from.toString(), to.toString()))
    ..orderBy([(t) => OrderingTerm.asc(t.date)]);
}
