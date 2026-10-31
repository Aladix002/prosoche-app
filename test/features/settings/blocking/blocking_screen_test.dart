import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/blocker/blocked_apps_repository.dart';
import 'package:prosoche/data/blocker/blocker_gateway.dart';
import 'package:prosoche/data/blocker/fake_blocker_gateway.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/settings/blocking/blocking_providers.dart';
import 'package:prosoche/features/settings/blocking/blocking_screen.dart';
import 'package:prosoche/features/settings/blocking/blocking_subscreens.dart';
import 'package:prosoche/features/settings/settings_paths.dart';

import '../settings_test_app.dart';
import 'blocking_test_app.dart';

Future<void> tapIn(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void resume(WidgetTester tester) {
  tester.binding
    ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
    ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}

void main() {
  group('A10.1 BlockingScreen', () {
    testWidgets('loading then data: off, empty list, no stats', (tester) async {
      final h = BlockingHarness();
      await pumpSettings(
        tester,
        gate: true,
        overrides: h.overrides,
        location: SettingsPaths.blocking,
        settle: false,
      );
      expect(find.byType(BlockingScreen), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Pause before chosen apps'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
      expect(
        find.text('No apps yet. Add the apps that should wait.'),
        findsOneWidget,
      );
      expect(find.text('No pauses yet.'), findsOneWidget);
      expect(find.text('All on'), findsOneWidget);
    });

    testWidgets('error state with retry', (tester) async {
      final blocker = FakeBlockerGateway()
        ..failNext = const UnsupportedOnPlatform('blocker');
      final h = BlockingHarness(blocker: blocker);
      await pumpSettings(
        tester,
        gate: true,
        overrides: h.overrides,
        location: SettingsPaths.blocking,
      );
      expect(find.text("Couldn't load the gate settings."), findsOneWidget);
      await tapIn(tester, find.text('Try again'));
      expect(find.text('Pause before chosen apps'), findsOneWidget);
    });

    testWidgets('data: apps, stats, switch on starts native gate', (
      tester,
    ) async {
      final h = BlockingHarness(
        apps: const [igApp],
        stats: const GateStats(
          gates: 4,
          unlocks: {UnlockSource.cards: 3, UnlockSource.emergency: 1},
          unlocksPerApp: {1: 4},
        ),
      );
      await pumpSettings(
        tester,
        gate: true,
        overrides: h.overrides,
        location: SettingsPaths.blocking,
      );
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('3 cards · 10 min\n4 unlocks'), findsOneWidget);
      expect(find.text('Pauses'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      await tapIn(tester, find.byKey(const ValueKey('blocking:switch')));
      expect(h.blocker.enabled, isTrue);
      expect(h.blocker.targets.single.ref, igApp.ref);
      expect(await h.fakes.settings.get(SettingsKeys.blockerEnabled), isTrue);
      expect(find.text('Running'), findsOneWidget);

      await tapIn(tester, find.byKey(const ValueKey('blocking:switch')));
      expect(h.blocker.enabled, isFalse);
      expect(await h.fakes.settings.get(SettingsKeys.blockerEnabled), isFalse);
    });

    testWidgets('switch without permissions opens permissions screen', (
      tester,
    ) async {
      final h = BlockingHarness(
        blocker: FakeBlockerGateway(permissionsState: noPermissions),
      );
      await pumpSettings(
        tester,
        gate: true,
        overrides: h.overrides,
        location: SettingsPaths.blocking,
      );
      expect(find.text('Some are off'), findsOneWidget);
      await tapIn(tester, find.byKey(const ValueKey('blocking:switch')));
      expect(find.byType(BlockingPermissionsScreen), findsOneWidget);
      expect(h.blocker.enabled, isFalse);
    });

    testWidgets('AC: usage access removed -> paused with Fix', (tester) async {
      final blocker = FakeBlockerGateway(apps: const [instagram])
        ..enabled = true;
      final h = BlockingHarness(blocker: blocker, apps: const [igApp]);
      await pumpSettings(
        tester,
        gate: true,
        overrides: h.overrides,
        location: SettingsPaths.blocking,
      );
      expect(find.text('Running'), findsOneWidget);

      blocker.permissionsState = const BlockerPermissions(
        usageAccess: false,
        overlay: true,
        notifications: true,
        exactAlarm: true,
        batteryOptimized: true,
      );
      resume(tester);
      await tester.pumpAndSettle();
      expect(
        find.text('Paused - usage access missing'),
        findsAtLeastNWidgets(1),
      );
      await tapIn(tester, find.text('Fix'));
      expect(find.byType(BlockingPermissionsScreen), findsOneWidget);
    });

    testWidgets('service stopped by Android -> Fix restarts it', (
      tester,
    ) async {
      final blocker = FakeBlockerGateway()
        ..enabled = true
        ..serviceRunning = false;
      final h = BlockingHarness(blocker: blocker);
      await pumpSettings(
        tester,
        gate: true,
        overrides: h.overrides,
        location: SettingsPaths.blocking,
      );
      expect(
        find.text('Paused - Android stopped the service'),
        findsAtLeastNWidgets(1),
      );
      blocker.serviceRunning = null;
      await tapIn(tester, find.text('Fix'));
      expect(blocker.calls, contains('setEnabled'));
      expect(find.text('Running'), findsOneWidget);
    });

    testWidgets('start failure shows error', (tester) async {
      final blocker = FakeBlockerGateway()
        ..enableFailure = const NativeFailure('internal', 'blocker');
      final h = BlockingHarness(blocker: blocker);
      await pumpSettings(
        tester,
        gate: true,
        overrides: h.overrides,
        location: SettingsPaths.blocking,
      );
      await tapIn(tester, find.byKey(const ValueKey('blocking:switch')));
      expect(blocker.enabled, isFalse);
      expect(
        find.text("The gate couldn't start. Please try again."),
        findsOneWidget,
      );
    });

    testWidgets('add apps: picker hides blocked apps and adds selection', (
      tester,
    ) async {
      final h = BlockingHarness(apps: const [igApp]);
      await pumpSettings(
        tester,
        gate: true,
        overrides: h.overrides,
        location: SettingsPaths.blocking,
      );
      await tapIn(tester, find.byKey(const ValueKey('blocking:add')));
      expect(find.byType(BlockingAddScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('app:com.instagram.android')),
        findsNothing,
      );
      await tester.enterText(find.byType(TextField), 'tik');
      await tester.pumpAndSettle();
      expect(find.text('Notes'), findsNothing);
      await tapIn(tester, find.text('TikTok'));
      await tapIn(tester, find.text('Add 1 app'));
      expect(find.byType(BlockingScreen), findsOneWidget);
      expect(h.repo.current.map((a) => a.ref), [igApp.ref, tiktok.ref]);
      expect(find.text('TikTok'), findsOneWidget);
    });
  });

  group('A10.2 BlockingAppScreen', () {
    testWidgets('changes are saved and mirrored, remove asks first', (
      tester,
    ) async {
      final h = BlockingHarness(apps: const [igApp]);
      await pumpSettings(
        tester,
        gate: true,
        overrides: h.overrides,
        location: SettingsPaths.blocking,
      );
      await tapIn(tester, find.text('Instagram'));
      expect(find.byType(BlockingAppScreen), findsOneWidget);

      await tapIn(tester, find.byTooltip('Increase Cards to unlock'));
      await tapIn(tester, find.byTooltip('Increase Cards to unlock'));
      expect(h.repo.current.single.cardsRequired, 5);
      expect(h.blocker.targets.single.cardsRequired, 5);
      await tapIn(tester, find.byTooltip('Decrease Unlock for'));
      expect(h.repo.current.single.unlockMinutes, 5);

      await tapIn(tester, find.byKey(const ValueKey('app:remove')));
      expect(find.text('Remove Instagram?'), findsOneWidget);
      await tapIn(tester, find.text('Remove'));
      expect(h.repo.current, isEmpty);
      expect(h.blocker.targets, isEmpty);
      expect(find.byType(BlockingScreen), findsOneWidget);
    });

    testWidgets('unknown app shows empty state', (tester) async {
      final h = BlockingHarness();
      await pumpSettings(
        tester,
        gate: true,
        overrides: h.overrides,
        location: '${SettingsPaths.blocking}/app/com.unknown.app',
      );
      expect(find.text('This app is no longer in the gate.'), findsOneWidget);
    });
  });

  group('permissions screen', () {
    testWidgets('disclosure before Allow, opens settings, turn on', (
      tester,
    ) async {
      final blocker = FakeBlockerGateway(
        permissionsState: noPermissions,
        manufacturer: 'samsung',
      );
      final h = BlockingHarness(blocker: blocker);
      await pumpSettings(
        tester,
        gate: true,
        overrides: h.overrides,
        location: '${SettingsPaths.blocking}/permissions',
      );
      expect(find.textContaining('Usage Access to notice'), findsOneWidget);
      expect(find.textContaining('never does'), findsNWidgets(2));
      expect(find.text('Battery (Samsung)'), findsOneWidget);

      await tapIn(tester, find.text('Allow in settings').first);
      expect(blocker.calls, contains('openSystemSettings'));
      resume(tester);
      await tester.pumpAndSettle();
      expect(find.text('Not allowed yet'), findsOneWidget);

      await tapIn(tester, find.byKey(const ValueKey('perm:battery')));
      expect(find.textContaining('Unrestricted'), findsOneWidget);
      await tapIn(tester, find.text('Open battery settings'));
      await tapIn(tester, find.text("I've done this"));
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      final turnOn = find.byKey(const ValueKey('blocking:turn_on'));
      await tester.ensureVisible(turnOn);
      expect(
        tester
            .widget<FilledButton>(
              find.descendant(of: turnOn, matching: find.byType(FilledButton)),
            )
            .onPressed,
        isNull,
      );
      blocker.permissionsState = BlockerPermissions.allGranted;
      resume(tester);
      await tester.pumpAndSettle();
      await tapIn(tester, turnOn);
      expect(blocker.enabled, isTrue);
    });

    testWidgets('generic battery note for other makers', (tester) async {
      final h = BlockingHarness(
        blocker: FakeBlockerGateway(permissionsState: noPermissions),
      );
      await pumpSettings(
        tester,
        gate: true,
        overrides: h.overrides,
        location: '${SettingsPaths.blocking}/permissions',
      );
      expect(find.textContaining('Some phones stop apps'), findsOneWidget);
      await tapIn(tester, find.text('Open battery settings'));
      expect(h.blocker.calls, contains('openSystemSettings'));
    });
  });

  group('helpers', () {
    test('battery vendor by manufacturer', () {
      expect(batteryVendorOf('Samsung'), BatteryVendor.samsung);
      expect(batteryVendorOf('POCO'), BatteryVendor.xiaomi);
      expect(batteryVendorOf('honor'), BatteryVendor.huawei);
      expect(batteryVendorOf('oneplus'), BatteryVendor.oppo);
      expect(batteryVendorOf('google'), isNull);
    });

    test('paths and health', () {
      expect(BlockingPaths.app('a.b'), '/settings/blocking/app/a.b');
      const state = BlockerState(
        enabled: true,
        permission: BlockerPermissionState.granted,
        serviceRunning: true,
        apiVersion: blockerApiVersion,
      );
      const o = BlockerOverview(
        state: state,
        permissions: BlockerPermissions(
          usageAccess: true,
          overlay: false,
          notifications: true,
          exactAlarm: true,
          batteryOptimized: false,
        ),
      );
      expect(o.health, GateHealth.noOverlay);
      expect(o, BlockerOverview(state: state, permissions: o.permissions));
      expect(o.hashCode, isNot(0));
      expect(
        const BlockerUnavailable(UnsupportedOnPlatform('blocker')).toString(),
        contains('BlockerUnavailable'),
      );
    });
  });
}
