import 'dart:async';

import 'package:flutter/services.dart';
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/blocker/blocker_api.pigeon.dart' as api;
import 'package:prosoche/data/blocker/blocker_gateway.dart';

/// [BlockerGateway] nad Pigeon API (docs/06 C.5). V `lite` a na iOS
/// nativna strana neexistuje, volania vratia [UnsupportedOnPlatform].
class PigeonBlockerGateway implements BlockerGateway {
  PigeonBlockerGateway(this._api, this._log, {this.binaryMessenger});

  static const _channel = 'blocker';

  final api.BlockerHostApi _api;
  final AppLogger _log;

  /// Messenger pre [api.BlockerFlutterApi] (null = predvoleny).
  final BinaryMessenger? binaryMessenger;

  late final StreamController<String> _gateRequests =
      StreamController<String>.broadcast(
        onListen: () => api.BlockerFlutterApi.setUp(
          _FlutterApiHandler(_gateRequests),
          binaryMessenger: binaryMessenger,
        ),
        onCancel: () =>
            api.BlockerFlutterApi.setUp(null, binaryMessenger: binaryMessenger),
      );

  @override
  Stream<String> get gateRequests => _gateRequests.stream;

  @override
  Future<Result<BlockerState>> status() => _guard('status', () async {
    final s = await _api.status();
    return BlockerState(
      enabled: s.enabled,
      permission: _permission(s.permission),
      serviceRunning: s.serviceRunning,
      apiVersion: s.apiVersion,
    );
  });

  @override
  Future<Result<BlockerPermissions>> permissions() =>
      _guard('permissionsDetail', () async {
        final p = await _api.permissionsDetail();
        return BlockerPermissions(
          usageAccess: p.usageAccess,
          overlay: p.overlay,
          notifications: p.notifications,
          exactAlarm: p.exactAlarm,
          batteryOptimized: p.batteryOptimized,
        );
      });

  @override
  Future<Result<BlockerPermissionState>> requestPermission() => _guard(
    'requestPermission',
    () async => _permission(await _api.requestPermission()),
  );

  @override
  Future<Result<void>> openSystemSettings(BlockerSettings target) => _guard(
    'openSystemSettings',
    () => _api.openSystemSettings(api.SystemSettingsKind.values[target.index]),
  );

  @override
  Future<Result<List<LaunchableApp>>> installedApps() => _guard(
    'installedApps',
    () async {
      final apps = await _api.installedApps();
      return [for (final a in apps) LaunchableApp(ref: a.ref, label: a.label)];
    },
  );

  @override
  Future<Result<Uint8List?>> appIcon(String ref) =>
      _guard('appIcon', () => _api.appIcon(ref));

  @override
  Future<Result<void>> setTargets(List<BlockTarget> targets) => _guard(
    'setTargets',
    () => _api.setTargets([
      for (final t in targets)
        api.BlockedTarget(
          ref: t.ref,
          label: t.label,
          cardsRequired: t.cardsRequired,
          unlockMinutes: t.unlockMinutes,
        ),
    ]),
  );

  @override
  Future<Result<void>> setEnabled({required bool enabled}) =>
      _guard('setEnabled', () => _api.setEnabled(enabled));

  @override
  Future<Result<void>> unlockFor(String ref, {required int minutes}) =>
      _guard('unlockFor', () => _api.unlockFor(ref, minutes));

  @override
  Future<Result<void>> closeGate({required bool openTarget}) =>
      _guard('closeGate', () => _api.closeGate(openTarget));

  @override
  Future<Result<void>> openPractice() =>
      _guard('openPractice', _api.openPractice);

  @override
  Future<Result<void>> clearUnlocks() =>
      _guard('clearUnlocks', _api.clearUnlocks);

  @override
  Future<Result<String>> deviceManufacturer() =>
      _guard('deviceManufacturer', _api.deviceManufacturer);

  static BlockerPermissionState _permission(api.BlockerPermission p) =>
      BlockerPermissionState.values[p.index];

  Future<Result<T>> _guard<T>(String op, Future<T> Function() call) async {
    try {
      return Ok(await call());
    } on PlatformException catch (e) {
      final failure = _failure(e.code);
      // Len op a kod, nikdy message/details (docs/06 C.5, C.7).
      _log.warn(_channel, 'native call failed', {'op': op, 'code': e.code});
      return Err(failure);
    } on MissingPluginException {
      return const Err(UnsupportedOnPlatform(_channel));
    }
  }

  static AppFailure _failure(String code) => switch (code) {
    'permission_missing' => const PermissionDenied('usage_stats'),
    'overlay_denied' => const PermissionDenied('overlay'),
    // os_unsupported z nativu, channel-error: nativna strana chyba (lite, iOS).
    'os_unsupported' ||
    'channel-error' => const UnsupportedOnPlatform(_channel),
    _ => NativeFailure(code, _channel),
  };
}

class _FlutterApiHandler implements api.BlockerFlutterApi {
  _FlutterApiHandler(this._sink);

  final StreamController<String> _sink;

  @override
  void onGateRequested(String ref) => _sink.add(ref);
}
