import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/data/blocker/gate_repository.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/data/db/user_enums.dart' as db;
import 'package:prosoche/data/repositories/infra/databases.dart';
import 'package:prosoche/domain/common/common.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late UserDb userDb;
  late DriftGateRepository repo;
  final now = DateTime(2026, 10, 29, 9);
  final date = LocalDate(2026, 10, 29);

  setUp(() {
    userDb = UserDb.memory();
    repo = DriftGateRepository(userDb: userDb, clock: Clock.fixed(now));
  });
  tearDown(() => userDb.close());

  test('app maps blocked_app, unknown ref is null', () async {
    final row = await userDb.blockerDao.addApp(
      platformRef: 'com.instagram.android',
      label: 'Instagram',
      cardsRequired: 5,
      unlockMinutes: 15,
      now: now,
    );
    final app = await repo.app('com.instagram.android');
    expect(
      app,
      GateTarget(
        id: row.id,
        ref: 'com.instagram.android',
        label: 'Instagram',
        cardsRequired: 5,
        unlockMinutes: 15,
      ),
    );
    expect(app.hashCode, isNot(0));
    expect(await repo.app('com.example.other'), isNull);
  });

  test('session open, close and overwrite', () async {
    final row = await userDb.blockerDao.addApp(
      platformRef: 'com.instagram.android',
      now: now,
    );
    final id = await repo.openSession(row.id);
    var s = await userDb.blockerDao.session(id);
    expect(s!.result, isNull);
    expect(s.openedAt, now.toUtc());
    await repo.closeSession(id, result: GateResult.passed, cardsSeen: 3);
    await repo.closeSession(id, result: GateResult.passed, cardsSeen: 5);
    s = await userDb.blockerDao.session(id);
    expect(s!.result, GateResult.passed);
    expect(s.cardsSeen, 5);
    expect(s.closedAt, now.toUtc());
  });

  test('unlock events by source', () async {
    final row = await userDb.blockerDao.addApp(
      platformRef: 'com.instagram.android',
      now: now,
    );
    await repo.logUnlock(row.id, source: UnlockSource.cards, minutes: 10);
    await repo.logUnlock(row.id, source: UnlockSource.emergency, minutes: 5);
    await repo.logUnlock(null, source: UnlockSource.error, minutes: 10);
    final counts = await userDb.blockerDao.unlockCounts(
      now.subtract(const Duration(days: 1)),
    );
    expect(counts, {
      UnlockSource.cards: 1,
      UnlockSource.emergency: 1,
      UnlockSource.error: 1,
    });
  });

  test('free reading: card_event seen in the gate, once per day', () async {
    await repo.markFreeReading(date, ContentCardId.quote('q_1'));
    await repo.markFreeReading(date, ContentCardId.quote('q_2'));
    await repo.markFreeReading(date, ContentCardId.quote('q_1'));
    final events = await userDb.select(userDb.cardEvents).get();
    expect(events.map((e) => (e.cardId, e.context, e.action, e.pos)), [
      ('quote:q_1', db.CardContext.gate, db.CardAction.seen, null),
      ('quote:q_2', db.CardContext.gate, db.CardAction.seen, null),
    ]);
  });

  group('G-01', () {
    test('intent is stored with the session, null clears it', () async {
      final id = await repo.openSession(null);
      await repo.setIntent(id, GateIntent.boredom);
      expect((await userDb.blockerDao.session(id))!.intent, GateIntent.boredom);
      await repo.setIntent(id, null);
      expect((await userDb.blockerDao.session(id))!.intent, null);
    });

    test('opensOn counts this app since local midnight', () async {
      final ig = await userDb.blockerDao.addApp(
        platformRef: 'com.instagram.android',
        now: now,
      );
      final yt = await userDb.blockerDao.addApp(
        platformRef: 'com.google.android.youtube',
        now: now,
      );
      Future<void> open(int appId, DateTime at) =>
          userDb.blockerDao.openSession(appId, at.toUtc());
      // Den pred polnocou a druha appka sa nepocitaju.
      await open(ig.id, DateTime(2026, 10, 28, 23, 59, 59));
      await open(ig.id, DateTime(2026, 10, 29));
      await open(ig.id, DateTime(2026, 10, 29, 8, 30));
      await open(yt.id, DateTime(2026, 10, 29, 8, 40));
      expect(await repo.opensOn(ig.id, date), 2);
      expect(await repo.opensOn(yt.id, date), 1);
      expect(await repo.opensOn(ig.id, LocalDate(2026, 10, 28)), 3);
      expect(await repo.opensOn(ig.id, LocalDate(2026, 10, 30)), 0);
    });

    test('morningPracticeDone reads practice_log of the day', () async {
      expect(await repo.morningPracticeDone(date), isFalse);
      await userDb.practiceLogDao.markDone(date, JournalKind.evening, now);
      expect(await repo.morningPracticeDone(date), isFalse);
      await userDb.practiceLogDao.markDone(
        date.addDays(-1),
        JournalKind.morning,
        now,
      );
      expect(await repo.morningPracticeDone(date), isFalse);
      await userDb.practiceLogDao.markDone(date, JournalKind.morning, now);
      expect(await repo.morningPracticeDone(date), isTrue);
    });

    test('app maps practice_first', () async {
      final row = await userDb.blockerDao.addApp(
        platformRef: 'com.instagram.android',
        now: now,
      );
      expect((await repo.app('com.instagram.android'))!.practiceFirst, isTrue);
      await userDb.blockerDao.updateApp(row.id, practiceFirst: false);
      final app = (await repo.app('com.instagram.android'))!;
      expect(app.practiceFirst, isFalse);
      expect(
        app,
        isNot(
          GateTarget(
            id: row.id,
            ref: 'com.instagram.android',
            cardsRequired: 3,
            unlockMinutes: 10,
          ),
        ),
      );
    });

    test('deleteAllData removes intents and practice_first', () async {
      final row = await userDb.blockerDao.addApp(
        platformRef: 'com.instagram.android',
        now: now,
      );
      await userDb.blockerDao.updateApp(row.id, practiceFirst: false);
      final id = await repo.openSession(row.id);
      await repo.setIntent(id, GateIntent.habit);
      await userDb.deleteAllData();
      expect(await userDb.select(userDb.gateSessions).get(), isEmpty);
      expect(await userDb.blockerDao.apps(), isEmpty);
    });
  });

  test('provider builds the drift repository', () {
    final container = ProviderContainer(
      overrides: [
        userDbProvider.overrideWithValue(userDb),
        appClockProvider.overrideWithValue(Clock.fixed(now)),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(gateRepositoryProvider), isA<DriftGateRepository>());
  });
}
