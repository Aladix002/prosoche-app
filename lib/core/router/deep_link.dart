import 'package:sakina/core/router/routes.dart';

/// Schema deep linkov (Android intent filter, iOS URL scheme).
const deepLinkScheme = 'mursa';

/// Prevedie `mursa://<host>/<path>?<query>` na go_router cestu
/// (docs/01 kap. 4.3). Vrati null, ak [uri] nie je deep link appky.
///
/// Mapovanie podla docs/02 C4. Nezname ciele vedu na `/today`. Deep link
/// je vzdy len navigacia, nikdy nezapisuje data. Vypnute funkcie (gate,
/// words) presmeruje az redirect routera.
String? mapDeepLink(Uri uri) {
  if (uri.scheme != deepLinkScheme) return null;
  final segments = [
    if (uri.host.isNotEmpty) uri.host,
    ...uri.pathSegments.where((s) => s.isNotEmpty),
  ];
  final target = segments.isEmpty ? '' : segments.first;
  switch (target) {
    case 'gate':
      final app = GateParams.parseApp(uri.queryParameters[GateParams.app]);
      if (app == null) return AppRoutes.today;
      final src = uri.queryParameters[GateParams.src];
      return Uri(
        path: AppRoutes.gate,
        queryParameters: {
          GateParams.app: app,
          GateParams.src: GateParams.sources.contains(src) ? src : 'monitor',
        },
      ).toString();
    case 'feed':
      return AppRoutes.feed;
    case 'quran':
      // mursa://quran/2/255 -> /quran/read/2?ayah=2255&mode=browse
      final surah = segments.length > 1 ? int.tryParse(segments[1]) : null;
      if (surah == null || surah < 1 || surah > 114) return AppRoutes.quran;
      final ayah = segments.length > 2 ? int.tryParse(segments[2]) : null;
      return Uri(
        path: '${AppRoutes.quran}/read/$surah',
        queryParameters: {
          if (ayah != null && ayah >= 1 && ayah <= 286)
            'ayah': '${surah * 1000 + ayah}',
          'mode': 'browse',
        },
      ).toString();
    case 'prayer':
      return segments.length > 1 && segments[1] == 'qibla'
          ? '${AppRoutes.prayer}/qibla'
          : AppRoutes.prayer;
    case 'journey':
      return AppRoutes.journey;
    case 'words':
      return segments.length > 1 && segments[1] == 'quiz'
          ? '/words/quiz'
          : '/words';
    case 'calendar':
      return '/calendar';
    case 'settings':
      final sub = segments.length > 1 ? segments[1] : null;
      return switch (sub) {
        'blocking' || 'notifications' => '/settings/$sub',
        _ => '/settings',
      };
    case 'dev':
      // Len flavor dev; v prod redirect routera presmeruje na Today.
      return segments.length > 1 && segments[1] == 'gallery'
          ? AppRoutes.devGallery
          : AppRoutes.today;
    case 'today':
    default:
      return AppRoutes.today;
  }
}
