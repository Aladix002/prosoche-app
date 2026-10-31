import 'package:meta/meta.dart';

/// Kluce a metadata z `--dart-define` (docs/06 C.8, D.6).
///
/// Prazdne `SENTRY_DSN` alebo `POSTHOG_API_KEY` = prislusne SDK sa nikdy
/// neinicializuje (dev flavor, lokalne buildy, testy).
@immutable
class ObservabilityConfig {
  const ObservabilityConfig({
    this.sentryDsn = '',
    this.posthogApiKey = '',
    this.sentryEnvironment = 'dev',
    this.sentryRelease,
    this.sentryDist,
  });

  /// Hodnoty z `--dart-define`.
  const ObservabilityConfig.fromEnvironment()
    : sentryDsn = const String.fromEnvironment('SENTRY_DSN'),
      posthogApiKey = const String.fromEnvironment('POSTHOG_API_KEY'),
      sentryEnvironment = const String.fromEnvironment(
        'SENTRY_ENVIRONMENT',
        defaultValue: 'dev',
      ),
      sentryRelease = const bool.hasEnvironment('SENTRY_RELEASE')
          ? const String.fromEnvironment('SENTRY_RELEASE')
          : null,
      sentryDist = const bool.hasEnvironment('SENTRY_DIST')
          ? const String.fromEnvironment('SENTRY_DIST')
          : null;

  final String sentryDsn;
  final String posthogApiKey;
  final String sentryEnvironment;
  final String? sentryRelease;
  final String? sentryDist;

  bool get hasSentry => sentryDsn.trim().isNotEmpty;
  bool get hasPosthog => posthogApiKey.trim().isNotEmpty;
}
