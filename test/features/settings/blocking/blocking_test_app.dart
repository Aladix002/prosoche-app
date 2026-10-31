import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:sakina/core/flags/feature_flags.dart';
import 'package:sakina/data/blocker/blocked_apps_repository.dart';
import 'package:sakina/data/blocker/blocker_gateway.dart';
import 'package:sakina/data/blocker/blocker_gateway_provider.dart';
import 'package:sakina/data/blocker/fake_blocked_apps_repository.dart';
import 'package:sakina/data/blocker/fake_blocker_gateway.dart';

import '../../../fakes/fake_repositories.dart';
import '../settings_test_app.dart';

const instagram = LaunchableApp(
  ref: 'com.instagram.android',
  label: 'Instagram',
);
const tiktok = LaunchableApp(ref: 'com.zhiliaoapp.musically', label: 'TikTok');
const notes = LaunchableApp(ref: 'com.example.notes', label: 'Notes');

const noPermissions = BlockerPermissions(
  usageAccess: false,
  overlay: false,
  notifications: false,
  exactAlarm: true,
  batteryOptimized: true,
);

/// Prostredie obrazoviek brany: fakes nativu a `blocked_app`.
class BlockingHarness {
  BlockingHarness({
    FakeBlockerGateway? blocker,
    List<BlockedApp> apps = const [],
    GateStats stats = const GateStats(),
    FakeRepositories? fakes,
  }) : blocker =
           blocker ??
           FakeBlockerGateway(apps: const [instagram, tiktok, notes]),
       fakes = fakes ?? FakeRepositories() {
    repo = FakeBlockedAppsRepository(
      gateway: this.blocker,
      apps: apps,
      statsValue: stats,
    );
  }

  final FakeBlockerGateway blocker;
  final FakeRepositories fakes;
  late final FakeBlockedAppsRepository repo;

  List<Override> get overrides => [
    ...settingsOverrides(fakes: fakes, flags: const FeatureFlags(gate: true)),
    blockerGatewayProvider.overrideWithValue(blocker),
    blockedAppsRepositoryProvider.overrideWithValue(repo),
  ];
}

const igApp = BlockedApp(
  id: 1,
  ref: 'com.instagram.android',
  label: 'Instagram',
  cardsRequired: 3,
  unlockMinutes: 10,
  prayerLock: true,
);
