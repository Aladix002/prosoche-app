import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/router/navigator_keys.dart';
import 'package:prosoche/core/router/routes.dart';
import 'package:prosoche/features/quran/quran_screen.dart';
import 'package:prosoche/features/quran/reader/quran_reader_screen.dart';
import 'package:prosoche/features/quran/search/quran_search_screen.dart';

/// Tab Quran (docs/02 C1, C2). Vlastnik: F-04.
abstract final class QuranRoutes {
  static const String root = AppRoutes.quran;
  static const search = '$root/search';

  /// Nazvy rout = `screen_view` (docs/02 C2).
  static const readerName = 'quran_reader';
  static const searchName = 'quran_search';

  /// Max dlzka `q` (docs/02 C2), dlhsi vstup sa oreze.
  static const maxQueryLength = 100;

  /// `/quran/read/:surah?ayah=<ayah_id>&mode=khatm|browse`
  static String read(int surah, {int? ayahId, String? mode}) {
    final query = {'ayah': ?ayahId?.toString(), 'mode': ?mode};
    return Uri(
      path: '$root/read/$surah',
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }

  /// `/quran/search?q=`
  static String searchFor(String query) => Uri(
    path: search,
    queryParameters: query.isEmpty ? null : {'q': query},
  ).toString();

  static int? parseSurah(String? raw) {
    final n = int.tryParse(raw ?? '');
    return n != null && n >= 1 && n <= 114 ? n : null;
  }

  static String parseQuery(String? raw) {
    final q = raw ?? '';
    return q.length > maxQueryLength ? q.substring(0, maxQueryLength) : q;
  }
}

List<RouteBase> quranRoutes() => [
  GoRoute(
    path: QuranRoutes.root,
    name: AppRouteNames.quran,
    builder: (context, state) => const QuranScreen(),
    routes: [
      // Citanie skryje spodnu navigaciu (docs/02 C1), preto root navigator.
      GoRoute(
        path: 'read/:surah',
        name: QuranRoutes.readerName,
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) =>
            QuranRoutes.parseSurah(state.pathParameters['surah']) == null
            ? QuranRoutes.root
            : null,
        builder: (context, state) {
          final params = state.uri.queryParameters;
          return QuranReaderScreen(
            key: ValueKey(state.uri.toString()),
            surah: QuranRoutes.parseSurah(state.pathParameters['surah'])!,
            // Neciselny `ayah` je tiez neplatny vers (E-LINK-1).
            ayahId: params.containsKey('ayah')
                ? int.tryParse(params['ayah']!) ?? -1
                : null,
            mode: QuranReaderScreen.parseMode(params['mode']),
          );
        },
      ),
      GoRoute(
        path: 'search',
        name: QuranRoutes.searchName,
        builder: (context, state) => QuranSearchScreen(
          initialQuery: QuranRoutes.parseQuery(state.uri.queryParameters['q']),
        ),
      ),
    ],
  ),
];
