import 'package:drift/drift.dart';
import 'package:sakina/data/db/content_db.dart';

part 'curated_dao.g.dart';

/// Stav kuratovaneho zaznamu, ktory appka nikdy nezobrazi.
const retiredStatus = 'retired';

/// Kuratovany obsah: dua, mena Allaha, zamyslenia, questy, eventy, uvodne
/// karty (B1, B6-B9, plan 7.2, 7.5). Vyradene (`retired`) zaznamy sa
/// nevracaju v zoznamoch; politiku `origin`/`reviewed_by` strazi pipeline.
@DriftAccessor(
  tables: [
    Duas,
    DuaTexts,
    NamesOfAllah,
    NameTexts,
    Reflections,
    ReflectionTexts,
    QuestTemplates,
    QuestTexts,
    IslamicEvents,
    IslamicEventTexts,
    IntroCards,
    IntroCardTexts,
  ],
)
class CuratedDao extends DatabaseAccessor<ContentDb> with _$CuratedDaoMixin {
  CuratedDao(super.attachedDatabase);

  // ---------------------------------------------------------------- dua
  Future<DuaRow?> dua(String id) =>
      (select(duas)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<DuaTextRow?> duaText(String id, String lang) => (select(
    duaTexts,
  )..where((t) => t.duaId.equals(id) & t.lang.equals(lang))).getSingleOrNull();

  /// ID dua pre cas dna [timeOfDay] (`morning`/`evening`); vzdy aj `any`.
  Future<List<String>> duaIds({String? timeOfDay}) {
    final q = selectOnly(duas)
      ..addColumns([duas.id])
      ..orderBy([OrderingTerm.asc(duas.id)]);
    if (timeOfDay != null) {
      q.where(duas.timeOfDay.isIn([timeOfDay, 'any']));
    }
    return q.map((r) => r.read(duas.id)!).get();
  }

  // ---------------------------------------------------------- mena Allaha
  Future<NameOfAllahRow?> nameOfAllah(int id) =>
      (select(namesOfAllah)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<NameTextRow?> nameText(int id, String lang) => (select(
    nameTexts,
  )..where((t) => t.nameId.equals(id) & t.lang.equals(lang))).getSingleOrNull();

  // ---------------------------------------------------------- zamyslenia
  Future<ReflectionRow?> reflection(String id) =>
      (select(reflections)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<ReflectionTextRow?> reflectionText(String id, String lang) =>
      (select(reflectionTexts)
            ..where((t) => t.reflectionId.equals(id) & t.lang.equals(lang)))
          .getSingleOrNull();

  Future<List<ReflectionRow>> activeReflections() =>
      (select(reflections)
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

  // --------------------------------------------------------------- eventy
  Future<List<IslamicEventRow>> activeIslamicEvents() =>
      (select(islamicEvents)
            ..where((t) => t.status.equals(retiredStatus).not())
            ..orderBy([
              (t) => OrderingTerm.desc(t.priority),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .get();

  /// Texty eventov v [lang] (`event_id` -> riadok), kalendar A9.
  Future<Map<String, IslamicEventTextRow>> eventTextsFor(String lang) async => {
    for (final r in await (select(
      islamicEventTexts,
    )..where((t) => t.lang.equals(lang))).get())
      r.eventId: r,
  };

  // -------------------------------------------------------- uvodne karty
  /// Aktivne uvodne karty, volitelne len pre [eventId].
  Future<List<IntroCardRow>> activeIntroCards({String? eventId}) {
    final q = select(introCards)
      ..where((t) => t.status.equals(retiredStatus).not())
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    if (eventId != null) q.where((t) => t.eventId.equals(eventId));
    return q.get();
  }

  Future<IntroCardTextRow?> introCardText(String id, String lang) =>
      (select(introCardTexts)
            ..where((t) => t.introId.equals(id) & t.lang.equals(lang)))
          .getSingleOrNull();
}
