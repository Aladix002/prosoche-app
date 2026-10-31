import 'package:drift/drift.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/domain/common/common.dart';

part 'saved_card_dao.g.dart';

/// Ulozene karty (A8.3, B0, A5.2).
@DriftAccessor(tables: [SavedCards])
class SavedCardDao extends DatabaseAccessor<UserDb> with _$SavedCardDaoMixin {
  SavedCardDao(super.attachedDatabase);

  /// Ulozi kartu; opakovane ulozenie zachova povodny cas.
  Future<void> save(CardId card, DateTime now) => into(savedCards).insert(
    SavedCardsCompanion.insert(cardId: card.format(), savedAt: now),
    onConflict: DoNothing(),
  );

  Future<void> unsave(CardId card) =>
      (delete(savedCards)..where((t) => t.cardId.equals(card.format()))).go();

  Stream<bool> watchIsSaved(CardId card) =>
      (select(savedCards)..where((t) => t.cardId.equals(card.format())))
          .watchSingleOrNull()
          .map((r) => r != null);

  /// Ulozene karty, najnovsie prve, volitelne len typ [type] (filtre A8.3).
  Stream<List<SavedCardRow>> watchAll({CardType? type}) {
    final q = select(savedCards)
      ..orderBy([
        (t) => OrderingTerm.desc(t.savedAt),
        (t) => OrderingTerm.asc(t.cardId),
      ]);
    if (type != null) {
      q.where((t) => t.cardId.like('${type.wire}:%'));
    }
    return q.watch();
  }

  Stream<int> watchCount() {
    final c = savedCards.cardId.count();
    return (selectOnly(
      savedCards,
    )..addColumns([c])).map((r) => r.read(c)!).watchSingle();
  }
}
