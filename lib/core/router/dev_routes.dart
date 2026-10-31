import 'package:go_router/go_router.dart';
import 'package:prosoche/core/router/navigator_keys.dart';
import 'package:prosoche/core/router/routes.dart';
import 'package:prosoche/ui/gallery/sk_gallery_screen.dart';

/// Vyvojarske routy, registruju sa len vo flavore `dev` (nie v `prod`).
///
/// Galeria komponentov U-01: `prosoche://dev/gallery` alebo `/dev/gallery`.
List<RouteBase> devRoutes() => [
  GoRoute(
    path: AppRoutes.devGallery,
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) => const SkGalleryScreen(),
  ),
];
