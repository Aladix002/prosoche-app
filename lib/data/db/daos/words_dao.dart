import 'package:drift/drift.dart';
import 'package:prosoche/data/db/content_db.dart';

part 'words_dao.g.dart';

/// Slova a lemy (A5.3, A6, B3, B4). Tabulky su vo v1 prazdne
/// (`meta.words_enabled = 0`), dotazy vtedy vracaju prazdne vysledky.
@DriftAccessor(tables: [Words, WordMeanings, Lemmas, LemmaMeanings])
class WordsDao extends DatabaseAccessor<ContentDb> with _$WordsDaoMixin {
  WordsDao(super.attachedDatabase);

  Future<List<WordRow>> wordsOfAyah(int ayahId) =>
      (select(words)
            ..where((t) => t.ayahId.equals(ayahId))
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();

  Future<WordRow?> word(int ayahId, int position) =>
      (select(words)..where(
            (t) => t.ayahId.equals(ayahId) & t.position.equals(position),
          ))
          .getSingleOrNull();

  Future<WordMeaningRow?> wordMeaning(int wordId, String lang) =>
      (select(wordMeanings)
            ..where((t) => t.wordId.equals(wordId) & t.lang.equals(lang)))
          .getSingleOrNull();

  Future<LemmaRow?> lemma(int id) =>
      (select(lemmas)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<LemmaRow>> lemmasByIds(Iterable<int> ids) =>
      (select(lemmas)
            ..where((t) => t.id.isIn(ids))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  /// Vyznamy lem [ids] v [lang] (`lemma_id` -> vyznam).
  Future<Map<int, String>> meaningsOfLemmas(
    Iterable<int> ids,
    String lang,
  ) async => {
    for (final r in await (select(
      lemmaMeanings,
    )..where((t) => t.lemmaId.isIn(ids) & t.lang.equals(lang))).get())
      r.lemmaId: r.meaning,
  };

  /// Vyskyty lemy (A6.3), max [limit], v poradi textu.
  Future<List<WordRow>> occurrences(int lemmaId, {int limit = 20}) =>
      (select(words)
            ..where((t) => t.lemmaId.equals(lemmaId))
            ..orderBy([(t) => OrderingTerm.asc(t.id)])
            ..limit(limit))
          .get();

  /// Sucet `frequency` lem [ids], alebo vsetkych pri null (pokrytie A6.1).
  Future<int> frequencySum([Iterable<int>? ids]) async {
    final sum = lemmas.frequency.sum();
    final q = selectOnly(lemmas)..addColumns([sum]);
    if (ids != null) q.where(lemmas.id.isIn(ids));
    return (await q.getSingle()).read<int>(sum) ?? 0;
  }
}
