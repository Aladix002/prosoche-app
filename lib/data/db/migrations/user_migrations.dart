import 'package:drift/drift.dart';

/// Migracie user.db (plan 5.2, 17.4).
///
/// Postup pri novej verzii N:
///  1. zmenit tabulky a `UserDb.currentSchemaVersion = N`,
///  2. `dart run drift_dev schema dump lib/data/db/user_db.dart
///     drift_schemas/user_db/`,
///  3. `dart run drift_dev schema generate drift_schemas/user_db/
///     test/data/migrations/generated/` a do kazdeho vygenerovaneho
///     suboru pridat `// ignore_for_file: strict_raw_type`,
///  4. doplnit krok `N-1 -> N` do [userDbSteps] a test v
///     `test/data/migrations/`.
MigrationStrategy userDbMigration() => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    for (var v = from; v < to; v++) {
      final step = userDbSteps[v];
      if (step == null) {
        throw StateError('No user.db migration from v$v to v${v + 1}');
      }
      await step(m);
    }
  },
);

/// Kroky `vN -> vN+1` podla zdrojovej verzie N. v1 je prva verzia.
final Map<int, Future<void> Function(Migrator m)> userDbSteps = {};
