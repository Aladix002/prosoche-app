import 'dart:async';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/blocker/blocker_gateway.dart';

/// Pamatovy [BlockerGateway] pre testy, galeriu a widget testy brany.
///
/// Spravanie zodpoveda nativu: `setEnabled(true)` bez povoleni vrati
/// [PermissionDenied], odomknutia sa meraju cez [clock]. [failNext] simuluje
/// chybu nasledujuceho volania (brana musi ponuknut "Continue").
class FakeBlockerGateway implements BlockerGateway {
  FakeBlockerGateway({
    this._clock = const Clock(),
    this.permissionsState = BlockerPermissions.allGranted,
    List<LaunchableApp> apps = const [],
    this.apiVersion = blockerApiVersion,
    this.manufacturer = 'google',
    Map<String, Uint8List>? icons,
  }) : apps = List.of(apps),
       icons = icons ?? {};

  final Clock _clock;
  final _gateRequests = StreamController<String>.broadcast();
  final _unlockedUntil = <String, DateTime>{};

  BlockerPermissions permissionsState;
  final List<LaunchableApp> apps;
  int apiVersion;
  String manufacturer;

  /// Ikony appiek podla ref (inak null).
  final Map<String, Uint8List> icons;

  /// Nativna sluzba bezi (default = [enabled]); false simuluje, ze ju
  /// Android zastavil.
  bool? serviceRunning;
  bool enabled = false;
  List<BlockTarget> targets = const [];

  /// Posledne `closeGate(openTarget)`, null ak este nebolo.
  bool? lastCloseOpenTarget;

  /// Nazvy volanych metod v poradi.
  final calls = <String>[];

  /// Ak nie je null, dalsie volanie vrati tuto chybu (a vynuluje sa).
  AppFailure? failNext;

  /// Ak nie je null, kazde `setEnabled(true)` vrati tuto chybu (sluzba
  /// sa nespustila).
  AppFailure? enableFailure;

  /// Nativ poziadal o branu (BlockerFlutterApi.onGateRequested).
  void requestGate(String ref) => _gateRequests.add(ref);

  bool isUnlocked(String ref) {
    final until = _unlockedUntil[ref];
    return until != null && _clock.now().isBefore(until);
  }

  @override
  Stream<String> get gateRequests => _gateRequests.stream;

  @override
  Future<Result<BlockerState>> status() async => _run(
    'status',
    () => BlockerState(
      enabled: enabled,
      permission: permissionsState.usageAccess
          ? BlockerPermissionState.granted
          : BlockerPermissionState.denied,
      serviceRunning: serviceRunning ?? enabled,
      apiVersion: apiVersion,
    ),
  );

  @override
  Future<Result<BlockerPermissions>> permissions() async =>
      _run('permissions', () => permissionsState);

  @override
  Future<Result<BlockerPermissionState>> requestPermission() async => _run(
    'requestPermission',
    () => permissionsState.usageAccess
        ? BlockerPermissionState.granted
        : BlockerPermissionState.denied,
  );

  @override
  Future<Result<void>> openSystemSettings(BlockerSettings target) async =>
      _run('openSystemSettings', () {});

  @override
  Future<Result<List<LaunchableApp>>> installedApps() async =>
      _run('installedApps', () => List.unmodifiable(apps));

  @override
  Future<Result<Uint8List?>> appIcon(String ref) async =>
      _run('appIcon', () => icons[ref]);

  @override
  Future<Result<void>> setTargets(List<BlockTarget> targets) async =>
      _run('setTargets', () => this.targets = List.unmodifiable(targets));

  @override
  Future<Result<void>> setEnabled({required bool enabled}) async {
    if (enabled && !permissionsState.usageAccess) {
      calls.add('setEnabled');
      return const Err(PermissionDenied('usage_stats'));
    }
    if (enabled && !permissionsState.overlay) {
      calls.add('setEnabled');
      return const Err(PermissionDenied('overlay'));
    }
    if (enabled && enableFailure != null) {
      calls.add('setEnabled');
      return Err(enableFailure!);
    }
    return _run('setEnabled', () => this.enabled = enabled);
  }

  @override
  Future<Result<void>> unlockFor(String ref, {required int minutes}) async {
    if (minutes < 1 || minutes > 24 * 60) {
      calls.add('unlockFor');
      return const Err(NativeFailure('invalid_target', 'blocker'));
    }
    return _run(
      'unlockFor',
      () => _unlockedUntil[ref] = _clock.now().add(Duration(minutes: minutes)),
    );
  }

  @override
  Future<Result<void>> closeGate({required bool openTarget}) async =>
      _run('closeGate', () => lastCloseOpenTarget = openTarget);

  @override
  Future<Result<void>> clearUnlocks() async =>
      _run('clearUnlocks', _unlockedUntil.clear);

  @override
  Future<Result<String>> deviceManufacturer() async =>
      _run('deviceManufacturer', () => manufacturer);

  Result<T> _run<T>(String op, T Function() body) {
    calls.add(op);
    final failure = failNext;
    if (failure != null) {
      failNext = null;
      return Err(failure);
    }
    return Ok(body());
  }

  Future<void> dispose() => _gateRequests.close();
}
