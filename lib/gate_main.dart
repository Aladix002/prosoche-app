import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:path_provider/path_provider.dart';
import 'package:sakina/app/content_wiring.dart';
import 'package:sakina/bootstrap.dart' show installGlobalErrorHandlers;
import 'package:sakina/core/flavor/flavor.dart';
import 'package:sakina/core/logging/app_logger.dart';
import 'package:sakina/core/logging/logger_provider.dart';
import 'package:sakina/data/content/content_providers.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/features/gate/gate_app.dart';

/// Entrypoint predhriateho enginu brany (ADR-16, TECHNICKY_PLAN 9.1).
///
/// Spusta ho nativ (`GateEngine.warmUp`) pri starte `BlockerService`, nie
/// az pri otvoreni blokovanej appky. Lahky bootstrap: logger, content.db
/// a user.db, ziadne notifikacie, poloha ani router. Engine zostava v
/// `FlutterEngineCache` a GateActivity ho len pripoji.
@pragma('vm:entry-point')
Future<void> gateMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  final flavor = flavorFromName(appFlavor);
  final logger = AppLogger(
    sinks: [RingBufferLog()],
    minLevel: flavor.isDev ? LogLevel.debug : LogLevel.info,
  );
  installGlobalErrorHandlers(logger);
  // Ziadne SystemChrome tu: engine bezi bez aktivity a PlatformPlugin
  // (systemove kanaly) existuje az po pripojeni GateActivity. Edge-to-edge
  // nastavi GateApp pri prvej poziadavke.

  final container = ProviderContainer(
    overrides: gateOverrides(
      flavor: flavor,
      edition: editionFromName(appFlavor),
      logger: logger,
      supportDir: await getApplicationSupportDirectory(),
    ),
  );
  runApp(
    UncontrolledProviderScope(container: container, child: const GateApp()),
  );
  unawaited(warmUpGate(container, logger));
}

/// Overrides enginu brany: len to, co brana potrebuje.
List<Override> gateOverrides({
  required Flavor flavor,
  required Edition edition,
  required AppLogger logger,
  required Directory supportDir,
}) => [
  flavorProvider.overrideWithValue(flavor),
  editionProvider.overrideWithValue(edition),
  appLoggerProvider.overrideWithValue(logger),
  ...contentOverrides(supportDir: supportDir),
];

/// Otvori content.db a user.db vopred, aby prva brana nacitala karty bez
/// cakania na disk. Sadu negeneruje (to robi az otvorena brana).
Future<void> warmUpGate(ProviderContainer container, AppLogger logger) async {
  try {
    await container.read(contentDatabaseProvider.future);
    await container.read(userDbProvider).customSelect('SELECT 1').get();
  } on Object catch (e, st) {
    // Brana sa pokusi znova pri otvoreni a pri chybe ponukne "Continue".
    logger.error('gate', 'warm up failed', error: e, stack: st);
  }
}
