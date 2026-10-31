import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:meta/meta.dart';
import 'package:sakina/core/clock/clock_provider.dart';
import 'package:sakina/core/flags/feature_flags.dart';
import 'package:sakina/core/result.dart';
import 'package:sakina/data/blocker/blocked_apps_repository.dart';
import 'package:sakina/data/blocker/blocker_gateway.dart';
import 'package:sakina/data/blocker/blocker_gateway_provider.dart';
import 'package:sakina/data/repositories/settings/settings_providers.dart';
import 'package:sakina/domain/settings/settings_repository.dart';

/// Caste socialne siete, ktore O5 ukaze navrchu a predvyberie, ak su
/// nainstalovane (docs/02 O5 `kSuggestedPackages`).
const kSuggestedPackages = <String>[
  'com.instagram.android',
  'com.zhiliaoapp.musically', // TikTok
  'com.ss.android.ugc.trill', // TikTok (Azia)
  'com.google.android.youtube',
  'com.twitter.android', // X
  'com.facebook.katana',
  'com.snapchat.android',
  'com.reddit.frontpage',
  'com.pinterest',
  'com.facebook.lite',
];

/// [AppFailure] ako chyba providera (stav error v UI).
T _unwrap<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw BlockerUnavailable(failure),
};

/// Chyba nativu v providere (lite, iOS, chyba kanala).
final class BlockerUnavailable implements Exception {
  const BlockerUnavailable(this.failure);

  final AppFailure failure;

  @override
  String toString() => 'BlockerUnavailable(${failure.code})';
}

/// Stav brany pre A10.1 a O6: nativny stav a povolenia.
@immutable
final class BlockerOverview {
  const BlockerOverview({required this.state, required this.permissions});

  final BlockerState state;
  final BlockerPermissions permissions;

  GateHealth get health {
    if (!state.enabled) return GateHealth.off;
    if (!permissions.usageAccess) return GateHealth.noUsageAccess;
    if (!permissions.overlay) return GateHealth.noOverlay;
    if (!state.serviceRunning) return GateHealth.stopped;
    return GateHealth.running;
  }

  @override
  bool operator ==(Object other) =>
      other is BlockerOverview &&
      other.state == state &&
      other.permissions == permissions;

  @override
  int get hashCode => Object.hash(state, permissions);
}

/// Stav brany (docs/02 A10.1, "detekcia sluzba nebezi").
enum GateHealth { off, running, noUsageAccess, noOverlay, stopped }

/// Stav nativu. Po navrate zo systemovych nastaveni sa invaliduje.
final FutureProvider<BlockerOverview> blockerOverviewProvider =
    FutureProvider<BlockerOverview>((ref) async {
      final gateway = ref.watch(blockerGatewayProvider);
      final state = _unwrap(await gateway.status());
      final permissions = _unwrap(await gateway.permissions());
      return BlockerOverview(state: state, permissions: permissions);
    }, name: 'blockerOverviewProvider');

/// Brana je zapnuta (`blocker.enabled` alebo nativ), ale chyba jej
/// povolenie (usage access, overlay): banner "The gate is paused" na Dnes
/// a varovna ikona v Nastaveniach (I-03). Bez `FEATURE_GATE` alebo pri
/// chybe nativu false.
final FutureProvider<bool> gateNeedsAttentionProvider = FutureProvider<bool>((
  ref,
) async {
  if (!ref.watch(featureFlagsProvider).gate) return false;
  try {
    // Zmena nastavenia provider prepocita; hodnota sa cita priamo, aby
    // necakal na (pozastaveny) stream bez posluchaca.
    final setting = ref.watch(settingProvider(SettingsKeys.blockerEnabled));
    final wanted = setting.hasValue
        ? setting.value == true
        : await ref
              .watch(settingsRepositoryProvider)
              .get(SettingsKeys.blockerEnabled);
    final overview = await ref.watch(blockerOverviewProvider.future);
    final on = wanted || overview.state.enabled;
    return on && !overview.permissions.readyForGate;
  } on Object {
    return false;
  }
}, name: 'gateNeedsAttentionProvider');

