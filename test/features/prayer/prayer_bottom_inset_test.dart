import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/core/router/routes.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:prosoche/features/prayer/prayer_routes.dart';
import 'package:prosoche/features/shell/app_shell.dart';
import 'package:prosoche/ui/components/sk_nav_bar.dart';
import 'package:prosoche/ui/theme/prosoche_theme.dart';

import '../../fakes/fake_repositories.dart';
import 'f05_test_app.dart';

// P-01: riadok s metodou vypoctu pri 1080x1920 (420 dpi) nesmie ostat
// pod spodnou navigaciou ani pod systemovou listou (edge-to-edge).

const _dpr = 2.625;

/// Gesta (24 dp) a 3 tlacidla (48 dp) systemovej navigacie.
const _insets = {'gesture': 24.0, 'three-button': 48.0};

GoRoute _stub(String path) =>
    GoRoute(path: path, builder: (context, state) => Text('stub:$path'));

/// Shell ako v appke (AppShell + SkNavBar), tab Prayer.
GoRouter _shellRouter() => GoRouter(
  initialLocation: PrayerRoutes.root,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [_stub(AppRoutes.today)]),
        StatefulShellBranch(routes: [_stub(AppRoutes.quran)]),
        StatefulShellBranch(routes: prayerRoutes()),
        StatefulShellBranch(routes: [_stub(AppRoutes.journey)]),
      ],
    ),
  ],
);

void _phone(WidgetTester tester, double bottomDp) {
  final bottom = bottomDp * _dpr;
  const top = 24 * _dpr;
  tester.view
    ..physicalSize = const Size(1080, 1920)
    ..devicePixelRatio = _dpr
    ..padding = FakeViewPadding(top: top, bottom: bottom)
    ..viewPadding = FakeViewPadding(top: top, bottom: bottom);
  addTearDown(tester.view.reset);
}

Future<void> _pump(WidgetTester tester, GoRouter router) async {
  addTearDown(router.dispose);
  final fakes = FakeRepositories(
    prayer: FakePrayerRepository(location: fakeBratislava),
  );
  final day = bratislavaDay(LocalDate(2026, 10, 29));
  await tester.pumpWidget(
    ProviderScope(
      overrides: fakes.overrides(
        now: day[Prayer.asr].subtract(const Duration(minutes: 72)),
      ),
      retry: (_, _) => null,
      child: MaterialApp.router(
        theme: ProsocheTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final Finder _infoLine = find.textContaining('Muslim World League');

Future<Rect> _scrolledToEnd(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -3000));
  await tester.pumpAndSettle();
  return tester.getRect(_infoLine);
}

double _listBottomPadding(WidgetTester tester) => tester
    .widget<ListView>(find.byType(ListView))
    .padding!
    .resolve(TextDirection.ltr)
    .bottom;

void main() {
  for (final MapEntry(key: nav, value: inset) in _insets.entries) {
    // Velky text pokryvaju goldeny (realne fonty); Ahem v testoch je sirsi.
    testWidgets('in the shell ($nav): info line fully above the bottom '
        'navigation after scrolling', (tester) async {
      _phone(tester, inset);
      await _pump(tester, _shellRouter());
      final navTop = tester.getTopLeft(find.byType(SkNavBar)).dy;
      // Pred scrollom je riadok pri 1080x1920 ciastocne pod navigaciou
      // (stav zo store screenshotu 06_prayer), dostupny je scrollom.
      // Pri 3 tlacidlach je cely mimo viewportu (ListView ho este nepostavil).
      if (_infoLine.evaluate().isNotEmpty) {
        expect(tester.getRect(_infoLine).bottom, greaterThan(navTop));
      }
      // Inset uz odobral Scaffold so SkNavBar: bez dvojiteho odsadenia.
      expect(_listBottomPadding(tester), 24);
      final rect = await _scrolledToEnd(tester);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(navTop));
      // Tap na riadok zasiahne riadok, nie navigaciu.
      final navBox = tester.renderObject(find.byType(SkNavBar));
      final hits = tester.hitTestOnBinding(rect.center).path;
      expect(hits.any((e) => e.target == navBox), isFalse);
    });

    testWidgets('outside the shell ($nav): info line above the system '
        'navigation bar (edge-to-edge bottom inset)', (tester) async {
      _phone(tester, inset);
      await _pump(tester, f05Router(PrayerRoutes.root));
      const screenBottom = 1920 / _dpr;
      // Koniec obsahu (po scrolle) konci nad systemovou listou.
      expect(_listBottomPadding(tester), 24 + inset);
      final rect = await _scrolledToEnd(tester);
      expect(rect.bottom, lessThanOrEqualTo(screenBottom - inset));
    });
  }
}
