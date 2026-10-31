import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/app/data_deletion_wiring.dart';
import 'package:prosoche/app/notification_wiring.dart';
import 'package:prosoche/app/observability_wiring.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/core/router/app_router.dart';
import 'package:prosoche/data/blocker/blocker_gateway_provider.dart';
import 'package:prosoche/data/blocker/fake_blocker_gateway.dart';
import 'package:prosoche/data/content/content_pack_state.dart';
import 'package:prosoche/data/content/content_providers.dart';
import 'package:prosoche/data/content/remote_config_policy.dart';
import 'package:prosoche/data/content/sem_ver.dart';
import 'package:prosoche/data/observability/crash_reporter.dart';
import 'package:prosoche/data/observability/observability_config.dart';
import 'package:prosoche/data/observability/observability_providers.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/settings/settings_providers.dart';

import '../data/notifications/fake_notification_platform.dart';
import '../data/observability/fakes.dart';
import '../fakes/fake_repositories.dart';
import '../fakes/in_memory_settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemorySettingsRepository settings;
  late FakeTransport transport;
  late FakeNotificationPlatform platform;
  late ProviderContainer c;

  setUp(() async {
    settings = InMemorySettingsRepository();
    transport = FakeTransport();
    platform = FakeNotificationPlatform();
    c = ProviderContainer(
      overrides: [
        ...observabilityOverrides(
          ring: RingBufferLog(),
          crashSink: CrashLogSink(),
        ),
        ...notificationOverrides(),
        ...dataDeletionOverrides(),
        settingsRepositoryProvider.overrideWithValue(settings),
        streakRepositoryProvider.overrideWithValue(FakeStreakRepository()),
        notificationPlatformProvider.overrideWithValue(platform),
        deviceLanguageProvider.overrideWithValue('en'),
        observabilityConfigProvider.overrideWithValue(
          const ObservabilityConfig(posthogApiKey: 'phc_x'),
        ),
        analyticsTransportProvider.overrideWithValue(transport),
        remoteConfigPolicyProvider.overrideWithValue(
          RemoteConfigPolicy(null, SemVer.parse('0.1.0')),
        ),
        contentPackStateProvider.overrideWith(
          (ref) => Stream.value(const ContentPackState()),
        ),
      ],
    );
    addTearDown(c.dispose);
    await settings.set(SettingsKeys.onboardingCompleted, true);
    await settings.set(SettingsKeys.ageConfirmed16, true);
    await settings.set(SettingsKeys.analyticsOptIn, true);
  });

  test('after delete: notifications cancelled, analytics wiped', () async {
    startObservability(c);
    await c.read(observabilityControllerProvider).refresh();
    expect(transport.running, isTrue);
    await c.read(notificationSchedulerProvider).reschedule();
    expect(platform.scheduled, isNotEmpty);

    // user.db zmazana: nastavenia su prazdne.
    for (final key in SettingsKeys.all) {
      await settings.reset(key);
    }
    await c.read(afterDataDeletedProvider)();

    expect(platform.scheduled, isEmpty);
    expect(transport.running, isFalse);
    expect(transport.stops.last, isTrue, reason: 'queues and ID wiped');

    // Spustace (zmena nastaveni, resume) nic nenaplanuju.
    await c.read(notificationSchedulerProvider).reschedule();
    expect(platform.scheduled, isEmpty);
  });

  test('after delete with the gate: native unlocks cleared', () async {
    final blocker = FakeBlockerGateway();
    await blocker.unlockFor('com.instagram.android', minutes: 10);
    final scoped = ProviderContainer(
      parent: c,
      overrides: [
        ...dataDeletionOverrides(),
        featureFlagsProvider.overrideWithValue(const FeatureFlags(gate: true)),
        blockerGatewayProvider.overrideWithValue(blocker),
      ],
    );
    addTearDown(scoped.dispose);
    await scoped.read(afterDataDeletedProvider)();
    expect(blocker.calls, contains('clearUnlocks'));
    expect(blocker.isUnlocked('com.instagram.android'), isFalse);
  });

  test('after delete without the gate: blocker untouched', () async {
    final blocker = FakeBlockerGateway();
    final scoped = ProviderContainer(
      parent: c,
      overrides: [
        ...dataDeletionOverrides(),
        blockerGatewayProvider.overrideWithValue(blocker),
      ],
    );
    addTearDown(scoped.dispose);
    await scoped.read(afterDataDeletedProvider)();
    expect(blocker.calls, isEmpty);
  });

  testWidgets('screen_view uses route names, never paths', (tester) async {
    final router = GoRouter(
      initialLocation: '/a',
      routes: [
        GoRoute(
          path: '/a',
          name: 'today',
          builder: (_, _) => const SizedBox(),
          routes: [
            GoRoute(
              path: 'read/:id',
              name: 'quran_reader',
              builder: (_, _) => const SizedBox(),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    final scoped = ProviderContainer(
      parent: c,
      overrides: [appRouterProvider.overrideWithValue(router)],
    );
    addTearDown(scoped.dispose);
    startObservability(scoped);
    await tester.runAsync(
      () => scoped.read(observabilityControllerProvider).refresh(),
    );
    startScreenViews(scoped);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    for (final path in ['/a/read/2', '/a/read/3', '/a']) {
      router.go(path);
      await tester.pumpAndSettle();
    }

    final views = [
      for (final (e, p) in transport.sent)
        if (e == 'screen_view') p['screen'],
    ];
    expect(views, ['today', 'quran_reader', 'today']);
  });
}
