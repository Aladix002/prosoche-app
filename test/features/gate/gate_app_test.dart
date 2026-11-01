import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/blocker/gate_repository.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/gate/gate_app.dart';
import 'package:prosoche/features/gate/gate_screen.dart';

import '../../fakes/fake_repositories.dart';
import '../../fakes/in_memory_settings_repository.dart';
import 'gate_harness.dart';

/// Nastavenia ako ich vidi predhriaty engine brany (drift v inom izolate):
/// `watch` vracia hodnotu z cache (aj novym odberom) a zapisy hlavnej appky
/// nevidi, kym drift nedostane signal o zmene tabulky ([refresh], v appke
/// `markTablesUpdated`). Jednorazove `get` cita aktualny stav.
class OtherIsolateSettings extends InMemorySettingsRepository {
  final _cache = <String, Object?>{};
  final _refresh = StreamController<void>.broadcast(sync: true);

  void refresh() {
    _cache.clear();
    _refresh.add(null);
  }

  @override
  Stream<T> watch<T>(SettingKey<T> key) async* {
    Future<T> cached() async => (_cache[key.name] ??= await get(key)) as T;
    yield await cached();
    await for (final _ in _refresh.stream) {
      yield await cached();
    }
  }
}

/// Poziadavka z nativu: nacitanie nastaveni (P-03) a prva snimka brany.
Future<void> pumpRequest(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump();
  }
}

ThemeMode gateThemeMode(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp).last).themeMode!;

void main() {
  testWidgets('idle until native asks, back to idle after close', (
    tester,
  ) async {
    final t = GateTest();
    await t.pump(tester, child: const GateApp());
    expect(find.byType(GateScreen), findsNothing);

    t.blocker.requestGate(igRef);
    await pumpRequest(tester);
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
    await pumpRequest(tester);
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

  testWidgets('each request reloads the theme set by the app in another '
      'isolate, also back to light', (tester) async {
    final settings = OtherIsolateSettings();
    await settings.set(SettingsKeys.displayTheme, 'light');
    final t = GateTest(
      repos: FakeRepositories(settings: settings),
      externalChanges: settings.refresh,
    );
    await t.pump(tester, child: const GateApp());
    expect(gateThemeMode(tester), ThemeMode.light);

    // Uzivatel v appke prepne na tmavu; engine brany uz bezi.
    await settings.set(SettingsKeys.displayTheme, 'dark');
    await tester.pump();
    expect(
      gateThemeMode(tester),
      ThemeMode.light,
      reason: 'stream predhriateho enginu zmenu nevidi',
    );

    t.blocker.requestGate(igRef);
    await pumpRequest(tester);
    expect(gateThemeMode(tester), ThemeMode.dark);
    var screen = tester.element(find.byType(GateScreen));
    expect(Theme.of(screen).brightness, Brightness.dark);
    expect(Localizations.localeOf(screen).languageCode, 'en');
    var region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>).last,
    );
    expect(region.value.statusBarIconBrightness, Brightness.light);

    // Zavriet, v appke spat na svetlu, dalsia brana je svetla.
    await tester.tap(find.text('Go back'));
    await tester.pump();
    await tester.pump();
    await settings.set(SettingsKeys.displayTheme, 'light');
    await tester.pump();
    expect(gateThemeMode(tester), ThemeMode.dark);

    t.blocker.requestGate(igRef);
    await pumpRequest(tester);
    expect(gateThemeMode(tester), ThemeMode.light);
    screen = tester.element(find.byType(GateScreen));
    expect(Theme.of(screen).brightness, Brightness.light);
    region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>).last,
    );
    expect(region.value.statusBarIconBrightness, Brightness.dark);
  });
}
