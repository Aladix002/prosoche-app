import 'package:go_router/go_router.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/core/flavor/flavor.dart';
import 'package:prosoche/core/router/deep_link.dart';
import 'package:prosoche/core/router/dev_routes.dart';
import 'package:prosoche/core/router/navigator_keys.dart';
import 'package:prosoche/core/router/routes.dart';
import 'package:prosoche/features/feed/feed_routes.dart';
import 'package:prosoche/features/gate/gate_routes.dart';
import 'package:prosoche/features/journey/journey_routes.dart';
import 'package:prosoche/features/library/library_routes.dart';
import 'package:prosoche/features/onboarding/onboarding_guard.dart';
import 'package:prosoche/features/onboarding/onboarding_routes.dart';
import 'package:prosoche/features/practice/practice_routes.dart';
import 'package:prosoche/features/settings/settings_routes.dart';
import 'package:prosoche/features/shell/app_shell.dart';
import 'package:prosoche/features/today/today_routes.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:prosoche/core/router/navigator_keys.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = buildAppRouter(
    flags: ref.watch(featureFlagsProvider),
    devTools: ref.watch(flavorProvider).isDev,
    onboarding: ref.watch(onboardingGuardProvider),
  );
  ref.onDispose(router.dispose);
  return router;
}

/// Konfiguracia rout (docs/02 C1, docs/01 D1: 4 taby). Routy definuju
/// featury v `lib/features/<f>/<f>_routes.dart`, tento subor ich len sklada.
///
/// Routy vypnutych funkcii ([FeatureFlags]) sa neregistruju a ich cesty
/// presmeruje [redirect] (gate -> Today).
///
/// [devTools] (flavor `dev`) prida vyvojarske routy ([devRoutes]); v `prod`
/// sa neregistruju a `/dev/...` presmeruje na Today.
///
/// [onboarding] (F-01) presmeruje na onboarding, kym nie je dokonceny
/// (docs/02 C3); bez neho (testy routera) sa onboarding nevynucuje.
GoRouter buildAppRouter({
  String initialLocation = AppRoutes.today,
  FeatureFlags flags = FeatureFlags.fromEnvironment,
  bool devTools = false,
  OnboardingGuard? onboarding,
}) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: initialLocation,
  refreshListenable: onboarding,
  redirect: (context, state) {
    final target = redirect(state.uri, flags, devTools: devTools);
    return onboarding == null ? target : onboarding.redirect(state.uri, target);
  },
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: todayRoutes()),
        StatefulShellBranch(routes: libraryRoutes()),
        StatefulShellBranch(routes: practiceRoutes()),
        StatefulShellBranch(routes: journeyRoutes()),
      ],
    ),
    // Fullscreen a push routy nad shellom (bez bottom nav).
    ...feedRoutes(),
    if (flags.gate) ...gateRoutes(),
    ...settingsRoutes(gate: flags.gate),
    ...onboardingRoutes(gate: flags.gate),
    if (devTools) ...devRoutes(),
  ],
);

/// Globalny redirect: deep linky, koren a vypnute funkcie.
String? redirect(Uri uri, FeatureFlags flags, {bool devTools = false}) {
  final deepLink = mapDeepLink(uri);
  final path = deepLink == null ? uri.path : Uri.parse(deepLink).path;
  if (path == '/' || path.isEmpty) return AppRoutes.today;
  if (path == OnboardingRoutes.root) {
    return OnboardingRoutes.step(OnboardingRoutes.firstStep);
  }
  if (!flags.gate &&
      (_under(path, AppRoutes.gate) || _under(path, SettingsRoutes.blocking))) {
    return AppRoutes.today;
  }
  if (!devTools && _under(path, AppRoutes.dev)) return AppRoutes.today;
  return deepLink;
}

bool _under(String path, String root) =>
    path == root || path.startsWith('$root/');
