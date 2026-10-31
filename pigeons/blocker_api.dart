// Pigeon definicia rozhrania nativneho blockeru (TECHNICKY_PLAN 11,
// docs/02 D14, docs/07 ADR-10). Generovanie:
//
//   dart run pigeon --input pigeons/blocker_api.dart
//   dart format lib/data/blocker   # tool/check.sh vyzaduje formatovany kod
//
// Vystupy (commitnute, needitovat rucne):
// - lib/data/blocker/blocker_api.pigeon.dart
// - android/app/src/full/kotlin/app/prosoche/blocker/BlockerApi.g.kt
//
// Kontrakt chybovych kodov (`FlutterError.code` -> `PlatformException.code`,
// docs/06 C.5): `permission_missing`, `service_not_running`,
// `overlay_denied`, `invalid_target`, `os_unsupported`, `internal`.
// Nativny kod nikdy nedava do `message`/`details` nazvy balikov ani data
// pouzivatela.
//
// Pri nekompatibilnej zmene zvysit `BLOCKER_API_VERSION` (Kotlin) a
// `blockerApiVersion` (Dart), status().apiVersion ich porovna,
// lebo GateActivity a hlavna appka mozu bezat v roznych enginoch.
// ignore_for_file: avoid_positional_boolean_parameters

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/data/blocker/blocker_api.pigeon.dart',
    dartPackageName: 'prosoche',
    kotlinOut: 'android/app/src/full/kotlin/app/prosoche/blocker/BlockerApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'app.prosoche.blocker'),
  ),
)
/// Stav povolenia na sledovanie appiek v popredi (Android: usage access).
enum BlockerPermission { granted, denied, notDetermined, restricted }

/// Systemove nastavenia, ktore vie appka otvorit (onboarding, O6).
enum SystemSettingsKind {
  usageAccess,
  overlay,
  exactAlarm,
  batteryOptimization,
  notifications,
}

/// Blokovana appka a jej pravidla.
class BlockedTarget {
  BlockedTarget({
    required this.ref,
    required this.cardsRequired,
    required this.unlockMinutes,
    this.label,
    this.iconPng,
  });

  /// Android: packageName, iOS: opaque id do App Group selection.
  String ref;

  /// iOS: null.
  String? label;

  /// Android: ikona appky (PNG), iOS: null.
  Uint8List? iconPng;
  int cardsRequired;
  int unlockMinutes;
}

/// Spustitelna appka zo zoznamu (`<queries>` MAIN/LAUNCHER, bez
/// QUERY_ALL_PACKAGES). Ikona sa taha zvlast cez `appIcon`.
class InstalledApp {
  InstalledApp({required this.ref, required this.label});
  String ref;
  String label;
}

/// Tri nezavisle stavy pre O6 (docs/02 D14).
class PermissionsDetail {
  PermissionsDetail({
    required this.usageAccess,
    required this.overlay,
    required this.notifications,
    required this.exactAlarm,
    required this.batteryOptimized,
  });
  bool usageAccess;
  bool overlay;
  bool notifications;
  bool exactAlarm;

  /// true = appka podlieha optimalizacii baterie (Doze moze zabit sluzbu).
  bool batteryOptimized;
}

class BlockerStatus {
  BlockerStatus({
    required this.apiVersion,
    required this.enabled,
    required this.permission,
    required this.serviceRunning,
  });

  /// Verzia nativnej strany (ADR-10).
  int apiVersion;
  bool enabled;
  BlockerPermission permission;

  /// iOS: vzdy true, ak su stity aktivne.
  bool serviceRunning;
}

@HostApi()
abstract class BlockerHostApi {
  BlockerStatus status();

  PermissionsDetail permissionsDetail();

  /// Android: ak chyba usage access, otvori jeho nastavenia a vrati
  /// aktualny stav (Flutter ho po navrate znova overi cez [status]).
  @async
  BlockerPermission requestPermission();

  /// Intenty podla verzie Androidu, fallback detail appky.
  void openSystemSettings(SystemSettingsKind kind);

  /// iOS: FamilyActivityPicker. Android: `os_unsupported` (zoznam je
  /// Flutter UI nad [installedApps]).
  @async
  List<BlockedTarget> pickTargets();

  /// Spustitelne appky okrem samotnej Mursy, zoradene podla nazvu.
  @async
  List<InstalledApp> installedApps();

  /// PNG ikona appky (cca 96 px) alebo null, ak appka neexistuje.
  @async
  Uint8List? appIcon(String ref);

  void setTargets(List<BlockedTarget> targets);

  /// Zapne/vypne BlockerService. Volat len z popredia (docs/08 B).
  /// Bez usage access hodi `permission_missing`.
  void setEnabled(bool enabled);

  /// Odomkne [ref] na [minutes] minut (1-1440), meria sa monotonnym casom.
  void unlockFor(String ref, int minutes);

  /// Zavrie branu. true: cielova appka, false: home screen.
  void closeGate(bool openTarget);

  /// Zmaze vsetky odomknutia (`UnlockStore`), napr. po "Delete all my
  /// data" (A10.9).
  void clearUnlocks();

  /// `Build.MANUFACTURER` malymi pismenami (navod k baterii v O6).
  String deviceManufacturer();

  /// Zatial len ulozi okna modlitieb (prayer lock je pripomienka v UI
  /// brany, nie zamknutie, TECHNICKY_PLAN 9.2 bod 7).
  void schedulePrayerLocks(List<int> startEpochMs, int durationMinutes);
}

@FlutterApi()
abstract class BlockerFlutterApi {
  /// Nativ -> Flutter: otvor branu (`/gate?app=ref`) v uz beziacom engine.
  void onGateRequested(String ref);
}
