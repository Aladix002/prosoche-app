import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakina/core/flags/feature_flags.dart';
import 'package:sakina/core/flavor/flavor.dart';
import 'package:sakina/core/router/deep_link.dart';
import 'package:sakina/core/router/dev_routes.dart';
import 'package:sakina/core/router/navigator_keys.dart';
import 'package:sakina/core/router/routes.dart';
import 'package:sakina/features/calendar/calendar_routes.dart';
import 'package:sakina/features/feed/feed_routes.dart';
import 'package:sakina/features/gate/gate_routes.dart';
import 'package:sakina/features/journey/journey_routes.dart';
import 'package:sakina/features/onboarding/onboarding_guard.dart';
import 'package:sakina/features/onboarding/onboarding_routes.dart';
import 'package:sakina/features/prayer/prayer_routes.dart';
import 'package:sakina/features/quran/quran_routes.dart';
import 'package:sakina/features/settings/settings_routes.dart';
import 'package:sakina/features/shell/app_shell.dart';
import 'package:sakina/features/today/today_routes.dart';
import 'package:sakina/features/words/words_routes.dart';

export 'package:sakina/core/router/navigator_keys.dart';

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
/// presmeruje [redirect] (gate -> Today, words -> Journey).
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
        StatefulShellBranch(routes: quranRoutes()),
        StatefulShellBranch(routes: prayerRoutes()),
        StatefulShellBranch(routes: journeyRoutes()),
      ],
    ),
    // Fullscreen a push routy nad shellom (bez bottom nav).
    ...feedRoutes(),
    if (flags.gate) ...gateRoutes(),
    if (flags.words) ...wordsRoutes(),
    ...calendarRoutes(),
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
  if (!flags.words && _under(path, WordsRoutes.root)) {
    return AppRoutes.journey;
  }
  return deepLink;
}

bool _under(String path, String root) =>
    path == root || path.startsWith('$root/');
