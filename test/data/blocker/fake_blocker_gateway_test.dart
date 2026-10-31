import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/result.dart';
import 'package:sakina/data/blocker/blocker_gateway.dart';
import 'package:sakina/data/blocker/blocker_gateway_provider.dart';
import 'package:sakina/data/blocker/fake_blocker_gateway.dart';
import 'package:sakina/data/blocker/pigeon_blocker_gateway.dart';

void main() {
  var now = DateTime.utc(2026, 11, 3, 12);
  late FakeBlockerGateway gateway;

  setUp(() {
    now = DateTime.utc(2026, 11, 3, 12);
    gateway = FakeBlockerGateway(
      clock: Clock(() => now),
      apps: const [LaunchableApp(ref: 'com.a.b', label: 'A')],
    );
  });

  test('defaults: disabled, permissions granted, compatible api', () async {
    final s = (await gateway.status()).valueOrNull!;
    expect(s.enabled, isFalse);
    expect(s.permission, BlockerPermissionState.granted);
    expect(s.apiCompatible, isTrue);
    expect(
      (await gateway.permissions()).valueOrNull,
      BlockerPermissions.allGranted,
    );
    expect(
      await gateway.requestPermission(),
      const Ok(BlockerPermissionState.granted),
    );
    expect((await gateway.installedApps()).valueOrNull, gateway.apps);
    expect((await gateway.appIcon('com.a.b')).valueOrNull, isNull);
    expect(
      (await gateway.openSystemSettings(BlockerSettings.overlay)).isOk,
      isTrue,
    );
  });

  test('setEnabled requires usage access and overlay', () async {
    gateway.permissionsState = const BlockerPermissions(
      usageAccess: false,
      overlay: false,
      notifications: true,
      exactAlarm: true,
      batteryOptimized: true,
    );
    expect(
      await gateway.setEnabled(enabled: true),
      const Err<void>(PermissionDenied('usage_stats')),
    );
    expect(
      await gateway.requestPermission(),
      const Ok(BlockerPermissionState.denied),
    );
    expect(
      (await gateway.status()).valueOrNull!.permission,
      BlockerPermissionState.denied,
    );
    gateway.permissionsState = const BlockerPermissions(
      usageAccess: true,
      overlay: false,
      notifications: true,
      exactAlarm: true,
      batteryOptimized: true,
    );
    expect(
      await gateway.setEnabled(enabled: true),
      const Err<void>(PermissionDenied('overlay')),
    );
    expect(gateway.enabled, isFalse);

    gateway.permissionsState = BlockerPermissions.allGranted;
    expect((await gateway.setEnabled(enabled: true)).isOk, isTrue);
    expect((await gateway.status()).valueOrNull!.serviceRunning, isTrue);
  });

  test('unlock expires with clock', () async {
    await gateway.unlockFor('com.a.b', minutes: emergencyUnlockMinutes);
    expect(gateway.isUnlocked('com.a.b'), isTrue);
    now = now.add(const Duration(minutes: 5));
    expect(gateway.isUnlocked('com.a.b'), isFalse);
    expect(gateway.isUnlocked('com.x.y'), isFalse);
  });

  test('unlockFor validates minutes', () async {
    expect((await gateway.unlockFor('com.a.b', minutes: 0)).isOk, isFalse);
    expect(gateway.calls, ['unlockFor']);
  });

  test('targets, closeGate, prayer locks are recorded', () async {
    const t = BlockTarget(ref: 'com.a.b', cardsRequired: 3, unlockMinutes: 10);
    await gateway.setTargets([t]);
    expect(gateway.targets, [t]);
    await gateway.closeGate(openTarget: true);
    expect(gateway.lastCloseOpenTarget, isTrue);
    await gateway.schedulePrayerLocks([now], durationMinutes: 15);
    expect(gateway.prayerStarts, [now]);
    expect(gateway.prayerMinutes, 15);
  });

  test('failNext fails exactly one call', () async {
    gateway.failNext = const NativeFailure('internal', 'blocker');
    final r = await gateway.closeGate(openTarget: false);
    expect(r.isOk, isFalse);
    expect(gateway.lastCloseOpenTarget, isNull);
    expect((await gateway.closeGate(openTarget: false)).isOk, isTrue);
  });

  test('gate requests stream', () async {
    final got = <String>[];
    final sub = gateway.gateRequests.listen(got.add);
    gateway.requestGate('com.a.b');
    await pumpEventQueue();
    expect(got, ['com.a.b']);
    await sub.cancel();
    await gateway.dispose();
  });

  test('provider builds pigeon gateway and can be overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(blockerGatewayProvider), isA<PigeonBlockerGateway>());

    final overridden = ProviderContainer(
      overrides: [blockerGatewayProvider.overrideWithValue(gateway)],
    );
    addTearDown(overridden.dispose);
    expect(overridden.read(blockerGatewayProvider), same(gateway));
  });
}
