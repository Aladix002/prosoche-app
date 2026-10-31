import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/app.dart';
import 'package:sakina/core/flags/feature_flags.dart';
import 'package:sakina/core/router/app_router.dart';
import 'package:sakina/ui/components/sk_nav_bar.dart';

import '../fakes/fake_repositories.dart';

extension PumpApp on WidgetTester {
  /// Spusti celu appku s routerom na [location]. Predvolene su vsetky
  /// funkcie zapnute ([FeatureFlags.all]); [devTools] = flavor `dev`.
  /// Repozitare su fakes z `test/fakes/` ([fakes]), ziadna databaza sa
  /// neotvara (obrazovky featur citaju data uz pri prvom builde).
  Future<GoRouter> pumpSakina({
    String location = '/today',
    FeatureFlags flags = FeatureFlags.all,
    bool devTools = false,
    FakeRepositories? fakes,
    List<Override> overrides = const [],
  }) async {
    final router = buildAppRouter(
      initialLocation: location,
      flags: flags,
      devTools: devTools,
    );
    addTearDown(router.dispose);
    await pumpWidget(
      ProviderScope(
        // Obrazovky citaju repozitare D-02: bez databazy v testoch fakes.
        retry: (_, _) => null,
        overrides: [
          ...(fakes ?? FakeRepositories()).overrides(
            now: DateTime(2026, 10, 29, 9),
          ),
          featureFlagsProvider.overrideWithValue(flags),
          appRouterProvider.overrideWithValue(router),
          ...overrides,
        ],
        child: const SakinaApp(),
      ),
    );
    await pumpAndSettle();
    return router;
  }
}

Finder get navBar => find.byType(SkNavBar);
