// Spolocny harness pre widget testy F-02 (Dnes, Feed, karty): GoRouter
// s /today, /feed a zastupnymi cielmi navigacie, tema a texty Sakina,
// fake repozitare D-02.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/app.dart';
import 'package:sakina/core/clock/clock_provider.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/core/router/routes.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/features/feed/feed_routes.dart';
import 'package:sakina/features/today/today_routes.dart';
import 'package:sakina/ui/foundation/sk_ui_strings.dart';
import 'package:sakina/ui/theme/sakina_theme.dart';

import '../../fakes/fake_repositories.dart';

/// Datum a cas testov (stvrtok 29. 10. 2026, 9:00).
final f02Today = LocalDate(2026, 10, 29);
final f02Now = DateTime(2026, 10, 29, 9);

/// Zastupna obrazovka cielov mimo F-02 (reader, nastavenia, kalendar).
class StubScreen extends StatelessWidget {
  const StubScreen(this.uri, {super.key});

  final Uri uri;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('stub:$uri')));
}

GoRoute _stub(String path) => GoRoute(
  path: path,
  builder: (context, state) => StubScreen(state.uri),
  routes: [
    GoRoute(
      path: ':a',
      builder: (context, state) => StubScreen(state.uri),
      routes: [
        GoRoute(path: ':b', builder: (context, state) => StubScreen(state.uri)),
      ],
    ),
  ],
);

/// Hodiny, ktore idu s fake casom testu (polnoc, navrat po pauze).
Clock advancingClock(WidgetTester tester, DateTime start) {
  final t0 = tester.binding.clock.now();
  return Clock(() => start.add(tester.binding.clock.now().difference(t0)));
}

/// Spusti F-02 obrazovky na [location] s [repos]; [below] = routa pod
/// [location] (napr. Dnes pod feedom); [host] sa zobrazi na `/host`.
Future<GoRouter> pumpF02(
  WidgetTester tester, {
  FakeRepositories? repos,
  String location = AppRoutes.today,
  Locale locale = const Locale('en'),
  DateTime? now,
  Clock? clock,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  List<Override> overrides = const [],
  String? below,
  Widget? host,
}) async {
  // Telefon 360 x 780 dp.
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final r = repos ?? FakeRepositories();
  final router = GoRouter(
    initialLocation: below ?? location,
    routes: [
      ...todayRoutes(),
      ...feedRoutes(),
      if (host != null)
        GoRoute(
          path: '/host',
          builder: (context, state) => Scaffold(body: SafeArea(child: host)),
        ),
      _stub('/quran'),
      _stub('/settings'),
      _stub('/calendar'),
      _stub('/prayer'),
    ],
  );
  addTearDown(router.dispose);
  final base = r.overrides(
    now: now ?? f02Now,
    deviceLanguage: locale.languageCode,
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        // Prvy override fakes su hodiny; [clock] ich nahradi.
        if (clock != null) ...[
          appClockProvider.overrideWithValue(clock),
          ...base.skip(1),
        ] else
          ...base,
        ...overrides,
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        theme: SakinaTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: Theme(
            data: sakinaAppTheme(
              brightness: brightness,
              locale: Localizations.localeOf(context),
            ),
            child: SkUiStringsScope(
              strings: skUiStringsOf(context.l10n),
              child: child!,
            ),
          ),
        ),
      ),
    ),
  );
  if (below != null) {
    await tester.pump();
    unawaited(router.push<void>(location));
  }
  await tester.pump();
  await tester.pump();
  return router;
}
