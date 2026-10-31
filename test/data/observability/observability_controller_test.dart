import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/data/observability/allowlist_analytics.dart';
import 'package:prosoche/data/observability/crash_reporter.dart';
import 'package:prosoche/data/observability/observability_config.dart';
import 'package:prosoche/data/observability/observability_controller.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';

import '../../fakes/in_memory_settings_repository.dart';
import 'fakes.dart';

class _BrokenSettings extends InMemorySettingsRepository {
  @override
  Future<T> get<T>(SettingKey<T> key) => Future.error(StateError('db'));
}

void main() {
  const keys = ObservabilityConfig(
    sentryDsn: 'https://k@o.ingest/1',
    posthogApiKey: 'phc_x',
  );

  late InMemorySettingsRepository settings;
  late FakeTransport transport;
  late FakeCrashReporter crash;
  late CrashLogSink sink;
  late RingBufferLog ring;
  late Set<String> killed;

  ObservabilityController build({
    ObservabilityConfig config = keys,
    SettingsRepository? repo,
  }) => ObservabilityController(
    settings: repo ?? settings,
    config: config,
    analytics: AllowlistAnalytics(transport),
    crashReporter: crash,
    crashSink: sink,
    isFeatureEnabled: (f) => !killed.contains(f),
    logger: AppLogger(sinks: [ring], echoToConsole: false),
  );

  Future<void> consent({
    bool analytics = false,
    bool crashReports = false,
    bool adult = true,
    bool completed = true,
  }) async {
    await settings.set(SettingsKeys.onboardingCompleted, completed);
    await settings.set(SettingsKeys.ageConfirmed16, adult);
    await settings.set(SettingsKeys.analyticsOptIn, analytics);
    await settings.set(SettingsKeys.crashReports, crashReports);
  }

  setUp(() {
    settings = InMemorySettingsRepository();
    transport = FakeTransport();
    crash = FakeCrashReporter();
    sink = CrashLogSink();
    ring = RingBufferLog();
    killed = {};
  });

  test('without opt-in nothing is ever initialized (fresh install)', () async {
    // crash_reports ma v kontrakte default true; pred O7 to nie je suhlas.
    final c = build();
    await c.refresh();
    expect(transport.starts, 0);
    expect(crash.starts, 0);
  });

  test('explicit "no" after onboarding keeps both off', () async {
    await consent();
    final c = build();
    await c.refresh();
    expect(transport.starts, 0);
    expect(crash.starts, 0);
  });

  test('consent without age confirmation is not consent', () async {
    await consent(analytics: true, crashReports: true, adult: false);
    final c = build();
    await c.refresh();
    expect(transport.starts, 0);
    expect(crash.starts, 0);
  });

  test('analytics opt-in starts only PostHog', () async {
    await consent(analytics: true);
    final c = build();
    await c.refresh();
    expect(transport.starts, 1);
    expect(c.analytics.isEnabled, isTrue);
    expect(crash.starts, 0);
  });

  test('crash opt-in starts only Sentry and attaches the log sink', () async {
    await consent(crashReports: true);
    final c = build();
    await c.refresh();
    expect(transport.starts, 0);
    expect(crash.starts, 1);
    sink.add(
      LogEntry(DateTime.utc(2027), LogLevel.info, 'content', 'ok', const {}),
    );
    expect(crash.crumbs, hasLength(1));
  });

  test(
    'without keys (no --dart-define) SDKs stay off despite consent',
    () async {
      await consent(analytics: true, crashReports: true);
      final c = build(config: const ObservabilityConfig());
      await c.refresh();
      expect(transport.starts, 0);
      expect(crash.starts, 0);
    },
  );

  test('kill-switch keeps SDKs off', () async {
    await consent(analytics: true, crashReports: true);
    killed = {ObservabilityFeature.posthog, ObservabilityFeature.sentry};
    final c = build();
    await c.refresh();
    expect(transport.starts, 0);
    expect(crash.starts, 0);
  });

  test('kill-switch turned on later stops running SDKs', () async {
    await consent(analytics: true, crashReports: true);
    final c = build();
    await c.refresh();
    killed = {ObservabilityFeature.posthog, ObservabilityFeature.sentry};
    await c.refresh();
    expect(transport.stops, [true]);
    expect(crash.stops, [true]);
  });

  test('revoking consent stops at once and wipes local queues', () async {
    await consent(analytics: true, crashReports: true);
    final c = build();
    await c.refresh();
    c.analytics.enqueueConsented([
      ('screen_view', {'screen': 'today'}),
    ]);
    await settings.set(SettingsKeys.analyticsOptIn, false);
    await settings.set(SettingsKeys.crashReports, false);
    await c.refresh();
    expect(transport.stops, [true]);
    expect(c.analytics.queuedCount, 0);
    expect(crash.stops, [true]);
    expect(crash.isRunning, isFalse);
    sink.add(LogEntry(DateTime.utc(2027), LogLevel.error, 'db', 'x', const {}));
    expect(crash.crumbs, isEmpty);
  });

  test('consented events survive a refresh that read stale settings', () async {
    final c = build();
    final stale = c.refresh(); // cita nastavenia este bez suhlasu
    await consent(analytics: true);
    final sent = c.sendConsented([
      ('onboarding_step', {'step': 'privacy', 'skipped': false}),
    ]);
    await Future.wait([stale, sent]);
    await pumpEventQueue();
    expect(transport.sent.single.$1, 'onboarding_step');
  });

  test('consented events are dropped when consent is not stored', () async {
    final c = build();
    await c.sendConsented([
      ('onboarding_step', {'step': 'privacy', 'skipped': false}),
    ]);
    expect(transport.starts, 0);
    expect(c.analytics.queuedCount, 0);
  });

  test('refreshes are applied in order', () async {
    await consent(analytics: true);
    final c = build();
    final a = c.refresh();
    final b = c.refresh();
    await Future.wait([a, b]);
    expect(transport.starts, 1);
  });

  test('unreadable settings mean no consent', () async {
    final c = build(repo: _BrokenSettings());
    await c.refresh();
    expect(transport.starts, 0);
    expect(ring.entries.map((e) => e.msg), contains('consent read failed'));
  });

  test(
    'crash reporter start failure is logged and sink stays detached',
    () async {
      await consent(crashReports: true);
      crash.startError = StateError('init');
      final c = build();
      await c.refresh();
      expect(ring.entries.last.msg, 'crash reporting toggle failed');
      sink.add(
        LogEntry(DateTime.utc(2027), LogLevel.error, 'db', 'x', const {}),
      );
      expect(crash.captured, isEmpty);
    },
  );

  test('dispose stops without wiping and ignores later refreshes', () async {
    await consent(analytics: true, crashReports: true);
    final c = build();
    await c.refresh();
    await c.dispose();
    expect(transport.stops, [false]);
    expect(crash.stops, [false]);
    await c.refresh();
    expect(transport.starts, 1);
  });
}
