// Spolocne prostredie widget testov Library a Practice (F-01): GoRouter
// s routami Library, citacky a Practice nad fake repozitarmi.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/app.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/features/library/library_routes.dart';
import 'package:prosoche/features/practice/practice_routes.dart';
import 'package:prosoche/ui/ui.dart';

import '../../fakes/fake_repositories.dart';

final f01Now = DateTime(2026, 10, 29, 9);

Future<GoRouter> pumpF01(
  WidgetTester tester, {
  required String location,
  FakeRepositories? repos,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  List<Override> overrides = const [],
}) async {
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final r = repos ?? FakeRepositories();
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SizedBox()),
      ...libraryRoutes(),
      ...readerRoutes(),
      ...practiceRoutes(),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        ...r.overrides(now: f01Now),
        ...overrides,
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: ProsocheTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: Theme(
            data: prosocheAppTheme(
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
  await tester.pumpAndSettle();
  return router;
}
