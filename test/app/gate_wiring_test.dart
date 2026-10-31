import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/app/gate_wiring.dart';
import 'package:prosoche/core/failures.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/data/blocker/blocked_apps_repository.dart';
import 'package:prosoche/data/blocker/blocker_gateway.dart';
import 'package:prosoche/data/blocker/blocker_gateway_provider.dart';
import 'package:prosoche/data/blocker/fake_blocked_apps_repository.dart';
import 'package:prosoche/data/blocker/fake_blocker_gateway.dart';
import 'package:prosoche/domain/settings/settings_keys.dart';
import 'package:prosoche/features/settings/blocking/blocking_providers.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/pump_app.dart';

const _noPermissions = BlockerPermissions(
  usageAccess: false,
  overlay: true,
  notifications: true,
  exactAlarm: true,
  batteryOptimized: true,
);

/// I-03: brana sa pri starte a navrate znova zapne, ked bezat ma; chybajuce
/// povolenie ukaze banner na Dnes a varovanie v Nastaveniach.
void main() {
  late FakeBlockerGateway gateway;
  late FakeRepositories fakes;

  setUp(() {
    gateway = FakeBlockerGateway();
    fakes = FakeRepositories();
  });

  ProviderContainer container({FeatureFlags flags = FeatureFlags.all}) {
    final c = ProviderContainer(
      overrides: [
        ...fakes.overrides(now: DateTime(2026, 10, 29, 9)),
        featureFlagsProvider.overrideWithValue(flags),
        blockerGatewayProvider.overrideWithValue(gateway),
        blockedAppsRepositoryProvider.overrideWithValue(
          FakeBlockedAppsRepository(gateway: gateway),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('ensureGateRunning', () {
    test('restarts a stopped service when permissions are fine', () async {
      await fakes.settings.set(SettingsKeys.blockerEnabled, true);
      gateway
        ..enabled = true
        ..serviceRunning = false;
      final c = container();
      expect(await ensureGateRunning(c), GateEnableResult.enabled);
      expect(gateway.calls, contains('setEnabled'));
      expect(await c.read(gateNeedsAttentionProvider.future), isFalse);
    });

    test('does nothing while the service runs', () async {
      await fakes.settings.set(SettingsKeys.blockerEnabled, true);
      gateway.enabled = true;
      expect(await ensureGateRunning(container()), isNull);
      expect(gateway.calls, isNot(contains('setEnabled')));
    });

    test('does nothing when the user turned the gate off', () async {
      gateway.serviceRunning = false;
      final c = container();
      expect(await ensureGateRunning(c), isNull);
      expect(gateway.calls, isNot(contains('setEnabled')));
      expect(await c.read(gateNeedsAttentionProvider.future), isFalse);
    });

    test('missing permission: no restart, needs attention', () async {
      await fakes.settings.set(SettingsKeys.blockerEnabled, true);
      gateway.permissionsState = _noPermissions;
      final c = container();
      expect(await ensureGateRunning(c), isNull);
      expect(gateway.calls, isNot(contains('setEnabled')));
      expect(await c.read(gateNeedsAttentionProvider.future), isTrue);
    });

    test('lite: never touches the native side', () async {
      await fakes.settings.set(SettingsKeys.blockerEnabled, true);
      final c = container(flags: FeatureFlags.none);
      expect(await ensureGateRunning(c), isNull);
      expect(await c.read(gateNeedsAttentionProvider.future), isFalse);
      expect(gateway.calls, isEmpty);
    });

    test('resumeGate swallows native errors', () async {
      await fakes.settings.set(SettingsKeys.blockerEnabled, true);
      gateway
        ..serviceRunning = false
        ..enableFailure = const NativeFailure('internal', 'blocker');
      expect(await resumeGate(container()), GateEnableResult.failed);
    });
  });

  group('UI', () {
    Future<void> pump(WidgetTester tester, String location) async {
      await fakes.settings.set(SettingsKeys.blockerEnabled, true);
      gateway
        ..enabled = true
        ..permissionsState = _noPermissions;
      await tester.pumpProsoche(
        location: location,
        fakes: fakes,
        overrides: [
          blockerGatewayProvider.overrideWithValue(gateway),
          blockedAppsRepositoryProvider.overrideWithValue(
            FakeBlockedAppsRepository(gateway: gateway),
          ),
        ],
      );
    }

    testWidgets('Today shows "The gate is paused" with Fix', (tester) async {
      await pump(tester, '/today');
      expect(find.text('The gate is paused'), findsOneWidget);
      await tester.tap(find.text('Fix'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('today:gatePaused')),
        findsNothing,
        reason: 'Fix otvori obrazovku povoleni brany',
      );
    });

    testWidgets('Settings marks The gate with a warning', (tester) async {
      await pump(tester, '/settings');
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
      expect(find.text('Needs attention'), findsOneWidget);
    });

    testWidgets('no banner when permissions are fine', (tester) async {
      await fakes.settings.set(SettingsKeys.blockerEnabled, true);
      gateway.enabled = true;
      await tester.pumpProsoche(
        fakes: fakes,
        overrides: [blockerGatewayProvider.overrideWithValue(gateway)],
      );
      expect(find.text('The gate is paused'), findsNothing);
    });
  });
}
