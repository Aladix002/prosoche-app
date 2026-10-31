import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/db/user_db.dart' as db;
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/quests.dart';
import 'package:prosoche/domain/streak/streak.dart';

import '../harness.dart';

void main() {
  late Harness h;
  final thu = LocalDate(2026, 10, 29);

  tearDown(() => h.dispose());

  group('QuestRepository', () {
    setUp(() async => h = await Harness.create());

    test('assigns quests once with template, generic learn and act', () async {
      final quests = await h.quests.ensure(thu);
      expect(quests.map((q) => q.slot), QuestSlot.values);
      final read = quests[0];
      expect(read.quest.questId, 'read.fx.verses');
      expect(read.title, '[PLACEHOLDER read quest]');
      expect(read.progress, const QuestProgress(current: 0, target: 3));
      final learn = quests[1];
      expect(learn.generic, GenericQuest.learnCards);
      expect(learn.genericCount, 1, reason: 'Read 1 hadith or dua card');
      expect(learn.title, isNull);
      expect(quests[2].quest.questId, 'q_act');
      expect(quests[2].progress, isNull);
      expect(await h.user.questLogDao.forDate(thu), hasLength(3));
      expect(await h.quests.ensure(thu), hasLength(3));
    });

    test('language without texts gets generic quests and no act', () async {
      h.lang = 'tr';
      final quests = await h.quests.ensure(thu);
      expect(quests.map((q) => q.quest.questId), [
        GenericQuest.readVerses.id,
        GenericQuest.learnCards.id,
      ]);
    });

    test('generic read quest is completable by the daily set alone', () async {
      h.lang = 'tr';
      // P-01: prvy vyber questov vytvori sadu, ciel je hned min(10, versy).
      final first = (await h.quests.ensure(thu)).first;
      final set = (await h.dailySets.get(thu))!;
      final verses = [
        for (final c in set.set.cards)
          if (c.cardId is AyahCardId) c,
      ];
      expect(verses.length, inInclusiveRange(1, 9));
      expect(first.generic, GenericQuest.readVerses);
      expect(first.genericCount, verses.length);
      for (final c in set.set.cards) {
        await h.dailySets.markSeen(thu, c);
      }
      await h.quests.syncAuto(thu);
      final read = (await h.quests.ensure(thu)).first;
      expect(read.isDone, isTrue);
      expect(read.genericCount, verses.length, reason: 'target is stable');
    });

    test(
      'P-01: done generic read keeps its target when a set appears',
      () async {
        h.lang = 'tr';
        // Quest vybrany este bez sady (napr. starsi stav z RC1): ciel 10.
        await h.user.questLogDao.assignIfAbsent(thu, {
          db.QuestSlotKind.read: GenericQuest.readVerses.id,
        });
        expect((await h.quests.ensure(thu)).first.genericCount, 10);
        final ids = [for (var a = 1; a <= 7; a++) 1000 + a, 2001, 2002, 2003];
        for (final (i, a) in ids.indexed) {
          await h.user.cardEventDao.log(
            date: thu,
            card: AyahCardId(AyahId.fromValue(a)),
            context: db.CardContext.reader,
            action: db.CardAction.seen,
            ts: DateTime.utc(2026, 10, 29, 8, i),
          );
        }
        await h.quests.syncAuto(thu);
        expect((await h.quests.ensure(thu)).first.isDone, isTrue);
        // Sada s < 10 versami vznikne az po splneni: ciel ostava 10.
        final set = await h.dailySets.ensure(thu);
        expect(
          set.set.cards.where((c) => c.cardId is AyahCardId).length,
          lessThan(10),
        );
        final read = (await h.quests.ensure(thu)).first;
        expect(read.isDone, isTrue);
        expect(read.genericCount, 10);
        expect(
          read.progress,
          isA<QuestProgress>()
              .having((p) => p.current, 'current', 10)
              .having((p) => p.target, 'target', 10),
        );
      },
    );

    test('lower target from the set is marked done by watch', () async {
      h.lang = 'tr';
      final set = await h.dailySets.ensure(thu);
      final n = set.set.cards.where((c) => c.cardId is AyahCardId).length;
      expect(n, lessThan(10));
      // n roznych versov v citacke, bez syncAuto.
      final ids = [for (var a = 1; a <= 7; a++) 1000 + a, 2001, 2002, 2003];
      for (final a in ids.take(n)) {
        await h.user.cardEventDao.log(
          date: thu,
          card: AyahCardId(AyahId.fromValue(a)),
          context: db.CardContext.reader,
          action: db.CardAction.seen,
          ts: DateTime.utc(2026, 10, 29, 8, a % 60),
        );
      }
      final done = await h.quests
          .watch(thu)
          .firstWhere((qs) => qs.first.isDone)
          .timeout(const Duration(seconds: 5));
      expect(done.first.genericCount, n);
    });

    test('act can be done, undone and skipped', () async {
      await h.quests.setActStatus(thu, QuestStatus.done);
      var act = (await h.quests.ensure(thu)).last;
      expect(act.isDone, isTrue);
      expect(act.doneAt, isNotNull);
      await h.quests.setActStatus(thu, QuestStatus.pending);
      act = (await h.quests.ensure(thu)).last;
      expect(act.status, QuestStatus.pending);
      expect(act.doneAt, isNull);
      await h.quests.setActStatus(thu, QuestStatus.skipped);
      expect((await h.quests.ensure(thu)).last.status, QuestStatus.skipped);
    });

    test('auto quest completes from card events and watch emits', () async {
      final done = h.quests
          .watch(thu)
          .firstWhere((qs) => qs.isNotEmpty && qs.first.isDone);
      for (final a in [1001, 1002, 1003]) {
        await h.user.cardEventDao.log(
          date: thu,
          card: AyahCardId(AyahId.fromValue(a)),
          context: db.CardContext.reader,
          action: db.CardAction.seen,
          ts: DateTime.utc(2026, 10, 29, 8, a % 10),
        );
      }
      await h.quests.syncAuto(thu);
      final read = (await done).first;
      expect(read.doneAt, DateTime.utc(2026, 10, 29, 8, 3).toLocal());
    });

    test('stored quest unknown today keeps its template', () async {
      await h.user.questLogDao.assignIfAbsent(thu, {
        db.QuestSlotKind.read: GenericQuest.readVerses.id,
        db.QuestSlotKind.act: 'act.removed',
      });
      final quests = await h.quests.ensure(thu);
      expect(quests.first.generic, GenericQuest.readVerses);
      expect(quests.last.quest.questId, 'act.removed');
      expect(quests.last.quest.rule, isNull);
    });
  });

  group('StreakRepository', () {
    Future<void> completeSet(LocalDate d, DateTime at) async {
      await h.user.dailySetDao.insertIfAbsent(
        date: d,
        seed: 1,
        cardsJson: '{}',
        generatorVersion: 1,
        contentVersion: 'x',
        tz: h.tz,
        phase: db.DayPhase.morning,
      );
      await h.user.dailySetDao.markCompleted(d, at.toUtc());
    }

    test('evaluates closed days, uses grace and keeps history', () async {
      h = await Harness.create(now: DateTime(2026, 10, 25, 10));
      await completeSet(LocalDate(2026, 10, 25), DateTime(2026, 10, 25, 9));
      var s = await h.streak.evaluate(LocalDate(2026, 10, 25));
      expect(s.todayDone, isTrue);
      expect(s.current, 1);

      await completeSet(LocalDate(2026, 10, 26), DateTime(2026, 10, 26, 9));
      // 27. vynechany, 28. hotovy cez quest.
      await h.user.questLogDao.assignIfAbsent(LocalDate(2026, 10, 28), {
        db.QuestSlotKind.act: 'q_act',
      });
      await h.user.questLogDao.setStatus(
        LocalDate(2026, 10, 28),
        db.QuestSlotKind.act,
        db.QuestStatus.done,
        at: DateTime(2026, 10, 28, 20).toUtc(),
      );
      h.clock.time = DateTime(2026, 10, 29, 10);
      s = await h.streak.evaluate(thu);
      expect(s.todayDone, isFalse);
      expect(s.state.current, 3);
      expect(s.graceLeft, 1);
      expect(s.longest, 3);

      final again = await h.streak.evaluate(thu);
      expect(again.state, s.state, reason: 'idempotent');

      final log = await h.streak
          .watchDayLog(LocalDate(2026, 10, 1), LocalDate(2026, 10, 31))
          .first;
      expect(log.map((e) => e.status), [
        DayStatus.done,
        DayStatus.done,
        DayStatus.grace,
        DayStatus.done,
      ]);
      expect(log.first.sources, {DaySource.set});
      expect(log.last.sources, {DaySource.quest});
    });

    test('day skipped by flying east is not missed', () async {
      // Posledna sada v Los Angeles, dnes v Tokiu o 2 dni neskor.
      h = await Harness.create(
        now: DateTime(2026, 10, 27, 10),
        tz: 'America/Los_Angeles',
      );
      await completeSet(LocalDate(2026, 10, 27), DateTime(2026, 10, 27, 9));
      await h.streak.evaluate(LocalDate(2026, 10, 27));
      h
        ..tz = 'Asia/Tokyo'
        // Hodiny zariadenia v Tokiu: 29. 10. 13:00 (+9), v LA 28. 10. 21:00.
        // UTC DateTime, aby test nezavisel od zony stroja.
        ..clock.time = DateTime.utc(2026, 10, 29, 4);
      final s = await h.streak.evaluate(thu);
      expect(s.graceLeft, 2);
      expect(s.state.lastEvaluatedDate, LocalDate(2026, 10, 28));
      final log = await h.streak
          .watchDayLog(LocalDate(2026, 10, 1), LocalDate(2026, 10, 31))
          .first;
      expect(log.map((e) => e.date), [LocalDate(2026, 10, 27)]);
    });

    test('watch re-evaluates when today is completed', () async {
      h = await Harness.create(now: DateTime(2026, 10, 29, 10));
      final done = h.streak.watch(thu).firstWhere((s) => s.todayDone);
      await completeSet(thu, DateTime(2026, 10, 29, 9));
      expect((await done).current, 1);
    });

    test('legacy comma sources are read', () async {
      h = await Harness.create();
      await h.user.streakDao.saveEvaluation(
        current: 1,
        longest: 1,
        graceLeft: 2,
        lastEvaluatedDate: LocalDate(2026, 10, 1),
        days: [
          db.DayLogRow(
            date: LocalDate(2026, 10, 1),
            status: db.DayStatus.done,
            sources: 'set,quest',
          ),
        ],
      );
      final log = await h.streak
          .watchDayLog(LocalDate(2026, 10, 1), LocalDate(2026, 10, 1))
          .first;
      expect(log.single.sources, {DaySource.set, DaySource.quest});
    });
  });
}
