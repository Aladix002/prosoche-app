import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/domain/common/common.dart';

final _t0 = DateTime.utc(2026, 10, 29, 8);
final _d = LocalDate(2026, 10, 29);
final _quote = CardId.parse('quote:q_2255');

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
      expect(await log(_quote), isTrue);
      expect(await log(_quote), isFalse);
      expect(await log(_quote, context: CardContext.gate), isTrue);
      expect(await log(_quote, date: _d.addDays(1)), isTrue);
      // ine akcie sa neobmedzuju
      expect(await log(_quote, action: CardAction.shared), isTrue);
      expect(await log(_quote, action: CardAction.shared), isTrue);
      final rows = await db.cardEventDao.forDate(_d);
      expect(rows, hasLength(4));
      expect(rows.first.type, CardType.quote);
      expect(rows.first.cardId, 'quote:q_2255');
      expect(rows.first.pos, 2);
    });

    test('distinct counts for quests, card ids, history', () async {
      final dao = db.cardEventDao;
      await log(_quote);
      await log(_quote, context: CardContext.reader);
      await log(CardId.parse('quote:q_2256'), context: CardContext.gate);
      final prompt = CardId.parse('prompt:p_1043');
      await log(prompt, action: CardAction.answered, value: 4, correct: true);
      await log(prompt, action: CardAction.answered, value: 1, correct: false);

      expect(
        await dao.countDistinctCards(
          _d,
          type: CardType.quote,
          action: CardAction.seen,
        ),
        2,
      );
      expect(
        await dao.countDistinctCards(
          _d,
          type: CardType.quote,
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
        'quote:q_2255',
        'quote:q_2256',
      });
      expect(
        await dao.cardIds(
          _d,
          action: CardAction.seen,
          context: CardContext.reader,
        ),
        {'quote:q_2255'},
      );

      final history = await dao.recentByPrefix('prompt:p_1043');
      expect([for (final h in history) h.value], [1, 4]);
      expect(history.first.correct, isFalse);
      expect(await dao.recentByPrefix('prompt:p_1043', limit: 1), hasLength(1));
      // _ a % v prefixe su literaly
      expect(await dao.recentByPrefix('prompt:p%1043'), isEmpty);
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
        await dao.updateApp(ig.id, cardsRequired: 4, enabled: false),
        isTrue,
      );
      expect(await dao.updateApp(999, label: 'x'), isFalse);
      final updated = (await dao.appByRef('com.example.a'))!;
      expect(updated.cardsRequired, 4);
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
      final concept = CardId.parse('concept:logos');
      expect(await dao.watchIsSaved(_quote).first, isFalse);
      await dao.save(_quote, _t0);
      await dao.save(_quote, _t0.add(_hour)); // povodny cas ostava
      await dao.save(concept, _t0.add(_hour));
      expect(await dao.watchIsSaved(_quote).first, isTrue);
      expect(
        [for (final r in await dao.watchAll().first) r.cardId],
        ['concept:logos', 'quote:q_2255'],
      );
      expect(
        [
          for (final r in await dao.watchAll(type: CardType.quote).first)
            r.savedAt,
        ],
        [_t0],
      );
      expect(await dao.watchCount().first, 2);
      await dao.unsave(_quote);
      expect(await dao.watchCount().first, 1);
    });
  });
}

const _hour = Duration(hours: 1);
