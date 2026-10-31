import 'package:go_router/go_router.dart';
import 'package:prosoche/core/router/placeholder_route.dart';

/// Slovicka (docs/02 C1). Vstup je z tabu Journey (docs/01 D1), preto
/// routy idu nad shell. Registruju sa len pri `FEATURE_WORDS`.
/// Vlastnik: buduca uloha slovicok (v1.1).
abstract final class WordsRoutes {
  static const root = '/words';
  static const quiz = '$root/quiz';

  static String lemma(int lemmaId) => '$root/lemma/$lemmaId';
}

List<RouteBase> wordsRoutes() => [
  placeholderRoute(
    WordsRoutes.root,
    'words',
    routes: [
      placeholderRoute(
        'lemma/:lemmaId',
        'lemma_detail',
        redirect: (context, state) =>
            (int.tryParse(state.pathParameters['lemmaId'] ?? '') ?? 0) < 1
            ? WordsRoutes.root
            : null,
      ),
      placeholderRoute('quiz', 'words_quiz'),
    ],
  ),
];
