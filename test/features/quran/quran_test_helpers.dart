// Spolocne pomocky pre testy obrazoviek Koranu (F-04). Obsah je len
// placeholder z fakes (PLAN_VYVOJA 5.5).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/app.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/core/router/navigator_keys.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/features/quran/quran_routes.dart';
import 'package:prosoche/ui/ui.dart';

import '../../fakes/fake_repositories.dart';

/// [FakeQuranRepository] s ovladatelnymi stavmi: chyba, nekonciace
/// nacitanie, progres sur, sajda, poznamky a vysledky vyhladavania.
class TestQuranRepository extends FakeQuranRepository {
  TestQuranRepository({
    this.surahCount = 2,
    this.sajda = const {},
    this.footnotes = const {},
    this.translations = const {},
    this.noTranslation = const {},
    this.hits = const [],
    this.sources,
  });

  /// Kolko sur vrati `surahs` (fake ma placeholder pre 1..114).
  final int surahCount;
  final Set<AyahId> sajda;
  final Map<AyahId, String> footnotes;

  /// Text prekladu namiesto placeholdera fake (napr. so znackami `[n]`).
  final Map<AyahId, String> translations;

  /// Zdroje prekladu namiesto [FakeQuranRepository.sources].
  final List<TranslationSource>? sources;
  final Set<AyahId> noTranslation;
  final List<SearchHit> hits;

  Error? error;
  Completer<void>? hold;
  Error? searchError;
  final counts = StreamController<Map<int, int>>.broadcast();
  Map<int, int> readCounts = const {};
  int searches = 0;

  Future<void> _gate() async {
    if (hold case final h?) await h.future;
    if (error case final e?) throw e;
  }

  @override
  Future<List<SurahInfo>> surahs(String lang) async {
    await _gate();
    return [for (var i = 1; i <= surahCount; i++) (await surah(i, lang))!];
  }

  @override
  Future<SurahInfo?> surah(int id, String lang) async {
    await _gate();
    final s = await super.surah(id, lang);
    if (s == null) return null;
    return SurahInfo(
      id: s.id,
      nameAr: s.nameAr,
      nameTranslit: s.nameTranslit,
      nameMeaning: s.nameMeaning,
      revelationPlace: id.isEven ? 'medinan' : 'meccan',
      ayahCount: s.ayahCount,
      bismillahPre: s.bismillahPre,
      bismillahUthmani: s.bismillahPre ? '[PLACEHOLDER bismillah]' : null,
    );
  }

  @override
  Future<List<JuzStart>> juzStarts() async {
    await _gate();
    return [(juz: 1, firstAyahId: 1001), (juz: 2, firstAyahId: 2142)];
  }

  @override
  Future<List<AyahView>> ayahsOfSurah(
    int surahId, {
    required String lang,
  }) async {
    await _gate();
    return [
      for (final a in await super.ayahsOfSurah(surahId, lang: lang))
        AyahView(
          id: a.id,
          textUthmani: a.textUthmani,
          juz: a.id.value >= 2142 ? 2 : 1,
          page: a.number ~/ 5 + 1,
          sajda: sajda.contains(a.id) ? 'recommended' : null,
          translation: noTranslation.contains(a.id) || a.translation == null
              ? null
              : TranslationText(
                  text: translations[a.id] ?? a.translation!.text,
                  sourceId: a.translation!.sourceId,
                  lang: a.translation!.lang,
                  isFallback: a.translation!.isFallback,
                  footnotes: footnotes[a.id],
                ),
        ),
    ];
  }

  @override
  Future<List<TranslationSource>> translationSources(String lang) async =>
      lang == 'en' && sources != null
      ? sources!
      : await super.translationSources(lang);

  @override
  Stream<Map<int, int>> watchReadCounts() async* {
    yield readCounts;
    yield* counts.stream;
  }

