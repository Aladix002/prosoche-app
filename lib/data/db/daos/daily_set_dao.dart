import 'package:drift/drift.dart';
import 'package:sakina/data/db/user_db.dart';
import 'package:sakina/domain/common/common.dart';

part 'daily_set_dao.g.dart';

/// `daily_set` (docs/02 0.1, 0.3, D13; A2, A3, A4).
@DriftAccessor(tables: [DailySets])
class DailySetDao extends DatabaseAccessor<UserDb> with _$DailySetDaoMixin {
  DailySetDao(super.attachedDatabase);

  SimpleSelectStatement<$DailySetsTable, DailySetRow> _byDate(LocalDate d) =>
      select(dailySets)..where((t) => t.date.equalsValue(d));

  Future<DailySetRow?> byDate(LocalDate date) =>
      _byDate(date).getSingleOrNull();

  Stream<DailySetRow?> watchByDate(LocalDate date) =>
      _byDate(date).watchSingleOrNull();

  /// Najvyssi datum sady (cestovanie na zapad, docs/02 0.1).
  Future<LocalDate?> latestDate() async {
    final max = dailySets.date.max();
    final raw = (await (selectOnly(
      dailySets,
    )..addColumns([max])).getSingle()).read(max);
    return raw == null ? null : LocalDate.parse(raw);
  }

  /// Ulozi novu sadu. Existujucu sadu pre ten den nikdy neprepise
  /// (determinizmus) a vrati `false`.
  Future<bool> insertIfAbsent({
    required LocalDate date,
    required int seed,
    required String cardsJson,
    required int generatorVersion,
    required String contentVersion,
    required String tz,
    required DayPhase phase,
  }) async {
    final row = await into(dailySets).insertReturningOrNull(
      DailySetsCompanion.insert(
        date: date,
        seed: seed,
        cardsJson: cardsJson,
        generatorVersion: generatorVersion,
        contentVersion: contentVersion,
        tz: tz,
        phase: phase,
      ),
      onConflict: DoNothing(),
    );
    return row != null;
  }

  /// Posunie `cursor` na [cursor], ak je vacsi (nikdy necuva). Pri prvom
  /// posune vyplni `started_at`. Vrati `true`, ak sa zmenil.
  Future<bool> advanceCursor(LocalDate date, int cursor, DateTime now) async {
    final n = await customUpdate(
      'UPDATE daily_set SET cursor = ?1, '
      'started_at = COALESCE(started_at, ?2) '
      'WHERE date = ?3 AND cursor < ?1',
      variables: [
        Variable.withInt(cursor),
        Variable.withInt(now.millisecondsSinceEpoch),
        Variable.withString(date.toString()),
      ],
      updates: {dailySets},
      updateKind: UpdateKind.update,
    );
    return n > 0;
  }

  /// Oznaci sadu ako dokoncenu (len raz). Vrati `true` pri prvom zapise.
  Future<bool> markCompleted(LocalDate date, DateTime now) async {
    final n =
        await (update(dailySets)
              ..where((t) => t.date.equalsValue(date) & t.completedAt.isNull()))
            .write(DailySetsCompanion(completedAt: Value(now)));
    return n > 0;
  }

  /// Sady v rozsahu [from]..[to] vratane (Moja cesta, A8).
  Future<List<DailySetRow>> range(LocalDate from, LocalDate to) =>
      (select(dailySets)
            ..where(
              (t) => t.date.isBetweenValues(from.toString(), to.toString()),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.date)]))
          .get();
}
