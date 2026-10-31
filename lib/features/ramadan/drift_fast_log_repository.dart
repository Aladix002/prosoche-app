import 'package:drift/drift.dart';
import 'package:sakina/data/db/user_db.dart';
import 'package:sakina/domain/common/local_date.dart';
import 'package:sakina/domain/ramadan/fast_log.dart';

/// [FastLogRepository] nad tabulkou `fast_log` (D-01), `type = ramadan`.
///
/// Patri F-08; po merge ho moze D-02 presunut do `lib/data/repositories/`.
class DriftFastLogRepository implements FastLogRepository {
  DriftFastLogRepository(this._db);

  final UserDb _db;

  @override
  Stream<FastEntry?> watch(LocalDate date) {
    final q = _db.select(_db.fastLogs)
      ..where((t) => t.date.equalsValue(date) & _ramadan(t));
    return q.watchSingleOrNull().map((r) => FastEntry.tryParse(r?.status));
  }

  @override
  Future<void> set(LocalDate date, FastEntry? entry) async {
    if (entry == null) {
      await (_db.delete(
        _db.fastLogs,
      )..where((t) => t.date.equalsValue(date) & _ramadan(t))).go();
      return;
    }
    await _db
        .into(_db.fastLogs)
        .insertOnConflictUpdate(
          FastLogsCompanion.insert(
            date: date,
            type: FastType.ramadan,
            status: entry.wire,
          ),
        );
  }

  static Expression<bool> _ramadan($FastLogsTable t) =>
      t.type.equalsValue(FastType.ramadan);
}