  @override
  Future<QuranSearchResult> search(String query, {required String lang}) async {
    searches++;
    if (searchError case final e?) throw e;
    final base = await super.search(query, lang: lang);
    if (base.reference != null) return base;
    final q = query.trim().toLowerCase();
    if (q.startsWith('place')) {
      return QuranSearchResult(
        surahs: [(await surah(1, lang))!, (await surah(2, lang))!],
        hits: hits,
      );
    }
    return QuranSearchResult(hits: q == 'none' ? const [] : hits);
  }
}

/// Fake repozitare s [quran] (jazyk zariadenia urci `pumpQuran`).
FakeRepositories quranFakes({TestQuranRepository? quran}) =>
    FakeRepositories(quran: quran ?? TestQuranRepository());

/// Router s routami Koranu (reader na root navigatore ako v appke).
GoRouter quranTestRouter(String location) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: location,
  routes: quranRoutes(),
);

extension PumpQuran on WidgetTester {
  /// Napumpuje routy Koranu na [location] v jazyku [locale] s fakes.
  Future<GoRouter> pumpQuran(
    String location, {
    FakeRepositories? fakes,
    Locale locale = const Locale('en'),
    double textScale = 1,
    Brightness brightness = Brightness.light,
    Size size = const Size(360, 800),
    bool settle = true,
  }) async {
    final router = quranTestRouter(location);
    addTearDown(router.dispose);
    final f = fakes ?? quranFakes();
    view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(view.reset);
    await pumpWidget(
      ProviderScope(
        overrides: f.overrides(
          now: DateTime(2026, 10, 29, 9),
          deviceLanguage: locale.languageCode,
        ),
        retry: (_, _) => null,
        child: MaterialApp.router(
          routerConfig: router,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: Theme(
              data: prosocheAppTheme(
                brightness: brightness,
                locale: Localizations.localeOf(context),
              ),
              child: SkTextScaling(
                child: SkUiStringsScope(
                  strings: skUiStringsOf(context.l10n),
                  child: child!,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (settle) await pumpAndSettle();
    return router;
  }
}

/// Segmenty (`TextSpan` deti) kazdeho `SkArabicText.quran` v [within].
List<List<String>> quranSegments(WidgetTester tester, {Finder? within}) => [
  for (final e
      in find
          .descendant(
            of: within ?? find.byWidgetPredicate((w) => w is SkArabicText),
            matching: find.byType(RichText),
          )
          .evaluate())
    if (e.findAncestorWidgetOfExactType<SkArabicText>()?.isQuran ?? false)
      _segmentsOf((e.widget as RichText).text),
];

/// Styl textu versa (vnutorny `TextSpan` so segmentmi) v [within].
TextStyle quranTextStyle(WidgetTester tester, Finder within) {
  final e = find
      .descendant(of: within, matching: find.byType(RichText))
      .evaluate()
      .firstWhere(
        (e) =>
            e.findAncestorWidgetOfExactType<SkArabicText>()?.isQuran ?? false,
      );
  return (_innermost((e.widget as RichText).text) as TextSpan).style!;
}

InlineSpan _innermost(InlineSpan root) {
  var span = root;
  while (span is TextSpan &&
      span.text == null &&
      span.children != null &&
      span.children!.length == 1) {
    span = span.children!.single;
  }
  return span;
}

List<String> _segmentsOf(InlineSpan root) {
  var span = root;
  // Text.rich obali TextSpan do dalsieho so stylom DefaultTextStyle.
  while (span is TextSpan &&
      span.text == null &&
      span.children != null &&
      span.children!.length == 1) {
    span = span.children!.single;
  }
  return switch (span) {
    TextSpan(:final children?) => [
      for (final c in children) c.toPlainText(includeSemanticsLabels: false),
    ],
    _ => [span.toPlainText(includeSemanticsLabels: false)],
  };
}

/// Prvy segment kazdeho `SkArabicText.quran`: text versa bez koncoveho
/// znaku, resp. bismillah.
List<String> displayedQuranTexts(WidgetTester tester) => [
  for (final s in quranSegments(tester)) s.first,
];
