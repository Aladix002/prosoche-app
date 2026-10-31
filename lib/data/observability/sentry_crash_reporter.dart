import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/data/observability/crash_reporter.dart';
import 'package:prosoche/data/observability/observability_config.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Typ breadcrumbov z [CrashLogSink]. Ine breadcrumbs (auto z SDK)
/// sa zahodia, lebo mozu niest texty tlacidiel, URL alebo route parametre.
const prosocheBreadcrumbType = 'prosoche';

/// Sentry konfiguracia (docs/06 C.8): bez PII, screenshotov, view
/// hierarchy, session replay a tracingu; release health zapnute.
void configureSentry(SentryFlutterOptions o, ObservabilityConfig config) {
  o
    ..dsn = config.sentryDsn
    ..environment = config.sentryEnvironment
    ..sendDefaultPii = false
    ..sampleRate = 1.0
    ..tracesSampleRate = 0.0
    ..enableAutoSessionTracking = true
    ..attachScreenshot = false
    ..attachViewHierarchy = false
    ..attachThreads = false
    ..maxBreadcrumbs = 50
    ..enableAutoPerformanceTracing = false
    ..enableUserInteractionBreadcrumbs = false
    ..enableUserInteractionTracing = false
    ..enableAutoNativeBreadcrumbs = false
    ..captureFailedRequests = false
    ..reportPackages = false
    ..diagnosticLevel = SentryLevel.warning
    ..beforeBreadcrumb = filterBreadcrumb
    ..beforeSend = scrubEvent;
  if (config.sentryRelease != null) o.release = config.sentryRelease;
  if (config.sentryDist != null) o.dist = config.sentryDist;
  o.replay
    ..sessionSampleRate = 0.0
    ..onErrorSampleRate = 0.0;
}

/// Necha len breadcrumbs z loggera (uz po allowliste klucov).
@visibleForTesting
Breadcrumb? filterBreadcrumb(Breadcrumb? crumb, Hint hint) =>
    crumb?.type == prosocheBreadcrumbType ? crumb : null;

/// `beforeSend`: odstrani pouzivatela, server, request, nazov zariadenia,
/// casove pasmo a extra; spravy a hodnoty vynimiek prejdu [scrubText].
@visibleForTesting
SentryEvent? scrubEvent(SentryEvent event, Hint hint) {
  event
    ..user = null
    ..serverName = null
    ..request = null
    // extra je deprecated, ale SDK ho stale posiela; vymazat.
    // ignore: deprecated_member_use
    ..extra = null
    ..breadcrumbs = event.breadcrumbs
        ?.where((b) => b.type == prosocheBreadcrumbType)
        .toList();
  final message = event.message;
  if (message != null) {
    message
      ..formatted = scrubText(message.formatted)
      ..params = null;
    final template = message.template;
    if (template != null) message.template = scrubText(template);
  }
  for (final e in event.exceptions ?? const <SentryException>[]) {
    final value = e.value;
    if (value != null) e.value = scrubText(value);
  }
  event.contexts.device?.name = null;
  event.contexts.culture?.timezone = null;
  event.tags?.remove('locale_city');
  return event;
}

final _coords = RegExp(r'-?\d{1,3}\.\d{2,}\s*,\s*-?\d{1,3}\.\d{2,}');
final _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');
final _pkg = RegExp(r'\b[a-z][a-z0-9_]*(\.[a-z0-9_]+){2,}\b');
final _url = RegExp(r'https?://\S+');

/// Nahradi suradnice, e-maily, URL a package names (docs/06 C.8).
@visibleForTesting
String scrubText(String s) => s
    .replaceAll(_url, '<url>')
    .replaceAll(_coords, '<coords>')
    .replaceAll(_email, '<email>')
    .replaceAll(_pkg, '<pkg>');

SentryLevel _levelOf(LogLevel l) => switch (l) {
  LogLevel.trace || LogLevel.debug => SentryLevel.debug,
  LogLevel.info => SentryLevel.info,
  LogLevel.warn => SentryLevel.warning,
  LogLevel.error => SentryLevel.error,
  LogLevel.fatal => SentryLevel.fatal,
};

/// Zmaze offline cache Sentry SDK (`<cache>/sentry`, Android
/// `SentryAndroidOptions.cacheDirPath`) [OVERIT pre iOS].
Future<void> deleteSentryCache() async {
  final dir = Directory(
    p.join((await getApplicationCacheDirectory()).path, 'sentry'),
  );
  if (dir.existsSync()) await dir.delete(recursive: true);
}

/// [CrashReporter] nad `sentry_flutter`. Inicializuje sa az po suhlase
/// (po `runApp`, bez `appRunner`); `Sentry.close` vrati povodne handlery.
class SentryCrashReporter implements CrashReporter {
  SentryCrashReporter(
    this._config, {
    Future<void> Function()? wipeCache,
    this._logger,
  }) : _wipeCache = wipeCache ?? deleteSentryCache;

  final ObservabilityConfig _config;
  final Future<void> Function() _wipeCache;
  final AppLogger? _logger;
  var _running = false;

  @override
  bool get isRunning => _running;

  @override
  Future<void> start() async {
    if (_running || !_config.hasSentry) return;
    await SentryFlutter.init((o) => configureSentry(o, _config));
    _running = Sentry.isEnabled;
  }

  @override
  Future<void> stop({required bool wipe}) async {
    _running = false;
    await Sentry.close();
    if (!wipe) return;
    try {
      await _wipeCache();
    } on Object catch (e) {
      _logger?.warn('crash', 'cache wipe failed', {
        'type': e.runtimeType.toString(),
      });
    }
  }

  @override
  void addBreadcrumb(LogEntry entry) => unawaited(
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: entry.tag,
        message: entry.msg,
        data: entry.kv.isEmpty ? null : Map.of(entry.kv),
        level: _levelOf(entry.level),
        type: prosocheBreadcrumbType,
      ),
    ),
  );

  @override
  void captureEntry(LogEntry entry) {
    final code = entry.kv['code'];
    final type = entry.kv['type'];
    final message = entry.msg == 'failure' && code is String
        ? code
        : '${entry.tag}: ${entry.msg}';
    unawaited(
      Sentry.captureMessage(
        message,
        level: _levelOf(entry.level),
        withScope: (s) async {
          await s.setTag('tag', entry.tag);
          if (code is String) await s.setTag('failure', code);
          if (type is String) await s.setTag('error_type', type);
          s.fingerprint = [message];
        },
      ),
    );
  }
}
