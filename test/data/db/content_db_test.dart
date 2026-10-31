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

      expect(await ro.contentMetaDao.cardCount(), fixtureCardCount);
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
      await expectLater(ro.contentMetaDao.cardCount(), throwsStateError);
    });

    test('empty file is not created by the app', () async {
      final file = File(p.join(tmp.path, 'empty.db'))..createSync();
      final ro = ContentDb.openReadOnly(file);
      addTearDown(ro.close);
      await expectLater(ro.contentMetaDao.cardCount(), throwsStateError);
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
      expect(ro.contentMetaDao.cardCount(), throwsA(isA<SqliteException>()));
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
            a.contentMetaDao.cardCount(),
            b.contentMetaDao.cardCount(),
          ]),
          [fixtureCardCount, fixtureCardCount],
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
      raw.execute('DELETE FROM card');
      expect(
        await const ContentIntegrityChecker().check(release),
        const Err<void>(ContentIntegrityFailed('empty')),
      );
    });

    test('section text not matching its sha256 fails', () async {
      final raw = buildContentFixture()
        ..execute(
          "UPDATE section SET text = text || 'x' WHERE key = 'work-flat.2'",
        );
      final bad = ContentDb(NativeDatabase.opened(raw));
      addTearDown(bad.close);
      expect(
        await devChecker.check(bad),
        const Err<void>(ContentIntegrityFailed('section_sha256')),
      );
    });

    test('sections_sha256 must match meta and the manifest', () async {
      final raw = buildContentFixture();
      final digest =
          raw
                  .select(
                    "SELECT value FROM meta WHERE key = 'sections_sha256'",
                  )
                  .single['value']
              as String;
      final ok = ContentDb(NativeDatabase.opened(raw));
      addTearDown(ok.close);
      expect(
        await devChecker.check(ok, expectedSectionsSha256: digest),
        const Ok<void>(null),
      );
      expect(
        await devChecker.check(ok, expectedSectionsSha256: 'e' * 64),
        const Err<void>(ContentIntegrityFailed('sections_sha256')),
      );
      raw.execute("UPDATE meta SET value = 'x' WHERE key = 'sections_sha256'");
      expect(
        await devChecker.check(ok),
        const Err<void>(ContentIntegrityFailed('sections_sha256')),
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
    test('meta, sources and counts', () async {
      final dao = db.contentMetaDao;
      expect(await dao.allMeta(), containsPair('schema_version', '1'));
      expect(await dao.metaValue('missing'), isNull);
      expect(await dao.allSources(), hasLength(2));
      final src = (await dao.source('fx-text'))!;
      expect(src.kind, 'text');
      expect(src.translator, 'Fixture Translator');
      expect((await dao.source('prosoche-curated'))!.url, isNull);
      expect(await dao.source('nope'), isNull);
      expect(await dao.cardCount(), fixtureCardCount);
      expect(await dao.sectionCount(), fixtureSectionKeys.length);
      expect((await dao.sectionHashes()).map((h) => h.$1), fixtureSectionKeys);
    });
  });

  group('CardDao', () {
    test('card by full id, all cards, by type', () async {
      final dao = db.cardDao;
      final q = await dao.card('quote:${fixtureQuoteId(1)}');
      expect(q!.textContent, '[PLACEHOLDER quote 1]');
      expect(q.sectionKey, fixtureSectionKeys.first);
      expect(await dao.card('quote:nope'), isNull);
      expect(await dao.allCards(), hasLength(fixtureCardCount));
      final practices = await dao.ofType('practice');
      expect(practices.first.id, 'practice:morning-preparation');
      expect(practices.map((r) => r.ord), [1, 2, 3, 4, 5]);
    });
  });

  group('LibraryDao', () {
    test('authors, works, books, sections', () async {
      final dao = db.libraryDao;
      expect((await dao.allAuthors()).map((a) => a.id), [
        'author-a',
        'author-b',
      ]);
      expect((await dao.allWorks()).map((w) => w.id), fixtureWorks);
      expect((await dao.workById('work-flat'))!.bookCount, 0);
      expect(await dao.workById('nope'), isNull);
      expect((await dao.booksOf('work-books')).map((b) => b.number), [1, 2]);
      expect(await dao.booksOf('work-flat'), isEmpty);
      final sections = await dao.sectionsOf('work-books');
      expect(sections.map((s) => s.ref), [
        '1.1',
        '1.2',
        '1.3',
        '2.1',
        '2.2',
        '2.3',
      ]);
      expect((await dao.sectionByKey('work-flat.2'))!.title, 'Chapter 2');
      expect(await dao.sectionByKey('x'), isNull);
    });

    test('FTS5 search with snippet highlight', () async {
      final hits = await db.libraryDao.search('"river"');
      expect(hits, isNotEmpty);
      expect(hits.every((h) => h.snippet.contains('[river]')), isTrue);
      expect(hits.map((h) => h.key), everyElement(isIn(fixtureSectionKeys)));
      expect(await db.libraryDao.search('"zzzz"'), isEmpty);
      // Porter stemming (kontrakt kap. 7): "rivers" najde "river".
      expect(await db.libraryDao.search('"rivers"'), isNotEmpty);
    });
  });
}
