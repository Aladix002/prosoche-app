import 'package:drift/drift.dart';
import 'package:prosoche/data/db/user_db.dart';

part 'reading_dao.g.dart';

/// Pozicia citania, precitane versy a khatm (docs/02 D6, D7; A5.1, A5.2,
/// A8.1, B11, B12).
@DriftAccessor(tables: [ReadingPositions, AyahReads, KhatmLogs])
class ReadingDao extends DatabaseAccessor<UserDb> with _$ReadingDaoMixin {
  ReadingDao(super.attachedDatabase);

  SimpleSelectStatement<$ReadingPositionsTable, ReadingPositionRow> get _pos =>
      select(readingPositions)..where((t) => t.id.equals(1));

  /// Posledny precitany vers v khatm poradi; `0` = pred 1:1.
  Future<int> readingPosition() async =>
      (await _pos.getSingleOrNull())?.ayahId ?? 0;

  Stream<int> watchReadingPosition() =>
      _pos.watchSingleOrNull().map((r) => r?.ayahId ?? 0);

  Future<void> setReadingPosition(int ayahId, DateTime now) =>
      into(readingPositions).insertOnConflictUpdate(
        ReadingPositionsCompanion.insert(
          id: const Value(1),
          ayahId: Value(ayahId),
          updatedAt: now,
        ),
      );

  /// Pocet precitanych versov podla sury (`surah` -> pocet), mapa sur a
  /// progres sur v A5.1 a A8.1.
  Future<Map<int, int>> readCountsBySurah() =>
      _readCounts().get().then((rows) => {for (final r in rows) r.$1: r.$2});

  Stream<Map<int, int>> watchReadCountsBySurah() =>
      _readCounts().watch().map((rows) => {for (final r in rows) r.$1: r.$2});

  Selectable<(int, int)> _readCounts() => customSelect(
    'SELECT ayah_id / 1000 AS surah, COUNT(*) AS n FROM ayah_read '
    'GROUP BY surah ORDER BY surah',
    readsFrom: {ayahReads},
  ).map((r) => (r.read<int>('surah'), r.read<int>('n')));

  Future<bool> isAyahRead(int ayahId) async =>
      await (select(
        ayahReads,
      )..where((t) => t.ayahId.equals(ayahId))).getSingleOrNull() !=
      null;

  // ---------------------------------------------------------------- khatm
  /// Rozpracovany khatm (bez `completed_at`), ak existuje.
  Future<KhatmLogRow?> currentKhatm() =>
      (select(khatmLogs)
            ..where((t) => t.completedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.n)])
            ..limit(1))
          .getSingleOrNull();

  /// Zacne novy khatm (n = posledne + 1), ak ziadny nebezi. Vrati
  /// rozpracovany khatm.
  Future<KhatmLogRow> startKhatmIfNone(DateTime now) => transaction(() async {
    final open = await currentKhatm();
    if (open != null) return open;
    final next = (await completedKhatmCount()) + 1;
    return await into(khatmLogs).insertReturning(
      KhatmLogsCompanion.insert(n: Value(next), startedAt: now),
    );
  });

  /// Dokonci rozpracovany khatm (po 114:6) a nastavi poziciu na 0 (D7).
  /// Vrati cislo dokonceneho khatmu.
  Future<int> completeKhatm(DateTime now) => transaction(() async {
    final open = await startKhatmIfNone(now);
    await (update(khatmLogs)..where((t) => t.n.equals(open.n))).write(
      KhatmLogsCompanion(completedAt: Value(now)),
    );
    await setReadingPosition(0, now);
    return open.n;
  });

  Future<int> completedKhatmCount() async {
    final c = khatmLogs.n.count();
    return (await (selectOnly(khatmLogs)
              ..addColumns([c])
              ..where(khatmLogs.completedAt.isNotNull()))
            .getSingle())
        .read<int>(c)!;
  }

  Future<List<KhatmLogRow>> khatmHistory() =>
      (select(khatmLogs)..orderBy([(t) => OrderingTerm.asc(t.n)])).get();
}
