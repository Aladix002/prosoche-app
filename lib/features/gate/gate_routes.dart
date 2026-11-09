import 'package:go_router/go_router.dart';
import 'package:prosoche/core/router/routes.dart';
import 'package:prosoche/features/gate/gate_screen.dart';

// Entrypoint predhriateho enginu (GateEngine.kt) musi byt v AOT snapshote:
// Flutter kompiluje len kniznice dosiahnutelne z lib/main.dart a toto je
// cesta cez router, bez zmeny main.dart.
export 'package:prosoche/gate_main.dart' show gateMain;

/// Brana `/gate?app=<packageName>&src=...` (docs/02 C1). Len pri
/// `FEATURE_GATE` v edicii `full`. Vlastnik: B-02.
///
/// Na Androide branu zobrazuje GateActivity v predhriatom engine
/// (`gateMain`, ADR-16); tato routa sluzi testovaciemu deep linku
/// `prosoche://gate?app=...` v hlavnom engine, kde `closeGate` nic nerobi,
/// preto sa po zavreti ide na Dnes.
List<RouteBase> gateRoutes() => [
  GoRoute(
    path: AppRoutes.gate,
    name: AppRouteNames.gate,
    redirect: (context, state) =>
        GateParams.parseApp(state.uri.queryParameters[GateParams.app]) == null
        ? AppRoutes.today
        : null,
    builder: (context, state) => GateScreen(
      app: GateParams.parseApp(state.uri.queryParameters[GateParams.app])!,
      source: state.uri.queryParameters[GateParams.src] ?? 'monitor',
      onClosed: () {
        if (context.mounted) context.go(AppRoutes.today);
      },
      onPractice: () {
        if (context.mounted) context.go(AppRoutes.practice);
      },
    ),
  ),
];
