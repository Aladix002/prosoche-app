import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/data/blocker/blocker_gateway.dart';
import 'package:prosoche/data/blocker/blocker_gateway_provider.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/data/repositories/infra/databases.dart';

export 'package:prosoche/data/db/user_enums.dart' show UnlockSource;

/// Rozsahy nastaveni appky (docs/02 O5, A10.2).
abstract final class BlockedAppLimits {
  static const minCards = 1;
  static const maxCards = 12;
  static const defaultCards = 3;
  static const minMinutes = 5;
  static const maxMinutes = 60;
  static const minutesStep = 5;
  static const defaultMinutes = 10;
}

/// Riadok `blocked_app` pre nastavenia brany (O5, A10.1, A10.2).
@immutable
final class BlockedApp {
  const BlockedApp({
    required this.id,
    required this.ref,
    required this.cardsRequired,
    required this.unlockMinutes,
    this.label,
    this.enabled = true,
  });

  final int id;

  /// Package name. Nikdy nelogovat ani neposielat do analytiky.
  final String ref;
  final String? label;
  final int cardsRequired;
  final int unlockMinutes;
  final bool enabled;

  String get displayName => label ?? ref;

  @override
  bool operator ==(Object other) =>
      other is BlockedApp &&
      other.id == id &&
      other.ref == ref &&
      other.label == label &&
      other.cardsRequired == cardsRequired &&
      other.unlockMinutes == unlockMinutes &&
      other.enabled == enabled;

  @override
  int get hashCode =>
      Object.hash(id, ref, label, cardsRequired, unlockMinutes, enabled);
}

/// Lokalna statistika brany (A10.1). Nikdy neodchadza z telefonu.
@immutable
final class GateStats {
  const GateStats({
    this.gates = 0,
    this.unlocks = const {},
    this.unlocksPerApp = const {},
  });

  /// Pocet otvoreni brany (`gate_session`).
  final int gates;

  /// Odomknutia podla zdroja (`unlock_event.source`).
  final Map<UnlockSource, int> unlocks;

  /// Odomknutia podla `blocked_app.id`.
  final Map<int, int> unlocksPerApp;

  int unlocksOf(UnlockSource source) => unlocks[source] ?? 0;

  bool get isEmpty => gates == 0 && unlocks.values.every((n) => n == 0);

  @override
  bool operator ==(Object other) =>
      other is GateStats &&
      other.gates == gates &&
      mapEquals(other.unlocks, unlocks) &&
      mapEquals(other.unlocksPerApp, unlocksPerApp);

  @override
  int get hashCode => Object.hash(
    gates,
    Object.hashAllUnordered(unlocks.entries.map((e) => (e.key, e.value))),
    Object.hashAllUnordered(unlocksPerApp.entries.map((e) => (e.key, e.value))),
  );
}

/// Zmena nastaveni appky (A10.2); null pole sa nemeni.
@immutable
final class BlockedAppPatch {
  const BlockedAppPatch({this.cardsRequired, this.unlockMinutes});

  final int? cardsRequired;
  final int? unlockMinutes;
}

/// Blokovane appky v user.db (zdroj pravdy) a ich zrkadlo v nativnej
/// sluzbe. Kazda zmena posle cely zoznam zapnutych appiek cez
/// [BlockerGateway.setTargets] (docs/02 A10.2).
abstract interface class BlockedAppsRepository {
  Stream<List<BlockedApp>> watchApps();

  Future<List<BlockedApp>> apps();

  /// O5: vysledny vyber. Nove appky sa pridaju s [cardsRequired] a
  /// [unlockMinutes], existujuce dostanu tieto hodnoty, nevybrane sa
  /// odstrania.
  Future<void> replaceSelection(
    List<LaunchableApp> selected, {
    required int cardsRequired,
    required int unlockMinutes,
  });

  /// A10.1 "Add apps": prida appky s predvolenymi hodnotami, existujuce
  /// necha tak.
  Future<void> add(List<LaunchableApp> apps);

  Future<void> update(int id, BlockedAppPatch patch);

  Future<void> remove(int id);

  /// Posle aktualny zoznam do nativu (napr. po starte appky).
  Future<void> sync();

  /// Statistika od [since] (A10.1 "this week").
  Future<GateStats> stats(DateTime since);
}

class DriftBlockedAppsRepository implements BlockedAppsRepository {
  DriftBlockedAppsRepository({
    required UserDb userDb,
    required this._gateway,
    required this._clock,
  }) : _db = userDb;

  final UserDb _db;
  final BlockerGateway _gateway;
  final Clock _clock;

