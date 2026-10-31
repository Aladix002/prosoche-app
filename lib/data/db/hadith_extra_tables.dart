// Deklaracie tabuliek cita len drift_dev pri generovani, za behu sa
// nevykonavaju.
// coverage:ignore-file
// Drift tabulky volitelneho balika hadith_extra.db (C-06, D-05). Zrkadlo
// kontraktu `prosoche-content/schema/hadith_extra_schema.sql` (kopia v
// `drift_schemas/content/hadith_extra_schema.sql`); zhodu strazi
// `test/data/db/hadith_extra_schema_test.dart`. Balik je iba na citanie.
//
// Vlastne triedy (nie ContentMeta/Sources z content_tables.dart), aby sa
// generovane mena v content_db.g.dart a hadith_extra_db.g.dart nebili.
import 'package:drift/drift.dart';

@DataClassName('ExtraMetaRow')
class ExtraMeta extends Table {
  @override
  String get tableName => 'meta';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DataClassName('ExtraSourceRow')
class ExtraSources extends Table {
  @override
  String get tableName => 'source';

  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get lang => text().nullable()();
  TextColumn get name => text()();
  TextColumn get version => text()();
  TextColumn get license => text()();
  TextColumn get licenseUrl => text().nullable()();
  TextColumn get licenseText => text()();
  TextColumn get attribution => text()();
  TextColumn get url => text()();
  TextColumn get commercialStatus => text()();
  TextColumn get sha256 => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('HadithExplanationRow')
class HadithExplanations extends Table {
  @override
  String get tableName => 'hadith_explanation';

  IntColumn get hadithId => integer()();
  TextColumn get lang => text()();
  TextColumn get explanation => text().nullable()();

  /// JSON pole retazcov zo zdroja.
  TextColumn get hints => text().nullable()();
  TextColumn get sourceId => text().references(ExtraSources, #id)();

  @override
  Set<Column<Object>> get primaryKey => {hadithId, lang};
}

/// Vsetky tabulky hadith_extra.db (poradie ako v kontrakte).
const hadithExtraTables = [ExtraMeta, ExtraSources, HadithExplanations];
