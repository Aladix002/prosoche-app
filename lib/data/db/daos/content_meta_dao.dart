import 'package:drift/drift.dart';
import 'package:prosoche/data/db/content_db.dart';

part 'content_meta_dao.g.dart';

/// `meta` a `source` (Zdroje a licencie) a kontrolne pocty pre integritu.
@DriftAccessor(tables: [ContentMeta, Sources, Sections, Cards])
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

  /// Pocet kariet (integrita: prazdna db sa neprijme).
  Future<int> cardCount() => _count(cards, cards.id);

  /// Pocet sekcii.
  Future<int> sectionCount() => _count(sections, sections.id);

  Future<int> _count(
    TableInfo<Table, Object?> table,
    Expression<Object> col,
  ) async {
    final c = col.count();
    final row = await (selectOnly(table)..addColumns([c])).getSingle();
    return row.read<int>(c)!;
  }

  /// `(key, sha256, text)` vsetkych sekcii v poradi `section.id` (kontrola
  /// `meta.sections_sha256`, kontrakt kap. 2).
  Future<List<(String, String, String)>> sectionHashes() async => [
    for (final r in await (select(
      sections,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get())
      (r.key, r.sha256, r.textContent),
  ];
}
