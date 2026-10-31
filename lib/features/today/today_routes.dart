import 'package:go_router/go_router.dart';
import 'package:prosoche/core/router/routes.dart';
import 'package:prosoche/features/today/today_screen.dart';

/// Tab Today (docs/02 C1). Vlastnik: F-02.
List<RouteBase> todayRoutes() => [
  GoRoute(
    path: AppRoutes.today,
    name: AppRouteNames.today,
    builder: (context, state) => const TodayScreen(),
  ),
];
