import 'dart:async';
import 'dart:ui' show ErrorCallback;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prosoche/app.dart';
import 'package:prosoche/app/background.dart';
import 'package:prosoche/app/content_wiring.dart';
import 'package:prosoche/app/data_deletion_wiring.dart';
import 'package:prosoche/app/gate_wiring.dart';
import 'package:prosoche/app/notification_wiring.dart';
import 'package:prosoche/app/observability_wiring.dart';
import 'package:prosoche/core/flavor/flavor.dart';
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/core/logging/logger_provider.dart';
import 'package:prosoche/core/router/app_router.dart';
import 'package:prosoche/data/content/content_providers.dart';
import 'package:prosoche/data/observability/crash_reporter.dart';
import 'package:prosoche/ui/foundation/font_licenses.dart';

/// Spolocny start appky pre vsetky flavory.
///
/// Poradie podla docs/06 C.4: vlastne handlery sa nastavuju pred inicializaciou
/// crash reportingu. Sentry a PostHog spusti `startObservability` az po
/// `runApp` a len po vyslovnom suhlase (TECHNICKY_PLAN 13, D-04).
Future<void> bootstrap(Flavor flavor, {Edition edition = Edition.lite}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final ring = RingBufferLog();
  final crashSink = CrashLogSink();
  final logger = AppLogger(
    sinks: [ring, crashSink],
    minLevel: flavor.isDev ? LogLevel.debug : LogLevel.info,
  );
  installGlobalErrorHandlers(logger);

  // OFL licencie pribalenych fontov (Nastavenia > Zdroje a licencie).
  registerProsocheFontLicenses();

  // targetSdk 36: edge-to-edge je povinne, obsah riesi insets cez SafeArea.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final container = ProviderContainer(
    overrides: [
      flavorProvider.overrideWithValue(flavor),
      editionProvider.overrideWithValue(edition),
      appLoggerProvider.overrideWithValue(logger),
      ...contentOverrides(supportDir: await getApplicationSupportDirectory()),
      ...notificationOverrides(),
      ...observabilityOverrides(ring: ring, crashSink: crashSink),
      ...dataDeletionOverrides(),
    ],
  );

  // Instalacia/kontrola pribalenej content.db hned pri starte (D-03);
  // obrazovky medzitym ukazu loading.
  container.read(contentDatabaseProvider.future).ignore();

  runApp(
    UncontrolledProviderScope(container: container, child: const ProsocheApp()),
  );

  startObservability(container);
  startScreenViews(container);
  startGateSync(container);

  unawaited(
    startNotifications(
      container,
      router: () => container.read(appRouterProvider),
      dispatcher: backgroundDispatcher,
    ),
  );
}

/// Globalne handlery pre neocakavane chyby (docs/06 C.4).
///
/// `FlutterError.onError` chyta chyby frameworku (build/layout/paint),
/// `PlatformDispatcher.onError` vsetko ostatne (async chyby mimo callbackov).
/// `runZonedGuarded` netreba.
void installGlobalErrorHandlers(AppLogger logger) {
  FlutterError.onError = flutterErrorHandler(logger);
  PlatformDispatcher.instance.onError = platformErrorHandler(logger);
}

FlutterExceptionHandler flutterErrorHandler(AppLogger logger) => (details) {
  FlutterError.presentError(details);
  logger.error(
    'flutter',
    'framework error',
    error: details.exception,
    stack: details.stack,
  );
};

ErrorCallback platformErrorHandler(AppLogger logger) => (error, stack) {
  logger.error('platform', 'uncaught', error: error, stack: stack);
  return true;
};
