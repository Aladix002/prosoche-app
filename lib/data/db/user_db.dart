import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:prosoche/data/db/converters.dart';
import 'package:prosoche/data/db/daos/blocker_dao.dart';
import 'package:prosoche/data/db/daos/card_event_dao.dart';
import 'package:prosoche/data/db/daos/daily_set_dao.dart';
import 'package:prosoche/data/db/daos/practice_log_dao.dart';
import 'package:prosoche/data/db/daos/quest_log_dao.dart';
import 'package:prosoche/data/db/daos/reading_dao.dart';
import 'package:prosoche/data/db/daos/saved_card_dao.dart';
import 'package:prosoche/data/db/daos/settings_dao.dart';
import 'package:prosoche/data/db/daos/streak_dao.dart';
import 'package:prosoche/data/db/journal_db.dart'
    show importLegacyJournal, journalDbFileName;
import 'package:prosoche/data/db/migrations/user_migrations.dart';
import 'package:prosoche/data/db/user_enums.dart';
import 'package:prosoche/data/db/user_tables.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:sqlite3/sqlite3.dart';

export 'package:prosoche/data/db/user_enums.dart';
export 'package:prosoche/data/db/user_tables.dart';

part 'user_db.g.dart';

/// Ako dlho caka zapis na zamok druheho spojenia (brana, docs/02 D14).
const userDbBusyTimeoutMs = 5000;

/// Nastavenie kazdeho spojenia na user.db: WAL (zapisuje aj engine brany,
/// 07 ADR-16), `busy_timeout` a cudzie kluce.
void configureUserDbConnection(Database db) {
  db
    ..execute('PRAGMA journal_mode = WAL')
    ..execute('PRAGMA busy_timeout = $userDbBusyTimeoutMs')
    ..execute('PRAGMA foreign_keys = ON');
}

/// Prijemca riadkov `journal_entry` zo starej user.db (migracia v2 -> v3,
/// C-02). Riadky su surove stlpce tabulky (`id`, `date`, `kind`, ...).
typedef LegacyJournalSink = Future<void> Function(
  List<Map<String, Object?>> rows,
);

/// [LegacyJournalSink] do `journal.db` v adresari [userDbFile].
LegacyJournalSink legacyJournalNextTo(File userDbFile) =>
    (rows) => importLegacyJournal(
      File('${userDbFile.parent.path}/$journalDbFileName'),
      rows,
    );

/// user.db: data pouzivatela (plan 5.2). Migracie v `migrations/`,
/// snapshoty schem v `drift_schemas/user_db/`.
@DriftDatabase(
  tables: [
    Settings,
    DailySets,
    CardEvents,
    QuestLogs,
    DayLogs,
    StreakStates,
    BlockedApps,
    GateSessions,
    UnlockEvents,
    SavedCards,
    PracticeLogs,
    ReadingPositions,
    SectionBookmarks,
  ],
  daos: [
    SettingsDao,
    DailySetDao,
    CardEventDao,
    QuestLogDao,
    StreakDao,
    BlockerDao,
    SavedCardDao,
    PracticeLogDao,
    ReadingDao,
  ],
)
class UserDb extends _$UserDb {
  UserDb(super.e, {this.legacyJournal});

  /// Otvori (alebo vytvori) user.db v [file] na pozadovom izolate. Dennik
  /// zo starej verzie (v2) presunie do `journal.db` v tom istom adresari.
  factory UserDb.open(File file) => UserDb(
    NativeDatabase.createInBackground(file, setup: configureUserDbConnection),
    legacyJournal: legacyJournalNextTo(file),
  );

  /// In-memory DB pre testy.
  factory UserDb.memory() =>
      UserDb(NativeDatabase.memory(setup: configureUserDbConnection));

  /// Kam migracia v2 -> v3 presunie riadky `journal_entry` (C-02). Bez
  /// neho migracia s neprazdnym dennikom zlyha (data sa nestratia).
  final LegacyJournalSink? legacyJournal;

  /// Aktualna verzia schemy. Zvysenie = novy krok v `user_migrations.dart`
  /// + `drift_dev schema dump` (plan 17.4).
  static const currentSchemaVersion = 4;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => userDbMigration();

  /// Zmaze vsetky data pouzivatela, schema ostane (A10.9 "Delete all my
  /// data"). Jedna transakcia.
  Future<void> deleteAllData() => transaction(() async {
    for (final t in allTables.toList().reversed) {
      await delete(t).go();
    }
  });
}
