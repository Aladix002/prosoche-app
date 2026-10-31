import 'package:drift/drift.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/domain/common/common.dart';

part 'practice_log_dao.g.dart';

/// Dokoncena ranna/vecerna prax dna (Practice, F-01). Len znacky
/// dokoncenia (bez textu), preto ostavaju v user.db; dennik je v journal.db.
@DriftAccessor(tables: [PracticeLogs])
class PracticeLogDao extends DatabaseAccessor<UserDb>
    with _$PracticeLogDaoMixin {
  PracticeLogDao(super.attachedDatabase);

  /// Oznaci rannu/vecernu prax dna ako dokoncenu (opakovane = bez zmeny).
  Future<void> markDone(LocalDate date, JournalKind routine, DateTime now) =>
      into(practiceLogs).insert(
        PracticeLogsCompanion.insert(date: date, routine: routine, doneAt: now),
        onConflict: DoNothing(),
      );

  Future<void> unmarkDone(LocalDate date, JournalKind routine) =>
      (delete(practiceLogs)..where(
            (t) => t.date.equalsValue(date) & t.routine.equalsValue(routine),
          ))
          .go();

  /// Dokoncene praxe dna.
  Stream<Set<JournalKind>> watchDone(LocalDate date) =>
      (select(practiceLogs)..where((t) => t.date.equalsValue(date)))
          .watch()
          .map((rows) => {for (final r in rows) r.routine});
}
