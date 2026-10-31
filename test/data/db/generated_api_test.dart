// Smoke test generovaneho drift API (data triedy a companions) nad kazdou
// tabulkou: JSON round trip, copyWith, rovnost, zapis spat. Generovane
// metody sa volaju dynamicky, aby test nemusel vymenovat stlpce.
// ignore_for_file: avoid_dynamic_calls

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/domain/common/common.dart';

import 'fixtures/content_fixture.dart';

typedef _FromJson = DataClass Function(Map<String, dynamic> json);

final Map<Type, _FromJson> _fromJson = {
  SettingRow: SettingRow.fromJson,
  ReadingPositionRow: ReadingPositionRow.fromJson,
  DailySetRow: DailySetRow.fromJson,
  CardEventRow: CardEventRow.fromJson,
  AyahReadRow: AyahReadRow.fromJson,
  KhatmLogRow: KhatmLogRow.fromJson,
  QuestLogRow: QuestLogRow.fromJson,
  SrsItemRow: SrsItemRow.fromJson,
  SrsReviewRow: SrsReviewRow.fromJson,
  PrayerLogRow: PrayerLogRow.fromJson,
  FastLogRow: FastLogRow.fromJson,
  DayLogRow: DayLogRow.fromJson,
  StreakStateRow: StreakStateRow.fromJson,
  BlockedAppRow: BlockedAppRow.fromJson,
  GateSessionRow: GateSessionRow.fromJson,
  UnlockEventRow: UnlockEventRow.fromJson,
  SavedCardRow: SavedCardRow.fromJson,
  MetaRow: MetaRow.fromJson,
  SourceRow: SourceRow.fromJson,
  SurahRow: SurahRow.fromJson,
  SurahTextRow: SurahTextRow.fromJson,
  AyahRow: AyahRow.fromJson,
  TranslationRow: TranslationRow.fromJson,
  LemmaRow: LemmaRow.fromJson,
  LemmaMeaningRow: LemmaMeaningRow.fromJson,
  WordRow: WordRow.fromJson,
  WordMeaningRow: WordMeaningRow.fromJson,
  HadithRow: HadithRow.fromJson,
  HadithTextRow: HadithTextRow.fromJson,
  DuaRow: DuaRow.fromJson,
  DuaTextRow: DuaTextRow.fromJson,
  NameOfAllahRow: NameOfAllahRow.fromJson,
  NameTextRow: NameTextRow.fromJson,
  ReflectionRow: ReflectionRow.fromJson,
  ReflectionTextRow: ReflectionTextRow.fromJson,
  QuestTemplateRow: QuestTemplateRow.fromJson,
  QuestTextRow: QuestTextRow.fromJson,
  IslamicEventRow: IslamicEventRow.fromJson,
  IslamicEventTextRow: IslamicEventTextRow.fromJson,
  IntroCardRow: IntroCardRow.fromJson,
  IntroCardTextRow: IntroCardTextRow.fromJson,
  CountryRow: CountryRow.fromJson,
  CityRow: CityRow.fromJson,
};

/// Prejde vsetky tabulky [db]; kazda musi mat aspon jeden riadok.
Future<void> _exercise(GeneratedDatabase db) async {
  for (final table in db.allTables) {
    final name = table.actualTableName;
    final rows = await db.select(table).get();
    expect(rows, isNotEmpty, reason: 'table $name has no rows');
    for (final row in rows) {
      final data = row as DataClass;
      final dyn = row as dynamic;

      final json = data.toJson();
      final back = _fromJson[row.runtimeType]!(json);
      expect(back, row, reason: name);
      expect(back.hashCode, row.hashCode, reason: name);
      expect(data.toJsonString(), isNotEmpty);
      expect(row.toString(), contains('Row('));

      final copy = dyn.copyWith() as Object;
      expect(copy, row, reason: name);

      final companion = dyn.toCompanion(false) as UpdateCompanion<DataClass>;
      final companionCopy = (companion as dynamic).copyWith() as Object;
      expect(companionCopy.toString(), companion.toString());
      expect(companion.toColumns(true), isNotEmpty);
      expect(dyn.toCompanion(true), isA<UpdateCompanion<DataClass>>());
      expect(dyn.copyWithCompanion(companion), row, reason: name);

      // zapis spat cez data triedu (toColumns) je idempotentny
      if (db is UserDb) {
        await db
            .into(table as TableInfo<Table, DataClass>)
            .insertOnConflictUpdate(row as Insertable<DataClass>);
      }
    }
    expect(table.$columns, isNotEmpty);
    expect(table.createAlias('x').actualTableName, name);
  }
}

void main() {
  // Kazdy test otvara novu DB nad vlastnym spojenim.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  test('content.db generated API on every table', () async {
    final db = openContentFixture();
    addTearDown(db.close);
    await _exercise(db);
  });

  test('user.db generated API on every table', () async {
    final db = UserDb.memory();
    addTearDown(db.close);
    final t = DateTime.utc(2026, 10, 29);
    final d = LocalDate(2026, 10, 29);

    await db.settingsDao.write('k', '1');
    await db.readingDao.setReadingPosition(1001, t);
    await db.dailySetDao.insertIfAbsent(
      date: d,
      seed: 1,
      cardsJson: '{}',
      generatorVersion: 1,
      contentVersion: 'x',
      tz: 'UTC',
      phase: DayPhase.night,
    );
    await db.cardEventDao.log(
      date: d,
      card: CardId.parse('ayah:1001'),
      context: CardContext.feed,
      action: CardAction.seen,
      ts: t,
      correct: true,
    );
    await db.readingDao.completeKhatm(t);
    await db.questLogDao.assignIfAbsent(d, {QuestSlotKind.learn: 'q'});
    await db.srsDao.addIfAbsent(1, source: SrsSource.manual, now: t);
    await db.srsDao.recordReview(
      (await db.srsDao.item(1))!,
      SrsReviewsCompanion.insert(
        lemmaId: 1,
        ts: t,
        grade: 3,
        elapsedDays: 0,
        scheduledDays: 1,
        stateBefore: SrsState.fresh,
      ),
    );
    await db.prayerLogDao.setStatus(d, PrayerKind.isha, PrayerStatus.qada, t);
    await db.prayerLogDao.setFast(d, FastType.nafl, 'done');
    await db.streakDao.saveEvaluation(
      current: 1,
      longest: 1,
      graceLeft: 2,
      lastEvaluatedDate: d,
      days: [DayLogRow(date: d, status: DayStatus.excused)],
    );
    final app = await db.blockerDao.addApp(platformRef: 'p', now: t);
    final s = await db.blockerDao.openSession(app.id, t);
    await db.blockerDao.closeSession(
      s,
      result: GateResult.prayerLocked,
      cardsSeen: 0,
      now: t,
    );
    await db.blockerDao.logUnlock(
      blockedAppId: app.id,
      source: UnlockSource.error,
      minutes: 1,
      ts: t,
    );
    await db.savedCardDao.save(CardId.parse('name:1'), t);

    await _exercise(db);
  });
}
