import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/router/placeholder_route.dart';
import 'package:sakina/features/calendar/calendar_routes.dart';
import 'package:sakina/features/prayer/prayer_routes.dart';
import 'package:sakina/features/settings/about_screen.dart';
import 'package:sakina/features/settings/blocking/blocking_screen.dart';
import 'package:sakina/features/settings/blocking/blocking_subscreens.dart';
import 'package:sakina/features/settings/display_settings_screen.dart';
import 'package:sakina/features/settings/language_settings_screen.dart';
import 'package:sakina/features/settings/notification_settings_screen.dart';
import 'package:sakina/features/settings/privacy_settings_screen.dart';
import 'package:sakina/features/settings/settings_paths.dart';
import 'package:sakina/features/settings/settings_screen.dart';
import 'package:sakina/features/settings/sources_screen.dart';

export 'package:sakina/features/settings/settings_paths.dart';

/// Nastavenia ako push route nad shellom (docs/02 C1, docs/01 D1).
/// Vlastnik: F-07.
abstract final class SettingsRoutes {
  static const String root = SettingsPaths.root;
  static const String blocking = SettingsPaths.blocking;
  static const String prayer = SettingsPaths.prayer;
  static const String notifications = SettingsPaths.notifications;
  static const String language = SettingsPaths.language;
}

GoRoute _route(String path, String name, Widget Function() screen) =>
    GoRoute(path: path, name: name, builder: (context, state) => screen());

/// [gate]: `/settings/blocking/**` len pri `FEATURE_GATE` (B-03). Audio (`FEATURE_AUDIO`) a zaloha
/// (F-09) su zatial zastupne a v koreni nastaveni skryte.
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
            GoRoute(
              path: 'app/:ref',
              name: 'settings_blocking_app',
              builder: (context, state) =>
                  BlockingAppScreen(appRef: state.pathParameters['ref']!),
            ),
          ],
        ),
      // Obrazovky F-05 (integracia I-01).
      GoRoute(
        path: 'prayer',
        name: 'settings_prayer',
        builder: PrayerSettingsBuilders.settings,
        routes: [
          GoRoute(
            path: 'location',
            name: 'settings_prayer_location',
            builder: PrayerSettingsBuilders.location,
            routes: [
              GoRoute(
                path: 'search',
                name: 'settings_prayer_location_search',
                builder: PrayerSettingsBuilders.location,
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: 'calendar',
        name: 'settings_calendar',
        builder: CalendarSettingsBuilders.offset,
      ),
      _route(
        'notifications',
        'settings_notifications',
        () => const NotificationSettingsScreen(),
      ),
      _route(
        'language',
        'settings_language',
        () => const LanguageSettingsScreen(),
      ),
      _route(
        'display',
        'settings_display',
        () => const DisplaySettingsScreen(),
      ),
      placeholderRoute('audio', 'settings_audio'),
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
