// Deklaracie tabuliek cita len drift_dev pri generovani, za behu sa
// nevykonavaju.
// coverage:ignore-file
// Drift tabulky user.db, schema v1 (plan 5.2 + docs/02 D1, D6, D7, D8, D10,
// D12, D13 + 07 ADR-06 Z2).
//
// Konvencie:
//  * datum dna (`date`) = TEXT `YYYY-MM-DD` ([LocalDateConverter]),
//  * okamih (`*_at`, `ts`, `due`) = INTEGER ms od epochy UTC
//    ([UtcMillisConverter]),
//  * enumy = TEXT s CHECK (`wire` hodnoty z user_enums.dart),
//  * booleany = INTEGER 0/1 s CHECK.
// Getter v `.check(...)` odkazuje sam na seba - drift vzor pre CHECK.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';
import 'package:sakina/data/db/converters.dart';
import 'package:sakina/data/db/user_enums.dart';

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

/// Jediny riadok `id = 1`; `ayah_id = 0` = pred 1:1 (docs/02 D7).
@DataClassName('ReadingPositionRow')
class ReadingPositions extends Table {
  @override
  String get tableName => 'reading_position';

  IntColumn get id => integer().check(id.equals(1))();
  IntColumn get ayahId => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().map(const UtcMillisConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};
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
          'ayah',
          'word',
          'quiz',
          'hadith',
          'dua',
          'name',
          'reflection',
          'event',
          'done',
          'khatm',
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

/// Precitane versy (docs/02 D6), udrziava `CardEventDao` pri `seen`.
@DataClassName('AyahReadRow')
class AyahReads extends Table {
  @override
  String get tableName => 'ayah_read';

  IntColumn get ayahId => integer()();
  IntColumn get firstReadAt => integer().map(const UtcMillisConverter())();
  IntColumn get readCount => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {ayahId};
}

/// Dokoncenia Koranu (docs/02 D7). `n` od 1.
@DataClassName('KhatmLogRow')
class KhatmLogs extends Table {
  @override
  String get tableName => 'khatm_log';

  IntColumn get n => integer()();
  IntColumn get startedAt => integer().map(const UtcMillisConverter())();
  IntColumn get completedAt =>
      integer().map(const UtcMillisConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {n};
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

/// SM-2 stav lemy; `stability`/`difficulty` pre FSRS vo v2 (07 ADR-06).
@DataClassName('SrsItemRow')
@TableIndex(name: 'srs_item_due', columns: {#due})
class SrsItems extends Table {
  @override
  String get tableName => 'srs_item';

  IntColumn get lemmaId => integer()();
  TextColumn get state => text()
      .check(state.isIn(SrsState.values.map((e) => e.wire)))
      .map(const WireEnumConverter(SrsState.values))();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  IntColumn get due => integer().map(const UtcMillisConverter())();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  IntColumn get lastReview =>
      integer().map(const UtcMillisConverter()).nullable()();
  IntColumn get addedAt => integer().map(const UtcMillisConverter())();
  TextColumn get source => text()
      .check(source.isIn(SrsSource.values.map((e) => e.wire)))
      .map(const WireEnumConverter(SrsSource.values))();
  RealColumn get stability => real().nullable()();
  RealColumn get difficulty => real().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {lemmaId};
}

/// Historia opakovani (07 ADR-06 Z2), podklad pre FSRS.
@DataClassName('SrsReviewRow')
@TableIndex(name: 'srs_review_lemma', columns: {#lemmaId})
class SrsReviews extends Table {
  @override
  String get tableName => 'srs_review';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get lemmaId => integer()();
  IntColumn get ts => integer().map(const UtcMillisConverter())();
  IntColumn get grade => integer()();
  IntColumn get elapsedDays => integer()();
  IntColumn get scheduledDays => integer()();
  TextColumn get stateBefore => text()
      .check(stateBefore.isIn(SrsState.values.map((e) => e.wire)))
      .map(const WireEnumConverter(SrsState.values))();
}

@DataClassName('PrayerLogRow')
class PrayerLogs extends Table {
  @override
  String get tableName => 'prayer_log';

  TextColumn get date => text().map(const LocalDateConverter())();
  TextColumn get prayer => text()
      .check(prayer.isIn(PrayerKind.values.map((e) => e.wire)))
      .map(const WireEnumConverter(PrayerKind.values))();
  TextColumn get status => text()
      .check(status.isIn(PrayerStatus.values.map((e) => e.wire)))
      .map(const WireEnumConverter(PrayerStatus.values))();
  IntColumn get ts => integer().map(const UtcMillisConverter())();

  @override
  Set<Column<Object>> get primaryKey => {date, prayer};
}

/// v1 len zapis z act questu (docs/02 D18).
@DataClassName('FastLogRow')
class FastLogs extends Table {
  @override
  String get tableName => 'fast_log';

  TextColumn get date => text().map(const LocalDateConverter())();
  TextColumn get type => text()
      .check(type.isIn(FastType.values.map((e) => e.wire)))
      .map(const WireEnumConverter(FastType.values))();
  TextColumn get status => text()();

  @override
  Set<Column<Object>> get primaryKey => {date};
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
  BoolColumn get prayerLock => boolean().withDefault(const Constant(false))();
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
