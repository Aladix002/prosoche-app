/// Cesty a nazvy rout (docs/01 kap. 4.2). Meni ich len integracia.
abstract final class AppRoutes {
  static const today = '/today';
  static const quran = '/quran';
  static const prayer = '/prayer';
  static const journey = '/journey';
  static const feed = '/feed';
  static const gate = '/gate';

  /// Vyvojarske obrazovky, len flavor `dev` (`dev_routes.dart`).
  static const dev = '/dev';
  static const devGallery = '/dev/gallery';
}

abstract final class AppRouteNames {
  static const today = 'today';
  static const quran = 'quran';
  static const prayer = 'prayer';
  static const journey = 'journey';
  static const feed = 'feed';
  static const gate = 'gate';
}

/// Query parametre brany: `/gate?app=<packageName>&src=<source>`, zdroj je
/// `monitor`, `notif`, `test` alebo `error` (nativny fallback, B-02).
abstract final class GateParams {
  static const app = 'app';
  static const src = 'src';
  static const sources = {'monitor', 'notif', 'test', 'error'};

  static final _packageName = RegExp(
    r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$',
  );

  /// Vrati package name, ak je validny, inak null.
  static String? parseApp(String? raw) =>
      raw != null && raw.length <= 255 && _packageName.hasMatch(raw)
      ? raw
      : null;
}
