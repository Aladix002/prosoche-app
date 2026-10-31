import 'package:go_router/go_router.dart';
import 'package:prosoche/core/router/routes.dart';
import 'package:prosoche/features/practice/practice_screen.dart';

/// Tab Practice (PLAN.md kap. 2). Vlastnik: F-01.
List<RouteBase> practiceRoutes() => [
  GoRoute(
    path: AppRoutes.practice,
    name: AppRouteNames.practice,
    builder: (context, state) => const PracticeScreen(),
  ),
];
