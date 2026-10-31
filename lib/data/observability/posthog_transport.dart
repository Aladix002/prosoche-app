import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:sakina/data/observability/allowlist_analytics.dart';
import 'package:sakina/data/observability/analytics.dart';

/// PostHog EU cloud (TECHNICKY_PLAN 13, docs/07 ADR-11).
const posthogEuHost = 'https://eu.i.posthog.com';

/// Vlastnost, ktora vypne GeoIP obohatenie eventu na serveri.
const _geoipDisable = r'$geoip_disable';

/// Konfiguracia PostHog: anonymne eventy bez person profilov, bez
/// autocapture, session replay, surveys, feature flags, error trackingu
/// a lifecycle eventov. Do PostHogu idu len eventy z [AnalyticsSchema].
PostHogConfig buildPostHogConfig(String apiKey) {
  final c = PostHogConfig(apiKey)
    ..host = posthogEuHost
    ..personProfiles = PostHogPersonProfiles.never
    ..captureApplicationLifecycleEvents = false
    ..sessionReplay = false
    ..surveys = false
    ..preloadFeatureFlags = false
    ..sendFeatureFlagEvent = false
    ..capturePushNotificationSubscriptions = false
    ..capturePushNotificationOpened = false
    ..debug = false
    ..beforeSend = [posthogGuard];
  c.rageClickConfig.enabled = false;
  // Error tracking PostHogu je default vypnuty; chyby idu len do Sentry
  // (po samostatnom suhlase `crash_reports`).
  c.errorTrackingConfig
    ..captureFlutterErrors = false
    ..capturePlatformDispatcherErrors = false
    ..captureIsolateErrors = false
    ..captureNativeExceptions = false;
  return c;
}

/// Posledna poistka pred SDK: neznamy event (napr. `$screen`, `$exception`)
/// zahodi, vlastnosti znova prefiltruje a zahodi `$set`/`$set_once`.
@visibleForTesting
PostHogEvent? posthogGuard(PostHogEvent event) {
  if (!AnalyticsSchema.isKnownEvent(event.event)) return null;
  final props = event.properties ?? const <String, Object>{};
  event
    ..properties = {
      ...AnalyticsSchema.sanitizeSuper(props),
      ...AnalyticsSchema.sanitize(event.event, props),
      _geoipDisable: true,
    }
    ..userProperties = null
    ..userPropertiesSetOnce = null;
  return event;
}

/// Adresare diskovych front nativneho SDK v `<cache>` (posthog-android
/// 3.x: `posthog-disk-queue`, `app_posthog-disk-queue`, replay a logs).
@visibleForTesting
const posthogQueueDirs = [
  'posthog-disk-queue',
  'app_posthog-disk-queue',
  'posthog-disk-replay-queue',
  'posthog-disk-logs-queue',
];

/// Zmaze diskove fronty PostHog. Nativne `reset()` maze len preferencie
/// a distinct ID, nie neodoslane eventy (overene v posthog 6.47.7).
Future<void> deletePosthogQueues([Directory? cacheDir]) async {
  final base = cacheDir ?? await getApplicationCacheDirectory();
  for (final name in posthogQueueDirs) {
    final dir = Directory(p.join(base.path, name));
    if (dir.existsSync()) await dir.delete(recursive: true);
  }
}

/// [AnalyticsTransport] nad `posthog_flutter`. Bez kluca sa nevytvara
/// (vid `analyticsTransportProvider`).
class PostHogTransport implements AnalyticsTransport {
  PostHogTransport(
    this._apiKey, {
    Posthog? posthog,
    Future<void> Function()? wipeDisk,
  }) : _posthog = posthog ?? Posthog(),
       _wipeDisk = wipeDisk ?? deletePosthogQueues;

  final String _apiKey;
  final Posthog _posthog;
  final Future<void> Function() _wipeDisk;

  @override
  Future<void> start() async {
    await _posthog.setup(buildPostHogConfig(_apiKey));
    // Po predchadzajucom odvolani je SDK v stave opt-out.
    await _posthog.optIn();
  }

  @override
  Future<void> capture(String event, Map<String, Object> props) =>
      _posthog.capture(eventName: event, properties: props);

  @override
  Future<void> stop({required bool wipe}) async {
    // optOut okamzite zastavi zber; reset zmaze anonymne distinct ID
    // a ulozene vlastnosti; close zastavi SDK; potom zmazat diskove fronty.
    await _posthog.optOut();
    if (wipe) await _posthog.reset();
    await _posthog.close();
    if (wipe) await _wipeDisk();
  }
}
