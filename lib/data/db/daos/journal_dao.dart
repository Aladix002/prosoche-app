import 'package:drift/drift.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/domain/common/common.dart';

part 'journal_dao.g.dart';

/// Lokalny dennik a dokoncena prax dna (Practice, F-01).
///
/// Texty dennika sa nikdy nelogovanu ani neposielaju do analytiky.
@DriftAccessor(tables: [JournalEntries, PracticeLogs])
class JournalDao extends DatabaseAccessor<UserDb> with _$JournalDaoMixin {
  JournalDao(super.attachedDatabase);

  /// Novy zaznam; vrati jeho `id`.
  Future<int> add({
    required LocalDate date,
    required JournalKind kind,
    required String body,
    required DateTime now,
    String? promptId,
    String? prompt,
  }) => into(journalEntries).insert(
    JournalEntriesCompanion.insert(
      date: date,
      kind: kind,
      body: body,
      promptId: Value(promptId),
      prompt: Value(prompt),
      createdAt: now,
      updatedAt: now,
    ),
  );

  /// Zmeni text zaznamu [id].
  Future<void> updateBody(int id, String body, DateTime now) =>
      (update(journalEntries)..where((t) => t.id.equals(id))).write(
        JournalEntriesCompanion(body: Value(body), updatedAt: Value(now)),
      );

  Future<void> remove(int id) =>
      (delete(journalEntries)..where((t) => t.id.equals(id))).go();

  /// Zaznam dna [date] pre [kind] a otazku [promptId] (posledny), alebo null.
  Future<JournalEntryRow?> find(
    LocalDate date,
    JournalKind kind, {
    String? promptId,
  }) async {
    final q = select(journalEntries)
      ..where(
        (t) =>
            t.date.equalsValue(date) &
            t.kind.equalsValue(kind) &
            (promptId == null
                ? t.promptId.isNull()
                : t.promptId.equals(promptId)),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.id)])
      ..limit(1);
    return await q.getSingleOrNull();
  }

  /// Vsetky zaznamy, najnovsie prve.
  Stream<List<JournalEntryRow>> watchAll() =>
      (select(journalEntries)..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.id),
          ]))
          .watch();

  Future<List<JournalEntryRow>> all() =>
      (select(journalEntries)..orderBy([
            (t) => OrderingTerm.asc(t.date),
            (t) => OrderingTerm.asc(t.id),
          ]))
          .get();

  Future<void> deleteAll() => delete(journalEntries).go();

  // ------------------------------------------------------------- prax dna

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
