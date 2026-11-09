import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/db/journal_db.dart';
import 'package:prosoche/data/db/migrations/user_migrations.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/domain/common/common.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;

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
    expect(GeneratedHelper.versions, [1, 2, 3, UserDb.currentSchemaVersion]);
  });

  test('current code matches the v4 dump (drift_schemas/user_db)', () async {
    final schema = await verifier.schemaAt(4);
    final db = UserDb(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, UserDb.currentSchemaVersion);
  });

  test('v1 -> v2 creates practice and reading tables', () async {
    final schema = await verifier.schemaAt(1);
    final db = UserDb(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, UserDb.currentSchemaVersion);
    final now = DateTime.utc(2026, 10, 31, 20);
    await db.practiceLogDao.markDone(
      LocalDate(2026, 10, 31),
      JournalKind.evening,
      now,
    );
    await db.readingDao.savePosition('meditations', 'meditations.2.1', now);
    expect(
      (await db.readingDao.position('meditations'))!.sectionKey,
      'meditations.2.1',
    );
  });

  group('v2 -> v3 moves the journal to journal.db (C-02)', () {
    Future<void> seedV2(QueryExecutor e) async {
      final old = v2.DatabaseAtV2(e);
      await old.customStatement(
        'INSERT INTO journal_entry '
        '(id, date, kind, prompt_id, prompt, body, created_at, updated_at) '
        "VALUES (7, '2026-10-31', 'evening', 'prompt:x', 'Why?', 'private', "
        '1, 2)',
      );
      await old.customStatement(
        "INSERT INTO settings VALUES ('ui.locale', '\"en\"')",
      );
      await old.close();
    }

    test('rows go to the sink, table is dropped', () async {
      final schema = await verifier.schemaAt(2);
      await seedV2(schema.newConnection());
      final journal = JournalDb.memory();
      addTearDown(journal.close);
      final db = UserDb(
        schema.newConnection(),
        legacyJournal: journal.importLegacyRows,
      );
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, UserDb.currentSchemaVersion);
      expect(await db.settingsDao.read('ui.locale'), '"en"');
      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE name LIKE 'journal%'",
          )
          .get();
      expect(tables, isEmpty);
      final entry = (await journal.journalDao.all()).single;
      expect(entry.id, 7);
      expect(entry.kind, JournalKind.evening);
      expect(entry.body, 'private');
      expect(entry.prompt, 'Why?');
      expect(entry.createdAt, DateTime.utc(1970, 1, 1, 0, 0, 0, 1));
      // Opakovany import (prerusena migracia) nic nezdvoji.
      await journal.importLegacyRows([
        {'id': 7, 'date': '2026-10-31', 'kind': 'evening', 'body': 'x'},
      ]);
      expect(await journal.journalDao.all(), hasLength(1));
    });

    test('without a sink a non-empty journal is kept', () async {
      final schema = await verifier.schemaAt(2);
      await seedV2(schema.newConnection());
      final db = UserDb(schema.newConnection());
      addTearDown(db.close);
      await expectLater(db.settingsDao.read('ui.locale'), throwsStateError);
      final check = v2.DatabaseAtV2(schema.newConnection());
      addTearDown(check.close);
      final rows = await check
          .customSelect('SELECT body FROM journal_entry')
          .get();
      expect(rows.single.read<String>('body'), 'private');
    });

    test('empty v2 journal migrates without a sink', () async {
      final schema = await verifier.schemaAt(2);
      final db = UserDb(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, UserDb.currentSchemaVersion);
    });

    test('importLegacyJournal writes to a journal.db file', () async {
      final dir = await Directory.systemTemp.createTemp('journal');
      addTearDown(() => dir.delete(recursive: true));
      final sink = legacyJournalNextTo(File('${dir.path}/user.db'));
      await sink([
        {
          'id': 1,
          'date': '2026-10-31',
          'kind': 'note',
          'prompt_id': null,
          'prompt': null,
          'body': 'n',
          'created_at': 0,
          'updated_at': 0,
        },
      ]);
      final db = JournalDb.open(File('${dir.path}/$journalDbFileName'));
      addTearDown(db.close);
      expect((await db.journalDao.all()).single.body, 'n');
    });
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

  group('v3 -> v4 adds gate intent and practice first (G-01)', () {
    test('existing apps and sessions keep data, new columns default', () async {
      final schema = await verifier.schemaAt(3);
      final old = v3.DatabaseAtV3(schema.newConnection());
      await old.customStatement(
        'INSERT INTO blocked_app (id, platform_ref, label, cards_required, '
        "unlock_minutes, enabled, created_at) VALUES (1, 'com.a.b', 'A', 2, "
        '15, 1, 0)',
      );
      await old.customStatement(
        'INSERT INTO gate_session (id, blocked_app_id, opened_at, closed_at, '
        "cards_seen, result) VALUES (5, 1, 10, 20, 2, 'passed')",
      );
      await old.close();

      final db = UserDb(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, UserDb.currentSchemaVersion);
      final app = (await db.blockerDao.apps()).single;
      expect(app.cardsRequired, 2);
      expect(app.practiceFirst, isTrue);
      final session = (await db.blockerDao.session(5))!;
      expect(session.result, GateResult.passed);
      expect(session.cardsSeen, 2);
      expect(session.intent, null);

      await db.blockerDao.setSessionIntent(5, GateIntent.habit);
      expect((await db.blockerDao.session(5))!.intent, GateIntent.habit);
      await db.blockerDao.updateApp(1, practiceFirst: false);
      expect((await db.blockerDao.apps()).single.practiceFirst, isFalse);
    });

    test('intent CHECK rejects unknown values', () async {
      final schema = await verifier.schemaAt(3);
      final db = UserDb(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, UserDb.currentSchemaVersion);
      final id = await db.blockerDao.openSession(null, DateTime.utc(2026));
      await expectLater(
        db.customStatement(
          "UPDATE gate_session SET intent = 'bogus' WHERE id = $id",
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  test('missing migration step fails loudly', () async {
    expect(userDbSteps.keys, [1, 2, 3]);
    final schema = await verifier.schemaAt(4);
    final db = _FutureUserDb(schema.newConnection());
    addTearDown(db.close);
    await expectLater(db.settingsDao.read('x'), throwsStateError);
  });
}
