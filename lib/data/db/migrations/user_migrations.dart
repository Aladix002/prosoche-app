import 'package:drift/drift.dart';
import 'package:prosoche/data/db/user_db.dart';

/// Migracie user.db (plan 5.2, 17.4).
///
/// Postup pri novej verzii N:
///  1. zmenit tabulky a `UserDb.currentSchemaVersion = N`,
///  2. `dart run drift_dev schema dump lib/data/db/user_db.dart
///     drift_schemas/user_db/`,
///  3. `dart run drift_dev schema generate drift_schemas/user_db/
///     test/data/migrations/generated/` a do kazdeho vygenerovaneho
///     suboru pridat `// ignore_for_file: strict_raw_type`,
///  4. doplnit krok `N-1 -> N` do [userDbSteps] a test v
///     `test/data/migrations/`.
MigrationStrategy userDbMigration() => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    for (var v = from; v < to; v++) {
      final step = userDbSteps[v];
      if (step == null) {
        throw StateError('No user.db migration from v$v to v${v + 1}');
      }
      await step(m);
    }
  },
);

/// Kroky `vN -> vN+1` podla zdrojovej verzie N. v1 je prva verzia.
///
/// v1 -> v2 (F-01): prax dna, pozicia citania, zalozky sekcii (a v2 aj
/// dennik `journal_entry`, ktory v3 uz v user.db nie je, preto ho tento
/// krok nevytvara). Len nove tabulky, existujuce data sa nemenia.
///
/// v2 -> v3 (C-02): dennik sa presuva do journal.db (nezalohuje sa).
/// Riadky `journal_entry` sa najprv zapisu cez [UserDb.legacyJournal]
/// (idempotentne), az potom sa tabulka v user.db zmaze. Bez prijemcu a s
/// neprazdnym dennikom migracia zlyha, aby sa dennik nestratil.
///
/// v3 -> v4 (G-01): `gate_session.intent` (zamer otvorenia, nullable) a
/// `blocked_app.practice_first` (default 1). Len nove stlpce.
final Map<int, Future<void> Function(Migrator m)> userDbSteps = {
  1: (m) async {
    final db = m.database as UserDb;
    await m.createTable(db.practiceLogs);
    await m.createTable(db.readingPositions);
    await m.createTable(db.sectionBookmarks);
    await m.createIndex(db.sectionBookmarkCreated);
  },
  2: (m) async {
    final db = m.database as UserDb;
    final exists = await db
        .customSelect(
          "SELECT 1 FROM sqlite_master WHERE type = 'table' "
          "AND name = 'journal_entry'",
        )
        .get();
    if (exists.isEmpty) return;
    final rows = await db
        .customSelect('SELECT * FROM journal_entry ORDER BY id')
        .get();
    if (rows.isNotEmpty) {
      final sink = db.legacyJournal;
      if (sink == null) {
        throw StateError('user.db v2 -> v3: no target for journal entries');
      }
      await sink([for (final r in rows) r.data]);
    }
    await db.customStatement('DROP INDEX IF EXISTS journal_entry_date');
    await db.customStatement('DROP TABLE journal_entry');
  },
  3: (m) async {
    final db = m.database as UserDb;
    await m.addColumn(db.gateSessions, db.gateSessions.intent);
    await m.addColumn(db.blockedApps, db.blockedApps.practiceFirst);
  },
};
