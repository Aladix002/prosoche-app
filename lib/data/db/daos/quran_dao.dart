import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:prosoche/data/db/content_db.dart';

part 'quran_dao.g.dart';

/// Vysledok fulltextu (A5.4). [snippet] ma zhodu medzi
/// [matchStart] a [matchEnd].
@immutable
class SearchHit {
  const SearchHit({required this.ayahId, required this.snippet});

  /// Znacky zhody v [snippet] (Unicode private use, v texte sa nevyskytuju).
  static const matchStart = '\u{E000}';
  static const matchEnd = '\u{E001}';

  final int ayahId;
  final String snippet;

  @override
  bool operator ==(Object other) =>
      other is SearchHit && other.ayahId == ayahId && other.snippet == snippet;

  @override
  int get hashCode => Object.hash(ayahId, snippet);

  @override
  String toString() => 'SearchHit($ayahId, $snippet)';
}

/// Zaciatok juz (A5.1, zalozka Juz).
typedef JuzStart = ({int juz, int firstAyahId});

/// Prevedie vstup pouzivatela na bezpecny FTS5 dotaz: kazde slovo v
/// uvodzovkach (operatory sa neinterpretuju), posledne ako prefix.
/// Prazdny vstup = null.
@visibleForTesting
String? ftsQuery(String input) {
  final tokens = input
      .replaceAll('"', ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return null;
  final quoted = [for (final t in tokens) '"$t"'];
  quoted[quoted.length - 1] = '${quoted.last}*';
  return quoted.join(' ');
}

/// Koran: sury, versy, preklady, vyhladavanie (A5, B2, B11, plan 7.1).
@DriftAccessor(tables: [Surahs, SurahTexts, Ayahs, Translations])
class QuranDao extends DatabaseAccessor<ContentDb> with _$QuranDaoMixin {
  QuranDao(super.attachedDatabase);

  Future<List<SurahRow>> allSurahs() =>
      (select(surahs)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

  Future<SurahRow?> surah(int id) =>
      (select(surahs)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Preklady nazvov sur pre [lang] (`surah_id` -> `name_meaning`, D4).
  Future<Map<int, String>> surahNameMeanings(String lang) async => {
    for (final r in await (select(
      surahTexts,
    )..where((t) => t.lang.equals(lang))).get())
      r.surahId: r.nameMeaning,
  };

  Future<AyahRow?> ayah(int id) =>
      (select(ayahs)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Versy sury v poradi (A5.2).
  Future<List<AyahRow>> ayahsOfSurah(int surahId) =>
      (select(ayahs)
            ..where((t) => t.surahId.equals(surahId))
            ..orderBy([(t) => OrderingTerm.asc(t.number)]))
          .get();

  /// Versy podla ID, zoradene podla `id` (karty dennej sady).
  Future<List<AyahRow>> ayahsByIds(Iterable<int> ids) =>
      (select(ayahs)
            ..where((t) => t.id.isIn(ids))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  /// [limit] versov po [afterAyahId] v poradi citania (volne citanie v
  /// brane B11, FeedGenerator). `0` = od 1:1. Bez pretocenia za 114:6.
  Future<List<AyahRow>> ayahsAfter(int afterAyahId, int limit) =>
      (select(ayahs)
            ..where((t) => t.id.isBiggerThanValue(afterAyahId))
            ..orderBy([(t) => OrderingTerm.asc(t.id)])
            ..limit(limit))
          .get();

  /// Prvy vers kazdeho juz (A5.1).
  Future<List<JuzStart>> juzStarts() {
    final first = ayahs.id.min();
    return (selectOnly(ayahs)
          ..addColumns([ayahs.juz, first])
          ..groupBy([ayahs.juz])
          ..orderBy([OrderingTerm.asc(ayahs.juz)]))
        .map((r) => (juz: r.read(ayahs.juz)!, firstAyahId: r.read(first)!))
        .get();
  }

  /// Preklady [ayahIds] v [lang] zo zdroja [sourceId] (`ayah_id` -> riadok).
  /// Chybajuci preklad v mape nie je (fallback B0.6 riesi volajuci).
  Future<Map<int, TranslationRow>> translationsFor(
    Iterable<int> ayahIds, {
    required String lang,
    required String sourceId,
  }) async => {
    for (final r
        in await (select(translations)..where(
              (t) =>
                  t.ayahId.isIn(ayahIds) &
                  t.lang.equals(lang) &
                  t.sourceId.equals(sourceId),
            ))
            .get())
      r.ayahId: r,
  };

  /// Fulltext v arabskom texte (`ayah_fts` nad `text_simple`), max [limit].
  Future<List<SearchHit>> searchArabic(String input, {int limit = 50}) {
    final q = ftsQuery(input);
    if (q == null) return Future.value(const []);
    return customSelect(
      'SELECT rowid AS ayah_id, '
      "snippet(ayah_fts, 0, '${SearchHit.matchStart}', "
      "'${SearchHit.matchEnd}', '…', 16) AS snip "
      'FROM ayah_fts WHERE ayah_fts MATCH ? ORDER BY rank LIMIT ?',
      variables: [Variable.withString(q), Variable.withInt(limit)],
      readsFrom: {ayahs},
    ).map(_hit).get();
  }

  /// Fulltext v preklade ([lang], [sourceId]), max [limit] (A5.4).
  Future<List<SearchHit>> searchTranslation(
    String input, {
    required String lang,
    required String sourceId,
    int limit = 50,
  }) {
    final q = ftsQuery(input);
    if (q == null) return Future.value(const []);
    return customSelect(
      'SELECT t.ayah_id AS ayah_id, '
      "snippet(translation_fts, 0, '${SearchHit.matchStart}', "
      "'${SearchHit.matchEnd}', '…', 16) AS snip "
      'FROM translation_fts JOIN "translation" t '
      'ON t.id = translation_fts.rowid '
      'WHERE translation_fts MATCH ? AND t.lang = ? AND t.source_id = ? '
      'ORDER BY rank LIMIT ?',
      variables: [
        Variable.withString(q),
        Variable.withString(lang),
        Variable.withString(sourceId),
        Variable.withInt(limit),
      ],
      readsFrom: {translations},
    ).map(_hit).get();
  }

  static SearchHit _hit(QueryRow r) => SearchHit(
    ayahId: r.read<int>('ayah_id'),
    snippet: r.read<String>('snip'),
  );
}
