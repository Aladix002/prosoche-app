import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sakina/data/db/daos/hadith_extra_dao.dart';
import 'package:sakina/data/db/hadith_extra_tables.dart';
import 'package:sqlite3/sqlite3.dart';

export 'package:sakina/data/db/hadith_extra_tables.dart';

part 'hadith_extra_db.g.dart';

/// hadith_extra.db: volitelny balik vysvetliviek HadeethEnc (C-06), iba na
/// citanie. Subor vytvara pipeline `sakina-content`, stahuje ho D-05.
/// Verzia schemy = `PRAGMA user_version` kontraktu.
@DriftDatabase(tables: hadithExtraTables, daos: [HadithExtraDao])
class HadithExtraDb extends _$HadithExtraDb {
  HadithExtraDb(super.e);

  /// Otvori [file] v read-only rezime (zapis skonci chybou SQLite).
  factory HadithExtraDb.openReadOnly(File file) => HadithExtraDb(
    NativeDatabase.opened(sqlite3.open(file.path, mode: OpenMode.readOnly)),
  );

  /// `meta.pack_id` balika (= `id` v `manifest.packs`).
  static const packId = 'hadith_extra';

  /// Verzia kontraktu `hadith_extra_schema.sql` (`schema_version` v `meta`).
  static const contractVersion = 1;

  @override
  int get schemaVersion => contractVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => throw StateError(
      'hadith_extra.db is created by the content pipeline, not by the app',
    ),
    onUpgrade: (m, from, to) async => throw StateError(
      'hadith_extra.db schema $from is not supported (app expects $to)',
    ),
  );
}
