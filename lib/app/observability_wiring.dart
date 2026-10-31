import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/logging/app_logger.dart';
import 'package:sakina/core/router/app_router.dart';
import 'package:sakina/data/observability/crash_reporter.dart';
import 'package:sakina/data/observability/observability_providers.dart';
import 'package:sakina/features/onboarding/onboarding_controller.dart';

/// D-04: ring buffer a Sentry sink zdielane s `AppLogger` z bootstrapu
/// a onboarding analytika (F-01 O7) cez allowlist [analyticsProvider].
List<Override> observabilityOverrides({
  required RingBufferLog ring,
  required CrashLogSink crashSink,
}) => [
  ringBufferLogProvider.overrideWithValue(ring),
  crashLogSinkProvider.overrideWithValue(crashSink),
  onboardingAnalyticsSinkProvider.overrideWith(
    (ref) => (events) {
      // Volane az po ulozeni suhlasu v O7; controller si ho precita sam.
      ref.read(observabilityControllerProvider).sendConsented([
        for (final e in events) (e.name, e.props),
      ]).ignore();
    },
  ),
];

/// Spusti riadenie PostHog/Sentry podla suhlasov (po `runApp`). Bez
/// suhlasu, bez kluca alebo pri kill-switchi sa SDK neinicializuju.
///
/// Trvaly listener: v Riverpod 3 by provider bez posluchaca pozastavil aj
/// svoje `ref.listen` na nastavenia a zmena suhlasu by sa neprejavila.
void startObservability(ProviderContainer container) {
  container.listen(observabilityControllerProvider, (_, _) {});
}

/// `screen_view{screen}` (docs/02 C2) pri kazdej zmene obrazovky: `screen`
/// je nazov GoRoute (`today`, `quran_reader`), nikdy cesta s parametrami.
/// Bez suhlasu [analyticsProvider] event zahodi.
///
/// Router sa po zmazani dat vytvori znova ([appRouterProvider]), preto sa
/// posluchac pripaja ku kazdej instancii.
void startScreenViews(ProviderContainer container) {
  String? last;
  container.listen<GoRouter>(appRouterProvider, (_, router) {
    void report() {
      final screen = screenNameOf(router.routerDelegate.currentConfiguration);
      if (screen == null || screen == last) return;
      last = screen;
      container.read(analyticsProvider).track('screen_view', {
        'screen': screen,
      });
    }

    router.routerDelegate.addListener(report);
  }, fireImmediately: true);
}

/// Nazov najvnorenejsej routy; null = routa bez nazvu.
String? screenNameOf(RouteMatchList matches) {
  if (matches.isEmpty) return null;
  return matches.last.route.name;
}