/// Start a navrat appky (I-03): `blocker.enabled`, sluzba nebezi
/// a povolenia su OK -> brana sa znova zapne
/// ([BlockingActions.enable]). Ked povolenia chybaju, nic (banner cez
/// [gateNeedsAttentionProvider]). Vrati vysledok zapnutia alebo null,
/// ked netreba nic robit.
Future<GateEnableResult?> ensureGateRunning(ProviderContainer c) async {
  if (!c.read(featureFlagsProvider).gate) return null;
  final wanted = await c
      .read(settingsRepositoryProvider)
      .get(SettingsKeys.blockerEnabled);
  c.invalidate(blockerOverviewProvider);
  if (!wanted) return null;
  final BlockerOverview overview;
  try {
    overview = await c.read(blockerOverviewProvider.future);
  } on Object {
    return null;
  }
  if (overview.state.serviceRunning) return null;
  if (!overview.permissions.readyForGate) return null;
  return await c.read(blockingActionsProvider).enable();
}

/// Spustitelne appky (O5, "Add apps").
final FutureProvider<List<LaunchableApp>> installedAppsProvider =
    FutureProvider<List<LaunchableApp>>((ref) async {
      final apps = await ref.watch(blockerGatewayProvider).installedApps();
      return _unwrap<List<LaunchableApp>>(apps);
    }, name: 'installedAppsProvider');

/// PNG ikona appky; chyba = bez ikony.
final FutureProviderFamily<Uint8List?, String> appIconProvider =
    FutureProvider.family<Uint8List?, String>(
      (ref, app) async =>
          switch (await ref.watch(blockerGatewayProvider).appIcon(app)) {
            Ok(:final value) => value,
            Err() => null,
          },
      name: 'appIconProvider',
    );

/// Vyrobca zariadenia (navod k baterii); chyba = neznamy.
final FutureProvider<String> deviceManufacturerProvider =
    FutureProvider<String>(
      (ref) async => switch (await ref
          .watch(blockerGatewayProvider)
          .deviceManufacturer()) {
        Ok(:final value) => value,
        Err() => '',
      },
      name: 'deviceManufacturerProvider',
    );

/// Lokalna statistika za poslednych 7 dni (A10.1).
final FutureProvider<GateStats> gateStatsProvider = FutureProvider<GateStats>((
  ref,
) {
  ref.watch(blockedAppsProvider);
  final since = ref
      .watch(appClockProvider)
      .now()
      .subtract(const Duration(days: 7));
  return ref.watch(blockedAppsRepositoryProvider).stats(since);
}, name: 'gateStatsProvider');

/// Vyrobca pre navod k baterii (docs/01 5.1). null = bez vlastneho navodu.
enum BatteryVendor { samsung, xiaomi, huawei, oppo }

BatteryVendor? batteryVendorOf(String manufacturer) =>
    switch (manufacturer.toLowerCase()) {
      'samsung' => BatteryVendor.samsung,
      'xiaomi' || 'redmi' || 'poco' => BatteryVendor.xiaomi,
      'huawei' || 'honor' => BatteryVendor.huawei,
      'oppo' || 'realme' || 'oneplus' => BatteryVendor.oppo,
      _ => null,
    };

/// Vysledok zapnutia brany.
enum GateEnableResult { enabled, needsPermissions, failed }

/// Zapnutie a vypnutie brany: nativ (`setEnabled`) a `blocker.enabled`.
class BlockingActions {
  BlockingActions(this._ref);

  final Ref _ref;

  BlockerGateway get _gateway => _ref.read(blockerGatewayProvider);

  Future<GateEnableResult> enable() async {
    final permissions = await _gateway.permissions();
    if (permissions case Ok(:final value) when !value.readyForGate) {
      return GateEnableResult.needsPermissions;
    }
    await _ref.read(blockedAppsRepositoryProvider).sync();
    final result = await _gateway.setEnabled(enabled: true);
    _ref.invalidate(blockerOverviewProvider);
    switch (result) {
      case Ok():
        await _setSetting(true);
        return GateEnableResult.enabled;
      case Err(failure: PermissionDenied()):
        return GateEnableResult.needsPermissions;
      case Err():
        return GateEnableResult.failed;
    }
  }

  Future<void> disable() async {
    await _gateway.setEnabled(enabled: false);
    await _setSetting(false);
    _ref.invalidate(blockerOverviewProvider);
  }

  Future<void> _setSetting(bool value) => _ref
      .read(settingsRepositoryProvider)
      .set(SettingsKeys.blockerEnabled, value);
}

final Provider<BlockingActions> blockingActionsProvider =
    Provider<BlockingActions>(
      BlockingActions.new,
      name: 'blockingActionsProvider',
    );
