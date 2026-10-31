import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/core/flavor/flavor.dart';
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/core/logging/logger_provider.dart';
import 'package:prosoche/data/content/content_providers.dart';
import 'package:prosoche/data/observability/allowlist_analytics.dart';
import 'package:prosoche/data/observability/analytics.dart';
import 'package:prosoche/data/observability/crash_reporter.dart';
import 'package:prosoche/data/observability/observability_config.dart';
import 'package:prosoche/data/observability/observability_controller.dart';
import 'package:prosoche/data/observability/posthog_transport.dart';
import 'package:prosoche/data/observability/problem_report.dart';
import 'package:prosoche/data/observability/sentry_crash_reporter.dart';
import 'package:prosoche/data/repositories/settings/settings_providers.dart';

/// Kluce z `--dart-define`. V testoch `overrideWithValue`.
final Provider<ObservabilityConfig> observabilityConfigProvider =
    Provider<ObservabilityConfig>(
      (ref) => const ObservabilityConfig.fromEnvironment(),
      name: 'observabilityConfigProvider',
    );

/// Ring buffer loggera. Bootstrap ho prepise instanciou, ktoru dostal
/// `AppLogger` (ta ista pamat pre "Nahlasit problem").
final Provider<RingBufferLog> ringBufferLogProvider = Provider<RingBufferLog>(
  (ref) => RingBufferLog(),
  name: 'ringBufferLogProvider',
);

/// Sink loggera pre Sentry. Bootstrap ho prepise instanciou z `AppLogger`.
final Provider<CrashLogSink> crashLogSinkProvider = Provider<CrashLogSink>(
  (ref) => CrashLogSink(),
  name: 'crashLogSinkProvider',
);

/// PostHog len s klucom; bez kluca transport, ktory nic neposle.
final Provider<AnalyticsTransport> analyticsTransportProvider =
    Provider<AnalyticsTransport>((ref) {
      final config = ref.watch(observabilityConfigProvider);
      return config.hasPosthog
          ? PostHogTransport(config.posthogApiKey)
          : const _NoopTransport();
    }, name: 'analyticsTransportProvider');

/// Sentry len s DSN; bez DSN no-op.
final Provider<CrashReporter> crashReporterProvider = Provider<CrashReporter>((
  ref,
) {
  final config = ref.watch(observabilityConfigProvider);
  return config.hasSentry
      ? SentryCrashReporter(config, logger: ref.watch(appLoggerProvider))
      : const NoopCrashReporter();
}, name: 'crashReporterProvider');

/// Spolocne vlastnosti eventov (docs/02 0.6): `app_version`,
/// `content_version`, `locale`, `flavor`. Hodnoty sa citaju v case eventu.
final Provider<Map<String, Object?> Function()>
analyticsSuperPropertiesProvider = Provider<Map<String, Object?> Function()>((
  ref,
) {
  String? locale;
  int? contentVersion;
  ref
    ..listen(contentLanguageProvider, (_, next) {
      locale = next.value ?? locale;
    }, fireImmediately: true)
    ..listen(contentPackStateProvider, (_, next) {
      contentVersion = next.value?.installedVersion ?? contentVersion;
    }, fireImmediately: true);
  final appVersion = ref.watch(appVersionProvider).toString();
  final flavor = ref.watch(flavorProvider).name;
  return () => {
    'app_version': appVersion,
    'content_version': contentVersion,
    'locale': locale,
    'flavor': flavor,
  };
}, name: 'analyticsSuperPropertiesProvider');

final Provider<AllowlistAnalytics> allowlistAnalyticsProvider =
    Provider<AllowlistAnalytics>(
      (ref) => AllowlistAnalytics(
        ref.watch(analyticsTransportProvider),
        superProperties: ref.watch(analyticsSuperPropertiesProvider),
        logger: ref.watch(appLoggerProvider),
      ),
      name: 'allowlistAnalyticsProvider',
    );

/// Analytika pre featury: `ref.read(analyticsProvider).track(...)`.
/// Bez suhlasu, bez kluca alebo pri kill-switchi eventy zahodi.
final Provider<Analytics> analyticsProvider = Provider<Analytics>(
  (ref) => ref.watch(allowlistAnalyticsProvider),
  name: 'analyticsProvider',
);

/// Riadenie PostHog a Sentry. Sleduje suhlasy v `settings` a kill-switch;
/// pri kazdej zmene znova vyhodnoti stav (vid [ObservabilityController]).
final Provider<ObservabilityController> observabilityControllerProvider =
    Provider<ObservabilityController>((ref) {
      final controller = ObservabilityController(
        settings: ref.watch(settingsRepositoryProvider),
        config: ref.watch(observabilityConfigProvider),
        analytics: ref.watch(allowlistAnalyticsProvider),
        crashReporter: ref.watch(crashReporterProvider),
        crashSink: ref.watch(crashLogSinkProvider),
        isFeatureEnabled: (f) =>
            ref.read(remoteConfigPolicyProvider).isFeatureEnabled(f),
        logger: ref.watch(appLoggerProvider),
      );
      for (final key in ObservabilityConsent.keys) {
        ref.listen(settingProvider(key), (prev, next) {
          if (prev?.value != next.value) unawaited(controller.refresh());
        });
      }
      ref
        ..listen(remoteConfigPolicyProvider, (_, _) {
          unawaited(controller.refresh());
        })
        ..onDispose(() => unawaited(controller.dispose()));
      unawaited(controller.refresh());
      return controller;
    }, name: 'observabilityControllerProvider');

/// "Nahlasit problem" (docs/06 C.9) pre Nastavenia > Pomoc (F-07).
final Provider<ProblemReport> problemReportProvider = Provider<ProblemReport>((
  ref,
) {
  final appVersion = ref.watch(appVersionProvider).toString();
  final flavor = ref.watch(flavorProvider).name;
  final edition = ref.watch(editionProvider).name;
  return ProblemReport(
    ring: ref.watch(ringBufferLogProvider),
    clock: ref.watch(appClockProvider),
    tempDirectory: getTemporaryDirectory,
    header: () {
      final content = ref.read(contentPackStateProvider).value;
      return DiagnosticsHeader({
        'app_version': appVersion,
        'flavor': '$flavor/$edition',
        'content_version': '${content?.installedVersion ?? '-'}',
        'os': '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      });
    },
  );
}, name: 'problemReportProvider');

final class _NoopTransport implements AnalyticsTransport {
  const _NoopTransport();

  @override
  Future<void> start() async {}

  @override
  Future<void> capture(String event, Map<String, Object> props) async {}

  @override
  Future<void> stop({required bool wipe}) async {}
}
