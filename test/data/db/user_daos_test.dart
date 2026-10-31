import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/domain/common/common.dart';

final _t0 = DateTime.utc(2026, 10, 29, 8);
final _d = LocalDate(2026, 10, 29);
final _ayah = CardId.parse('ayah:2255');

void main() {
  // Kazdy test otvara novu DB nad vlastnym spojenim.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late UserDb db;
  setUp(() => db = UserDb.memory());
  tearDown(() => db.close());

  group('SettingsDao', () {
    test('read, write, watch, remove, readAll', () async {
      final dao = db.settingsDao;
      expect(await dao.read('ui.locale'), isNull);
      final seen = <String?>[];
      final sub = dao.watch('ui.locale').listen(seen.add);
      await pumpEventQueue();
      await dao.write('ui.locale', '"en"');
      await pumpEventQueue();
      await dao.write('ui.locale', '"ar"');
      await pumpEventQueue();
      expect(await dao.readAll(), {'ui.locale': '"ar"'});
      await dao.remove('ui.locale');
      await pumpEventQueue();
      await sub.cancel();
      expect(seen, [null, '"en"', '"ar"', null]);
    });
  });

  group('DailySetDao', () {
    Future<bool> insert(LocalDate d, {int seed = 1}) =>
        db.dailySetDao.insertIfAbsent(
          date: d,
          seed: seed,
          cardsJson: '{"v":1,"cards":[]}',
          generatorVersion: 1,
          contentVersion: 'fixture',
          tz: 'Europe/Bratislava',
          phase: DayPhase.morning,
        );

    test('never overwrites an existing set (determinism)', () async {
      final dao = db.dailySetDao;
      expect(await dao.latestDate(), isNull);
      expect(await insert(_d), isTrue);
      expect(await insert(_d, seed: 2), isFalse);
      final row = (await dao.byDate(_d))!;
      expect(row.seed, 1);
      expect(row.cursor, 0);
      expect(row.phase, DayPhase.morning);
      expect(row.startedAt, isNull);
      expect(await dao.byDate(_d.addDays(1)), isNull);
    });

    test('latest date, range, watch', () async {
      final dao = db.dailySetDao;
      await insert(_d);
      await insert(_d.addDays(2));
      await insert(_d.addDays(-1));
      expect(await dao.latestDate(), _d.addDays(2));
      expect(
        [for (final r in await dao.range(_d, _d.addDays(5))) r.date],
        [_d, _d.addDays(2)],
      );
      expect((await dao.watchByDate(_d).first)!.date, _d);
    });

    test('cursor only moves forward, started/completed once', () async {
      final dao = db.dailySetDao;
      await insert(_d);
      expect(await dao.advanceCursor(_d, 3, _t0), isTrue);
      final later = _t0.add(const Duration(minutes: 5));
      expect(await dao.advanceCursor(_d, 2, later), isFalse);
      expect(await dao.advanceCursor(_d, 4, later), isTrue);
      var row = (await dao.byDate(_d))!;
      expect(row.cursor, 4);
      expect(row.startedAt, _t0);

      expect(await dao.markCompleted(_d, later), isTrue);
      expect(await dao.markCompleted(_d, later.add(_hour)), isFalse);
      row = (await dao.byDate(_d))!;
      expect(row.completedAt, later);
    });
  });

  group('CardEventDao', () {
    Future<bool> log(
      CardId card, {
      CardAction action = CardAction.seen,
      CardContext context = CardContext.feed,
      LocalDate? date,
      DateTime? ts,
      int? value,
      bool? correct,
    }) => db.cardEventDao.log(
      date: date ?? _d,
      card: card,
      context: context,
      action: action,
      ts: ts ?? _t0,
      pos: 2,
      value: value,
      correct: correct,
    );

    test('seen is written once per (date, card, context)', () async {
      expect(await log(_ayah), isTrue);
      expect(await log(_ayah), isFalse);
      expect(await log(_ayah, context: CardContext.gate), isTrue);
      expect(await log(_ayah, date: _d.addDays(1)), isTrue);
      // ine akcie sa neobmedzuju
      expect(await log(_ayah, action: CardAction.shared), isTrue);
      expect(await log(_ayah, action: CardAction.shared), isTrue);
      final rows = await db.cardEventDao.forDate(_d);
      expect(rows, hasLength(4));
      expect(rows.first.type, CardType.ayah);
      expect(rows.first.cardId, 'ayah:2255');
      expect(rows.first.pos, 2);
    });

    test('new seen of a verse maintains ayah_read (D6)', () async {
      await log(_ayah, ts: _t0);
      await log(_ayah, ts: _t0.add(_hour)); // duplicitne, nepocita sa
      await log(_ayah, context: CardContext.reader, ts: _t0.add(_hour));
      await log(CardId.parse('ayah:2001'));
      await log(CardId.parse('hadith:11'));
      await log(CardId.parse('ayah:1001'), action: CardAction.saved);

      final rows = await db.select(db.ayahReads).get();
      expect({for (final r in rows) r.ayahId: r.readCount}, {2255: 2, 2001: 1});
      expect(rows.firstWhere((r) => r.ayahId == 2255).firstReadAt, _t0);
      expect(await db.readingDao.readCountsBySurah(), {2: 2});
      expect(await db.readingDao.isAyahRead(2255), isTrue);
      expect(await db.readingDao.isAyahRead(1001), isFalse);
    });

    test('distinct counts for quests, card ids, history', () async {
      final dao = db.cardEventDao;
      await log(_ayah);
      await log(_ayah, context: CardContext.reader);
      await log(CardId.parse('ayah:2256'), context: CardContext.gate);
      final quiz = CardId.parse('quiz:1043:ar2mean');
      await log(
        quiz,
        action: CardAction.answered,
        context: CardContext.quiz,
        value: 4,
        correct: true,
      );
      await log(
        quiz,
        action: CardAction.answered,
        context: CardContext.quiz,
        value: 1,
        correct: false,
      );

      expect(
        await dao.countDistinctCards(
          _d,
          type: CardType.ayah,
          action: CardAction.seen,
        ),
        2,
      );
      expect(
        await dao.countDistinctCards(
          _d,
          type: CardType.ayah,
          action: CardAction.seen,
          context: CardContext.gate,
        ),
        1,
      );
      expect(
        await dao
            .watchCountDistinctCards(_d, action: CardAction.answered)
            .first,
        1,
      );
      expect(await dao.countDistinctCards(_d.addDays(1)), 0);
      expect(await dao.cardIds(_d, action: CardAction.seen), {
        'ayah:2255',
        'ayah:2256',
      });
      expect(
        await dao.cardIds(
          _d,
          action: CardAction.seen,
          context: CardContext.reader,
        ),
        {'ayah:2255'},
      );

      final history = await dao.recentByPrefix('quiz:1043:');
      expect([for (final h in history) h.value], [1, 4]);
      expect(history.first.correct, isFalse);
      expect(await dao.recentByPrefix('quiz:1043:', limit: 1), hasLength(1));
      // _ a % v prefixe su literaly
      expect(await dao.recentByPrefix('quiz_1043'), isEmpty);
    });
  });

  group('ReadingDao', () {
    test('reading position defaults to 0 and updates', () async {
      final dao = db.readingDao;
      expect(await dao.readingPosition(), 0);
      await dao.setReadingPosition(2142, _t0);
      await dao.setReadingPosition(2144, _t0.add(_hour));
      expect(await dao.readingPosition(), 2144);
      expect(await dao.watchReadingPosition().first, 2144);
      final row = await db.select(db.readingPositions).getSingle();
      expect(row.updatedAt, _t0.add(_hour));
    });

    test('khatm lifecycle (D7)', () async {
      final dao = db.readingDao;
      expect(await dao.currentKhatm(), isNull);
      final k1 = await dao.startKhatmIfNone(_t0);
      expect(k1.n, 1);
      expect((await dao.startKhatmIfNone(_t0.add(_hour))).startedAt, _t0);
      await dao.setReadingPosition(114006, _t0);

      expect(await dao.completeKhatm(_t0.add(_hour)), 1);
      expect(await dao.readingPosition(), 0);
      expect(await dao.completedKhatmCount(), 1);
      expect(await dao.currentKhatm(), isNull);

      // dalsi khatm bez explicitneho startu
      expect(await dao.completeKhatm(_t0.add(_hour * 2)), 2);
      final history = await dao.khatmHistory();
      expect([for (final k in history) k.n], [1, 2]);
      expect(history.last.completedAt, _t0.add(_hour * 2));
    });

    test('watch read counts by surah', () async {
      final counts = db.readingDao.watchReadCountsBySurah();
      expect(await counts.first, isEmpty);
    });
  });

  group('QuestLogDao', () {
    test('assign once, set status with undo, cooldown data', () async {
      final dao = db.questLogDao;
      final quests = {QuestSlotKind.read: 'q_read', QuestSlotKind.act: 'q_act'};
      expect(await dao.assignIfAbsent(_d, quests), 2);
      expect(await dao.assignIfAbsent(_d, {QuestSlotKind.act: 'other'}), 0);
      var rows = await dao.forDate(_d);
      expect([for (final r in rows) r.questId], ['q_act', 'q_read']);
      expect(rows.first.status, QuestStatus.open);

      expect(
        await dao.setStatus(_d, QuestSlotKind.act, QuestStatus.done, at: _t0),
        isTrue,
      );
      rows = await dao.watchForDate(_d).first;
      expect(rows.first.status, QuestStatus.done);
      expect(rows.first.doneAt, _t0);

      await dao.setStatus(_d, QuestSlotKind.act, QuestStatus.open);
      expect((await dao.forDate(_d)).first.doneAt, isNull);
      expect(
        await dao.setStatus(_d, QuestSlotKind.learn, QuestStatus.skipped),
        isFalse,
      );

      await dao.assignIfAbsent(_d.addDays(3), {QuestSlotKind.act: 'q_act'});
      expect(await dao.lastAssigned(), {'q_act': _d.addDays(3), 'q_read': _d});
    });
  });

  group('SrsDao', () {
    test('add, due, review with history, stats, reset, remove', () async {
      final dao = db.srsDao;
      expect(
        await dao.addIfAbsent(1, source: SrsSource.wordCard, now: _t0),
        isTrue,
      );
      expect(
        await dao.addIfAbsent(1, source: SrsSource.manual, now: _t0),
        isFalse,
      );
      await dao.addIfAbsent(2, source: SrsSource.manual, now: _t0.add(_hour));

      final item = (await dao.item(1))!;
      expect(item.state, SrsState.fresh);
      expect(item.easeFactor, 2.5);
      expect(item.stability, isNull);
      expect(await dao.watchItem(1).first, item);

      expect([for (final i in await dao.dueItems(_t0)) i.lemmaId], [1]);
      expect(await dao.dueItems(_t0.add(_hour), limit: 1), hasLength(1));
      expect(await dao.watchDueCount(_t0.add(_hour)).first, 2);
      expect(await dao.nextDueAfter(_t0), _t0.add(_hour));
      expect(await dao.nextDueAfter(_t0.add(_hour)), isNull);

      final due = _t0.add(const Duration(days: 30));
      await dao.recordReview(
        item.copyWith(
          state: SrsState.review,
          intervalDays: 30,
          reps: 3,
          due: due,
          lastReview: Value(_t0),
        ),
        SrsReviewsCompanion.insert(
          lemmaId: 1,
          ts: _t0,
          grade: 5,
          elapsedDays: 0,
          scheduledDays: 30,
          stateBefore: SrsState.fresh,
        ),
      );
      expect((await dao.item(1))!.due, due);
      final reviews = await dao.reviews(1);
      expect(reviews.single.stateBefore, SrsState.fresh);
      expect(await dao.countsByState(), {
        SrsState.review: 1,
        SrsState.fresh: 1,
      });
      expect(await dao.knownCount(), 1);
      expect([for (final i in await dao.allByDue()) i.lemmaId], [2, 1]);

      await dao.reset(1, _t0);
      final reset = (await dao.item(1))!;
      expect(reset.state, SrsState.fresh);
      expect(reset.lastReview, isNull);
      expect(await dao.knownCount(), 0);

      await dao.remove(2);
      expect(await dao.item(2), isNull);
    });
  });

  group('PrayerLogDao', () {
    test('set, overwrite, clear, range, fast', () async {
      final dao = db.prayerLogDao;
      await dao.setStatus(_d, PrayerKind.asr, PrayerStatus.onTime, _t0);
      await dao.setStatus(_d, PrayerKind.asr, PrayerStatus.late, _t0);
      await dao.setStatus(_d, PrayerKind.fajr, PrayerStatus.qada, _t0);
      await dao.setStatus(
        _d.addDays(1),
        PrayerKind.isha,
        PrayerStatus.excused,
        _t0,
      );
      final today = await dao.forDate(_d);
      expect(today, hasLength(2));
      expect(
        today.firstWhere((r) => r.prayer == PrayerKind.asr).status,
        PrayerStatus.late,
      );
      await dao.clear(_d, PrayerKind.fajr);
      expect(await dao.watchForDate(_d).first, hasLength(1));
      expect(await dao.range(_d, _d.addDays(1)), hasLength(2));

      expect(await dao.fast(_d), isNull);
      await dao.setFast(_d, FastType.sunnah, 'done');
      expect((await dao.fast(_d))!.type, FastType.sunnah);
    });
  });

  group('StreakDao', () {
    test('evaluation is atomic and idempotent', () async {
      final dao = db.streakDao;
      expect(await dao.state(), isNull);
      final days = [
        DayLogRow(date: _d, status: DayStatus.done, sources: '["feed"]'),
        DayLogRow(date: _d.addDays(1), status: DayStatus.grace),
      ];
      for (var i = 0; i < 2; i++) {
        await dao.saveEvaluation(
          current: 2,
          longest: 5,
          graceLeft: 1,
          lastEvaluatedDate: _d.addDays(1),
          graceRefillAt: _d.addDays(7),
          days: days,
        );
      }
      final s = (await dao.state())!;
      expect(s.current, 2);
      expect(s.lastEvaluatedDate, _d.addDays(1));
      expect(s.graceRefillAt, _d.addDays(7));
      expect((await dao.watchState().first)!.longest, 5);
      expect(await dao.range(_d, _d.addDays(30)), days);
      expect(await dao.watchRange(_d, _d).first, hasLength(1));
      expect((await dao.day(_d.addDays(1)))!.status, DayStatus.grace);
      expect(await dao.day(_d.addDays(2)), isNull);
    });
  });

  group('BlockerDao', () {
    test('apps: add once, update, remove keeps stats', () async {
      final dao = db.blockerDao;
      final ig = await dao.addApp(
        platformRef: 'com.example.a',
        label: 'A',
        now: _t0,
      );
      expect(ig.cardsRequired, 3);
      expect(ig.unlockMinutes, 10);
      expect(ig.enabled, isTrue);
      expect(ig.prayerLock, isFalse);
      expect(
        (await dao.addApp(platformRef: 'com.example.a', now: _t0)).id,
        ig.id,
      );
      final tt = await dao.addApp(
        platformRef: 'com.example.b',
        cardsRequired: 5,
        unlockMinutes: 20,
        now: _t0,
      );
      expect(tt.cardsRequired, 5);

      expect(
        await dao.updateApp(ig.id, prayerLock: true, enabled: false),
        isTrue,
      );
      expect(await dao.updateApp(999, label: 'x'), isFalse);
      final updated = (await dao.appByRef('com.example.a'))!;
      expect(updated.prayerLock, isTrue);
      expect(updated.enabled, isFalse);
      expect(updated.label, 'A');
      expect(await dao.watchApps().first, hasLength(2));

      final session = await dao.openSession(ig.id, _t0);
      expect((await dao.session(session))!.result, isNull);
      await dao.closeSession(
        session,
        result: GateResult.passed,
        cardsSeen: 3,
        now: _t0.add(const Duration(seconds: 40)),
      );
      final closed = (await dao.session(session))!;
      expect(closed.result, GateResult.passed);
      expect(closed.cardsSeen, 3);

      await dao.logUnlock(
        blockedAppId: ig.id,
        source: UnlockSource.cards,
        minutes: 10,
        ts: _t0,
      );
      await dao.logUnlock(
        blockedAppId: tt.id,
        source: UnlockSource.emergency,
        minutes: 20,
        ts: _t0,
      );
      await dao.logUnlock(
        blockedAppId: ig.id,
        source: UnlockSource.cards,
        minutes: 10,
        ts: _t0.subtract(const Duration(days: 8)),
      );
      final weekAgo = _t0.subtract(const Duration(days: 7));
      expect(await dao.unlockCounts(weekAgo), {
        UnlockSource.cards: 1,
        UnlockSource.emergency: 1,
      });
      expect(await dao.unlockCounts(weekAgo, blockedAppId: tt.id), {
        UnlockSource.emergency: 1,
      });

      await dao.removeApp(ig.id);
      expect(await dao.apps(), hasLength(1));
      expect((await dao.session(session))!.blockedAppId, isNull);
      expect(await dao.unlockCounts(weekAgo), hasLength(2));
    });
  });

  group('SavedCardDao', () {
    test('save, unsave, filter by type, count', () async {
      final dao = db.savedCardDao;
      final hadith = CardId.parse('hadith:11');
      expect(await dao.watchIsSaved(_ayah).first, isFalse);
      await dao.save(_ayah, _t0);
      await dao.save(_ayah, _t0.add(_hour)); // povodny cas ostava
      await dao.save(hadith, _t0.add(_hour));
      expect(await dao.watchIsSaved(_ayah).first, isTrue);
      expect(
        [for (final r in await dao.watchAll().first) r.cardId],
        ['hadith:11', 'ayah:2255'],
      );
      expect(
        [
          for (final r in await dao.watchAll(type: CardType.ayah).first)
            r.savedAt,
        ],
        [_t0],
      );
      expect(await dao.watchCount().first, 2);
      await dao.unsave(_ayah);
      expect(await dao.watchCount().first, 1);
    });
  });
}

const _hour = Duration(hours: 1);
