import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/data/db/content_integrity.dart';

import 'fixtures/content_fixture.dart';
import 'fixtures/content_fixture.dart' as fixture show main;

void main() {
  // Kazdy test otvara novu DB nad vlastnym spojenim.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late ContentDb db;

  setUp(() => db = openContentFixture());
  tearDown(() => db.close());

  group('read-only file', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('content_db'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('opens fixture file and rejects writes', () async {
      final file = File(p.join(tmp.path, 'content.db'));
      buildContentFixture(file.path).close();
      final ro = ContentDb.openReadOnly(file);
      addTearDown(ro.close);

      expect(await ro.contentMetaDao.quoteCount(), fixtureQuoteCount + 2);
      await expectLater(
        ro.customStatement("INSERT INTO meta VALUES ('x', 'y')"),
        throwsA(isA<SqliteException>()),
      );
    });

    test('script main writes the fixture file', () async {
      final out = p.join(tmp.path, 'out.db');
      File(out).writeAsStringSync('stale');
      fixture.main([out]);
      final ro = ContentDb.openReadOnly(File(out));
      addTearDown(ro.close);
      expect(await ro.contentMetaDao.metaValue('content_version'), 'fixture');
    });

    test('newer contract version is rejected', () async {
      final file = File(p.join(tmp.path, 'next.db'));
      (buildContentFixture(file.path)
            ..execute('PRAGMA user_version = ${ContentDb.contractVersion + 1}'))
          .close();
      final ro = ContentDb.openReadOnly(file);
      addTearDown(ro.close);
      await expectLater(ro.contentMetaDao.quoteCount(), throwsStateError);
    });

    test('empty file is not created by the app', () async {
      final file = File(p.join(tmp.path, 'empty.db'))..createSync();
      final ro = ContentDb.openReadOnly(file);
      addTearDown(ro.close);
      await expectLater(ro.contentMetaDao.quoteCount(), throwsStateError);
    });

    test('P-01: background connection is query_only and read-only', () async {
      final file = File(p.join(tmp.path, 'content.db'));
      buildContentFixture(file.path).close();
      final before = file.readAsBytesSync();
      final ro = ContentDb.openReadOnly(file);
      final pragma = await ro.customSelect('PRAGMA query_only').getSingle();
      expect(pragma.data.values.single, 1);
      // Ani PRAGMA zapis, ani DDL neprejde; chyba je SqliteException,
      // nie DriftRemoteException z izolatu.
      await expectLater(
        ro.customStatement('CREATE TABLE x (a INTEGER)'),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        ro.customStatement("UPDATE meta SET value = 'x'"),
        throwsA(isA<SqliteException>()),
      );
      await ro.close();
      expect(file.readAsBytesSync(), before, reason: 'file unchanged');
    });

    test('P-01: opening does not touch the file on the calling isolate', () {
      // Subor sa otvara az v izolate pri prvom dotaze: factory nehodi ani
      // pri chybajucom subore, chyba pride z dotazu.
      final ro = ContentDb.openReadOnly(File(p.join(tmp.path, 'missing.db')));
      addTearDown(ro.close);
      expect(ro.contentMetaDao.quoteCount(), throwsA(isA<SqliteException>()));
      expect(File(p.join(tmp.path, 'missing.db')).existsSync(), isFalse);
    });

    test('P-01: parallel readers and repeated open/close', () async {
      final file = File(p.join(tmp.path, 'content.db'));
      buildContentFixture(file.path).close();
      for (var i = 0; i < 3; i++) {
        final a = ContentDb.openReadOnly(file);
        final b = ContentDb.openReadOnly(file);
        expect(
          await Future.wait([
            a.contentMetaDao.quoteCount(),
            b.contentMetaDao.quoteCount(),
          ]),
          [fixtureQuoteCount + 2, fixtureQuoteCount + 2],
        );
        await Future.wait([a.close(), b.close()]);
      }
    });
  });

  group('ContentIntegrityChecker (plan 17.3)', () {
    const devChecker = ContentIntegrityChecker(allowDevContent: true);

    test('fixture passes when dev content is allowed', () async {
      expect(await devChecker.check(db), const Ok<void>(null));
    });

    test('dev content is rejected unless allowed', () async {
      expect(
        await const ContentIntegrityChecker().check(db),
        const Err<void>(ContentIntegrityFailed('dev_content')),
      );
      final raw = buildContentFixture()
        ..execute("DELETE FROM meta WHERE key = 'dev_content'");
      final noKey = ContentDb(NativeDatabase.opened(raw));
      addTearDown(noKey.close);
      expect(
        await const ContentIntegrityChecker().check(noKey),
        const Err<void>(ContentIntegrityFailed('dev_content')),
      );
    });

    test('release build passes, empty content fails', () async {
      final raw = buildContentFixture()
        ..execute("UPDATE meta SET value = '0' WHERE key = 'dev_content'");
      final release = ContentDb(NativeDatabase.opened(raw));
      addTearDown(release.close);
      expect(
        await const ContentIntegrityChecker().check(release),
        const Ok<void>(null),
      );
      raw.execute('DELETE FROM quote');
      expect(
        await const ContentIntegrityChecker().check(release),
        const Err<void>(ContentIntegrityFailed('empty')),
      );
    });

    test('wrong schema_version fails', () async {
      final raw = buildContentFixture()
        ..execute("UPDATE meta SET value = '9' WHERE key = 'schema_version'");
      final other = ContentDb(NativeDatabase.opened(raw));
      addTearDown(other.close);
      expect(
        await devChecker.check(other),
        const Err<void>(ContentIntegrityFailed('schema_version')),
      );
    });
  });

  group('ContentMetaDao', () {
    test('meta, sources and quote count', () async {
      final dao = db.contentMetaDao;
      expect(await dao.allMeta(), containsPair('schema_version', '1'));
      expect(await dao.metaValue('missing'), isNull);
      expect(await dao.allSources(), hasLength(2));
      expect((await dao.source('fx-text'))!.kind, 'text');
      expect(await dao.source('nope'), isNull);
      expect(await dao.quoteCount(), fixtureQuoteCount + 2);
    });
  });

  group('CuratedDao', () {
    test('quotes: by id, active without retired', () async {
      final dao = db.curatedDao;
      final q = await dao.quote(fixtureQuoteId(1));
      expect(q!.textContent, '[PLACEHOLDER quote 1]');
      expect(q.timeOfDay, 'morning');
      expect(await dao.quote('nope'), isNull);
      final active = await dao.activeQuotes();
      expect(active.map((r) => r.id), isNot(contains('q_retired')));
      expect(active.map((r) => r.id), contains('q_draft'));
      expect(active, hasLength(fixtureQuoteCount + 1));
    });

    test('quests by slot with texts', () async {
      final dao = db.curatedDao;
      expect(await dao.activeQuestTemplates(), hasLength(5));
      expect((await dao.activeQuestTemplates(slot: 'act')).map((r) => r.id), [
        'act.draft',
        'act.placeholder',
      ]);
      final texts = await dao.questTextsFor(['learn.idea', 'nope'], 'en');
      expect(texts.keys, ['learn.idea']);
      expect(await dao.questTextsFor(['learn.idea'], 'de'), isEmpty);
    });
  });
}
