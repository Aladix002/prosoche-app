import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/data/db/user_db.dart' as db;
import 'package:sakina/data/repositories/today/daily_set_repository.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/feed/feed.dart';
import 'package:sakina/domain/settings/settings_repository.dart';

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
    expect(a.n, 10, reason: 'words disabled = N 10 (docs/02 0.3)');
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
    await h.settings.reset(SettingsKeys.namesCursor);
    final again = await h.dailySets.ensure(thu);
    expect(again.set.cards, first.set.cards);
  });

  test('stores advanced names cursor and event cursor', () async {
    await h.dailySets.ensure(fri);
    expect(await h.settings.get(SettingsKeys.namesCursor), greaterThan(1));
    final cursor = await h.settings.get(SettingsKeys.eventCursor('fx_friday'));
    expect(cursor, isNotNull);
    final set = (await h.dailySets.get(fri))!.set;
    expect(set.cards[1].cardId, EventCardId('fx_friday', fri));
    expect(set.cards[2].khatm, isFalse, reason: 'event verses keep position');
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

  test('khatm verse moves reading position, finishing completes the set '
      'and auto quests', () async {
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

    final khatmVerses = cards.where((c) => c.khatm).toList();
    expect(khatmVerses, isNotEmpty);
    final lastVerse = (khatmVerses.last.cardId as AyahCardId).ayahId;
    expect(await h.user.readingDao.readingPosition(), lastVerse.value);

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

  test('day phase uses prayer boundaries when given', () async {
    final repo = DriftDailySetRepository(
      userDb: h.user,
      catalog: h.catalog,
      calendar: h.calendar,
      quests: h.quests,
      settings: h.settings,
      clock: h.clock..time = DateTime(2026, 10, 29, 4),
      installId: () async => 'test-install',
      language: () async => 'en',
      timeZone: () async => 'Europe/Bratislava',
      dayBoundaries: (d) async => DayBoundaries(
        fajr: DateTime(2026, 10, 29, 3),
        dhuhr: DateTime(2026, 10, 29, 11),
        asr: DateTime(2026, 10, 29, 14),
        isha: DateTime(2026, 10, 29, 18),
      ),
      disabledIds: () => const {},
    );
    expect((await repo.ensure(thu)).set.phase, DayPhase.morning);
  });
}
