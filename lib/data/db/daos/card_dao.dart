import 'package:drift/drift.dart';
import 'package:prosoche/data/db/content_db.dart';

part 'card_dao.g.dart';

/// Karty denneho feedu (`card`, kontrakt kap. 6).
@DriftAccessor(tables: [Cards])
class CardDao extends DatabaseAccessor<ContentDb> with _$CardDaoMixin {
  CardDao(super.attachedDatabase);

  /// Karta podla celeho `card.id` (napr. `quote:meditations.2.1.a`).
  Future<CardRow?> card(String id) =>
      (select(cards)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Vsetky karty v poradi typ, `ord`.
  Future<List<CardRow>> allCards() =>
      (select(cards)..orderBy([
            (t) => OrderingTerm.asc(t.type),
            (t) => OrderingTerm.asc(t.ord),
          ]))
          .get();

  /// Karty typu [type] v poradi `ord`.
  Future<List<CardRow>> ofType(String type) =>
      (select(cards)
            ..where((t) => t.type.equals(type))
            ..orderBy([(t) => OrderingTerm.asc(t.ord)]))
          .get();
}