  static BlockedApp _map(BlockedAppRow r) => BlockedApp(
    id: r.id,
    ref: r.platformRef,
    label: r.label,
    cardsRequired: r.cardsRequired,
    unlockMinutes: r.unlockMinutes,
    enabled: r.enabled,
  );

  @override
  Stream<List<BlockedApp>> watchApps() =>
      _db.blockerDao.watchApps().map((rows) => rows.map(_map).toList());

  @override
  Future<List<BlockedApp>> apps() async =>
      (await _db.blockerDao.apps()).map(_map).toList();

  @override
  Future<void> replaceSelection(
    List<LaunchableApp> selected, {
    required int cardsRequired,
    required int unlockMinutes,
  }) async {
    final dao = _db.blockerDao;
    await _db.transaction(() async {
      final refs = {for (final a in selected) a.ref};
      for (final row in await dao.apps()) {
        if (!refs.contains(row.platformRef)) await dao.removeApp(row.id);
      }
      for (final app in selected) {
        final row = await dao.addApp(
          platformRef: app.ref,
          label: app.label,
          cardsRequired: cardsRequired,
          unlockMinutes: unlockMinutes,
          now: _clock.now().toUtc(),
        );
        await dao.updateApp(
          row.id,
          cardsRequired: cardsRequired,
          unlockMinutes: unlockMinutes,
          label: app.label,
        );
      }
    });
    await sync();
  }

  @override
  Future<void> add(List<LaunchableApp> apps) async {
    await _db.transaction(() async {
      for (final app in apps) {
        await _db.blockerDao.addApp(
          platformRef: app.ref,
          label: app.label,
          now: _clock.now().toUtc(),
        );
      }
    });
    await sync();
  }

  @override
  Future<void> update(int id, BlockedAppPatch patch) async {
    await _db.blockerDao.updateApp(
      id,
      cardsRequired: patch.cardsRequired?.clamp(
        BlockedAppLimits.minCards,
        BlockedAppLimits.maxCards,
      ),
      unlockMinutes: patch.unlockMinutes?.clamp(
        BlockedAppLimits.minMinutes,
        BlockedAppLimits.maxMinutes,
      ),
    );
    await sync();
  }

  @override
  Future<void> remove(int id) async {
    await _db.blockerDao.removeApp(id);
    await sync();
  }

  @override
  Future<void> sync() async {
    final targets = [
      for (final a in await apps())
        if (a.enabled)
          BlockTarget(
            ref: a.ref,
            label: a.label,
            cardsRequired: a.cardsRequired,
            unlockMinutes: a.unlockMinutes,
          ),
    ];
    // Chybu (lite, iOS, nativ) loguje gateway; DB je zdroj pravdy a dalsia
    // zmena alebo start appky zoznam posle znova.
    await _gateway.setTargets(targets);
  }

  @override
  Future<GateStats> stats(DateTime since) async {
    final sinceUtc = since.toUtc();
    final sessions = _db.gateSessions;
    final count = sessions.id.count();
    final gatesQuery = _db.selectOnly(sessions)
      ..addColumns([count])
      ..where(
        sessions.openedAt.isBiggerOrEqualValue(sinceUtc.millisecondsSinceEpoch),
      );
    final gates = (await gatesQuery.getSingle()).read(count) ?? 0;

    final events = _db.unlockEvents;
    final perAppCount = events.id.count();
    final perAppQuery = _db.selectOnly(events)
      ..addColumns([events.blockedAppId, perAppCount])
      ..where(
        events.ts.isBiggerOrEqualValue(sinceUtc.millisecondsSinceEpoch) &
            events.blockedAppId.isNotNull(),
      )
      ..groupBy([events.blockedAppId]);
    final perApp = {
      for (final r in await perAppQuery.get())
        r.read(events.blockedAppId)!: r.read(perAppCount)!,
    };
    return GateStats(
      gates: gates,
      unlocks: await _db.blockerDao.unlockCounts(sinceUtc),
      unlocksPerApp: perApp,
    );
  }
}

/// V testoch `blockedAppsRepositoryProvider.overrideWithValue(...)`.
final Provider<BlockedAppsRepository> blockedAppsRepositoryProvider =
    Provider<BlockedAppsRepository>(
      (ref) => DriftBlockedAppsRepository(
        userDb: ref.watch(userDbProvider),
        gateway: ref.watch(blockerGatewayProvider),
        clock: ref.watch(appClockProvider),
      ),
      name: 'blockedAppsRepositoryProvider',
    );

/// Zoznam blokovanych appiek (docs/02 0.9 `blockedAppsProvider`).
final StreamProvider<List<BlockedApp>> blockedAppsProvider =
    StreamProvider<List<BlockedApp>>(
      (ref) => ref.watch(blockedAppsRepositoryProvider).watchApps(),
      name: 'blockedAppsProvider',
    );
