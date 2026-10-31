@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/features/quran/reader/quran_reader_screen.dart';
import 'package:prosoche/features/quran/widgets/ayah_tile.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/theme/prosoche_theme.dart';

import '../../../fakes/fake_repositories.dart';
import '../../../helpers/golden/golden.dart';
import '../full_db.dart';
import '../quran_test_helpers.dart';

/// F-04 DoD nad plnou content.db: goldeny sury 1, 2:255, 18:1-10 a
/// 112-114 s prekladom v kazdom zo 6 jazykov (AR bez prekladu, BN s EN
/// fallbackom, kym pipeline nema BN preklad) a widget test, ze zobrazeny
/// text je bajtovo `ayah.text_uthmani`. Text ide len z db, ziadny literal.
///
///   PROSOCHE_CONTENT_DB=../prosoche-content/dist/content.db flutter test --update-goldens \
///     test/features/quran/full_db
void main() {
  final path = fullContentDbPath();
  if (path == null) {
    test('full content.db goldens', () {}, skip: fullDbSkip);
    return;
  }

  const surahs = [1, 2, 18, 112, 113, 114];
  final data = <String, _Preloaded>{};
  final expected = <int, String>{};

  setUpAll(() async {
    final q = openFullQuran(path);
    for (final locale in ProsocheLocales.all) {
      final lang = locale.languageCode;
      data[lang] = await _Preloaded.load(q.repo, lang, surahs);
    }
    for (final s in surahs) {
      for (final a in await q.repo.ayahsOfSurah(s, lang: 'ar')) {
        expected[a.id.value] = a.textUthmani;
      }
    }
    await q.content.close();
    await q.user.close();
  });

  ThemeData theme(Brightness b) =>
      b == Brightness.dark ? ProsocheTheme.dark() : ProsocheTheme.light();

  Widget scope(BuildContext context, Widget child) => ProviderScope(
    overrides:
        FakeRepositories(
          quran: data[Localizations.localeOf(context).languageCode],
        ).overrides(
          now: DateTime(2026, 10, 29, 9),
          deviceLanguage: Localizations.localeOf(context).languageCode,
        ),
    child: child,
  );

  goldenAllLocales(
    'full db surah 1',
    fileName: 'full_db_surah_1',
    theme: theme,
    constraints: const BoxConstraints.tightFor(width: 360, height: 1600),
    builder: (context) => scope(context, const QuranReaderScreen(surah: 1)),
  );

  goldenAllLocales(
    'full db 2:255',
    fileName: 'full_db_2_255',
    theme: theme,
    constraints: const BoxConstraints.tightFor(width: 360, height: 900),
    builder: (context) =>
        scope(context, const QuranReaderScreen(surah: 2, ayahId: 2255)),
  );

  goldenAllLocales(
    'full db 18:1-10',
    fileName: 'full_db_18_1_10',
    theme: theme,
    textScales: const [1.0],
    constraints: const BoxConstraints.tightFor(width: 360, height: 4400),
    builder: (context) => scope(context, const QuranReaderScreen(surah: 18)),
  );

  goldenAllLocales(
    'full db 112-114',
    fileName: 'full_db_112_114',
    theme: theme,
    constraints: const BoxConstraints.tightFor(width: 360, height: 3300),
    builder: (context) => scope(
      context,
      Column(
        children: [
          for (final s in [112, 113, 114])
            SizedBox(height: 1100, child: QuranReaderScreen(surah: s)),
        ],
      ),
    ),
  );

  group('displayed text is ayah.text_uthmani byte for byte', () {
    for (final (lang, location, size) in [
      ('en', '/quran/read/1', const Size(360, 3000)),
      ('ar', '/quran/read/1', const Size(360, 3000)),
      ('ur', '/quran/read/2?ayah=2255', const Size(360, 1200)),
      ('bn', '/quran/read/18', const Size(360, 6000)),
      ('en', '/quran/read/112', const Size(360, 2000)),
      ('ar', '/quran/read/114', const Size(360, 2000)),
    ]) {
      testWidgets('$lang $location', (tester) async {
        await tester.pumpQuran(
          location,
          fakes: FakeRepositories(quran: data[lang]),
          locale: Locale(lang),
          size: size,
        );
        final tiles = find.byWidgetPredicate(
          (w) => w is AyahTile && w.key is ValueKey<int>,
        );
        expect(tiles, findsWidgets);
        for (final e in tiles.evaluate()) {
          final id = (e.widget.key! as ValueKey<int>).value;
          final segments = quranSegments(
            tester,
            within: find.byKey(ValueKey(id)),
          );
          expect(segments.single.first.codeUnits, expected[id]!.codeUnits);
        }
      });
    }
  });
}

/// Data plnej db prednacitane mimo `testWidgets` (FakeAsync zona).
class _Preloaded extends FakeQuranRepository {
  _Preloaded(this._surahs, this._ayahs, this._sources);

  static Future<_Preloaded> load(
    QuranRepository repo,
    String lang,
    List<int> ids,
  ) async => _Preloaded(
    await repo.surahs(lang),
    {for (final s in ids) s: await repo.ayahsOfSurah(s, lang: lang)},
    {
      for (final l in {lang, 'en'}) l: await repo.translationSources(l),
    },
  );

  final List<SurahInfo> _surahs;
  final Map<int, List<AyahView>> _ayahs;
  final Map<String, List<TranslationSource>> _sources;

  @override
  Future<List<SurahInfo>> surahs(String lang) async => _surahs;

  @override
  Future<SurahInfo?> surah(int id, String lang) async =>
      _surahs.where((s) => s.id == id).firstOrNull;

  @override
  Future<List<AyahView>> ayahsOfSurah(
    int surahId, {
    required String lang,
  }) async => _ayahs[surahId] ?? const [];

  @override
  Future<List<TranslationSource>> translationSources(String lang) async =>
      _sources[lang] ?? const [];

  @override
  Future<TranslationSource?> selectedTranslation(String lang) async =>
      (_sources[lang] ?? const []).firstOrNull;
}
