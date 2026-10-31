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
    await userDb.blockerDao.updateApp(row.id, prayerLock: true);
    final app = await repo.app('com.instagram.android');
    expect(
      app,
      GateTarget(
        id: row.id,
        ref: 'com.instagram.android',
        label: 'Instagram',
        cardsRequired: 5,
        unlockMinutes: 15,
        prayerLock: true,
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

  test('free reading: card_event gate and reading_position', () async {
    expect(await repo.readingPosition(), isNull);
    await repo.markFreeReading(date, AyahId(1, 1));
    await repo.markFreeReading(date, AyahId(1, 2));
    expect(await repo.readingPosition(), AyahId(1, 2));
    // Opakovane seen v ten isty den neposuva poziciu znova.
    await repo.markFreeReading(date, AyahId(1, 1));
    expect(await repo.readingPosition(), AyahId(1, 2));
    final events = await userDb.select(userDb.cardEvents).get();
    expect(events.map((e) => (e.cardId, e.context, e.action, e.pos)), [
      ('ayah:1001', db.CardContext.gate, db.CardAction.seen, null),
      ('ayah:1002', db.CardContext.gate, db.CardAction.seen, null),
    ]);
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
