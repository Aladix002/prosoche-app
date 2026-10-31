import 'package:prosoche/core/router/routes.dart';
import 'package:prosoche/features/settings/settings_routes.dart';

/// Cesty, na ktore F-05 naviguje (docs/02 C1). Nastavenia su routy F-07
/// (`settings_routes.dart`); obrazovky im dodava F-05
/// (`PrayerSettingsScreen`, `CitySearchScreen`, `HijriOffsetScreen`).
abstract final class PrayerPaths {
  static const String qibla = '${AppRoutes.prayer}/qibla';
  static const String settings = SettingsRoutes.prayer;
  static const String location = '${SettingsRoutes.prayer}/location';
  static const String citySearch = '$location/search';
  static const String notifications = SettingsRoutes.notifications;
  static const String calendarSettings = '${SettingsRoutes.root}/calendar';
}
