import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:prosoche/data/db/converters.dart';
import 'package:prosoche/data/db/daos/journal_dao.dart';
import 'package:prosoche/data/db/journal_tables.dart';
import 'package:prosoche/data/db/user_enums.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:sqlite3/sqlite3.dart';

export 'package:prosoche/data/db/journal_tables.dart';
export 'package:prosoche/data/db/user_enums.dart';

part 'journal_db.g.dart';

/// Nazov suboru dennika vedla user.db. Android zaloha ho nezahrna
/// (`data_extraction_rules.xml`, `backup_rules_legacy.xml` zalohuju len
/// user.db), kontroluje `tool/check_manifest.sh` a
/// `test/android/backup_rules_test.dart`.
const journalDbFileName = 'journal.db';

/// Nastavenie spojenia na journal.db: `busy_timeout` (pri migracii user.db
/// v2 -> v3 moze byt kratko otvorene druhe spojenie).
void configureJournalDbConnection(Database db) {
  db.execute('PRAGMA busy_timeout = 5000');
}

/// journal.db: lokalny dennik (C-02). Oddeleny od user.db, aby nikdy
/// neopustil zariadenie ani cez Android zalohu.
@DriftDatabase(tables: [JournalEntries], daos: [JournalDao])
class JournalDb extends _$JournalDb {
  JournalDb(super.e);

  /// Otvori (alebo vytvori) journal.db v [file] na pozadovom izolate.
  factory JournalDb.open(File file) => JournalDb(
    NativeDatabase.createInBackground(
      file,
      setup: configureJournalDbConnection,
    ),
  );

  /// In-memory DB pre testy.
  factory JournalDb.memory() =>
      JournalDb(NativeDatabase.memory(setup: configureJournalDbConnection));

  /// Aktualna verzia schemy. Zvysenie = migracny krok + `drift_dev schema
  /// dump lib/data/db/journal_db.dart drift_schemas/journal_db/`.
  static const currentSchemaVersion = 1;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async =>
        throw StateError('No journal.db migration from v$from to v$to'),
  );

  /// Zmaze cely dennik ("Delete all my data").
  Future<void> deleteAllData() => delete(journalEntries).go();

  /// Prevezme riadky `journal_entry` zo starej user.db (v2). Idempotentne:
  /// riadok s rovnakym `id` sa preskoci, takze opakovany beh po preruseni
  /// migracie nic nezdvoji.
  Future<void> importLegacyRows(List<Map<String, Object?>> rows) =>
      transaction(() async {
        for (final r in rows) {
          await customStatement(
            'INSERT OR IGNORE INTO journal_entry '
            '(id, date, kind, prompt_id, prompt, body, created_at, updated_at) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            [
              r['id'],
              r['date'],
              r['kind'],
              r['prompt_id'],
              r['prompt'],
              r['body'],
              r['created_at'],
              r['updated_at'],
            ],
          );
        }
      });
}

/// Prenesie riadky dennika zo starej user.db do journal.db v [file]
/// (kratko otvorene samostatne spojenie, potom zatvorene).
Future<void> importLegacyJournal(
  File file,
  List<Map<String, Object?>> rows,
) async {
  final db = JournalDb(
    NativeDatabase(file, setup: configureJournalDbConnection),
  );
  try {
    await db.importLegacyRows(rows);
  } finally {
    await db.close();
  }
}
