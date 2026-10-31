import 'package:go_router/go_router.dart';
import 'package:prosoche/core/router/navigator_keys.dart';
import 'package:prosoche/features/onboarding/onboarding_screen.dart';
import 'package:prosoche/features/onboarding/onboarding_steps.dart';

/// Onboarding `/onboarding/:step` (docs/02 C1, C2), fullscreen mimo shell.
/// Guard podla `onboarding.completed` (C3) je `OnboardingGuard`.
/// Vlastnik: F-01.
abstract final class OnboardingRoutes {
  static const root = '/onboarding';
  static const firstStep = 'welcome';

  static String step(String step) => '$root/$step';
}

/// [gate]: kroky O5 a O6 len pri `FEATURE_GATE`, inak je krok neplatny
/// a routa presmeruje na prvy krok (C2).
List<RouteBase> onboardingRoutes({bool gate = false}) {
  final flow = OnboardingFlow(gate: gate);
  OnboardingStep? stepOf(GoRouterState state) {
    final step = OnboardingStep.tryParse(state.pathParameters['step']);
    return step != null && flow.contains(step) ? step : null;
  }

  return [
    GoRoute(
      path: '${OnboardingRoutes.root}/:step',
      name: 'onboarding',
      parentNavigatorKey: rootNavigatorKey,
      redirect: (context, state) =>
          stepOf(state) == null ? OnboardingRoutes.step(flow.first.key) : null,
      pageBuilder: (context, state) => NoTransitionPage<void>(
        key: state.pageKey,
        name: 'onboarding_${stepOf(state)!.key}',
        child: OnboardingScreen(step: stepOf(state)!, flow: flow),
      ),
    ),
  ];
}
