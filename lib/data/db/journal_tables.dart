// Deklaracie tabuliek cita len drift_dev pri generovani, za behu sa
// nevykonavaju.
// coverage:ignore-file
// Drift tabulky journal.db, schema v1 (C-02). Dennik je v samostatnej db,
// aby ho Android zaloha (cloud aj prenos do noveho telefonu) nezahrnula:
// pravidla v android/app/src/main/res/xml* zalohuju len user.db.
// Konvencie ako user_tables.dart.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';
import 'package:prosoche/data/db/converters.dart';
import 'package:prosoche/data/db/user_enums.dart';

/// Lokalny dennik (ranna priprava, vecerna reflexia, poznamky). Nikdy
/// neopusti zariadenie: nie je v analytike, v logoch ani v Android zalohe,
/// je v exporte a v "Delete all my data".
@DataClassName('JournalEntryRow')
@TableIndex(name: 'journal_entry_date', columns: {#date})
class JournalEntries extends Table {
  @override
  String get tableName => 'journal_entry';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text().map(const LocalDateConverter())();
  TextColumn get kind => text()
      .check(kind.isIn(JournalKind.values.map((e) => e.wire)))
      .map(const WireEnumConverter(JournalKind.values))();

  /// `card.id` otazky (prompt), ak zaznam odpoveda na otazku z obsahu.
  TextColumn get promptId => text().nullable()();

  /// Text otazky v case zapisu (export je citatelny aj bez content.db).
  TextColumn get prompt => text().nullable()();
  TextColumn get body => text()();
  IntColumn get createdAt => integer().map(const UtcMillisConverter())();
  IntColumn get updatedAt => integer().map(const UtcMillisConverter())();
}
