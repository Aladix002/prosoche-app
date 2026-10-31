import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/placeholder_screen.dart';

/// Routa so zastupnou obrazovkou, kym featura nedoda skutocne UI.
///
/// [screen] je nazov z docs/02 C2 (pouzije sa ako `name` routy aj pre
/// `screen_view`). Obrazovka ukaze nazov a aktualnu URI (len na vyvoj).
GoRoute placeholderRoute(
  String path,
  String screen, {
  List<RouteBase> routes = const [],
  GlobalKey<NavigatorState>? parentNavigatorKey,
  GoRouterRedirect? redirect,
}) => GoRoute(
  path: path,
  name: screen,
  parentNavigatorKey: parentNavigatorKey,
  redirect: redirect,
  routes: routes,
  builder: (context, state) => PlaceholderScreen(
    key: ValueKey('placeholder:$screen'),
    title: screen,
    body: Text(state.uri.toString()),
  ),
);
