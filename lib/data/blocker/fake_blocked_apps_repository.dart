import 'dart:async';

import 'package:prosoche/data/blocker/blocked_apps_repository.dart';
import 'package:prosoche/data/blocker/blocker_gateway.dart';

/// Pamatovy [BlockedAppsRepository] pre widget testy a galeriu. Zmeny
/// zrkadli do [gateway] ako drift verzia.
class FakeBlockedAppsRepository implements BlockedAppsRepository {
  FakeBlockedAppsRepository({
    this.gateway,
    List<BlockedApp> apps = const [],
    this.statsValue = const GateStats(),
  }) : _apps = List.of(apps),
       _nextId = apps.fold(0, (m, a) => a.id > m ? a.id : m) + 1;

  final BlockerGateway? gateway;
  GateStats statsValue;
  final List<BlockedApp> _apps;
  int _nextId;
  final _changes = StreamController<List<BlockedApp>>.broadcast();

  List<BlockedApp> get current => List.unmodifiable(_apps);

  void _emit() => _changes.add(current);

  @override
  Stream<List<BlockedApp>> watchApps() async* {
    yield current;
    yield* _changes.stream;
  }

  @override
  Future<List<BlockedApp>> apps() async => current;

  BlockedApp _new(LaunchableApp a, int cards, int minutes) => BlockedApp(
    id: _nextId++,
    ref: a.ref,
    label: a.label,
    cardsRequired: cards,
    unlockMinutes: minutes,
  );

  @override
  Future<void> replaceSelection(
    List<LaunchableApp> selected, {
    required int cardsRequired,
    required int unlockMinutes,
  }) async {
    final old = {for (final a in _apps) a.ref: a};
    _apps
      ..clear()
      ..addAll([
        for (final a in selected)
          if (old[a.ref] case final o?)
            BlockedApp(
              id: o.id,
              ref: o.ref,
              label: a.label,
              cardsRequired: cardsRequired,
              unlockMinutes: unlockMinutes,
              prayerLock: o.prayerLock,
              enabled: o.enabled,
            )
          else
            _new(a, cardsRequired, unlockMinutes),
      ]);
    await sync();
  }

  @override
  Future<void> add(List<LaunchableApp> apps) async {
    for (final a in apps) {
      if (_apps.any((x) => x.ref == a.ref)) continue;
      _apps.add(
        _new(a, BlockedAppLimits.defaultCards, BlockedAppLimits.defaultMinutes),
      );
    }
    await sync();
  }

  @override
  Future<void> update(int id, BlockedAppPatch patch) async {
    final i = _apps.indexWhere((a) => a.id == id);
    if (i < 0) return;
    final o = _apps[i];
    _apps[i] = BlockedApp(
      id: o.id,
      ref: o.ref,
      label: o.label,
      cardsRequired: patch.cardsRequired ?? o.cardsRequired,
      unlockMinutes: patch.unlockMinutes ?? o.unlockMinutes,
      prayerLock: patch.prayerLock ?? o.prayerLock,
      enabled: o.enabled,
    );
    await sync();
  }

  @override
  Future<void> remove(int id) async {
    _apps.removeWhere((a) => a.id == id);
    await sync();
  }

  @override
  Future<void> sync() async {
    _emit();
    await gateway?.setTargets([
      for (final a in _apps)
        if (a.enabled)
          BlockTarget(
            ref: a.ref,
            label: a.label,
            cardsRequired: a.cardsRequired,
            unlockMinutes: a.unlockMinutes,
          ),
    ]);
  }

  @override
  Future<GateStats> stats(DateTime since) async => statsValue;

  Future<void> dispose() => _changes.close();
}
