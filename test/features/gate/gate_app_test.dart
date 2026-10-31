import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/data/blocker/gate_repository.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/gate/gate_app.dart';
import 'package:sakina/features/gate/gate_screen.dart';

import 'gate_harness.dart';

void main() {
  testWidgets('idle until native asks, back to idle after close', (
    tester,
  ) async {
    final t = GateTest();
    await t.pump(tester, child: const GateApp());
    expect(find.byType(GateScreen), findsNothing);

    t.blocker.requestGate(igRef);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.byType(GateScreen), findsOneWidget);
    expect(find.text('A pause before Instagram'), findsOneWidget);

    await tester.tap(find.text('Go back'));
    await tester.pump();
    await tester.pump();
    expect(t.blocker.lastCloseOpenTarget, isFalse);
    expect(find.byType(GateScreen), findsNothing);
  });

  testWidgets('a new request restarts the gate', (tester) async {
    final t = GateTest();
    await t.pump(tester, child: const GateApp(initialApp: igRef));
    await tester.pump();
    expect(find.text('4 s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('2 s'), findsOneWidget);

    t.blocker.requestGate(igRef);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('4 s'), findsOneWidget);
    expect(t.gates.sessions, hasLength(2));
    expect(t.gates.sessions[1]!.result, GateResult.dismissed);
  });

  test('status bar icons contrast with the theme', () {
    expect(
      gateSystemUiStyle(Brightness.light).statusBarIconBrightness,
      Brightness.dark,
    );
    expect(
      gateSystemUiStyle(Brightness.dark).statusBarIconBrightness,
      Brightness.light,
    );
  });

  testWidgets('follows display.theme from settings', (tester) async {
    final t = GateTest();
    await t.repos.settings.set(SettingsKeys.displayTheme, 'dark');
    await t.pump(tester, child: const GateApp());
    await tester.pump();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp).last);
    expect(app.themeMode, ThemeMode.dark);
    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>).last,
    );
    expect(region.value.statusBarIconBrightness, Brightness.light);
  });
}
