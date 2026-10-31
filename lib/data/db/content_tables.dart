// Deklaracie tabuliek cita len drift_dev pri generovani, za behu sa
// nevykonavaju.
// coverage:ignore-file
// Drift tabulky content.db. Zrkadlo kontraktu
// `prosoche-content/schema/content_schema.sql` (kopia v
// `drift_schemas/content/content_schema.sql`); zhodu strazi
// `test/data/db/content_schema_test.dart`. content.db je iba na citanie,
// appka ju nikdy nevytvara ani nemigruje (07 ADR-04).
//
// CHECK obmedzenia su len v kontrakte (pipeline). FTS5 tabulky `ayah_fts`
// a `translation_fts` drift nemodeluje, pristupuju sa cez customSelect.
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

@DataClassName('SurahRow')
class Surahs extends Table {
  @override
  String get tableName => 'surah';

  IntColumn get id => integer()();
  TextColumn get nameAr => text()();
  TextColumn get nameTranslit => text()();
  TextColumn get revelationPlace => text()();
  IntColumn get revelationOrder => integer()();
  IntColumn get ayahCount => integer()();
  BoolColumn get bismillahPre => boolean()();
  TextColumn get bismillahUthmani => text().nullable()();
  TextColumn get sourceId => text().references(Sources, #id)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SurahTextRow')
class SurahTexts extends Table {
  @override
  String get tableName => 'surah_text';

  IntColumn get surahId => integer().references(Surahs, #id)();
  TextColumn get lang => text()();
  TextColumn get nameMeaning => text()();
  TextColumn get sourceId => text().references(Sources, #id)();

  @override
  Set<Column<Object>> get primaryKey => {surahId, lang};
}

@DataClassName('AyahRow')
class Ayahs extends Table {
  @override
  String get tableName => 'ayah';

  IntColumn get id => integer()();
  IntColumn get surahId => integer().references(Surahs, #id)();
  IntColumn get number => integer()();
  TextColumn get textUthmani => text()();
  TextColumn get textSimple => text()();
  IntColumn get juz => integer()();
  IntColumn get hizbQuarter => integer()();
  IntColumn get page => integer()();
  TextColumn get sajda => text().nullable()();
  TextColumn get sourceId => text().references(Sources, #id)();
  TextColumn get simpleSourceId => text().references(Sources, #id)();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {surahId, number},
  ];
}

@DataClassName('TranslationRow')
class Translations extends Table {
  @override
  String get tableName => 'translation';

  IntColumn get id => integer()();
  IntColumn get ayahId => integer().references(Ayahs, #id)();
  TextColumn get lang => text()();
  TextColumn get sourceId => text().references(Sources, #id)();
  TextColumn get textContent => text().named('text')();
  TextColumn get footnotes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {ayahId, lang, sourceId},
  ];
}

@DataClassName('LemmaRow')
class Lemmas extends Table {
  @override
  String get tableName => 'lemma';

  IntColumn get id => integer()();
  TextColumn get textAr => text()();
  TextColumn get translit => text().nullable()();
  TextColumn get root => text().nullable()();
  IntColumn get frequency => integer().nullable()();
  IntColumn get rank => integer().nullable()();
  TextColumn get sourceId => text().references(Sources, #id)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('LemmaMeaningRow')
class LemmaMeanings extends Table {
  @override
  String get tableName => 'lemma_meaning';

  IntColumn get lemmaId => integer().references(Lemmas, #id)();
  TextColumn get lang => text()();
  TextColumn get meaning => text()();
  TextColumn get sourceId => text().references(Sources, #id)();

  @override
  Set<Column<Object>> get primaryKey => {lemmaId, lang};
}

@DataClassName('WordRow')
class Words extends Table {
  @override
  String get tableName => 'word';

  IntColumn get id => integer()();
  IntColumn get ayahId => integer().references(Ayahs, #id)();
  IntColumn get position => integer()();
  TextColumn get textAr => text()();
  TextColumn get translit => text().nullable()();
  IntColumn get lemmaId => integer().nullable().references(Lemmas, #id)();
  IntColumn get charStart => integer().nullable()();
  IntColumn get charEnd => integer().nullable()();
  TextColumn get sourceId => text().references(Sources, #id)();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {ayahId, position},
  ];
}

@DataClassName('WordMeaningRow')
class WordMeanings extends Table {
  @override
  String get tableName => 'word_meaning';

  IntColumn get wordId => integer().references(Words, #id)();
  TextColumn get lang => text()();
  TextColumn get meaning => text()();
  TextColumn get sourceId => text().references(Sources, #id)();

  @override
  Set<Column<Object>> get primaryKey => {wordId, lang};
}

@DataClassName('HadithRow')
class Hadiths extends Table {
  @override
  String get tableName => 'hadith';

  IntColumn get id => integer()();
  TextColumn get collection => text()();
  TextColumn get number => text().nullable()();
  TextColumn get textAr => text()();
  TextColumn get introAr => text().nullable()();
  TextColumn get narratorAr => text().nullable()();
  TextColumn get grade => text()();
  TextColumn get gradeAr => text()();
  TextColumn get tags => text().nullable()();
  TextColumn get categories => text()();
  TextColumn get sourceId => text().references(Sources, #id)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('HadithTextRow')
class HadithTexts extends Table {
  @override
  String get tableName => 'hadith_text';

  IntColumn get hadithId => integer().references(Hadiths, #id)();
  TextColumn get lang => text()();
  TextColumn get title => text()();
  TextColumn get textContent => text().named('text')();
  TextColumn get intro => text().nullable()();
  TextColumn get narrator => text().nullable()();
  TextColumn get attribution => text()();
  TextColumn get gradeLabel => text()();
  // explanation a hints su od v3 v baliku hadith_extra.db (HadithExtraDb).
  TextColumn get sourceId => text().references(Sources, #id)();

  @override
  Set<Column<Object>> get primaryKey => {hadithId, lang};
}

@DataClassName('DuaRow')
class Duas extends Table {
  @override
  String get tableName => 'dua';

  TextColumn get id => text()();
  TextColumn get category => text()();
  TextColumn get title => text().nullable()();
  TextColumn get textAr => text()();
  TextColumn get translit => text().nullable()();
  IntColumn get repeatCount => integer().withDefault(const Constant(1))();
  TextColumn get timeOfDay => text().withDefault(const Constant('any'))();
  TextColumn get sourceRef => text()();
  TextColumn get sourceId => text().references(Sources, #id)();
  TextColumn get reviewedBy => text().nullable()();
  TextColumn get reviewedAt => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('DuaTextRow')
class DuaTexts extends Table {
  @override
  String get tableName => 'dua_text';

  TextColumn get duaId => text().references(Duas, #id)();
  TextColumn get lang => text()();
  TextColumn get textContent => text().named('text')();
  TextColumn get sourceId => text().references(Sources, #id)();

  @override
  Set<Column<Object>> get primaryKey => {duaId, lang};
}

@DataClassName('NameOfAllahRow')
class NamesOfAllah extends Table {
  @override
  String get tableName => 'name_of_allah';

  IntColumn get id => integer()();
  TextColumn get textAr => text()();
  TextColumn get translit => text().nullable()();
  IntColumn get refAyahId => integer().nullable().references(Ayahs, #id)();
  TextColumn get sourceId => text().references(Sources, #id)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('NameTextRow')
class NameTexts extends Table {
  @override
  String get tableName => 'name_text';

  IntColumn get nameId => integer().references(NamesOfAllah, #id)();
  TextColumn get lang => text()();
  TextColumn get meaning => text()();
  TextColumn get shortNote => text().nullable()();
  TextColumn get sourceId => text().references(Sources, #id)();

  @override
  Set<Column<Object>> get primaryKey => {nameId, lang};
}

@DataClassName('ReflectionRow')
class Reflections extends Table {
  @override
  String get tableName => 'reflection';

  TextColumn get id => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get status => text()();
  TextColumn get origin => text()();
  TextColumn get tags => text()();
  TextColumn get facetsJson => text().nullable()();
  TextColumn get anchorJson => text().nullable()();
  TextColumn get season => text().nullable()();
  TextColumn get reviewedBy => text().nullable()();
  TextColumn get reviewedAt => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ReflectionTextRow')
class ReflectionTexts extends Table {
  @override
  String get tableName => 'reflection_text';

  TextColumn get reflectionId => text().references(Reflections, #id)();
  TextColumn get lang => text()();
  TextColumn get textContent => text().named('text')();
  TextColumn get question => text().nullable()();
  TextColumn get sourceId => text().references(Sources, #id)();

  @override
  Set<Column<Object>> get primaryKey => {reflectionId, lang};
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
  TextColumn get evidenceJson => text().nullable()();
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

@DataClassName('IslamicEventRow')
class IslamicEvents extends Table {
  @override
  String get tableName => 'islamic_event';

  TextColumn get id => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get status => text()();
  TextColumn get origin => text()();
  TextColumn get category => text()();
  IntColumn get priority => integer()();
  TextColumn get ruleJson => text()();
  TextColumn get questOverridesJson => text().nullable()();
  TextColumn get cardOverridesJson => text().nullable()();
  TextColumn get testsJson => text().nullable()();
  TextColumn get reviewedBy => text().nullable()();
  TextColumn get reviewedAt => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('IslamicEventTextRow')
class IslamicEventTexts extends Table {
  @override
  String get tableName => 'islamic_event_text';

  TextColumn get eventId => text().references(IslamicEvents, #id)();
  TextColumn get lang => text()();
  TextColumn get title => text()();
  TextColumn get body => text().nullable()();
  TextColumn get sourceId => text().references(Sources, #id)();

  @override
  Set<Column<Object>> get primaryKey => {eventId, lang};
}

@DataClassName('IntroCardRow')
class IntroCards extends Table {
  @override
  String get tableName => 'intro_card';

  TextColumn get id => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get status => text()();
  TextColumn get origin => text()();
  TextColumn get eventId => text().nullable().references(IslamicEvents, #id)();
  TextColumn get reviewedBy => text().nullable()();
  TextColumn get reviewedAt => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('IntroCardTextRow')
class IntroCardTexts extends Table {
  @override
  String get tableName => 'intro_card_text';

  TextColumn get introId => text().references(IntroCards, #id)();
  TextColumn get lang => text()();
  TextColumn get title => text()();
  TextColumn get body => text().nullable()();
  TextColumn get sourceId => text().references(Sources, #id)();

  @override
  Set<Column<Object>> get primaryKey => {introId, lang};
}

/// Krajiny GeoNames (kontrakt v2).
@DataClassName('CountryRow')
class Countries extends Table {
  @override
  String get tableName => 'country';

  TextColumn get iso2 => text()();
  TextColumn get name => text()();
  TextColumn get sourceId => text().references(Sources, #id)();

  @override
  Set<Column<Object>> get primaryKey => {iso2};
}

@DataClassName('CityRow')
class Cities extends Table {
  @override
  String get tableName => 'city';

  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get asciiName => text()();
  TextColumn get countryCode => text().references(Countries, #iso2)();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  TextColumn get tz => text()();
  IntColumn get population => integer().nullable()();
  TextColumn get sourceId => text().references(Sources, #id)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Vsetky tabulky content.db (poradie ako v kontrakte).
const contentTables = [
  ContentMeta,
  Sources,
  Surahs,
  SurahTexts,
  Ayahs,
  Translations,
  Lemmas,
  LemmaMeanings,
  Words,
  WordMeanings,
  Hadiths,
  HadithTexts,
  Duas,
  DuaTexts,
  NamesOfAllah,
  NameTexts,
  Reflections,
  ReflectionTexts,
  QuestTemplates,
  QuestTexts,
  IslamicEvents,
  IslamicEventTexts,
  IntroCards,
  IntroCardTexts,
  Countries,
  Cities,
];
