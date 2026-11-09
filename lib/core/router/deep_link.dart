import 'package:prosoche/core/router/routes.dart';

/// Schema deep linkov (Android intent filter, iOS URL scheme).
const deepLinkScheme = 'prosoche';

/// Prevedie `prosoche://<host>/<path>?<query>` na go_router cestu
/// (docs/01 kap. 4.3). Vrati null, ak [uri] nie je deep link appky.
///
/// Mapovanie podla docs/02 C4. Nezname ciele vedu na `/today`. Deep link
/// je vzdy len navigacia, nikdy nezapisuje data. Vypnute funkcie (gate)
/// presmeruje az redirect routera.
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
    case 'library':
      return AppRoutes.library;
    case 'reader':
      return _reader(segments, uri.queryParameters);
    case 'practice':
      return AppRoutes.practice;
    case 'journey':
      return AppRoutes.journey;
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

/// W-01: `prosoche://reader/<workId>?section=<key>&hl=<text>` (widget na
/// ploche, "Read in context"). Neplatne id diela vedie na Library, neplatna
/// sekcia sa zahodi, `hl` (zvyrazneny text) ma max. [_maxHighlight] znakov.
String _reader(List<String> segments, Map<String, String> query) {
  final work = segments.length > 1 ? segments[1] : null;
  if (work == null || !_workId.hasMatch(work)) return AppRoutes.library;
  final section = query['section'];
  final hl = query['hl'];
  final params = {
    if (section != null && _sectionKey.hasMatch(section)) 'section': section,
    if (hl != null && hl.trim().isNotEmpty && hl.length <= _maxHighlight)
      'hl': hl,
  };
  return Uri(
    path: '/reader/$work',
    queryParameters: params.isEmpty ? null : params,
  ).toString();
}

final _workId = RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$');
final _sectionKey = RegExp(r'^[a-z0-9][a-z0-9_.-]{0,127}$');
const _maxHighlight = 600;
