import 'dart:async';

import 'package:meta/meta.dart';
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/data/observability/allowlist_analytics.dart';
import 'package:prosoche/data/observability/crash_reporter.dart';
import 'package:prosoche/data/observability/observability_config.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';

/// Nazvy funkcii pre kill-switch v `remote_config.json` (docs/06 A.7).
/// `posthog` je v D-03 `RemoteFeature.posthog`; `sentry` je navrh D-04.
abstract final class ObservabilityFeature {
  static const posthog = 'posthog';
  static const sentry = 'sentry';
}

/// Vyslovne suhlasy (TECHNICKY_PLAN 13, 24.3; docs/02 A1 O7).
///
/// Suhlas plati len po dokonceni onboardingu a potvrdeni veku 16+ (oba
/// suhlasy maju default `false`; stare instalacie mohli mat `true` z
/// predchadzajuceho defaultu, preto sa pred O7 nikdy neberu ako suhlas).
@immutable
class ObservabilityConsent {
  const ObservabilityConsent({
    required this.analytics,
    required this.crashReports,
  });

  static const none = ObservabilityConsent(
    analytics: false,
    crashReports: false,
  );

  /// Kluce, ktorych zmena znamena novy vypocet suhlasu.
  static final keys = <SettingKey<bool>>[
    SettingsKeys.onboardingCompleted,
    SettingsKeys.ageConfirmed16,
    SettingsKeys.analyticsOptIn,
    SettingsKeys.crashReports,
  ];

  static Future<ObservabilityConsent> read(SettingsRepository s) async {
    final completed = await s.get(SettingsKeys.onboardingCompleted);
    final adult = await s.get(SettingsKeys.ageConfirmed16);
    if (!completed || !adult) return none;
    return ObservabilityConsent(
      analytics: await s.get(SettingsKeys.analyticsOptIn),
      crashReports: await s.get(SettingsKeys.crashReports),
    );
  }

  final bool analytics;
  final bool crashReports;
}

/// Zapina a vypina PostHog a Sentry podla suhlasu, kluca a kill-switchu.
///
/// Kazde [refresh] cita suhlas znova z [SettingsRepository] (nie zo
/// streamu), takze nikdy nepouzije zastaranu hodnotu; volania sa radia za
/// sebou. Odvolanie suhlasu alebo kill-switch = okamzite vypnutie
/// a zmazanie lokalnych front.
class ObservabilityController {
  ObservabilityController({
    required this._settings,
    required this.config,
    required this.analytics,
    required this.crashReporter,
    required this.crashSink,
    required this._isFeatureEnabled,
    this._logger,
  });

  final SettingsRepository _settings;
  final ObservabilityConfig config;
  final AllowlistAnalytics analytics;
  final CrashReporter crashReporter;
  final CrashLogSink crashSink;
  final bool Function(String feature) _isFeatureEnabled;
  final AppLogger? _logger;

  Future<void> _chain = Future.value();
  var _disposed = false;

  /// Znova vyhodnoti suhlas a kill-switch. Vrati Future, ktory skonci,
  /// ked je novy stav aplikovany.
  Future<void> refresh() => _enqueue(_apply);

  /// Eventy nazbierane pred suhlasom (onboarding O7), volane az po ulozeni
  /// suhlasu. Zaradia sa za rozbehnute vyhodnotenia (tie mohli citat
  /// nastavenia este pred ulozenim), potom sa suhlas precita znova: ak
  /// plati, eventy sa odoslu, inak sa zahodia.
  Future<void> sendConsented(Iterable<(String, Map<String, Object?>)> events) =>
      _enqueue(() async {
        if (_disposed) return;
        analytics.enqueueConsented(events);
        await _apply();
      });

  Future<void> _enqueue(Future<void> Function() step) =>
      _chain = _chain.then((_) => step()).catchError((Object e) {
        _logger?.warn('observability', 'refresh failed', {
          'type': e.runtimeType.toString(),
        });
      });

  Future<void> _apply() async {
    if (_disposed) return;
    ObservabilityConsent consent;
    try {
      consent = await ObservabilityConsent.read(_settings);
    } on Object catch (e) {
      // Bez citatelnych nastaveni nic neodosielat.
      _logger?.warn('observability', 'consent read failed', {
        'type': e.runtimeType.toString(),
      });
      consent = ObservabilityConsent.none;
    }
    if (_disposed) return;

    final analyticsOn =
        consent.analytics &&
        config.hasPosthog &&
        _isFeatureEnabled(ObservabilityFeature.posthog);
    if (analyticsOn) {
      await analytics.enable();
    } else {
      await analytics.disable();
    }

    final crashOn =
        consent.crashReports &&
        config.hasSentry &&
        _isFeatureEnabled(ObservabilityFeature.sentry);
    await _applyCrash(on: crashOn);
  }

  Future<void> _applyCrash({required bool on}) async {
    if (on == crashReporter.isRunning) return;
    try {
      if (on) {
        await crashReporter.start();
        crashSink.attach(crashReporter);
        _logger?.info('observability', 'crash reporting on');
      } else {
        crashSink.attach(null);
        await crashReporter.stop(wipe: true);
        _logger?.info('observability', 'crash reporting off');
      }
    } on Object catch (e) {
      crashSink.attach(null);
      _logger?.warn('observability', 'crash reporting toggle failed', {
        'type': e.runtimeType.toString(),
      });
    }
  }

  /// Vypne vsetko (koniec containera).
  Future<void> dispose() async {
    _disposed = true;
    await _chain;
    crashSink.attach(null);
    await analytics.disable(wipe: false);
    if (crashReporter.isRunning) await crashReporter.stop(wipe: false);
  }
}
