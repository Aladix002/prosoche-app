import 'package:go_router/go_router.dart';
import 'package:sakina/core/router/routes.dart';
import 'package:sakina/features/prayer/location/city_search_screen.dart';
import 'package:sakina/features/prayer/prayer_screen.dart';
import 'package:sakina/features/prayer/qibla/qibla_screen.dart';
import 'package:sakina/features/prayer/settings/prayer_settings_screen.dart';

export 'package:sakina/features/prayer/location/city_search_screen.dart'
    show CitySearchScreen;
export 'package:sakina/features/prayer/settings/prayer_settings_screen.dart'
    show PrayerSettingsScreen;

/// Tab Prayer (docs/02 C1). Vlastnik: F-05.
abstract final class PrayerRoutes {
  static const String root = AppRoutes.prayer;
  static const qibla = '$root/qibla';
}

List<RouteBase> prayerRoutes() => [
  GoRoute(
    path: PrayerRoutes.root,
    name: AppRouteNames.prayer,
    builder: (context, state) => const PrayerScreen(),
    routes: [
      GoRoute(
        path: 'qibla',
        name: 'qibla',
        builder: (context, state) => const QiblaScreen(),
      ),
    ],
  ),
];

/// Obrazovky F-05 pre `/settings/prayer/**` (routy patria F-07,
/// `settings_routes.dart`; integracia nahradi zastupne obrazovky):
///
/// - `prayer` -> [PrayerSettingsScreen] (`settings_prayer`)
/// - `prayer/location` a `prayer/location/search` -> [CitySearchScreen]
///   (`settings_prayer_location`, `settings_prayer_location_search`)
abstract final class PrayerSettingsBuilders {
  static GoRouterWidgetBuilder get settings =>
      (context, state) => const PrayerSettingsScreen();

  static GoRouterWidgetBuilder get location =>
      (context, state) => const CitySearchScreen();
}
