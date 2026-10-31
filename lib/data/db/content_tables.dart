// Deklaracie tabuliek cita len drift_dev pri generovani, za behu sa
// nevykonavaju.
// coverage:ignore-file
// Drift tabulky content.db. Zrkadlo prechodneho kontraktu
// `drift_schemas/content/content_schema.sql` (S-01, finalny dodava C-01);
// zhodu strazi `test/data/db/content_schema_test.dart`. content.db je iba
// na citanie, appka ju nikdy nevytvara ani nemigruje (07 ADR-04).
//
// CHECK obmedzenia su len v kontrakte (pipeline).
//
// Stlpec `text` je v Darte `textContent` (meno `text` koliduje s builderom).
import 'package:drift/drift.dart';

@DataClassName('MetaRow')
class ContentMeta extends Table {
  @override
  String get tableName => 'meta';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DataClassName('SourceRow')
class Sources extends Table {
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

@DataClassName('QuoteRow')
class Quotes extends Table {
  @override
  String get tableName => 'quote';

  TextColumn get id => text()();
  TextColumn get status => text()();
  TextColumn get origin => text()();
  TextColumn get textContent => text().named('text')();
  TextColumn get author => text()();
  TextColumn get work => text()();
  TextColumn get ref => text().nullable()();
  TextColumn get tags => text()();
  TextColumn get timeOfDay => text().withDefault(const Constant('any'))();
  RealColumn get weight => real().withDefault(const Constant(1))();
  TextColumn get sourceId => text().references(Sources, #id)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('QuestTemplateRow')
class QuestTemplates extends Table {
  @override
  String get tableName => 'quest_template';

  TextColumn get id => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get status => text()();
  TextColumn get origin => text()();
  TextColumn get slot => text()();
  TextColumn get ruleJson => text()();
  TextColumn get tags => text()();
  TextColumn get facetsJson => text().nullable()();
  RealColumn get weight => real().withDefault(const Constant(1))();
  IntColumn get cooldownDays => integer().withDefault(const Constant(21))();
  TextColumn get reviewedBy => text().nullable()();
  TextColumn get reviewedAt => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('QuestTextRow')
class QuestTexts extends Table {
  @override
  String get tableName => 'quest_text';

  TextColumn get questId => text().references(QuestTemplates, #id)();
  TextColumn get lang => text()();
  TextColumn get title => text()();
  TextColumn get body => text().nullable()();
  TextColumn get sourceId => text().references(Sources, #id)();

  @override
  Set<Column<Object>> get primaryKey => {questId, lang};
}

/// Vsetky tabulky content.db (poradie ako v kontrakte).
const contentTables = [
  ContentMeta,
  Sources,
  Quotes,
  QuestTemplates,
  QuestTexts,
];
