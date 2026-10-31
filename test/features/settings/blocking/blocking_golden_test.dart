@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/blocker/blocked_apps_repository.dart';
import 'package:prosoche/data/blocker/fake_blocker_gateway.dart';
import 'package:prosoche/features/settings/blocking/blocking_screen.dart';
import 'package:prosoche/features/settings/blocking/blocking_subscreens.dart';
import 'package:prosoche/ui/theme/prosoche_theme.dart';

import '../../../helpers/golden/golden.dart';
import 'blocking_test_app.dart';

/// Goldeny brany A10.1 a A10.2 (EN, AR, UR, BN, smoke ID a TR).
///
///   flutter test --update-goldens test/features/settings/blocking/blocking_golden_test.dart
void main() {
  ThemeData theme(Brightness b) =>
      b == Brightness.dark ? ProsocheTheme.dark() : ProsocheTheme.light();
  const screen = BoxConstraints.tightFor(width: 360, height: 760);

  Widget scoped(BlockingHarness h, Widget child) => ProviderScope(
    overrides: h.overrides,
    retry: (_, _) => null,
    child: Overlay(initialEntries: [OverlayEntry(builder: (_) => child)]),
  );

  goldenAllLocales(
    'BlockingScreen',
    fileName: 'b03_blocking',
    theme: theme,
    constraints: screen,
    builder: (_) => scoped(
      BlockingHarness(
        blocker: FakeBlockerGateway()
          ..enabled = true
          ..serviceRunning = false,
        apps: const [igApp],
        stats: const GateStats(
          gates: 4,
          unlocks: {UnlockSource.cards: 3, UnlockSource.emergency: 1},
          unlocksPerApp: {1: 4},
        ),
      ),
      const BlockingScreen(),
    ),
  );

  goldenAllLocales(
    'BlockingAppScreen',
    fileName: 'b03_blocking_app',
    theme: theme,
    constraints: screen,
    builder: (_) => scoped(
      BlockingHarness(apps: const [igApp]),
      BlockingAppScreen(appRef: igApp.ref),
    ),
  );
}
