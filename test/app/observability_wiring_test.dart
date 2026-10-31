import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/app/observability_wiring.dart';
import 'package:sakina/core/logging/app_logger.dart';
import 'package:sakina/data/content/content_pack_state.dart';
import 'package:sakina/data/content/content_providers.dart';
import 'package:sakina/data/content/remote_config_policy.dart';
import 'package:sakina/data/content/sem_ver.dart';
import 'package:sakina/data/observability/crash_reporter.dart';
import 'package:sakina/data/observability/observability_config.dart';
import 'package:sakina/data/observability/observability_providers.dart';
import 'package:sakina/data/repositories/infra/time_providers.dart';
import 'package:sakina/data/repositories/settings/settings_providers.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/onboarding/onboarding_controller.dart';

import '../data/observability/fakes.dart';
import '../fakes/in_memory_settings_repository.dart';

void main() {
  late InMemorySettingsRepository settings;
  late FakeTransport transport;
  late RingBufferLog ring;
  late CrashLogSink sink;
  late ProviderContainer c;

  setUp(() {
    settings = InMemorySettingsRepository();
    transport = FakeTransport();
    ring = RingBufferLog();
    sink = CrashLogSink();
    c = ProviderContainer(
      overrides: [
        ...observabilityOverrides(ring: ring, crashSink: sink),
        settingsRepositoryProvider.overrideWithValue(settings),
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
  });

  const events = [
    OnboardingEvent('onboarding_step', {'step': 'language', 'skipped': false}),
    OnboardingEvent('onboarding_completed', {
      'blocker_enabled': false,
      'notif_granted': true,
    }),
  ];

  test('logger ring buffer and crash sink are shared with providers', () {
    expect(c.read(ringBufferLogProvider), same(ring));
    expect(c.read(crashLogSinkProvider), same(sink));
  });

  test('onboarding events are sent after consent saved in O7', () async {
    startObservability(c);
    await pumpEventQueue();
    // OnboardingController.finish uklada suhlas pred volanim sinku.
    await settings.set(SettingsKeys.ageConfirmed16, true);
    await settings.set(SettingsKeys.analyticsOptIn, true);
    await settings.set(SettingsKeys.onboardingCompleted, true);
    c.read(onboardingAnalyticsSinkProvider)(events);
    await pumpEventQueue();
    expect(transport.sent.map((e) => e.$1), [
      'onboarding_step',
      'onboarding_completed',
    ]);
  });

  test('without consent onboarding events are dropped', () async {
    startObservability(c);
    await settings.set(SettingsKeys.onboardingCompleted, true);
    c.read(onboardingAnalyticsSinkProvider)(events);
    await pumpEventQueue();
    expect(transport.starts, 0);
    expect(transport.sent, isEmpty);
    expect(c.read(allowlistAnalyticsProvider).queuedCount, 0);
  });
}
