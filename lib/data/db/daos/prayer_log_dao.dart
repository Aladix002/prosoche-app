import 'package:drift/drift.dart';
import 'package:sakina/data/db/user_db.dart';
import 'package:sakina/domain/common/common.dart';

part 'prayer_log_dao.g.dart';

/// `prayer_log` a `fast_log` (A2 mini tracker, A7.1, A8.2, docs/02 D18).
@DriftAccessor(tables: [PrayerLogs, FastLogs])
class PrayerLogDao extends DatabaseAccessor<UserDb> with _$PrayerLogDaoMixin {
  PrayerLogDao(super.attachedDatabase);

  SimpleSelectStatement<$PrayerLogsTable, PrayerLogRow> _forDate(LocalDate d) =>
      select(prayerLogs)..where((t) => t.date.equalsValue(d));

  Future<List<PrayerLogRow>> forDate(LocalDate date) => _forDate(date).get();

  Stream<List<PrayerLogRow>> watchForDate(LocalDate date) =>
      _forDate(date).watch();

  Future<void> setStatus(
    LocalDate date,
    PrayerKind prayer,
    PrayerStatus status,
    DateTime ts,
  ) => into(prayerLogs).insertOnConflictUpdate(
    PrayerLogsCompanion.insert(
      date: date,
      prayer: prayer,
      status: status,
      ts: ts,
    ),
  );

  /// Zrusi zaznam modlitby (tap na oznacenu = spat na neoznacenu).
  Future<void> clear(LocalDate date, PrayerKind prayer) =>
      (delete(prayerLogs)..where(
            (t) => t.date.equalsValue(date) & t.prayer.equalsValue(prayer),
          ))
          .go();

  /// Zaznamy v rozsahu [from]..[to] vratane (kalendar Moja cesta).
  Future<List<PrayerLogRow>> range(LocalDate from, LocalDate to) =>
      (select(prayerLogs)
            ..where(
              (t) => t.date.isBetweenValues(from.toString(), to.toString()),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.date),
              (t) => OrderingTerm.asc(t.ts),
            ]))
          .get();

  // ------------------------------------------------------------- fast_log
  Future<void> setFast(LocalDate date, FastType type, String status) =>
      into(fastLogs).insertOnConflictUpdate(
        FastLogsCompanion.insert(date: date, type: type, status: status),
      );

  Future<FastLogRow?> fast(LocalDate date) => (select(
    fastLogs,
  )..where((t) => t.date.equalsValue(date))).getSingleOrNull();
}
