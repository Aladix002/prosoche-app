import 'package:go_router/go_router.dart';
import 'package:prosoche/core/router/routes.dart';
import 'package:prosoche/features/feed/feed_screen.dart';

/// Fullscreen feed nad shellom (docs/02 C1). Vlastnik: F-02.
List<RouteBase> feedRoutes() => [
  GoRoute(
    path: AppRoutes.feed,
    name: AppRouteNames.feed,
    builder: (context, state) => const FeedScreen(),
  ),
];
