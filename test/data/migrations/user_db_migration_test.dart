import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/db/migrations/user_migrations.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/domain/common/common.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

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
    expect(GeneratedHelper.versions, [1, UserDb.currentSchemaVersion]);
  });

  test('current code matches the v2 dump (drift_schemas/user_db)', () async {
    final schema = await verifier.schemaAt(2);
    final db = UserDb(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, UserDb.currentSchemaVersion);
  });

  test('v1 -> v2 creates journal, practice and reading tables', () async {
    final schema = await verifier.schemaAt(1);
    final db = UserDb(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);
    final day = LocalDate(2026, 10, 31);
    final now = DateTime.utc(2026, 10, 31, 20);
    final id = await db.journalDao.add(
      date: day,
      kind: JournalKind.evening,
      body: 'note',
      now: now,
    );
    expect((await db.journalDao.all()).single.id, id);
    await db.readingDao.savePosition('meditations', 'meditations.2.1', now);
    expect(
      (await db.readingDao.position('meditations'))!.sectionKey,
      'meditations.2.1',
    );
  });

  test('v2 data opens with the latest app', () async {
    final schema = await verifier.schemaAt(2);
    final old = v2.DatabaseAtV2(schema.newConnection());
    await old.customStatement(
      'INSERT INTO journal_entry (date, kind, body, created_at, updated_at) '
      "VALUES ('2026-10-31', 'morning', 'x', 0, 0)",
    );
    await old.close();
    final db = UserDb(schema.newConnection());
    addTearDown(db.close);
    expect((await db.journalDao.all()).single.kind, JournalKind.morning);
  });

  test('v1 data survives opening with the latest app (plan 17.4)', () async {
    final schema = await verifier.schemaAt(1);
    final old = v1.DatabaseAtV1(schema.newConnection());
    await old.customStatement(
      "INSERT INTO settings VALUES ('ui.locale', '\"en\"')",
    );
    await old.customStatement(
      'INSERT INTO card_event (date, card_id, type, context, action, ts) '
      "VALUES ('2026-10-29', 'quote:q_1', 'quote', 'feed', 'seen', 0)",
    );
    await old.close();

    final db = UserDb(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, UserDb.currentSchemaVersion);
    expect(await db.settingsDao.read('ui.locale'), '"en"');
    expect(
      (await db.cardEventDao.forDate(LocalDate(2026, 10, 29))).single.action,
      CardAction.seen,
    );
  });

  test('missing migration step fails loudly', () async {
    expect(userDbSteps.keys, [1]);
    final schema = await verifier.schemaAt(1);
    final db = _FutureUserDb(schema.newConnection());
    addTearDown(db.close);
    await expectLater(db.settingsDao.read('x'), throwsStateError);
  });
}
