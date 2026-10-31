import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/db/migrations/user_migrations.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/domain/common/common.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;

/// UserDb s vyssou verziou bez definovaneho kroku migracie.
class _FutureUserDb extends UserDb {
  _FutureUserDb(super.e);

  @override
  int get schemaVersion => UserDb.currentSchemaVersion + 1;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('every dumped version is tested', () {
    expect(GeneratedHelper.versions, [UserDb.currentSchemaVersion]);
  });

  test('current code matches the v1 dump (drift_schemas/user_db)', () async {
    final schema = await verifier.schemaAt(1);
    final db = UserDb(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, UserDb.currentSchemaVersion);
  });

  test('v1 data survives opening with the latest app (plan 17.4)', () async {
    final schema = await verifier.schemaAt(1);
    final old = v1.DatabaseAtV1(schema.newConnection());
    await old.customStatement(
      "INSERT INTO settings VALUES ('ui.locale', '\"ar\"')",
    );
    await old.customStatement(
      'INSERT INTO card_event (date, card_id, type, context, action, ts) '
      "VALUES ('2026-10-29', 'ayah:2255', 'ayah', 'feed', 'seen', 0)",
    );
    await old.customStatement(
      'INSERT INTO reading_position (id, ayah_id, updated_at) '
      'VALUES (1, 2255, 0)',
    );
    await old.close();

    final db = UserDb(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, UserDb.currentSchemaVersion);
    expect(await db.settingsDao.read('ui.locale'), '"ar"');
    expect(await db.readingDao.readingPosition(), 2255);
    expect(
      (await db.cardEventDao.forDate(LocalDate(2026, 10, 29))).single.action,
      CardAction.seen,
    );
  });

  test('missing migration step fails loudly', () async {
    expect(userDbSteps, isEmpty);
    final schema = await verifier.schemaAt(1);
    final db = _FutureUserDb(schema.newConnection());
    addTearDown(db.close);
    await expectLater(db.settingsDao.read('x'), throwsStateError);
  });
}
