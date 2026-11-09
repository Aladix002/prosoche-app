import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/router/placeholder_route.dart';
import 'package:prosoche/features/settings/about_screen.dart';
import 'package:prosoche/features/settings/blocking/blocking_screen.dart';
import 'package:prosoche/features/settings/blocking/blocking_subscreens.dart';
import 'package:prosoche/features/settings/blocking/gate_behavior.dart';
import 'package:prosoche/features/settings/display_settings_screen.dart';
import 'package:prosoche/features/settings/notification_settings_screen.dart';
import 'package:prosoche/features/settings/privacy_settings_screen.dart';
import 'package:prosoche/features/settings/settings_paths.dart';
import 'package:prosoche/features/settings/settings_screen.dart';
import 'package:prosoche/features/settings/sources_screen.dart';

export 'package:prosoche/features/settings/settings_paths.dart';

/// Nastavenia ako push route nad shellom (docs/02 C1, docs/01 D1).
/// Vlastnik: F-07.
abstract final class SettingsRoutes {
  static const String root = SettingsPaths.root;
  static const String blocking = SettingsPaths.blocking;
  static const String notifications = SettingsPaths.notifications;
}

GoRoute _route(String path, String name, Widget Function() screen) =>
    GoRoute(path: path, name: name, builder: (context, state) => screen());

/// [gate]: `/settings/blocking/**` len pri `FEATURE_GATE` (B-03). Zaloha
/// (F-09) je zatial zastupna a v koreni nastaveni skryta.
List<RouteBase> settingsRoutes({required bool gate}) => [
  GoRoute(
    path: SettingsPaths.root,
    name: 'settings',
    builder: (context, state) => const SettingsScreen(),
    routes: [
      // Brana (B-03), len pri FEATURE_GATE; v lite routy nie su.
      if (gate)
        GoRoute(
          path: 'blocking',
          name: 'settings_blocking',
          builder: (context, state) => const BlockingScreen(),
          routes: [
            _route(
              'permissions',
              'settings_blocking_permissions',
              () => const BlockingPermissionsScreen(),
            ),
            _route(
              'add',
              'settings_blocking_add',
              () => const BlockingAddScreen(),
            ),
            _route(
              'practice-first',
              'settings_blocking_practice_first',
              () => const PracticeFirstScreen(),
            ),
            GoRoute(
              path: 'app/:ref',
              name: 'settings_blocking_app',
              builder: (context, state) =>
                  BlockingAppScreen(appRef: state.pathParameters['ref']!),
            ),
          ],
        ),
      _route(
        'notifications',
        'settings_notifications',
        () => const NotificationSettingsScreen(),
      ),
      _route(
        'display',
        'settings_display',
        () => const DisplaySettingsScreen(),
      ),
      _route(
        'privacy',
        'settings_privacy',
        () => const PrivacySettingsScreen(),
      ),
      placeholderRoute('backup', 'settings_backup'),
      _route('sources', 'settings_sources', () => const SourcesScreen()),
      _route('about', 'settings_about', () => const AboutScreen()),
    ],
  ),
];
