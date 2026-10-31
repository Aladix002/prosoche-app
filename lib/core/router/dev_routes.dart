import 'package:go_router/go_router.dart';
import 'package:sakina/core/router/navigator_keys.dart';
import 'package:sakina/core/router/routes.dart';
import 'package:sakina/ui/gallery/sk_gallery_screen.dart';

/// Vyvojarske routy, registruju sa len vo flavore `dev` (nie v `prod`).
///
/// Galeria komponentov U-01: `mursa://dev/gallery` alebo `/dev/gallery`.
List<RouteBase> devRoutes() => [
  GoRoute(
    path: AppRoutes.devGallery,
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) => const SkGalleryScreen(),
  ),
];
