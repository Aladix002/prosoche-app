import 'package:drift/drift.dart';
import 'package:sakina/data/db/content_db.dart';

part 'content_meta_dao.g.dart';

/// `meta` a `source` (Zdroje a licencie A11, vyber prekladu A10.5, O1).
@DriftAccessor(tables: [ContentMeta, Sources, Ayahs])
class ContentMetaDao extends DatabaseAccessor<ContentDb>
    with _$ContentMetaDaoMixin {
  ContentMetaDao(super.attachedDatabase);

  Future<Map<String, String>> allMeta() async => {
    for (final r in await select(contentMeta).get()) r.key: r.value,
  };

  Future<String?> metaValue(String key) async => (await (select(
    contentMeta,
  )..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<List<SourceRow>> allSources() =>
      (select(sources)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

  Future<SourceRow?> source(String id) =>
      (select(sources)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Zdroje prekladu Koranu pre [lang] (docs/02 D11, bez DISTINCT nad
  /// `translation`).
  Future<List<SourceRow>> translationSources(String lang) =>
      (select(sources)
            ..where((t) => t.kind.equals('translation') & t.lang.equals(lang))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  /// Pocet versov (integrita, plan 17.3).
  Future<int> ayahCount() async {
    final c = ayahs.id.count();
    final row = await (selectOnly(ayahs)..addColumns([c])).getSingle();
    return row.read<int>(c)!;
  }

  /// `text_uthmani` vsetkych versov podla `id` (vstup hashu integrity).
  Future<List<String>> uthmaniTextsInOrder() =>
      (selectOnly(ayahs)
            ..addColumns([ayahs.textUthmani])
            ..orderBy([OrderingTerm.asc(ayahs.id)]))
          .map((r) => r.read(ayahs.textUthmani)!)
          .get();
}
