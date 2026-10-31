import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/data/db/user_db.dart';
import 'package:sakina/domain/common/local_date.dart';
import 'package:sakina/domain/ramadan/fast_log.dart';
import 'package:sakina/features/ramadan/drift_fast_log_repository.dart';

void main() {
  late UserDb db;
  late DriftFastLogRepository repo;
  final day = LocalDate(2027, 2, 10);

  setUp(() {
    db = UserDb.memory();
    repo = DriftFastLogRepository(db);
  });
  tearDown(() => db.close());

  test('set, overwrite and clear a day', () async {
    expect(await repo.watch(day).first, isNull);
    await repo.set(day, FastEntry.fasted);
    expect(await repo.watch(day).first, FastEntry.fasted);
    await repo.set(day, FastEntry.excused);
    expect(await repo.watch(day).first, FastEntry.excused);

    final rows = await db.select(db.fastLogs).get();
    expect(rows.single.type, FastType.ramadan);
    expect(rows.single.status, 'excused');

    await repo.set(day, null);
    expect(await repo.watch(day).first, isNull);
    expect(await db.select(db.fastLogs).get(), isEmpty);
  });

  test('watch emits changes', () async {
    final seen = <FastEntry?>[];
    final sub = repo.watch(day).listen(seen.add);
    await pumpEventQueue();
    await repo.set(day, FastEntry.notFasted);
    await pumpEventQueue();
    await sub.cancel();
    expect(seen, [null, FastEntry.notFasted]);
  });

  test('ignores non-ramadan rows of the day', () async {
    await db
        .into(db.fastLogs)
        .insert(
          FastLogsCompanion.insert(
            date: day,
            type: FastType.sunnah,
            status: 'fasted',
          ),
        );
    expect(await repo.watch(day).first, isNull);
  });
}
