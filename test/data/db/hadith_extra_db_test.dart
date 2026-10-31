import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sakina/data/db/content_db.dart';
import 'package:sakina/data/db/hadith_extra_db.dart';
import 'package:sakina/data/db/hadith_extra_repository.dart';

import 'fixtures/hadith_extra_fixture.dart';
import 'fixtures/hadith_extra_fixture.dart' as fixture show main;
import 'fixtures/schema_compare.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('HadithExtraDao', () {
    late HadithExtraDb db;
    setUp(() => db = openHadithExtraFixture());
    tearDown(() => db.close());

    test('explanationFor returns the row or null', () async {
      final dao = db.hadithExtraDao;
      final row = (await dao.explanationFor(11, 'en'))!;
      expect(row.explanation, '[PLACEHOLDER explanation 11]');
      expect(row.sourceId, 'fx-hadith');
      expect((await dao.explanationFor(12, 'en'))!.explanation, isNull);
      expect(await dao.explanationFor(11, 'id'), isNull);
      expect(await dao.explanationFor(13, 'en'), isNull);
    });

    test('meta and source', () async {
      final dao = db.hadithExtraDao;
      expect(await dao.metaValue('pack_id'), HadithExtraDb.packId);
      expect(await dao.metaValue('missing'), isNull);
      expect((await dao.source('fx-hadith'))!.kind, 'hadith');
      expect(await dao.source('nope'), isNull);
    });
  });

  group('file', () {
    late Directory tmp;
    late File file;
    setUp(() {
      tmp = Directory.systemTemp.createTempSync('hadith_extra');
      file = File(p.join(tmp.path, 'hadith_extra.db'));
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    test('opens read-only and rejects writes', () async {
      buildHadithExtraFixture(file.path).close();
      final ro = HadithExtraDb.openReadOnly(file);
      addTearDown(ro.close);
      expect(await ro.hadithExtraDao.explanationFor(11, 'en'), isNotNull);
      await expectLater(
        ro.customStatement("INSERT INTO meta VALUES ('x', 'y')"),
        throwsA(isA<SqliteException>()),
      );
    });

    test('newer contract version is rejected', () async {
      (buildHadithExtraFixture(file.path)..execute(
            'PRAGMA user_version = ${HadithExtraDb.contractVersion + 1}',
          ))
          .close();
      final ro = HadithExtraDb.openReadOnly(file);
      addTearDown(ro.close);
      await expectLater(
        ro.hadithExtraDao.metaValue('pack_id'),
        throwsStateError,
      );
    });

    test('script main writes the fixture file', () async {
      file.writeAsStringSync('stale');
      fixture.main([file.path]);
      final ro = HadithExtraDb.openReadOnly(file);
      addTearDown(ro.close);
      expect(await ro.hadithExtraDao.metaValue('row_count'), '2');
    });

    group('FileHadithExtraRepository', () {
      test('null while the file does not exist, then reads it', () async {
        final repo = FileHadithExtraRepository(file, contentVersion: 7);
        addTearDown(repo.reload);
        expect(await repo.explanationFor(11, 'en'), isNull);

        buildHadithExtraFixture(file.path).close();
        final e = (await repo.explanationFor(11, 'en'))!;
        expect(e.hadithId, 11);
        expect(e.lang, 'en');
        expect(e.explanation, '[PLACEHOLDER explanation 11]');
        expect(e.hints, ['[PLACEHOLDER hint 1]\r', '[PLACEHOLDER hint 2]']);
        expect(e.sourceId, 'fx-hadith');
        expect((await repo.explanationFor(12, 'en'))!.explanation, isNull);
        expect(await repo.explanationFor(99, 'en'), isNull);
      });

      for (final (name, meta, cv) in <(String, Map<String, String>, int?)>[
        ('other pack_id', {'pack_id': 'other'}, null),
        ('other schema_version', {'schema_version': '2'}, null),
        ('other base_schema_version', {'base_schema_version': '2'}, null),
        ('other content_version', {}, 8),
      ]) {
        test('incompatible pack ($name) is null', () async {
          buildHadithExtraFixture(file.path, meta).close();
          final repo = FileHadithExtraRepository(file, contentVersion: cv);
          addTearDown(repo.reload);
          expect(await repo.explanationFor(11, 'en'), isNull);
        });
      }

      test('corrupt file is null', () async {
        file.writeAsStringSync('not a database');
        final repo = FileHadithExtraRepository(file);
        addTearDown(repo.reload);
        expect(await repo.explanationFor(11, 'en'), isNull);
      });

      test('query failure after open is null', () async {
        final repo = FileHadithExtraRepository(
          file,
          open: (_) => HadithExtraDb(
            NativeDatabase.opened(
              buildHadithExtraFixture()
                ..execute('DROP TABLE hadith_explanation'),
            ),
          ),
        );
        file.writeAsStringSync('placeholder');
        addTearDown(repo.reload);
        expect(await repo.explanationFor(11, 'en'), isNull);
      });

      test('reload reopens a replaced file', () async {
        buildHadithExtraFixture(file.path).close();
        final repo = FileHadithExtraRepository(file);
        expect(await repo.explanationFor(11, 'en'), isNotNull);
        await repo.reload();
        file.deleteSync();
        expect(await repo.explanationFor(11, 'en'), isNull);
        await repo.reload();
      });
    });
  });

  test('parseHints accepts only a JSON list of strings', () {
    expect(FileHadithExtraRepository.parseHints(null), isEmpty);
    expect(FileHadithExtraRepository.parseHints('["a", "b"]'), ['a', 'b']);
    expect(FileHadithExtraRepository.parseHints('[1]'), isEmpty);
    expect(FileHadithExtraRepository.parseHints('{"a": 1}'), isEmpty);
    expect(FileHadithExtraRepository.parseHints('not json'), isEmpty);
  });

  test('real hadith_extra.db from sakina-content/dist (when built)', () async {
    final pack = findSakinaContentFile(['dist', 'hadith_extra.db']);
    final base = findSakinaContentFile(['dist', 'content.db']);
    if (pack == null || base == null) {
      markTestSkipped('sakina-content/dist not built');
      return;
    }
    final content = ContentDb.openReadOnly(base);
    addTearDown(content.close);
    final meta = await content.contentMetaDao.allMeta();
    expect(meta['hadith_extra_schema_version'], '1');
    expect(meta['hadith_extra_size'], '${pack.lengthSync()}');
    expect(
      meta['hadith_extra_sha256'],
      (await sha256.bind(pack.openRead()).first).toString(),
    );

    final extra = HadithExtraDb.openReadOnly(pack);
    addTearDown(extra.close);
    expect(
      await isCompatibleHadithExtra(
        extra,
        contentVersion: int.parse(meta['content_version']!),
      ),
      isTrue,
    );
  });
}
