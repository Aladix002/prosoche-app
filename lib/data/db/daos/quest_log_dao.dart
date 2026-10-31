import 'package:drift/drift.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/domain/common/common.dart';

part 'quest_log_dao.g.dart';

/// `quest_log` (A2 Dnes, A8.2, plan 7.2).
@DriftAccessor(tables: [QuestLogs])
class QuestLogDao extends DatabaseAccessor<UserDb> with _$QuestLogDaoMixin {
  QuestLogDao(super.attachedDatabase);

  SimpleSelectStatement<$QuestLogsTable, QuestLogRow> _forDate(LocalDate d) =>
      select(questLogs)
        ..where((t) => t.date.equalsValue(d))
        ..orderBy([(t) => OrderingTerm.asc(t.slot)]);

  Future<List<QuestLogRow>> forDate(LocalDate date) => _forDate(date).get();

  Stream<List<QuestLogRow>> watchForDate(LocalDate date) =>
      _forDate(date).watch();

  /// Priradi questy dna, ak este nie su (questy dna sa po zmene nastaveni
  /// nemenia, A10.8). Vrati pocet novych riadkov.
  Future<int> assignIfAbsent(
    LocalDate date,
    Map<QuestSlotKind, String> questIds,
  ) => transaction(() async {
    var n = 0;
    for (final MapEntry(key: slot, value: id) in questIds.entries) {
      final row = await into(questLogs).insertReturningOrNull(
        QuestLogsCompanion.insert(date: date, slot: slot, questId: id),
        onConflict: DoNothing(),
      );
      if (row != null) n++;
    }
    return n;
  });

  /// Zmeni stav questu; `done_at` = [at] pri `done`, inak null (Undo).
  Future<bool> setStatus(
    LocalDate date,
    QuestSlotKind slot,
    QuestStatus status, {
    DateTime? at,
  }) async {
    final n =
        await (update(questLogs)..where(
              (t) => t.date.equalsValue(date) & t.slot.equalsValue(slot),
            ))
            .write(
              QuestLogsCompanion(
                status: Value(status),
                doneAt: Value(status == QuestStatus.done ? at : null),
              ),
            );
    return n > 0;
  }

  /// Posledny datum priradenia kazdeho questu (cooldown, docs/03 3.4).
  Future<Map<String, LocalDate>> lastAssigned() async {
    final max = questLogs.date.max();
    final q = selectOnly(questLogs)
      ..addColumns([questLogs.questId, max])
      ..groupBy([questLogs.questId]);
    return {
      for (final r in await q.get())
        r.read(questLogs.questId)!: LocalDate.parse(r.read(max)!),
    };
  }
}
