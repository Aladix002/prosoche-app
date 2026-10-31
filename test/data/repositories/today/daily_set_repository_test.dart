import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/db/user_db.dart' as db;
import 'package:prosoche/data/repositories/today/daily_set_repository.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/feed.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';

import '../harness.dart';

void main() {
  late Harness h;
  final thu = LocalDate(2026, 10, 29);
  final fri = LocalDate(2026, 10, 30);

  setUp(() async => h = await Harness.create());
  tearDown(() => h.dispose());

  Future<int> rows() async =>
      (await h.user.select(h.user.dailySets).get()).length;

  test('generates the set once per day and stores it', () async {
    final a = await h.dailySets.ensure(thu);
    final b = await h.dailySets.ensure(thu);
    expect(a.set, b.set);
    expect(a.n, 12, reason: 'feed.cards_count default 12');
    // Mix typov kariet z content.db v1 (F-01).
    expect(
      a.set.cards.skip(1).map((c) => c.cardId.type).toSet(),
      containsAll([CardType.quote, CardType.passage, CardType.practice]),
    );
    expect(a.cursor, 0);
    expect(a.isStarted, isFalse);
    expect(a.nextCard!.pos, 1);
    expect(await rows(), 1);
    final row = (await h.user.dailySetDao.byDate(thu))!;
    expect(row.tz, 'Europe/Bratislava');
    expect(row.contentVersion, 'fixture');
    expect(row.seed, feedSeed(thu, 'test-install'));
  });

  test('concurrent ensure generates a single set', () async {
    final results = await Future.wait([
      h.dailySets.ensure(thu),
      h.dailySets.ensure(thu),
    ]);
    expect(results[0].set, results[1].set);
    expect(await rows(), 1);
  });

  test('two engines (connections) generate the set once', () async {
    // Hlavna appka a brana (B-02) maju kazda vlastne spojenie na user.db.
    final dir = Directory.systemTemp.createTempSync('user_db');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/user.db');
    final a = await Harness.create(user: db.UserDb.open(file));
    final b = await Harness.create(user: db.UserDb.open(file));
    addTearDown(() async {
      await a.dispose();
      await b.dispose();
    });
    final results = await Future.wait([
      a.dailySets.ensure(thu),
      b.dailySets.ensure(thu),
    ]);
    expect(results[0].set, results[1].set);
    expect((await a.user.select(a.user.dailySets).get()).length, 1);
  });

  test('same install and date regenerate the identical set', () async {
    final first = await h.dailySets.ensure(thu);
    await h.user.delete(h.user.dailySets).go();
    final again = await h.dailySets.ensure(thu);
    expect(again.set.cards, first.set.cards);
  });

  test('cards count setting and disabled ids are applied', () async {
    await h.settings.set(SettingsKeys.feedCardsCount, 8);
    final repo = DriftDailySetRepository(
      userDb: h.user,
      catalog: h.catalog,
      quests: h.quests,
      settings: h.settings,
      clock: h.clock,
      installId: () async => 'test-install',
      timeZone: () async => 'Europe/Bratislava',
      disabledIds: () => {
        for (var i = 1; i <= 15; i++)
          ContentCardId.quote('q_00${'$i'.padLeft(2, '0')}'),
      },
    );
    final set = (await repo.ensure(fri)).set;
    expect(set.n, 8);
    expect(
      set.cards
          .where((c) => c.cardId.type == CardType.quote)
          .map((c) => c.cardId.key),
      everyElement(isIn(['q_0016', 'q_0017', 'q_0018', 'q_0019', 'q_0020'])),
    );
  });

  test('next day avoids quotes shown yesterday', () async {
    final a = (await h.dailySets.ensure(thu)).set;
    final b = (await h.dailySets.ensure(fri)).set;
    final yesterday = a.cards.skip(1).map((c) => c.cardId).toSet();
    expect(
      b.cards.skip(1).where((c) => yesterday.contains(c.cardId)),
      hasLength(lessThanOrEqualTo(3)),
      reason: '20 citatov, 11 za den: opakuje sa len nutne minimum',
    );
  });

  test('activeSetDate keeps the highest set when travelling west', () async {
    await h.dailySets.ensure(fri);
    expect(await h.dailySets.activeSetDate(thu), fri);
    expect(await h.dailySets.activeSetDate(fri.addDays(1)), fri.addDays(1));
    expect(() => h.dailySets.ensure(thu), throwsStateError);
  });

  test('inactiveDays counts days without a set', () async {
    expect(await h.dailySets.inactiveDays(thu), 0);
    await h.dailySets.ensure(thu);
    expect(await h.dailySets.inactiveDays(thu.addDays(8)), 7);
  });

  test('seen is written at most once and advances the cursor', () async {
    final s = await h.dailySets.ensure(thu);
    final first = await h.dailySets.markSeen(thu, s.set.cards[0]);
    expect(first.newlySeen, isTrue);
    expect(first.cursor, 1);
    final again = await h.dailySets.markSeen(thu, s.set.cards[0]);
    expect(again.newlySeen, isFalse);
    final seen = await h.user.cardEventDao.countDistinctCards(
      thu,
      action: db.CardAction.seen,
    );
    expect(seen, 1);
    final state = (await h.dailySets.get(thu))!;
    expect(state.cursor, 1);
    expect(state.startedAt, isNotNull);
    expect(state.seenContentCount, 1);
  });

  test('cursor does not jump over an unseen card', () async {
    final s = await h.dailySets.ensure(thu);
    final r = await h.dailySets.markSeen(thu, s.set.cards[2]);
    expect(r.cursor, 0);
    await h.dailySets.markSeen(thu, s.set.cards[0]);
    final r2 = await h.dailySets.markSeen(thu, s.set.cards[1]);
    expect(r2.cursor, 3);
  });

  test('finishing completes the set and auto quests', () async {
    final s = await h.dailySets.ensure(thu);
    final cards = s.set.cards;
    SeenResult? last;
    for (final c in cards.take(cards.length - 1)) {
      last = await h.dailySets.markSeen(thu, c);
      expect(last.completedNow, isFalse);
    }
    last = await h.dailySets.markSeen(thu, cards.last);
    expect(last.completedNow, isTrue);
    final state = (await h.dailySets.get(thu))!;
    expect(state.isCompleted, isTrue);
    expect(state.nextCard, isNull);

    final quests = await h.quests.ensure(thu);
    final read = quests.firstWhere((q) => q.slot == QuestSlot.read);
    expect(read.isDone, isTrue);
    expect(read.doneAt, isNotNull);
  });

  test('skipped card counts for the cursor', () async {
    final s = await h.dailySets.ensure(thu);
    final r = await h.dailySets.markSkipped(thu, s.set.cards[0]);
    expect(r.cursor, 1);
  });

  test('markSeen without a set is a bug', () async {
    final card = DailySetCard(
      pos: 1,
      cardId: IntroCardId(thu),
      slot: Slot.intro,
    );
    expect(() => h.dailySets.markSeen(thu, card), throwsStateError);
  });

  test('done card marks the set completed once', () async {
    await h.dailySets.ensure(thu);
    await h.dailySets.markDoneShown(thu);
    await h.dailySets.markDoneShown(thu);
    expect((await h.dailySets.get(thu))!.isCompleted, isTrue);
    final done = await h.user.cardEventDao.countDistinctCards(
      thu,
      type: CardType.done,
    );
    expect(done, 1);
  });

  test('watch emits the stored set and its changes', () async {
    expect(await h.dailySets.watch(thu).first, isNull);
    final s = await h.dailySets.ensure(thu);
    final states = h.dailySets.watch(thu).where((x) => x?.cursor == 1);
    await h.dailySets.markSeen(thu, s.set.cards[0]);
    expect((await states.first)!.cursor, 1);
  });

  test('day phase uses custom boundaries when given', () async {
    final repo = DriftDailySetRepository(
      userDb: h.user,
      catalog: h.catalog,
      quests: h.quests,
      settings: h.settings,
      clock: h.clock..time = DateTime(2026, 10, 29, 4),
      installId: () async => 'test-install',
      timeZone: () async => 'Europe/Bratislava',
      dayBoundaries: (d) async => DayBoundaries(
        morning: DateTime(2026, 10, 29, 3),
        day: DateTime(2026, 10, 29, 11),
        evening: DateTime(2026, 10, 29, 14),
        night: DateTime(2026, 10, 29, 18),
      ),
      disabledIds: () => const {},
    );
    expect((await repo.ensure(thu)).set.phase, DayPhase.morning);
  });
}
