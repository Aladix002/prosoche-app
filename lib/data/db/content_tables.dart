// Deklaracie tabuliek cita len drift_dev pri generovani, za behu sa
// nevykonavaju.
// coverage:ignore-file
// Drift tabulky content.db v1. Zrkadlo kontraktu prosoche-content
// `drift_schemas/content/content_schema.sql` (kopia `schema/content_schema.sql`,
// popis `docs/CONTENT_CONTRACT.md`); zhodu strazi
// `test/data/db/content_schema_test.dart`. content.db je iba na citanie,
// appka ju nikdy nevytvara ani nemigruje (07 ADR-04).
//
// CHECK obmedzenia su len v kontrakte (pipeline). FTS5 tabulka `section_fts`
// nie je v drift DSL, dotazuje sa cez `customSelect` (LibraryDao.search).
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
  TextColumn get name => text()();
  TextColumn get translator => text().nullable()();
  IntColumn get translatorDied => integer().nullable()();
  IntColumn get editionYear => integer().nullable()();
  TextColumn get version => text()();
  TextColumn get license => text()();
  TextColumn get licenseNote => text()();
  TextColumn get attribution => text()();
  TextColumn get url => text().nullable()();
  TextColumn get sha256 => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AuthorRow')
class Authors extends Table {
  @override
  String get tableName => 'author';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get fullName => text()();
  TextColumn get lifespan => text()();
  IntColumn get ord => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('WorkRow')
class Works extends Table {
  @override
  String get tableName => 'work';

  TextColumn get id => text()();
  TextColumn get authorId => text().references(Authors, #id)();
  TextColumn get sourceId => text().references(Sources, #id)();
  TextColumn get title => text()();
  TextColumn get originalTitle => text()();
  TextColumn get translator => text()();
  TextColumn get shortRef => text()();
  IntColumn get bookCount => integer()();
  IntColumn get sectionCount => integer()();
  IntColumn get ord => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('BookRow')
class Books extends Table {
  @override
  String get tableName => 'book';

  TextColumn get workId => text().references(Works, #id)();
  IntColumn get number => integer()();
  TextColumn get title => text()();
  IntColumn get sectionCount => integer()();

  @override
  Set<Column<Object>> get primaryKey => {workId, number};
}

@DataClassName('SectionRow')
class Sections extends Table {
  @override
  String get tableName => 'section';

  IntColumn get id => integer()();
  TextColumn get key => text().unique()();
  TextColumn get workId => text().references(Works, #id)();
  IntColumn get book => integer().nullable()();
  IntColumn get number => integer()();
  TextColumn get ref => text()();
  TextColumn get title => text().nullable()();
  TextColumn get textContent => text().named('text')();
  IntColumn get charCount => integer()();
  TextColumn get sha256 => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (work_id, book) REFERENCES book(work_id, number)',
  ];
}

@DataClassName('CardRow')
class Cards extends Table {
  @override
  String get tableName => 'card';

  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get authorId => text().nullable().references(Authors, #id)();
  TextColumn get workId => text().nullable().references(Works, #id)();
  TextColumn get sectionKey => text().nullable().references(Sections, #key)();
  TextColumn get ref => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get subtitle => text().nullable()();
  TextColumn get textContent => text().named('text')();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  TextColumn get status => text()();
  TextColumn get sourceId => text().references(Sources, #id)();
  IntColumn get ord => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Vsetky bezne tabulky content.db (poradie ako v kontrakte).
const contentTables = [
  ContentMeta,
  Sources,
  Authors,
  Works,
  Books,
  Sections,
  Cards,
];
