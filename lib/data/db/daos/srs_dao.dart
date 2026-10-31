import 'package:drift/drift.dart';
import 'package:sakina/data/db/user_db.dart';

part 'srs_dao.g.dart';

/// SRS stav a historia (A6, B3, B4, 07 ADR-06).
@DriftAccessor(tables: [SrsItems, SrsReviews])
class SrsDao extends DatabaseAccessor<UserDb> with _$SrsDaoMixin {
  SrsDao(super.attachedDatabase);

  /// `interval_days`, od ktoreho je lema "Known" (A6.1).
  static const knownIntervalDays = 21;

  Future<SrsItemRow?> item(int lemmaId) => (select(
    srsItems,
  )..where((t) => t.lemmaId.equals(lemmaId))).getSingleOrNull();

  Stream<SrsItemRow?> watchItem(int lemmaId) => (select(
    srsItems,
  )..where((t) => t.lemmaId.equals(lemmaId))).watchSingleOrNull();

  /// Prida lemu v stave `new` (due = [now]), ak este nie je. Vrati `true`
  /// pri novom zazname.
  Future<bool> addIfAbsent(
    int lemmaId, {
    required SrsSource source,
    required DateTime now,
  }) async {
    final row = await into(srsItems).insertReturningOrNull(
      SrsItemsCompanion.insert(
        lemmaId: Value(lemmaId),
        state: SrsState.fresh,
        due: now,
        addedAt: now,
        source: source,
      ),
      onConflict: DoNothing(),
    );
    return row != null;
  }

  /// Ulozi novy stav po opakovani a zapise `srs_review` (jedna transakcia).
  Future<void> recordReview(SrsItemRow updated, SrsReviewsCompanion review) =>
      transaction(() async {
        await update(srsItems).replace(updated);
        await into(srsReviews).insert(review);
      });

  /// Reset progresu (A6.3): stav `new`, due = [now], bez historie.
  Future<void> reset(int lemmaId, DateTime now) =>
      (update(srsItems)..where((t) => t.lemmaId.equals(lemmaId))).write(
        SrsItemsCompanion(
          state: const Value(SrsState.fresh),
          easeFactor: const Value(2.5),
          intervalDays: const Value(0),
          reps: const Value(0),
          lapses: const Value(0),
          due: Value(now),
          lastReview: const Value(null),
        ),
      );

  Future<void> remove(int lemmaId) =>
      (delete(srsItems)..where((t) => t.lemmaId.equals(lemmaId))).go();

  /// Lemy na opakovanie k [now], najstarsie prve.
  Future<List<SrsItemRow>> dueItems(DateTime now, {int? limit}) {
    final q = select(srsItems)
      ..where((t) => t.due.isSmallerOrEqualValue(now.millisecondsSinceEpoch))
      ..orderBy([
        (t) => OrderingTerm.asc(t.due),
        (t) => OrderingTerm.asc(t.lemmaId),
      ]);
    if (limit != null) q.limit(limit);
    return q.get();
  }

  Stream<int> watchDueCount(DateTime now) {
    final c = srsItems.lemmaId.count();
    return (selectOnly(srsItems)
          ..addColumns([c])
          ..where(
            srsItems.due.isSmallerOrEqualValue(now.millisecondsSinceEpoch),
          ))
        .map((r) => r.read(c)!)
        .watchSingle();
  }

  /// Najblizsi buduci termin po [now] ("Next review in 5 h").
  Future<DateTime?> nextDueAfter(DateTime now) async {
    final min = srsItems.due.min();
    final raw =
        (await (selectOnly(srsItems)
                  ..addColumns([min])
                  ..where(
                    srsItems.due.isBiggerThanValue(now.millisecondsSinceEpoch),
                  ))
                .getSingle())
            .read(min);
    return raw == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
  }

  /// Pocty lem podla stavu (A6.1).
  Future<Map<SrsState, int>> countsByState() async {
    final c = srsItems.lemmaId.count();
    final q = selectOnly(srsItems)
      ..addColumns([srsItems.state, c])
      ..groupBy([srsItems.state]);
    return {
      for (final r in await q.get())
        r.readWithConverter(srsItems.state)!: r.read(c)!,
    };
  }

  /// Pocet "Known" lem: `review` a `interval_days >= 21` (A6.1).
  Future<int> knownCount() async {
    final c = srsItems.lemmaId.count();
    return (await (selectOnly(srsItems)
              ..addColumns([c])
              ..where(
                srsItems.state.equalsValue(SrsState.review) &
                    srsItems.intervalDays.isBiggerOrEqualValue(
                      knownIntervalDays,
                    ),
              ))
            .getSingle())
        .read<int>(c)!;
  }

  /// Vsetky lemy podla `due` (zoznam A6.1; texty doplni repozitar).
  Future<List<SrsItemRow>> allByDue() =>
      (select(srsItems)..orderBy([
            (t) => OrderingTerm.asc(t.due),
            (t) => OrderingTerm.asc(t.lemmaId),
          ]))
          .get();

  Future<List<SrsReviewRow>> reviews(int lemmaId) =>
      (select(srsReviews)
            ..where((t) => t.lemmaId.equals(lemmaId))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();
}
