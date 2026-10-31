import 'package:drift/drift.dart';
import 'package:prosoche/data/db/content_db.dart';

part 'curated_dao.g.dart';

/// Stav kuratovaneho zaznamu, ktory appka nikdy nezobrazi.
const retiredStatus = 'retired';

/// Obsah kariet a sablony questov. Vyradene (`retired`) zaznamy sa
/// nevracaju v zoznamoch; politiku `origin`/`reviewed_by` strazi pipeline.
@DriftAccessor(tables: [Quotes, QuestTemplates, QuestTexts])
class CuratedDao extends DatabaseAccessor<ContentDb> with _$CuratedDaoMixin {
  CuratedDao(super.attachedDatabase);

  // --------------------------------------------------------------- citaty
  Future<QuoteRow?> quote(String id) =>
      (select(quotes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<QuoteRow>> activeQuotes() =>
      (select(quotes)
            ..where((t) => t.status.equals(retiredStatus).not())
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  // --------------------------------------------------------------- questy
  /// Aktivne sablony questov, volitelne pre [slot] (`read`/`learn`/`act`).
  Future<List<QuestTemplateRow>> activeQuestTemplates({String? slot}) {
    final q = select(questTemplates)
      ..where((t) => t.status.equals(retiredStatus).not())
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    if (slot != null) q.where((t) => t.slot.equals(slot));
    return q.get();
  }

  /// Texty questov [ids] v [lang] (`quest_id` -> riadok).
  Future<Map<String, QuestTextRow>> questTextsFor(
    Iterable<String> ids,
    String lang,
  ) async => {
    for (final r in await (select(
      questTexts,
    )..where((t) => t.questId.isIn(ids) & t.lang.equals(lang))).get())
      r.questId: r,
  };
}
