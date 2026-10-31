/// Cesty nastaveni (docs/02 C1). Routy sklada `settings_routes.dart`.
abstract final class SettingsPaths {
  static const root = '/settings';
  static const blocking = '$root/blocking';
  static const prayer = '$root/prayer';
  static const notifications = '$root/notifications';
  static const language = '$root/language';
  static const display = '$root/display';
  static const audio = '$root/audio';
  static const calendar = '$root/calendar';
  static const privacy = '$root/privacy';
  static const backup = '$root/backup';
  static const sources = '$root/sources';
  static const about = '$root/about';
}
