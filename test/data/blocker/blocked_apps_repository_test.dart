import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/data/blocker/blocked_apps_repository.dart';
import 'package:prosoche/data/blocker/blocker_gateway.dart';
import 'package:prosoche/data/blocker/fake_blocker_gateway.dart';
import 'package:prosoche/data/db/user_db.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late UserDb db;
  late FakeBlockerGateway gateway;
  late DriftBlockedAppsRepository repo;
  final now = DateTime.utc(2026, 10, 29, 9);

  const ig = LaunchableApp(ref: 'com.instagram.android', label: 'Instagram');
  const tt = LaunchableApp(ref: 'com.zhiliaoapp.musically', label: 'TikTok');
  const yt = LaunchableApp(ref: 'com.google.android.youtube', label: 'YouTube');

  setUp(() {
    db = UserDb.memory();
    gateway = FakeBlockerGateway();
    repo = DriftBlockedAppsRepository(
      userDb: db,
      gateway: gateway,
      clock: Clock.fixed(now),
    );
  });
  tearDown(() => db.close());

  test('O5 AC: two apps with cards 3 and 10 min, mirrored to native', () async {
    await repo.replaceSelection([ig, tt], cardsRequired: 3, unlockMinutes: 10);
    final apps = await repo.apps();
    expect(apps.map((a) => a.ref), [ig.ref, tt.ref]);
    expect(apps.every((a) => a.cardsRequired == 3), isTrue);
    expect(apps.every((a) => a.unlockMinutes == 10), isTrue);
    expect(gateway.targets, [
      BlockTarget(
        ref: ig.ref,
        label: 'Instagram',
        cardsRequired: 3,
        unlockMinutes: 10,
      ),
      BlockTarget(
        ref: tt.ref,
        label: 'TikTok',
        cardsRequired: 3,
        unlockMinutes: 10,
      ),
    ]);
  });

  test('replaceSelection removes unselected and updates kept apps', () async {
    await repo.replaceSelection([ig, tt], cardsRequired: 3, unlockMinutes: 10);
    final igId = (await repo.apps()).first.id;
    await repo.replaceSelection([ig, yt], cardsRequired: 5, unlockMinutes: 20);
    final apps = await repo.apps();
    expect(apps.map((a) => a.ref), [ig.ref, yt.ref]);
    expect(apps.first.id, igId, reason: 'kept row keeps its id (stats)');
    expect(apps.first.cardsRequired, 5);
    expect(gateway.targets.map((t) => t.ref), [ig.ref, yt.ref]);
  });

  test('add keeps existing settings, update clamps and syncs', () async {
    await repo.replaceSelection([ig], cardsRequired: 7, unlockMinutes: 30);
    await repo.add([ig, yt]);
    var apps = await repo.apps();
    expect(apps.first.cardsRequired, 7);
    expect(apps.last.cardsRequired, BlockedAppLimits.defaultCards);
    expect(apps.last.unlockMinutes, BlockedAppLimits.defaultMinutes);

    await repo.update(
      apps.last.id,
      const BlockedAppPatch(cardsRequired: 99, unlockMinutes: 1),
    );
    apps = await repo.apps();
    expect(apps.last.cardsRequired, BlockedAppLimits.maxCards);
    expect(apps.last.unlockMinutes, BlockedAppLimits.minMinutes);
    expect(gateway.targets.last.cardsRequired, BlockedAppLimits.maxCards);

    await repo.remove(apps.first.id);
    expect(gateway.targets.map((t) => t.ref), [yt.ref]);
    expect(await repo.watchApps().first, hasLength(1));
  });

  test('disabled apps are not sent to native', () async {
    await repo.add([ig, yt]);
    final first = (await repo.apps()).first;
    await db.blockerDao.updateApp(first.id, enabled: false);
    await repo.sync();
    expect(gateway.targets.map((t) => t.ref), [yt.ref]);
  });

  test('stats count sessions and unlocks since date', () async {
    await repo.add([ig, yt]);
    final [a, b] = await repo.apps();
    final old = now.subtract(const Duration(days: 8));
    await db.blockerDao.openSession(a.id, old);
    await db.blockerDao.openSession(a.id, now);
    await db.blockerDao.openSession(b.id, now);
    Future<void> unlock(int? id, UnlockSource s, DateTime ts) => db.blockerDao
        .logUnlock(blockedAppId: id, source: s, minutes: 5, ts: ts);
    await unlock(a.id, UnlockSource.cards, now);
    await unlock(a.id, UnlockSource.emergency, now);
    await unlock(b.id, UnlockSource.cards, now);
    await unlock(null, UnlockSource.error, now);
    await unlock(a.id, UnlockSource.cards, old);

    final stats = await repo.stats(now.subtract(const Duration(days: 7)));
    expect(stats.gates, 2);
    expect(stats.unlocksOf(UnlockSource.cards), 2);
    expect(stats.unlocksOf(UnlockSource.emergency), 1);
    expect(stats.unlocksOf(UnlockSource.error), 1);
    expect(stats.unlocksPerApp, {a.id: 2, b.id: 1});
    expect(stats.isEmpty, isFalse);
    expect(stats, isNot(const GateStats()));
    expect(const GateStats().isEmpty, isTrue);
  });

  test('BlockedApp equality and display name', () {
    const a = BlockedApp(
      id: 1,
      ref: 'a.b',
      cardsRequired: 3,
      unlockMinutes: 10,
    );
    expect(
      a,
      const BlockedApp(id: 1, ref: 'a.b', cardsRequired: 3, unlockMinutes: 10),
    );
    expect(a.hashCode, isNot(0));
    expect(a.displayName, 'a.b');
  });
}
