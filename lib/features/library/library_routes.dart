import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/router/routes.dart';
import 'package:prosoche/features/library/bookmarks_screen.dart';
import 'package:prosoche/features/library/library_screen.dart';
import 'package:prosoche/features/library/reader_screen.dart';
import 'package:prosoche/features/library/search_screen.dart';

/// Cesty Library (F-01).
abstract final class LibraryRoutes {
  static const String root = AppRoutes.library;
  static const search = '$root/search';
  static const bookmarks = '$root/bookmarks';

  /// Citacka je fullscreen nad shellom (otvara sa aj z feedu, Today,
  /// Practice a karty "Read in context").
  static const readerRoot = '/reader';

  static const searchName = 'library_search';
  static const bookmarksName = 'library_bookmarks';
  static const readerName = 'reader';

  /// Query parameter sekcie (`section.key`).
  static const sectionParam = 'section';

  /// `/reader/<workId>?section=<key>`.
  static String reader(String workId, {String? section}) => Uri(
    path: '$readerRoot/$workId',
    queryParameters: section == null ? null : {sectionParam: section},
  ).toString();
}

/// `work.id` zo `section.key` (`<work>.<kniha>.<n>` alebo `<work>.<n>`,
/// kontrakt kap. 3; `work.id` neobsahuje bodku).
String workIdOfSection(String sectionKey) {
  final i = sectionKey.indexOf('.');
  return i < 0 ? sectionKey : sectionKey.substring(0, i);
}

/// Otvori citacku diela [workId] na sekcii [section] (inak na pozicii
/// citania). [highlight] je text, ktory sa v sekcii zvyrazni (citat
/// z karty).
Future<void> openReader(
  BuildContext context, {
  required String workId,
  String? section,
  String? highlight,
}) => context.push(
  LibraryRoutes.reader(workId, section: section),
  extra: highlight,
);

/// Tab Library (PLAN.md kap. 2). Vlastnik: F-01.
List<RouteBase> libraryRoutes() => [
  GoRoute(
    path: AppRoutes.library,
    name: AppRouteNames.library,
    builder: (context, state) => const LibraryScreen(),
    routes: [
      GoRoute(
        path: 'search',
        name: LibraryRoutes.searchName,
        builder: (context, state) => const LibrarySearchScreen(),
      ),
      GoRoute(
        path: 'bookmarks',
        name: LibraryRoutes.bookmarksName,
        builder: (context, state) => const BookmarksScreen(),
      ),
    ],
  ),
];

/// Citacka nad shellom (bez bottom nav): top-level routa je na root
/// navigatore ako `/feed`.
List<RouteBase> readerRoutes() => [
  GoRoute(
    path: '${LibraryRoutes.readerRoot}/:workId',
    name: LibraryRoutes.readerName,
    builder: (context, state) => ReaderScreen(
      workId: state.pathParameters['workId']!,
      sectionKey: state.uri.queryParameters[LibraryRoutes.sectionParam],
      highlight: state.extra is String ? state.extra! as String : null,
    ),
  ),
];
