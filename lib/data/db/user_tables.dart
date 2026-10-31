// Deklaracie tabuliek cita len drift_dev pri generovani, za behu sa
// nevykonavaju.
// coverage:ignore-file
// Drift tabulky user.db, schema v3 (plan 5.2 + docs/02 D1, D7, D8, D12, D13
// + 07 ADR-06 Z2). v2 (F-01): dennik, prax dna, pozicia citania a zalozky
// sekcii v Library. v3 (C-02): dennik presunuty do journal.db
// (journal_tables.dart), ktora sa nezalohuje.
//
// Konvencie:
//  * datum dna (`date`) = TEXT `YYYY-MM-DD` ([LocalDateConverter]),
//  * okamih (`*_at`, `ts`) = INTEGER ms od epochy UTC
//    ([UtcMillisConverter]),
//  * enumy = TEXT s CHECK (`wire` hodnoty z user_enums.dart),
//  * booleany = INTEGER 0/1 s CHECK.
// Getter v `.check(...)` odkazuje sam na seba - drift vzor pre CHECK.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';
import 'package:prosoche/data/db/converters.dart';
import 'package:prosoche/data/db/user_enums.dart';

/// Nazov jedineho partial unique indexu pre `seen` (docs/02 D1, 0.4).
const cardEventSeenIndex = 'card_event_seen_unique';

@DataClassName('SettingRow')
class Settings extends Table {
  @override
  String get tableName => 'settings';

  TextColumn get key => text()();
  TextColumn get valueJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Denna sada (docs/02 0.3, D13, docs/03 3.4).
@DataClassName('DailySetRow')
class DailySets extends Table {
  @override
  String get tableName => 'daily_set';

  TextColumn get date => text().map(const LocalDateConverter())();
  IntColumn get seed => integer()();
  TextColumn get cardsJson => text()();
  IntColumn get cursor => integer().withDefault(const Constant(0))();
  IntColumn get startedAt =>
      integer().map(const UtcMillisConverter()).nullable()();
  IntColumn get completedAt =>
      integer().map(const UtcMillisConverter()).nullable()();
  IntColumn get generatorVersion => integer()();
  TextColumn get contentVersion => text()();
  TextColumn get tz => text()();
  TextColumn get phase => text()
      .check(phase.isIn(DayPhase.values.map((e) => e.wire)))
      .map(const WireEnumConverter(DayPhase.values))();

