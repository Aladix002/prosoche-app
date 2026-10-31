import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:patrol/patrol.dart';
import 'package:sakina/app.dart';
import 'package:sakina/app/background.dart';
import 'package:sakina/app/content_wiring.dart';
import 'package:sakina/app/data_deletion_wiring.dart';
import 'package:sakina/app/gate_wiring.dart';
import 'package:sakina/app/location_wiring.dart';
import 'package:sakina/app/notification_wiring.dart';
import 'package:sakina/app/observability_wiring.dart';
import 'package:sakina/core/clock/clock_provider.dart';
import 'package:sakina/core/flavor/flavor.dart';
import 'package:sakina/core/logging/app_logger.dart';
import 'package:sakina/core/logging/logger_provider.dart';
import 'package:sakina/core/router/app_router.dart';
import 'package:sakina/data/content/content_providers.dart';
import 'package:sakina/data/observability/crash_reporter.dart';
import 'package:sakina/data/repositories/infra/databases.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fixny cas E2E: streda 11. 11. 2026 09:00 (lokalny cas zariadenia).
/// Nie je piatok (al-Kahf), Ramadan ani sviatok, Bratislava ma vsetkych
/// 5 modlitieb. Hodiny od tohto okamihu bezia realnym tempom (dwell,
/// casovace). `--dart-define=E2E_REAL_TIME=true` = realny cas (testy su
/// tolerantne).
final DateTime e2eStart = DateTime(2026, 11, 11, 9);

const _realTime = bool.fromEnvironment('E2E_REAL_TIME');

/// Hodiny appky pre E2E (prepisu `appClockProvider`).
Clock e2eClock() {
  if (_realTime) return const Clock();
  final elapsed = Stopwatch()..start();
  return Clock(() => e2eStart.add(elapsed.elapsed));
}

/// Kontajner spustenej appky (pre kontroly stavu, napr. suhlasy).
late ProviderContainer appContainer;

/// Spusti realnu appku (flavor z `--flavor`, realna content.db z assetov).
///
/// Kopia `bootstrap()` z `lib/bootstrap.dart` s dvoma rozdielmi:
/// prepisane hodiny ([e2eClock]) a bez globalnych error handlerov (chyby
/// frameworku, napr. pretecenie layoutu, musia zhodit test).
///
/// [resetData] zmaze user.db a SharedPreferences pred startom (ako cerstva
/// instalacia; nainstalovana content.db ostava). Orchestrator spusta kazdy
/// test v novom procese, preto sa nic nemusi zatvarat. `false` = restart
/// appky nad datami z predchadzajuceho testu.
Future<void> startApp(
  PatrolIntegrationTester $, {
  bool resetData = true,
}) async {
  final support = await getApplicationSupportDirectory();
  if (resetData) await wipeUserData(support);

  final flavor = flavorFromName(appFlavor);
  final ring = RingBufferLog();
  final crashSink = CrashLogSink();
  final logger = AppLogger(sinks: [ring, crashSink], minLevel: LogLevel.debug);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final container = ProviderContainer(
    overrides: [
      flavorProvider.overrideWithValue(flavor),
      editionProvider.overrideWithValue(editionFromName(appFlavor)),
      appLoggerProvider.overrideWithValue(logger),
      appClockProvider.overrideWithValue(e2eClock()),
      ...contentOverrides(supportDir: support),
      ...notificationOverrides(),
      ...locationOverrides(),
      ...observabilityOverrides(ring: ring, crashSink: crashSink),
      ...dataDeletionOverrides(),
    ],
  );
  appContainer = container;
  container.read(contentDatabaseProvider.future).ignore();

  await $.tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const SakinaApp()),
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

/// Zmaze user.db (aj WAL) a SharedPreferences.
Future<void> wipeUserData(Directory support) async {
  for (final suffix in ['', '-wal', '-shm', '-journal']) {
    final f = File(p.join(support.path, '$userDbFileName$suffix'));
    if (f.existsSync()) await f.delete();
  }
  await SharedPreferencesAsync().clear();
}
