import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sakina/core/result.dart';
import 'package:sakina/data/db/content_db.dart';
import 'package:sakina/data/db/content_integrity.dart';
import 'package:sakina/data/db/daos/quran_dao.dart';

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

      expect(await ro.contentMetaDao.ayahCount(), fixtureAyahCount);
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
      await expectLater(ro.contentMetaDao.ayahCount(), throwsStateError);
    });

    test('empty file is not created by the app', () async {
      final file = File(p.join(tmp.path, 'empty.db'))..createSync();
      final ro = ContentDb.openReadOnly(file);
      addTearDown(ro.close);
      await expectLater(ro.contentMetaDao.ayahCount(), throwsStateError);
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
      expect(ro.contentMetaDao.ayahCount(), throwsA(isA<SqliteException>()));
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
            a.contentMetaDao.ayahCount(),
            b.contentMetaDao.ayahCount(),
          ]),
          [fixtureAyahCount, fixtureAyahCount],
        );
        await Future.wait([a.close(), b.close()]);
      }
    });
  });

  group('ContentIntegrityChecker (plan 17.3)', () {
    final fixtureChecker = ContentIntegrityChecker(
      expectedAyahCount: fixtureAyahCount,
      expectedUthmaniSha256: fixtureUthmaniSha256(),
      allowDevContent: true,
    );

    test('fixture passes with mocked constants', () async {
      expect(await fixtureChecker.check(db), const Ok<void>(null));
      expect(
        await db.contentMetaDao.metaValue('uthmani_sha256'),
        fixtureUthmaniSha256(),
      );
    });

    test('production constants: 6236 verses and sha256 hex', () {
      const c = ContentIntegrityChecker();
      expect(c.expectedAyahCount, 6236);
      expect(c.expectedUthmaniSha256, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(
        ContentIntegrityChecker.uthmaniSha256(['a', 'b']),
        sha256.convert(utf8.encode('a\nb')).toString(),
      );
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

    test('release build of the fixture fails on ayah_count', () async {
      final raw = buildContentFixture()
        ..execute("UPDATE meta SET value = '0' WHERE key = 'dev_content'");
      final release = ContentDb(NativeDatabase.opened(raw));
      addTearDown(release.close);
      expect(
        await const ContentIntegrityChecker().check(release),
        const Err<void>(ContentIntegrityFailed('ayah_count')),
      );
    });

    test('changed text fails uthmani_hash', () async {
      final checker = ContentIntegrityChecker(
        expectedAyahCount: fixtureAyahCount,
        expectedUthmaniSha256: '0' * 64,
        allowDevContent: true,
      );
      expect(
        await checker.check(db),
        const Err<void>(ContentIntegrityFailed('uthmani_hash')),
      );
    });

    test('wrong schema_version fails', () async {
      final raw = buildContentFixture()
        ..execute("UPDATE meta SET value = '9' WHERE key = 'schema_version'");
      final other = ContentDb(NativeDatabase.opened(raw));
      addTearDown(other.close);
      expect(
        await fixtureChecker.check(other),
        const Err<void>(ContentIntegrityFailed('schema_version')),
      );
    });
  });

  group('ContentMetaDao', () {
    test('meta and sources', () async {
      final dao = db.contentMetaDao;
      expect(await dao.allMeta(), containsPair('schema_version', '3'));
      expect(await dao.metaValue('missing'), isNull);
      expect(await dao.allSources(), hasLength(10));
      expect((await dao.source('fx-id'))!.lang, 'id');
      expect(await dao.source('nope'), isNull);
      expect(
        [for (final s in await dao.translationSources('en')) s.id],
        ['fx-en-a', 'fx-en-b'],
      );
      expect(await dao.translationSources('bn'), isEmpty);
    });
  });

  group('QuranDao', () {
    test('surahs, names, ayahs', () async {
      final dao = db.quranDao;
      final surahs = await dao.allSurahs();
      expect([for (final s in surahs) s.id], [1, 2]);
      expect(surahs.first.bismillahPre, isFalse);
      expect(surahs.last.bismillahPre, isTrue);
      expect((await dao.surah(2))!.ayahCount, 286);
      expect(await dao.surah(3), isNull);
      expect(await dao.surahNameMeanings('en'), hasLength(2));
      expect(await dao.surahNameMeanings('tr'), isEmpty);

      final s1 = await dao.ayahsOfSurah(1);
      expect([for (final a in s1) a.number], [1, 2, 3, 4, 5, 6, 7]);
      expect((await dao.ayah(2255))!.textUthmani, uthmaniOf(2, 255));
      expect(await dao.ayah(9999), isNull);
      expect(
        [
          for (final a in await dao.ayahsByIds([2255, 1001, 1007])) a.id,
        ],
        [1001, 1007, 2255],
      );
    });

    test('ayahsAfter walks in reading order across surahs', () async {
      final dao = db.quranDao;
      expect([for (final a in await dao.ayahsAfter(0, 2)) a.id], [1001, 1002]);
      expect(
        [for (final a in await dao.ayahsAfter(1006, 3)) a.id],
        [1007, 2001, 2002],
      );
      expect(await dao.ayahsAfter(2286, 3), isEmpty);
    });

    test('juz starts', () async {
      expect(await db.quranDao.juzStarts(), [
        (juz: 1, firstAyahId: 1001),
        (juz: 2, firstAyahId: 2142),
        (juz: 3, firstAyahId: 2253),
      ]);
    });

    test('translations for a source, missing ones are absent', () async {
      final dao = db.quranDao;
      final en = await dao.translationsFor(
        [1001, 2255],
        lang: 'en',
        sourceId: 'fx-en-a',
      );
      expect(en.keys, unorderedEquals([1001, 2255]));
      expect(en[1001]!.footnotes, isNotNull);
      final id = await dao.translationsFor(
        [1001, 2255],
        lang: 'id',
        sourceId: 'fx-id',
      );
      expect(id.keys, [1001]);
    });

    test('FTS5 search in Arabic and translation', () async {
      final dao = db.quranDao;
      final ar = await dao.searchArabic(fixtureArabicToken);
      expect([for (final h in ar) h.ayahId], [2255]);
      expect(ar.single.snippet, contains(SearchHit.matchStart));
      expect(ar.single.snippet, contains(SearchHit.matchEnd));

      // prefix na poslednom slove
      expect(await dao.searchArabic('alphaw'), hasLength(1));

      final tr = await dao.searchTranslation(
        fixtureTranslationToken,
        lang: 'en',
        sourceId: 'fx-en-a',
      );
      expect([for (final h in tr) h.ayahId], [2255]);
      final trId = await dao.searchTranslation(
        fixtureTranslationToken,
        lang: 'id',
        sourceId: 'fx-id',
      );
      expect(trId, hasLength(7));
      expect(
        await dao.searchTranslation(
          'placeholder',
          lang: 'en',
          sourceId: 'fx-en-a',
          limit: 5,
        ),
        hasLength(5),
      );
    });

    test('FTS input is escaped, empty input returns nothing', () async {
      final dao = db.quranDao;
      expect(await dao.searchArabic('  '), isEmpty);
      expect(
        await dao.searchTranslation('"', lang: 'en', sourceId: 'fx-en-a'),
        isEmpty,
      );
      // operatory FTS5 sa neinterpretuju
      expect(await dao.searchArabic('NOT AND (*'), isEmpty);
      expect(ftsQuery('a  b'), '"a" "b"*');
      expect(ftsQuery('x"y'), '"x" "y"*');
      expect(ftsQuery(''), isNull);
    });

    test('SearchHit value semantics', () {
      const a = SearchHit(ayahId: 1, snippet: 's');
      expect(a, const SearchHit(ayahId: 1, snippet: 's'));
      expect(a.hashCode, const SearchHit(ayahId: 1, snippet: 's').hashCode);
      expect(a, isNot(const SearchHit(ayahId: 2, snippet: 's')));
      expect(a.toString(), contains('1'));
    });
  });

  group('HadithDao', () {
    test('hadith, text, ids by tag', () async {
      final dao = db.hadithDao;
      expect((await dao.hadith(13))!.grade, 'hasan');
      expect(await dao.hadith(1), isNull);
      expect((await dao.hadithText(11, 'en'))!.title, isNotEmpty);
      expect(await dao.hadithText(11, 'ur'), isNull);
      expect(await dao.hadithIds(), [11, 12, 13]);
      expect(await dao.hadithIds(tag: 'jumuah'), [11]);
      expect(await dao.hadithIds(tag: 'none'), isEmpty);
    });
  });

  group('CuratedDao', () {
    test('dua by id and time of day', () async {
      final dao = db.curatedDao;
      expect((await dao.dua('dua_any'))!.repeatCount, 1);
      expect(await dao.dua('x'), isNull);
      expect(await dao.duaText('dua_morning', 'en'), isNotNull);
      expect(await dao.duaText('dua_evening', 'en'), isNull);
      expect(await dao.duaIds(), ['dua_any', 'dua_evening', 'dua_morning']);
      expect(await dao.duaIds(timeOfDay: 'morning'), [
        'dua_any',
        'dua_morning',
      ]);
    });

    test('names of Allah', () async {
      final dao = db.curatedDao;
      expect((await dao.nameOfAllah(1))!.refAyahId, 1001);
      expect(await dao.nameOfAllah(99), isNull);
      expect(await dao.nameText(1, 'en'), isNotNull);
      expect(await dao.nameText(2, 'en'), isNull);
    });

    test('reflections skip retired', () async {
      final dao = db.curatedDao;
      expect(
        [for (final r in await dao.activeReflections()) r.id],
        ['refl_a', 'refl_b'],
      );
      expect((await dao.reflection('refl_old'))!.status, 'retired');
      expect(await dao.reflectionText('refl_a', 'en'), isNotNull);
    });

    test('quests by slot with texts', () async {
      final dao = db.curatedDao;
      expect(
        [for (final q in await dao.activeQuestTemplates()) q.id],
        ['q_act', 'q_learn', 'q_read'],
      );
      final act = await dao.activeQuestTemplates(slot: 'act');
      expect([for (final q in act) q.id], ['q_act']);
      expect(act.single.cooldownDays, 21);
      expect(act.single.weight, 1.0);
      final texts = await dao.questTextsFor(['q_read', 'q_learn'], 'en');
      expect(texts.keys, ['q_read']);
    });

    test('events by priority, texts, intro cards', () async {
      final dao = db.curatedDao;
      expect(
        [for (final e in await dao.activeIslamicEvents()) e.id],
        ['ev_high', 'ev_low'],
      );
      expect((await dao.eventTextsFor('en')).keys, ['ev_high']);
      expect(await dao.activeIntroCards(), hasLength(2));
      expect(
        [for (final c in await dao.activeIntroCards(eventId: 'ev_high')) c.id],
        ['intro_ev'],
      );
      expect(await dao.introCardText('intro_a', 'en'), isNotNull);
      expect(await dao.introCardText('intro_ev', 'en'), isNull);
    });
  });

  group('WordsDao', () {
    test('words, meanings, lemmas, occurrences, coverage', () async {
      final dao = db.wordsDao;
      expect(
        [for (final w in await dao.wordsOfAyah(1001)) w.position],
        [1, 2, 3],
      );
      expect((await dao.word(1001, 3))!.lemmaId, isNull);
      expect(await dao.word(1001, 9), isNull);
      expect(await dao.wordMeaning(1, 'en'), isNotNull);
      expect(await dao.wordMeaning(2, 'en'), isNull);
      expect((await dao.lemma(1))!.frequency, 100);
      expect(await dao.lemma(9), isNull);
      expect(
        [
          for (final l in await dao.lemmasByIds([2, 1])) l.id,
        ],
        [1, 2],
      );
      expect(await dao.meaningsOfLemmas([1, 2, 3], 'en'), hasLength(2));
      expect(
        [for (final w in await dao.occurrences(1)) w.ayahId],
        [1001, 2255],
      );
      expect(await dao.occurrences(1, limit: 1), hasLength(1));
      expect(await dao.frequencySum(), 160);
      expect(await dao.frequencySum([1, 3]), 110);
      expect(await dao.frequencySum([42]), 0);
    });
  });

  group('PlacesDao', () {
    test('prefix search by name and ascii name, largest first', () async {
      final dao = db.placesDao;
      expect([for (final c in await dao.searchCities('br')) c.id], [1, 2]);
      expect([for (final c in await dao.searchCities('Banska')) c.id], [3]);
      expect([for (final c in await dao.searchCities('Banská')) c.id], [3]);
      expect(await dao.searchCities('  '), isEmpty);
      expect(await dao.searchCities('b', limit: 1), hasLength(1));
      // % a _ su literaly, nie zastupne znaky
      expect([for (final c in await dao.searchCities('100%_')) c.id], [4]);
      expect(await dao.searchCities('1_0'), isEmpty);
      expect((await dao.city(2))!.countryCode, 'CZ');
      expect((await dao.country('SK'))!.name, 'Slovakia');
      expect(await dao.country('DE'), isNull);
      expect(await dao.countryNames(), hasLength(3));
      expect(await dao.city(99), isNull);
    });

    test('nearest city', () async {
      final dao = db.placesDao;
      expect((await dao.nearestCity(48.2, 17.2))!.id, 1);
      expect((await dao.nearestCity(49.1, 16.5))!.id, 2);
      // daleko od vsetkeho: stvorec sa zvacsuje
      expect((await dao.nearestCity(13, 13))!.id, 4);
      expect(await dao.nearestCity(-80, -170), isNull);
    });
  });
}