  @override
  Set<Column<Object>> get primaryKey => {date};
}

/// Log interakcii s kartami (docs/02 0.5, D1).
@DataClassName('CardEventRow')
@TableIndex(name: 'card_event_date', columns: {#date})
@TableIndex(name: 'card_event_card_id', columns: {#cardId})
@TableIndex(name: 'card_event_type_action', columns: {#type, #action, #cardId})
@TableIndex.sql(
  'CREATE UNIQUE INDEX card_event_seen_unique '
  'ON card_event (date, card_id, context) WHERE "action" = \'seen\'',
)
class CardEvents extends Table {
  @override
  String get tableName => 'card_event';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text().map(const LocalDateConverter())();
  TextColumn get cardId => text()();
  TextColumn get type => text()
      .check(
        type.isIn(const [
          'intro',
          'quote',
          'passage',
          'practice',
          'prompt',
          'concept',
          'author',
          'done',
        ]),
      )
      .map(const CardTypeConverter())();
  TextColumn get context => text()
      .check(context.isIn(CardContext.values.map((e) => e.wire)))
      .map(const WireEnumConverter(CardContext.values))();
  TextColumn get action => text()
      .check(action.isIn(CardAction.values.map((e) => e.wire)))
      .map(const WireEnumConverter(CardAction.values))();
  IntColumn get pos => integer().nullable()();
  IntColumn get value => integer().nullable()();
  BoolColumn get correct => boolean().nullable()();
  IntColumn get ts => integer().map(const UtcMillisConverter())();
}

@DataClassName('QuestLogRow')
class QuestLogs extends Table {
  @override
  String get tableName => 'quest_log';

  TextColumn get date => text().map(const LocalDateConverter())();
  TextColumn get slot => text()
      .check(slot.isIn(QuestSlotKind.values.map((e) => e.wire)))
      .map(const WireEnumConverter(QuestSlotKind.values))();
  TextColumn get questId => text()();
  TextColumn get status => text()
      .check(status.isIn(QuestStatus.values.map((e) => e.wire)))
      .map(const WireEnumConverter(QuestStatus.values))
      .withDefault(const Constant('open'))();
  IntColumn get doneAt =>
      integer().map(const UtcMillisConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {date, slot};
}

/// Historia dni pre streak a kalendar (docs/02 D8). `sources` = JSON pole.
@DataClassName('DayLogRow')
class DayLogs extends Table {
  @override
  String get tableName => 'day_log';

  TextColumn get date => text().map(const LocalDateConverter())();
  TextColumn get status => text()
      .check(status.isIn(DayStatus.values.map((e) => e.wire)))
      .map(const WireEnumConverter(DayStatus.values))();
  TextColumn get sources => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {date};
}

/// Jediny riadok `id = 1` (docs/02 D8).
@DataClassName('StreakStateRow')
class StreakStates extends Table {
  @override
  String get tableName => 'streak_state';

  IntColumn get id => integer().check(id.equals(1))();
  IntColumn get current => integer().withDefault(const Constant(0))();
  IntColumn get longest => integer().withDefault(const Constant(0))();
  IntColumn get graceLeft => integer().withDefault(const Constant(0))();
  TextColumn get graceRefillAt =>
      text().map(const LocalDateConverter()).nullable()();
  TextColumn get lastEvaluatedDate =>
      text().map(const LocalDateConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Blokovane appky (docs/02 D12). `platform_ref` = package name / token.
@DataClassName('BlockedAppRow')
class BlockedApps extends Table {
  @override
  String get tableName => 'blocked_app';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get platformRef => text().unique()();
  TextColumn get label => text().nullable()();
  IntColumn get cardsRequired => integer().withDefault(const Constant(3))();
  IntColumn get unlockMinutes => integer().withDefault(const Constant(10))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer().map(const UtcMillisConverter())();
}

/// Otvorenie brany (docs/02 D12). `result` je null, kym brana bezi.
@DataClassName('GateSessionRow')
class GateSessions extends Table {
  @override
  String get tableName => 'gate_session';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get blockedAppId => integer().nullable().references(
    BlockedApps,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get openedAt => integer().map(const UtcMillisConverter())();
  IntColumn get closedAt =>
      integer().map(const UtcMillisConverter()).nullable()();
  IntColumn get cardsSeen => integer().withDefault(const Constant(0))();
  TextColumn get result => text()
      .nullable()
      .check(result.isIn(GateResult.values.map((e) => e.wire)))
      .map(const WireEnumConverter(GateResult.values))();
}

@DataClassName('UnlockEventRow')
@TableIndex(name: 'unlock_event_ts', columns: {#ts})
class UnlockEvents extends Table {
  @override
  String get tableName => 'unlock_event';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get blockedAppId => integer().nullable().references(
    BlockedApps,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get ts => integer().map(const UtcMillisConverter())();
  TextColumn get source => text()
      .check(source.isIn(UnlockSource.values.map((e) => e.wire)))
      .map(const WireEnumConverter(UnlockSource.values))();
  IntColumn get minutes => integer()();
}

@DataClassName('SavedCardRow')
@TableIndex(name: 'saved_card_saved_at', columns: {#savedAt})
class SavedCards extends Table {
  @override
  String get tableName => 'saved_card';

  TextColumn get cardId => text()();
  IntColumn get savedAt => integer().map(const UtcMillisConverter())();

  @override
  Set<Column<Object>> get primaryKey => {cardId};
}

// ------------------------------------------------------------------ F-01

/// Dokoncena ranna/vecerna prax dna (Practice, F-01).
@DataClassName('PracticeLogRow')
class PracticeLogs extends Table {
  @override
  String get tableName => 'practice_log';

  TextColumn get date => text().map(const LocalDateConverter())();
  TextColumn get routine => text()
      .check(routine.isIn(['morning', 'evening']))
      .map(const WireEnumConverter(JournalKind.values))();
  IntColumn get doneAt => integer().map(const UtcMillisConverter())();

  @override
  Set<Column<Object>> get primaryKey => {date, routine};
}

/// Pozicia citania v diele (Library). Kluc sekcie je stabilny
/// `section.key` z content.db (kontrakt kap. 2).
@DataClassName('ReadingPositionRow')
class ReadingPositions extends Table {
  @override
  String get tableName => 'reading_position';

  TextColumn get workId => text()();
  TextColumn get sectionKey => text()();

  /// Posun v ramci sekcie 0..1 (volitelne).
  RealColumn get offset => real().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().map(const UtcMillisConverter())();

  @override
  Set<Column<Object>> get primaryKey => {workId};
}

/// Zalozka na sekciu (Library).
@DataClassName('SectionBookmarkRow')
@TableIndex(name: 'section_bookmark_created', columns: {#createdAt})
class SectionBookmarks extends Table {
  @override
  String get tableName => 'section_bookmark';

  TextColumn get sectionKey => text()();
  TextColumn get workId => text()();
  IntColumn get createdAt => integer().map(const UtcMillisConverter())();

  @override
  Set<Column<Object>> get primaryKey => {sectionKey};
}
