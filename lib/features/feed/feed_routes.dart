import 'package:go_router/go_router.dart';
import 'package:sakina/core/router/routes.dart';
import 'package:sakina/features/feed/feed_screen.dart';

/// Fullscreen feed nad shellom (docs/02 C1). Vlastnik: F-02.
List<RouteBase> feedRoutes() => [
  GoRoute(
    path: AppRoutes.feed,
    name: AppRouteNames.feed,
    builder: (context, state) => const FeedScreen(),
  ),
];
