import 'package:drift/drift.dart';
import 'package:prosoche/data/db/content_db.dart';

part 'content_meta_dao.g.dart';

/// `meta` a `source` (Zdroje a licencie A11).
@DriftAccessor(tables: [ContentMeta, Sources, Quotes])
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

  /// Pocet citatov (integrita: prazdna db sa neprijme).
  Future<int> quoteCount() async {
    final c = quotes.id.count();
    final row = await (selectOnly(quotes)..addColumns([c])).getSingle();
    return row.read<int>(c)!;
  }
}
