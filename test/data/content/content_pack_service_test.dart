import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/content/content_documents.dart';
import 'package:prosoche/data/content/content_pack_service.dart';
import 'package:prosoche/data/content/content_pack_state.dart';
import 'package:prosoche/data/content/remote_config_policy.dart';
import 'package:prosoche/data/content/sem_ver.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:sqlite3/sqlite3.dart';

import 'content_test_helpers.dart';

const v1 = 2026010100;

ContentManifest _manifest({required bool dev}) => ContentManifest.parse(
  manifestBytes(contentVersion: v2, db: [1], gz: [2], devContent: dev),
).valueOrNull!;
const v2 = 2026020100;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late Directory dir;
  late TestKeys keys;
  late FakeHttpClient http;
  late RingBufferLog log;
  late MemoryBundledSource bundled;
  late Uint8List bundledDb;
  late List<Duration> delays;

  setUpAll(() async => keys = await TestKeys.create());

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('content_pack');
    dir = Directory(p.join(tmp.path, 'support', 'content'));
    http = FakeHttpClient();
    log = RingBufferLog();
    delays = [];
    bundledDb = fixtureDbBytes(tmp, v1);
    bundled = MemoryBundledSource(bundledDb);
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  ContentPackService service({String appVersion = '0.1.0'}) => buildService(
    dir: dir,
    bundled: bundled,
    http: http,
    keys: keys,
    log: log,
    appVersion: appVersion,
    delays: delays,
  );

  File active() => File(p.join(dir.path, ContentPackService.dbFileName));

  Future<String?> activeVersion() async {
    final db = ContentDb.openReadOnly(active());
    try {
      return await db.contentMetaDao.metaValue('content_version');
    } finally {
      await db.close();
    }
  }

  /// Publikuje podpisany manifest a db (verzia [cv]) na fake CDN.
  Future<({Uint8List db, Uint8List gz, Uint8List manifest})> publish(
    int cv, {
    String minApp = '0.1.0',
    int schemaVersion = ContentDb.contractVersion,
    List<String> disabledIds = const [],
    TestKey? signer,
    bool corruptText = false,
    int? metaVersion,
  }) async {
    final db = fixtureDbBytes(tmp, metaVersion ?? cv, corruptText: corruptText);
    final gz = Uint8List.fromList(gzip.encode(db));
    final manifest = manifestBytes(
      contentVersion: cv,
      db: db,
      gz: gz,
      minApp: minApp,
      schemaVersion: schemaVersion,
      disabledIds: disabledIds,
    );
    final key = signer ?? keys.contentA;
    http
      ..serve('$cdn/manifest.json', manifest)
      ..serve('$cdn/manifest.json.sig', await key.sign(manifest))
      ..serve('https://cdn.test/db/$cv/content.db.gz', gz);
    return (db: db, gz: gz, manifest: manifest);
  }

  Future<void> install(ContentPackService s) async =>
      expect((await s.ensureInstalled()).isOk, isTrue);

  group('ensureInstalled', () {
    test('first start copies bundled db and verifies it', () async {
      final s = service();
      final r = await s.ensureInstalled();
      expect(r.valueOrNull?.path, active().path);
      expect(await activeVersion(), '$v1');
      final st = await s.state();
      expect(st.installedVersion, v1);
      expect(st.origin, ContentDbOrigin.bundled);
      // Druhe volanie pouzije overeny subor.
      bundled.db = null;
      expect((await s.ensureInstalled()).isOk, isTrue);
    });

    test('next start verifies existing db without copying', () async {
      await install(service());
      bundled.db = null;
      final r = await service().ensureInstalled();
      expect(r.isOk, isTrue);
    });

    test('next start checks meta only, not the full content', () async {
      await install(service());
      bundled.db = null;
      // Zmena textu po instalacii: plna kontrola (17.3) bezi len pri
      // instalacii a po aktualizacii, nie pri kazdom starte.
      sqlite3.open(active().path)
        ..execute('DELETE FROM card')
        ..close();
      final r = await service().ensureInstalled();
      expect(r.isOk, isTrue);
      expect(
        log.entries.map((e) => e.msg),
        contains('active content.db verified'),
      );
    });

    for (final (key, value, code) in [
      ('schema_version', '999', 'data.content_integrity.schema_version'),
      ('content_version', '1', 'data.content_integrity.content_version'),
    ]) {
      test('next start with wrong $key falls back to bundled', () async {
        await install(service());
        sqlite3.open(active().path)
          ..execute('UPDATE meta SET value = ? WHERE key = ?', [value, key])
          ..close();
        final r = await service().ensureInstalled();
        expect(r.isOk, isTrue);
        expect(await activeVersion(), '$v1');
        expect(failureCodes(log), contains(code));
      });
    }

    test('bundled manifest sha256 mismatch is rejected', () async {
      final other = fixtureDbBytes(tmp, v1 + 1);
      bundled.manifest = manifestBytes(
        contentVersion: v1,
        db: other,
        gz: gzip.encode(other),
      );
      final r = await service().ensureInstalled();
      expect(r, const Err<File>(ContentIntegrityFailed('sha256')));
      expect(active().existsSync(), isFalse);
    });

    test('bundled manifest with matching hash is accepted', () async {
      bundled.manifest = manifestBytes(
        contentVersion: v1,
        db: bundledDb,
        gz: gzip.encode(bundledDb),
      );
      expect((await service().ensureInstalled()).isOk, isTrue);
    });

    test('bundled db failing integrity is an error', () async {
      bundled.db = fixtureDbBytes(tmp, v1, corruptText: true);
      final r = await service().ensureInstalled();
      expect(r, const Err<File>(ContentIntegrityFailed('empty')));
      expect(active().existsSync(), isFalse);
      expect(failureCodes(log), contains('data.content_integrity.empty'));
    });

    test('bundled gz is inflated, temp files removed', () async {
      bundled.manifest = manifestBytes(
        contentVersion: v1,
        db: bundledDb,
        gz: gzip.encode(bundledDb),
      );
      expect((await service().ensureInstalled()).isOk, isTrue);
      expect(active().readAsBytesSync(), bundledDb);
      expect(dir.listSync().map((e) => p.basename(e.path)).toSet(), {
        ContentPackService.dbFileName,
        'state.json',
      });
    });

    test('bundled gz_sha256 mismatch is rejected', () async {
      bundled.manifest = manifestBytes(
        contentVersion: v1,
        db: bundledDb,
        gz: gzip.encode(bundledDb) + [0],
      );
      final r = await service().ensureInstalled();
      expect(r, const Err<File>(ContentIntegrityFailed('sha256')));
      expect(active().existsSync(), isFalse);
    });

    test('corrupted bundled gzip without manifest is rejected', () async {
      bundled.archive = Uint8List.fromList(
        gzip.encode(bundledDb).sublist(0, 100),
      );
      // Skrateny gzip: bud chyba rozbalenia, alebo neplatna sqlite db.
      final r = await service().ensureInstalled();
      expect(r.isOk, isFalse);
      expect(active().existsSync(), isFalse);
      expect(dir.listSync(), isEmpty);
    });

    test('missing bundled asset is DbCorrupted', () async {
      bundled.db = null;
      final r = await service().ensureInstalled();
      expect(r, const Err<File>(DbCorrupted('content')));
    });

    test('corrupted downloaded db falls back to bundled and logs', () async {
      final s = service();
      await install(s);
      await publish(v2);
      expect(await s.checkForUpdate(), const Ok(ContentUpdateOutcome.updated));
      active().writeAsStringSync('garbage, not sqlite');

      final r = await service().ensureInstalled();
      expect(r.isOk, isTrue);
      expect(await activeVersion(), '$v1');
      final st = await service().state();
      expect(st.origin, ContentDbOrigin.bundled);
      expect(st.installedVersion, v1);
      expect(failureCodes(log), contains('data.db_corrupted.content'));
      expect(
        log.entries.map((e) => e.msg),
        contains('active content.db failed integrity, using bundled'),
      );
    });

    test('newer bundled db replaces older installed db', () async {
      await install(service());
      final newer = fixtureDbBytes(tmp, v2);
      bundled
        ..db = newer
        ..manifest = manifestBytes(
          contentVersion: v2,
          db: newer,
          gz: gzip.encode(newer),
        );
      expect((await service().ensureInstalled()).isOk, isTrue);
      expect(await activeVersion(), '$v2');
    });
  });

  group('checkForUpdate', () {
    test('valid newer manifest downloads, verifies and swaps', () async {
      final s = service();
      await install(s);
      await publish(v2, disabledIds: ['quote:q_1234']);
      final swaps = <int>[];
      s.swaps.listen(swaps.add);

      expect(await s.checkForUpdate(), const Ok(ContentUpdateOutcome.updated));
      expect(await activeVersion(), '$v2');
      final st = await s.state();
      expect(st.installedVersion, v2);
      expect(st.origin, ContentDbOrigin.downloaded);
      expect(st.disabledIds, {'quote:q_1234'});
      await pumpEventQueue();
      expect(swaps, [v2]);
      expect(dir.listSync().map((e) => p.basename(e.path)).toSet(), {
        'content.db',
        'state.json',
      });
      expect((await s.ensureInstalled()).valueOrNull?.path, active().path);
    });

    test('bad signature is rejected and old db stays', () async {
      final s = service();
      await install(s);
      final pub = await publish(v2);
      final tampered = Uint8List.fromList(pub.manifest)..[10] ^= 1;
      http
        ..serve('$cdn/manifest.json', tampered)
        ..serve('$mirror/manifest.json', tampered)
        ..serve(
          '$mirror/manifest.json.sig',
          await keys.contentA.sign(pub.manifest),
        );

      final r = await s.checkForUpdate();
      expect(
        r,
        const Err<ContentUpdateOutcome>(SecurityFailure.badSignature()),
      );
      expect(await activeVersion(), '$v1');
      expect(http.count('https://cdn.test/db/$v2/content.db.gz'), 0);
    });

    test('signature by unknown key is rejected', () async {
      final s = service();
      await install(s);
      final pub = await publish(v2);
      http.serve(
        '$cdn/manifest.json.sig',
        await keys.contentA.sign(pub.manifest, asKid: 'other'),
      );
      expect(
        await s.checkForUpdate(),
        const Err<ContentUpdateOutcome>(SecurityFailure.unknownKey()),
      );
    });

    test('bad sha256 is rejected, old db stays, version blocked', () async {
      final s = service();
      await install(s);
      final pub = await publish(v2);
      final bad = Uint8List.fromList(pub.gz)..[pub.gz.length ~/ 2] ^= 0xff;
      http
        ..serve('https://cdn.test/db/$v2/content.db.gz', bad)
        ..serve('https://fallback.test/db/$v2/content.db.gz', bad);

      final r = await s.checkForUpdate();
      expect(
        r,
        const Err<ContentUpdateOutcome>(ContentIntegrityFailed('sha256')),
      );
      expect(await activeVersion(), '$v1');
      // 1x znova stiahnut, potom stop (06 C.6).
      expect(http.count('https://cdn.test/db/$v2/content.db.gz'), 2);
      expect(http.count('https://fallback.test/db/$v2/content.db.gz'), 0);
      expect((await s.state()).rejectedVersion, v2);
      expect(
        await s.checkForUpdate(),
        const Ok(ContentUpdateOutcome.previouslyRejected),
      );
      expect(dir.listSync().where((f) => f.path.endsWith('.part')), isEmpty);
    });

    test('oversized download is a hash mismatch', () async {
      final s = service();
      await install(s);
      final pub = await publish(v2);
      http.serve('https://cdn.test/db/$v2/content.db.gz', [
        ...pub.gz,
        ...List.filled(10, 0),
      ]);
      expect(
        await s.checkForUpdate(),
        const Err<ContentUpdateOutcome>(ContentIntegrityFailed('sha256')),
      );
    });

    test('valid gz with wrong inner sha256 is rejected', () async {
      final s = service();
      await install(s);
      final pub = await publish(v2);
      final otherDb = fixtureDbBytes(tmp, v2 + 1);
      final manifest = manifestBytes(
        contentVersion: v2,
        db: otherDb,
        gz: pub.gz,
      );
      http
        ..serve('$cdn/manifest.json', manifest)
        ..serve('$cdn/manifest.json.sig', await keys.contentA.sign(manifest));
      expect(
        await s.checkForUpdate(),
        const Err<ContentUpdateOutcome>(ContentIntegrityFailed('sha256')),
      );
      expect(await activeVersion(), '$v1');
      expect(dir.listSync().where((f) => f.path.endsWith('.next')), isEmpty);
    });

    test('interrupted download keeps old db', () async {
      final s = service();
      await install(s);
      final pub = await publish(v2);
      http.routes['https://cdn.test/db/$v2/content.db.gz'] = () =>
          interrupted(pub.gz, 100);
      http.routes['https://fallback.test/db/$v2/content.db.gz'] = () =>
          interrupted(pub.gz, 50);

      final r = await s.checkForUpdate();
      expect(r, const Err<ContentUpdateOutcome>(Offline()));
      expect(await activeVersion(), '$v1');
      expect((await s.state()).installedVersion, v1);
      expect(dir.listSync().where((f) => f.path.endsWith('.part')), isEmpty);
      expect(http.count('https://cdn.test/db/$v2/content.db.gz'), 3);
      expect(http.count('https://fallback.test/db/$v2/content.db.gz'), 3);
      expect(delays, ContentPackService.backoff + ContentPackService.backoff);
      // Siet sa nevzdava natrvalo: dalsi beh to skusi znova.
      expect((await s.state()).rejectedVersion, isNull);
    });

    test('primary 404 falls back to fallback_url', () async {
      final s = service();
      await install(s);
      final pub = await publish(v2);
      http
        ..routes.remove('https://cdn.test/db/$v2/content.db.gz')
        ..serve('https://fallback.test/db/$v2/content.db.gz', pub.gz);
      expect(await s.checkForUpdate(), const Ok(ContentUpdateOutcome.updated));
      expect(http.count('https://cdn.test/db/$v2/content.db.gz'), 1);
      expect(delays, isEmpty);
    });

    test('higher min_app_version skips update', () async {
      final s = service();
      await install(s);
      await publish(v2, minApp: '99.0.0', disabledIds: ['quote:q_2255']);
      expect(
        await s.checkForUpdate(),
        const Ok(ContentUpdateOutcome.appTooOld),
      );
      expect(await activeVersion(), '$v1');
      expect(http.count('https://cdn.test/db/$v2/content.db.gz'), 0);
      // disabled_ids sa aplikuju aj bez novej db.
      expect((await s.state()).disabledIds, {'quote:q_2255'});
    });

    test('same or lower content_version is not newer', () async {
      final s = service();
      await install(s);
      await publish(v1, disabledIds: ['quote:q_0001']);
      expect(await s.checkForUpdate(), const Ok(ContentUpdateOutcome.notNewer));
      await publish(v1 - 1, disabledIds: ['quote:q_0002']);
      expect(await s.checkForUpdate(), const Ok(ContentUpdateOutcome.notNewer));
      // Starsi manifest neprepise disabled_ids.
      expect((await s.state()).disabledIds, {'quote:q_0001'});
    });

    test('different schema_version is skipped', () async {
      final s = service();
      await install(s);
      await publish(v2, schemaVersion: ContentDb.contractVersion + 1);
      expect(
        await s.checkForUpdate(),
        const Ok(ContentUpdateOutcome.schemaIncompatible),
      );
    });

    test('downloaded db failing integrity is rejected', () async {
      final s = service();
      await install(s);
      await publish(v2, corruptText: true);
      expect(
        await s.checkForUpdate(),
        const Err<ContentUpdateOutcome>(ContentIntegrityFailed('empty')),
      );
      expect(await activeVersion(), '$v1');
      expect((await s.state()).rejectedVersion, v2);
    });

    test('db content_version must match manifest', () async {
      final s = service();
      await install(s);
      await publish(v2, metaVersion: v2 + 5);
      expect(
        await s.checkForUpdate(),
        const Err<ContentUpdateOutcome>(
          ContentIntegrityFailed('content_version'),
        ),
      );
    });

    test('signed but malformed manifest is rejected', () async {
      final s = service();
      await install(s);
      final bad = Uint8List.fromList('{"schema": 1}'.codeUnits);
      http
        ..serve('$cdn/manifest.json', bad)
        ..serve('$cdn/manifest.json.sig', await keys.contentA.sign(bad));
      expect(
        await s.checkForUpdate(),
        const Err<ContentUpdateOutcome>(ContentIntegrityFailed('manifest')),
      );
    });

    test('manifest from mirror when cdn is down', () async {
      final s = service();
      await install(s);
      final pub = await publish(v2);
      final sig = await keys.contentA.sign(pub.manifest);
      http
        ..serve('$mirror/manifest.json', pub.manifest)
        ..serve('$mirror/manifest.json.sig', sig)
        ..routes['$cdn/manifest.json'] = () => status(503);
      expect(await s.checkForUpdate(), const Ok(ContentUpdateOutcome.updated));
      expect(http.count('$cdn/manifest.json'), 3);
    });

    test('missing signature file tries next mirror', () async {
      final s = service();
      await install(s);
      final pub = await publish(v2);
      http.routes.remove('$cdn/manifest.json.sig');
      expect(
        await s.checkForUpdate(),
        const Err<ContentUpdateOutcome>(HttpStatus(404)),
      );
      expect(http.count('$mirror/manifest.json'), 1);
      expect(pub.manifest, isNotEmpty);
    });

    test('oversized manifest is rejected', () async {
      final s = service();
      await install(s);
      http.serve('$cdn/manifest.json', List.filled((1 << 20) + 1, 32));
      expect(
        await s.checkForUpdate(),
        const Err<ContentUpdateOutcome>(ContentIntegrityFailed('size')),
      );
      expect(failureCodes(log), contains('data.content_integrity.size'));
    });

    test('without endpoints nothing is fetched', () async {
      final s = buildService(
        dir: dir,
        bundled: bundled,
        http: http,
        keys: keys,
        log: log,
        endpoints: ContentEndpoints.none,
      );
      expect(
        await s.checkForUpdate(),
        const Ok(ContentUpdateOutcome.notConfigured),
      );
      expect(http.requests, isEmpty);
    });
  });

  group('dev content and sections (contract v1)', () {
    test('prod (no dev content) skips a dev manifest', () {
      final m = _manifest(dev: true);
      expect(
        ContentPackService.decide(m, appVersion: SemVer.parse('1.0.0')),
        ContentUpdateOutcome.devContentRejected,
      );
      expect(
        ContentPackService.decide(
          m,
          appVersion: SemVer.parse('1.0.0'),
          allowDevContent: true,
        ),
        isNull,
      );
      expect(
        ContentPackService.decide(
          _manifest(dev: false),
          appVersion: SemVer.parse('1.0.0'),
        ),
        isNull,
      );
    });

    test('manifest sections_sha256 must match the downloaded db', () async {
      final s = service();
      await install(s);
      final db = fixtureDbBytes(tmp, v2);
      final gz = Uint8List.fromList(gzip.encode(db));
      final manifest = manifestBytes(
        contentVersion: v2,
        db: db,
        gz: gz,
        sectionsSha256: 'd' * 64,
      );
      http
        ..serve('$cdn/manifest.json', manifest)
        ..serve('$cdn/manifest.json.sig', await keys.contentA.sign(manifest))
        ..serve('https://cdn.test/db/$v2/content.db.gz', gz);
      expect(
        await s.checkForUpdate(),
        const Err<ContentUpdateOutcome>(
          ContentIntegrityFailed('sections_sha256'),
        ),
      );
      expect(await activeVersion(), '$v1');
    });

    test('policy is defaults (no remote config in v1)', () async {
      final s = service();
      final policy = s.policyOf(await s.state());
      expect(policy.isFeatureEnabled(RemoteFeature.contentAutoUpdate), isTrue);
      expect(policy.updateRequired, isFalse);
    });
  });
}
