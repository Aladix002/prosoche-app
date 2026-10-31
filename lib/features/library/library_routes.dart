import 'package:go_router/go_router.dart';
import 'package:prosoche/core/router/routes.dart';
import 'package:prosoche/features/library/library_screen.dart';

/// Tab Library (PLAN.md kap. 2). Vlastnik: F-01.
List<RouteBase> libraryRoutes() => [
  GoRoute(
    path: AppRoutes.library,
    name: AppRouteNames.library,
    builder: (context, state) => const LibraryScreen(),
  ),
];
