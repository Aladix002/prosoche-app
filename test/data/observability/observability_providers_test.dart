import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/content/content_documents.dart';
import 'package:prosoche/data/content/content_pack_state.dart';
import 'package:prosoche/data/content/content_providers.dart';
import 'package:prosoche/data/content/remote_config_policy.dart';
import 'package:prosoche/data/content/sem_ver.dart';
import 'package:prosoche/data/observability/allowlist_analytics.dart';
import 'package:prosoche/data/observability/crash_reporter.dart';
import 'package:prosoche/data/observability/observability_config.dart';
import 'package:prosoche/data/observability/observability_providers.dart';
import 'package:prosoche/data/observability/posthog_transport.dart';
import 'package:prosoche/data/observability/sentry_crash_reporter.dart';
import 'package:prosoche/data/repositories/infra/time_providers.dart';
import 'package:prosoche/data/repositories/settings/settings_providers.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';

import '../../fakes/in_memory_settings_repository.dart';
import 'fakes.dart';

const _keys = ObservabilityConfig(
  sentryDsn: 'https://k@o1.ingest.de.sentry.io/1',
  posthogApiKey: 'phc_x',
);

RemoteConfigPolicy _policy({bool posthog = true}) => RemoteConfigPolicy(
  RemoteConfig(
    seq: 1,
    issuedAt: DateTime.utc(2027),
    expiresAt: DateTime.utc(2028),
    minSupportedVersion: SemVer.parse('0.0.1'),
    features: {'posthog': FeatureSwitch(enabled: posthog)},
    brokenVersions: const {},
  ),
  SemVer.parse('0.1.0'),
);

void main() {
  late InMemorySettingsRepository settings;
  late FakeTransport transport;
  late FakeCrashReporter crash;

  ProviderContainer container({
    RemoteConfigPolicy? policy,
    List<Override> extra = const [],
  }) {
    final c = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settings),
        deviceLanguageProvider.overrideWithValue('en'),
        observabilityConfigProvider.overrideWithValue(_keys),
        analyticsTransportProvider.overrideWithValue(transport),
        crashReporterProvider.overrideWithValue(crash),
        remoteConfigPolicyProvider.overrideWithValue(policy ?? _policy()),
        contentPackStateProvider.overrideWith(
          (ref) => Stream.value(const ContentPackState(installedVersion: 7)),
        ),
        ...extra,
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> consent({bool analytics = true, bool crashReports = false}) =>
      Future.wait([
        settings.set(SettingsKeys.onboardingCompleted, true),
        settings.set(SettingsKeys.ageConfirmed16, true),
        settings.set(SettingsKeys.analyticsOptIn, analytics),
        settings.set(SettingsKeys.crashReports, crashReports),
      ]);

  setUp(() {
    settings = InMemorySettingsRepository();
    transport = FakeTransport();
    crash = FakeCrashReporter();
  });

  test('fresh install: nothing starts, analytics drops events', () async {
    final c = container()..listen(observabilityControllerProvider, (_, _) {});
    await pumpEventQueue();
    c.read(analyticsProvider).track('screen_view', {'screen': 'today'});
    await pumpEventQueue();
    expect(transport.starts, 0);
    expect(transport.sent, isEmpty);
    expect(crash.starts, 0);
  });

  test('settings change starts PostHog, events carry super props', () async {
    final c = container()..listen(observabilityControllerProvider, (_, _) {});
    await pumpEventQueue();
    await consent(crashReports: true);
    await pumpEventQueue();
    expect(transport.starts, 1);
    expect(crash.starts, 1);

    c.read(analyticsProvider).track('screen_view', {
      'screen': 'quran_reader',
      'ayah_id': 262,
    });
    await pumpEventQueue();
    expect(transport.sent.single.$2, {
      'app_version': '0.1.0',
      'content_version': 7,
      'locale': 'en',
      'flavor': 'dev',
      'screen': 'quran_reader',
    });

    await settings.set(SettingsKeys.analyticsOptIn, false);
    await pumpEventQueue();
    expect(transport.stops, [true]);
    expect(crash.isRunning, isTrue);
  });

  test('kill-switch posthog=false keeps PostHog off', () async {
    await consent();
    container(policy: _policy(posthog: false))
        .listen(observabilityControllerProvider, (_, _) {});
    await pumpEventQueue();
    expect(transport.starts, 0);
  });

  test('default transport/reporter follow the keys', () async {
    final none = ProviderContainer();
    addTearDown(none.dispose);
    final noop = none.read(analyticsTransportProvider);
    expect(noop, isNot(isA<PostHogTransport>()));
    await noop.start();
    await noop.capture('screen_view', const {});
    await noop.stop(wipe: true);
    expect(none.read(crashReporterProvider), isA<NoopCrashReporter>());

    final keyed = ProviderContainer(
      overrides: [
        observabilityConfigProvider.overrideWithValue(_keys),
        settingsRepositoryProvider.overrideWithValue(settings),
        deviceLanguageProvider.overrideWithValue('en'),
        contentPackStateProvider.overrideWith(
          (ref) => Stream.value(const ContentPackState()),
        ),
      ],
    );
    addTearDown(keyed.dispose);
    expect(keyed.read(analyticsTransportProvider), isA<PostHogTransport>());
    expect(keyed.read(crashReporterProvider), isA<SentryCrashReporter>());
    expect(keyed.read(allowlistAnalyticsProvider), isA<AllowlistAnalytics>());
    expect(keyed.read(crashLogSinkProvider), isA<CrashLogSink>());
  });

  test('problem report header has only technical fields', () async {
    final c = container()..listen(contentPackStateProvider, (_, _) {});
    await pumpEventQueue();
    final text = c.read(problemReportProvider).preview();
    expect(text, contains('app_version: 0.1.0'));
    expect(text, contains('flavor: dev/lite'));
    expect(text, contains('content_version: 7'));
    expect(text, contains('os: '));
  });
}
