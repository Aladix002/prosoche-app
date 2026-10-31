import 'package:drift/drift.dart';
import 'package:sakina/data/db/user_db.dart';
import 'package:sakina/domain/common/common.dart';

part 'card_event_dao.g.dart';

/// `card_event` + udrzba `ayah_read` (docs/02 0.4, 0.5, D1, D6).
@DriftAccessor(tables: [CardEvents, AyahReads])
class CardEventDao extends DatabaseAccessor<UserDb> with _$CardEventDaoMixin {
  CardEventDao(super.attachedDatabase);

  /// Zapise udalost. `seen` je najviac raz za `(date, card_id, context)`
  /// (partial unique index); opakovany `seen` sa ignoruje a vrati `false`.
  /// Novy `seen` versa zvysi `ayah_read` v tej istej transakcii.
  Future<bool> log({
    required LocalDate date,
    required CardId card,
    required CardContext context,
    required CardAction action,
    required DateTime ts,
    int? pos,
    int? value,
    bool? correct,
  }) => transaction(() async {
    final row = await into(cardEvents).insertReturningOrNull(
      CardEventsCompanion.insert(
        date: date,
        cardId: card.format(),
        type: card.type,
        context: context,
        action: action,
        ts: ts,
        pos: Value(pos),
        value: Value(value),
        correct: Value(correct),
      ),
      // Prazdny target = akykolvek unikatny index, aj partial `seen`.
      onConflict: DoNothing(target: const []),
    );
    if (row == null) return false;
    if (action == CardAction.seen && card is AyahCardId) {
      await _markAyahRead(card.ayahId.value, ts);
    }
    return true;
  });

  Future<void> _markAyahRead(int ayahId, DateTime ts) => customInsert(
    'INSERT INTO ayah_read (ayah_id, first_read_at, read_count) '
    'VALUES (?1, ?2, 1) ON CONFLICT (ayah_id) '
    'DO UPDATE SET read_count = read_count + 1',
    variables: [
      Variable.withInt(ayahId),
      Variable.withInt(ts.millisecondsSinceEpoch),
    ],
    updates: {ayahReads},
  );

  /// Udalosti dna [date] v poradi zapisu (detail dna A8.2, QuestEngine).
  Future<List<CardEventRow>> forDate(LocalDate date) =>
      (select(cardEvents)
            ..where((t) => t.date.equalsValue(date))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  Expression<bool> _filter(
    $CardEventsTable t,
    LocalDate date,
    CardType? type,
    CardAction? action,
    CardContext? context,
  ) {
    var e = t.date.equalsValue(date);
    if (type != null) e &= t.type.equalsValue(type);
    if (action != null) e &= t.action.equalsValue(action);
    if (context != null) e &= t.context.equalsValue(context);
    return e;
  }

  /// Pocet roznych `card_id` dna s filtrom (READ quest: precitane versy
  /// zo vsetkych kontextov, LEARN: zodpovedane kvizy).
  Future<int> countDistinctCards(
    LocalDate date, {
    CardType? type,
    CardAction? action,
    CardContext? context,
  }) => _distinctCount(date, type, action, context).getSingle();

  /// Ako [countDistinctCards], ako stream (progres questov na Dnes).
  Stream<int> watchCountDistinctCards(
    LocalDate date, {
    CardType? type,
    CardAction? action,
    CardContext? context,
  }) => _distinctCount(date, type, action, context).watchSingle();

  Selectable<int> _distinctCount(
    LocalDate date,
    CardType? type,
    CardAction? action,
    CardContext? context,
  ) {
    final c = cardEvents.cardId.count(distinct: true);
    return (selectOnly(cardEvents)
          ..addColumns([c])
          ..where(_filter(cardEvents, date, type, action, context)))
        .map((r) => r.read(c)!);
  }

  /// `card_id` kariet dna s danou akciou (napr. uz videne v brane).
  Future<Set<String>> cardIds(
    LocalDate date, {
    required CardAction action,
    CardContext? context,
  }) async {
    final q = selectOnly(cardEvents, distinct: true)
      ..addColumns([cardEvents.cardId])
      ..where(_filter(cardEvents, date, null, action, context));
    return {for (final r in await q.get()) r.read(cardEvents.cardId)!};
  }

  /// Poslednych [limit] udalosti kariet s prefixom [cardIdPrefix]
  /// (napr. `quiz:1043:` pre historiu lemy A6.3), najnovsie prve.
  Future<List<CardEventRow>> recentByPrefix(
    String cardIdPrefix, {
    int limit = 10,
  }) {
    final escaped = cardIdPrefix.replaceAllMapped(
      RegExp(r'[\\%_]'),
      (m) => '\\${m[0]}',
    );
    return (select(cardEvents)
          ..where((t) => t.cardId.like('$escaped%', escapeChar: r'\'))
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(limit))
        .get();
  }
}
