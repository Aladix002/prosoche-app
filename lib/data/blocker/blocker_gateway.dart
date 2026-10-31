import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:prosoche/core/result.dart';

/// Verzia Pigeon API, ktoru ocakava Dart (ADR-10). Musi sediet s Kotlin
/// `BLOCKER_API_VERSION`, inak [BlockerState.apiCompatible] je false.
const blockerApiVersion = 1;

/// Emergency odomknutie: vzdy 5 min, nie `unlock_minutes` (TECHNICKY_PLAN
/// 9.2 bod 6). Podrzanie 1,5 s a 10 s odpocet riesi UI brany (B-02).
const emergencyUnlockMinutes = 5;

/// Stav povolenia na sledovanie appiek v popredi (Android: usage access).
enum BlockerPermissionState { granted, denied, notDetermined, restricted }

/// Systemove nastavenia, ktore vie blocker otvorit (onboarding, O6).
enum BlockerSettings {
  usageAccess,
  overlay,
  exactAlarm,
  batteryOptimization,
  notifications,
}

@immutable
class BlockerState {
  const BlockerState({
    required this.enabled,
    required this.permission,
    required this.serviceRunning,
    required this.apiVersion,
  });

  final bool enabled;
  final BlockerPermissionState permission;
  final bool serviceRunning;

  /// Verzia nativnej strany (`status().apiVersion`).
  final int apiVersion;

  bool get apiCompatible => apiVersion == blockerApiVersion;

  @override
  bool operator ==(Object other) =>
      other is BlockerState &&
      other.enabled == enabled &&
      other.permission == permission &&
      other.serviceRunning == serviceRunning &&
      other.apiVersion == apiVersion;

  @override
  int get hashCode =>
      Object.hash(enabled, permission, serviceRunning, apiVersion);
}

/// Nezavisle stavy povoleni pre O6 (docs/02 D14).
@immutable
class BlockerPermissions {
  const BlockerPermissions({
    required this.usageAccess,
    required this.overlay,
    required this.notifications,
    required this.exactAlarm,
    required this.batteryOptimized,
  });

  static const allGranted = BlockerPermissions(
    usageAccess: true,
    overlay: true,
    notifications: true,
    exactAlarm: true,
    batteryOptimized: false,
  );

  final bool usageAccess;
  final bool overlay;
  final bool notifications;
  final bool exactAlarm;

  /// true = appka podlieha optimalizacii baterie (Doze moze zabit sluzbu).
  final bool batteryOptimized;

  /// Minimum na zapnutie brany (`setEnabled(true)`).
  bool get readyForGate => usageAccess && overlay;

  @override
  bool operator ==(Object other) =>
      other is BlockerPermissions &&
      other.usageAccess == usageAccess &&
      other.overlay == overlay &&
      other.notifications == notifications &&
      other.exactAlarm == exactAlarm &&
      other.batteryOptimized == batteryOptimized;

  @override
  int get hashCode => Object.hash(
    usageAccess,
    overlay,
    notifications,
    exactAlarm,
    batteryOptimized,
  );
}

/// Spustitelna appka (zoznam pre vyber blokovanych appiek).
@immutable
class LaunchableApp {
  const LaunchableApp({required this.ref, required this.label});

  /// Android package name. Nikdy nelogovat.
  final String ref;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is LaunchableApp && other.ref == ref && other.label == label;

  @override
  int get hashCode => Object.hash(ref, label);
}

/// Blokovana appka, zrkadlo riadku `blocked_app` pre nativnu sluzbu.
@immutable
class BlockTarget {
  const BlockTarget({
    required this.ref,
    required this.cardsRequired,
    required this.unlockMinutes,
    this.label,
  });

  final String ref;
  final String? label;
  final int cardsRequired;
  final int unlockMinutes;

  @override
  bool operator ==(Object other) =>
      other is BlockTarget &&
      other.ref == ref &&
      other.label == label &&
      other.cardsRequired == cardsRequired &&
      other.unlockMinutes == unlockMinutes;

  @override
  int get hashCode => Object.hash(ref, label, cardsRequired, unlockMinutes);
}

/// Rozhranie nativneho blockeru (TECHNICKY_PLAN 11). Ocakavane chyby su
/// [Err] s [AppFailure] (docs/06 C.5): chybajuce povolenie
/// [PermissionDenied], lite/iOS [UnsupportedOnPlatform], ostatne
/// [NativeFailure].
///
/// Brana nikdy neuvazni: ked volanie zlyha, UI ponukne "Continue to {app}"
/// (`source=error`) a zavola `closeGate(openTarget: true)`.
abstract interface class BlockerGateway {
  Future<Result<BlockerState>> status();

  Future<Result<BlockerPermissions>> permissions();

  /// Android: otvori nastavenia usage access, ak chyba.
  Future<Result<BlockerPermissionState>> requestPermission();

  Future<Result<void>> openSystemSettings(BlockerSettings target);

  /// Spustitelne appky okrem Mursy, zoradene podla nazvu.
  Future<Result<List<LaunchableApp>>> installedApps();

  /// PNG ikona appky alebo null.
  Future<Result<Uint8List?>> appIcon(String ref);

  Future<Result<void>> setTargets(List<BlockTarget> targets);

  /// Volat len z popredia. Vyzaduje usage access a overlay.
  Future<Result<void>> setEnabled({required bool enabled});

  /// [minutes] 1-1440, meria sa monotonnym casom zariadenia.
  Future<Result<void>> unlockFor(String ref, {required int minutes});

  /// true: cielova appka (s kratkym prechodom, ak nebolo [unlockFor]),
  /// false: home screen.
  Future<Result<void>> closeGate({required bool openTarget});

  /// Zmaze vsetky odomknutia (po "Delete all my data", A10.9).
  Future<Result<void>> clearUnlocks();

  /// Vyrobca zariadenia malymi pismenami (`samsung`, `xiaomi`, ...), pre
  /// navod k baterii v O6.
  Future<Result<String>> deviceManufacturer();

  /// Zatial len ulozi okna (prayer lock je pripomienka, nie zamknutie).
  Future<Result<void>> schedulePrayerLocks(
    List<DateTime> starts, {
    required int durationMinutes,
  });

  /// Poziadavky nativu na branu v uz beziacom engine (package name).
  Stream<String> get gateRequests;
}
