import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/features/quran/quran_routes.dart';
import 'package:sakina/features/quran/reader/quran_reader_screen.dart';
import 'package:sakina/features/quran/search/quran_search_screen.dart';
import 'package:sakina/ui/i18n/i18n.dart';

import '../../../fakes/fake_repositories.dart';
import '../../../helpers/golden/golden.dart';
import '../quran_test_helpers.dart';

/// A5.4 vyhladavanie: tipy, debounce 300 ms, min 2 znaky, referencia,
/// sury, fulltext so zvyraznenim, prazdny vysledok, chyba, a11y.
void main() {
  setUpAll(loadSakinaFonts);

  const m0 = SearchHit.matchStart;
  const m1 = SearchHit.matchEnd;
  const hits = [
    SearchHit(ayahId: 2255, snippet: 'before ${m0}zephyr$m1 after'),
    SearchHit(ayahId: 1002, snippet: '${m0}zephyr$m1 again'),
  ];
  FakeRepositories withHits() =>
      quranFakes(quran: TestQuranRepository(hits: hits));

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(QuranSearchScreen.defaultDebounce);
    await tester.pumpAndSettle();
  }

  testWidgets('before searching: tips, nothing is stored', (tester) async {
    await tester.pumpQuran(QuranRoutes.search);
    expect(
      find.text("Try a word like 'mercy' or a surah name."),
      findsOneWidget,
    );
  });

  testWidgets('reference: first result is Go to 2:255', (tester) async {
    final router = await tester.pumpQuran(QuranRoutes.search);
    await type(tester, '2:255');
    final go = find.textContaining('Go to ');
    expect(
      Bidi.strip(tester.widget<Text>(go).data!),
      'Go to Placeholder 2 2:255',
    );
    await tester.tap(go);
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), '/quran/read/2?ayah=2255&mode=browse');
    expect(find.byType(QuranReaderScreen), findsOneWidget);
  });

  testWidgets('debounce 300 ms and minimum 2 characters', (tester) async {
    final quran = TestQuranRepository(hits: hits);
    await tester.pumpQuran(QuranRoutes.search, fakes: quranFakes(quran: quran));
    await tester.enterText(find.byType(TextField), 'z');
    await tester.pump(const Duration(seconds: 1));
    expect(quran.searches, 0);
    expect(find.textContaining('Try a word'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'ze');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), 'zep');
    await tester.pump(const Duration(milliseconds: 200));
    expect(quran.searches, 0);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(quran.searches, 1);
  });

  testWidgets('full text hits with highlighted match open the verse', (
    tester,
  ) async {
    final router = await tester.pumpQuran(
      QuranRoutes.search,
      fakes: withHits(),
    );
    await type(tester, 'zephyr');
    expect(find.text('Verses'), findsOneWidget);
    final rich = tester.widget<RichText>(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText() == 'before zephyr after',
      ),
    );
    final spans = <TextSpan>[];
    rich.text.visitChildren((s) {
      if (s is TextSpan && s.text != null) spans.add(s);
      return true;
    });
    expect(spans.map((s) => s.text), ['before ', 'zephyr', ' after']);
    expect(spans[1].style?.fontWeight, FontWeight.w600);
    await tester.tap(find.textContaining('before'));
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), '/quran/read/2?ayah=2255&mode=browse');
  });

  testWidgets('arabic query renders snippets via SkArabicText', (tester) async {
    await tester.pumpQuran(QuranRoutes.search, fakes: withHits());
    // Arabske pismena len cez kody znakov (ziadny literal v zdrojaku).
    await type(tester, String.fromCharCodes([0x628, 0x633, 0x645]));
    final segments = quranSegments(tester);
    expect(segments, hasLength(2));
    expect(segments.first, ['before ', 'zephyr', ' after']);
  });

  testWidgets('surah names are found by transliteration', (tester) async {
    final router = await tester.pumpQuran(QuranRoutes.search);
    await type(tester, 'placeholder');
    expect(find.text('Placeholder 2'), findsOneWidget);
    await tester.tap(find.text('Placeholder 2'));
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), '/quran/read/2?mode=browse');
  });

  testWidgets('no results: EMPTY-SEARCH', (tester) async {
    await tester.pumpQuran(QuranRoutes.search);
    await type(tester, 'none');
    expect(find.text('No results for "none"'), findsOneWidget);
    expect(
      find.text('Try another word, a surah name or a number like 2:255.'),
      findsOneWidget,
    );
  });

  testWidgets('error: E-SEARCH-1 with retry', (tester) async {
    final quran = TestQuranRepository(hits: hits)
      ..searchError = StateError('fts');
    await tester.pumpQuran(QuranRoutes.search, fakes: quranFakes(quran: quran));
    await type(tester, 'zephyr');
    expect(find.text("Search isn't working right now"), findsOneWidget);
    quran.searchError = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Verses'), findsOneWidget);
  });

  testWidgets('q from the route is used and clear resets', (tester) async {
    await tester.pumpQuran(QuranRoutes.searchFor('2:255'));
    expect(find.textContaining('Go to '), findsOneWidget);
    await tester.tap(find.byTooltip('Clear'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Try a word'), findsOneWidget);
  });

  test('q is cut to 100 characters (docs/02 C2)', () {
    expect(QuranRoutes.parseQuery('x' * 150), hasLength(100));
    expect(QuranRoutes.parseQuery(null), '');
    expect(QuranRoutes.searchFor(''), '/quran/search');
  });

  testWidgets('semantics and tap targets', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpQuran(QuranRoutes.search, fakes: withHits());
    await type(tester, 'zephyr');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  for (final locale in fullGoldenLocales) {
    testWidgets('${locale.languageCode}: textScale 2.0 without clipping', (
      tester,
    ) async {
      await tester.pumpQuran(
        QuranRoutes.searchFor('placeholder'),
        fakes: withHits(),
        locale: locale,
        textScale: 2,
      );
      expectNoTextClipping(tester);
    });
  }
}
