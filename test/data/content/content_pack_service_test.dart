import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sakina/core/logging/app_logger.dart';
import 'package:sakina/core/result.dart';
import 'package:sakina/data/content/content_pack_service.dart';
import 'package:sakina/data/content/content_pack_state.dart';
import 'package:sakina/data/content/remote_config_policy.dart';
import 'package:sakina/data/content/sem_ver.dart';
import 'package:sakina/data/db/content_db.dart';
import 'package:sqlite3/sqlite3.dart';

import 'content_test_helpers.dart';

const v1 = 2026010100;
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

  ContentPackService service({String appVersion = '0.1.0', DateTime? now}) =>
      buildService(
        dir: dir,
        bundled: bundled,
        http: http,
        keys: keys,
        log: log,
        appVersion: appVersion,
        delays: delays,
        now: now,
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

    test('next start checks meta only, not the full Uthmani hash', () async {
      await install(service());
      bundled.db = null;
      // Zmena textu po instalacii: plna kontrola (17.3) bezi len pri
      // instalacii a po aktualizacii, nie pri kazdom starte.
      sqlite3.open(active().path)
        ..execute("UPDATE ayah SET text_uthmani = 'x' WHERE id = 1001")
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
      expect(r, const Err<File>(ContentIntegrityFailed('uthmani_hash')));
      expect(active().existsSync(), isFalse);
      expect(
        failureCodes(log),
        contains('data.content_integrity.uthmani_hash'),
      );
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
      await publish(v2, disabledIds: ['hadith:1234']);
      final swaps = <int>[];
      s.swaps.listen(swaps.add);

      expect(await s.checkForUpdate(), const Ok(ContentUpdateOutcome.updated));
      expect(await activeVersion(), '$v2');
      final st = await s.state();
      expect(st.installedVersion, v2);
      expect(st.origin, ContentDbOrigin.downloaded);
      expect(st.disabledIds, {'hadith:1234'});
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
      await publish(v2, minApp: '99.0.0', disabledIds: ['ayah:2255']);
      expect(
        await s.checkForUpdate(),
        const Ok(ContentUpdateOutcome.appTooOld),
      );
      expect(await activeVersion(), '$v1');
      expect(http.count('https://cdn.test/db/$v2/content.db.gz'), 0);
      // disabled_ids sa aplikuju aj bez novej db.
      expect((await s.state()).disabledIds, {'ayah:2255'});
    });

    test('same or lower content_version is not newer', () async {
      final s = service();
      await install(s);
      await publish(v1, disabledIds: ['hadith:1']);
      expect(await s.checkForUpdate(), const Ok(ContentUpdateOutcome.notNewer));
      await publish(v1 - 1, disabledIds: ['hadith:2']);
      expect(await s.checkForUpdate(), const Ok(ContentUpdateOutcome.notNewer));
      // Starsi manifest neprepise disabled_ids.
      expect((await s.state()).disabledIds, {'hadith:1'});
    });

    test('different schema_version is skipped', () async {
      final s = service();
      await install(s);
      await publish(v2, schemaVersion: 1);
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
        const Err<ContentUpdateOutcome>(ContentIntegrityFailed('uthmani_hash')),
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
      expect(await s.refreshRemoteConfig(), const Ok<Object?>(null));
      expect(http.requests, isEmpty);
    });
  });

  group('revocations', () {
    Future<void> serveRevocations(List<String> kids, TestKey signer) async {
      final rev = revocationsBytes(kids);
      http
        ..serve('$cdn/revocations.json', rev)
        ..serve('$cdn/revocations.json.sig', await signer.sign(rev));
    }

    test('root-signed revocation blocks the key permanently', () async {
      final s = service();
      await install(s);
      await publish(v2);
      await serveRevocations(['test-content-a'], keys.root);
      expect(
        await s.checkForUpdate(),
        const Err<ContentUpdateOutcome>(SecurityFailure.revokedKey()),
      );
      expect((await s.state()).revokedKids, {'test-content-a'});

      // Revokacia ostane aj ked subor zmizne; nasledovnik funguje.
      http.routes.remove('$cdn/revocations.json');
      final s2 = service();
      expect(
        await s2.checkForUpdate(),
        const Err<ContentUpdateOutcome>(SecurityFailure.revokedKey()),
      );
      await publish(v2, signer: keys.contentB);
      expect(await s2.checkForUpdate(), const Ok(ContentUpdateOutcome.updated));
    });

    test('revocation signed by content key is ignored', () async {
      final s = service();
      await install(s);
      await publish(v2);
      await serveRevocations(['test-content-b'], keys.contentA);
      expect(await s.checkForUpdate(), const Ok(ContentUpdateOutcome.updated));
      expect((await s.state()).revokedKids, isEmpty);
      expect(failureCodes(log), contains('security.wrong_key_role'));
    });

    test('revocation of a root key is invalid', () async {
      final s = service();
      await install(s);
      await serveRevocations(['test-root-1'], keys.root);
      await s.checkForUpdate();
      expect((await s.state()).revokedKids, isEmpty);
      expect(failureCodes(log), contains('data.content_integrity.revocations'));
    });

    test('same revocations twice do not rewrite state', () async {
      final s = service();
      await install(s);
      await serveRevocations(['test-content-b'], keys.root);
      await s.checkForUpdate();
      final changes = <ContentPackState>[];
      s.changes.listen(changes.add);
      await s.checkForUpdate();
      expect((await s.state()).revocationsSeq, 1);
      expect(changes.where((c) => c.revokedKids.isEmpty), isEmpty);
    });
  });

  group('remote config', () {
    Future<void> serveConfig(Uint8List bytes, {TestKey? signer}) async => http
      ..serve('$cdn/remote_config.json', bytes)
      ..serve(
        '$cdn/remote_config.json.sig',
        await (signer ?? keys.contentA).sign(bytes),
      );

    test('valid config is stored and drives the policy', () async {
      final s = service();
      await serveConfig(
        remoteConfigBytes(
          seq: 4,
          broken: ['0.1.0'],
          recommended: '0.2.0',
          extraFeatures: {
            RemoteFeature.blockerOverlay: {
              'enabled': false,
              'max_version': null,
            },
          },
        ),
      );
      final r = await s.refreshRemoteConfig();
      expect(r.valueOrNull?.seq, 4);
      final policy = s.policyOf(await s.state());
      expect(policy.updateRequired, isTrue);
      expect(policy.updateRecommended, isTrue);
      expect(policy.isFeatureEnabled(RemoteFeature.blockerOverlay), isFalse);
      expect(policy.isFeatureEnabled(RemoteFeature.audioStream), isTrue);
    });

    test('kill-switch disables content auto update', () async {
      final s = service();
      await install(s);
      await publish(v2);
      await serveConfig(remoteConfigBytes(autoUpdate: false));
      expect(
        await s.checkForUpdate(),
        const Ok(ContentUpdateOutcome.disabledByRemoteConfig),
      );
      expect(http.count('$cdn/manifest.json'), 0);
    });

    test('lower seq is a rollback and keeps the newer config', () async {
      final s = service();
      await serveConfig(remoteConfigBytes(seq: 5));
      await s.refreshRemoteConfig();
      await serveConfig(remoteConfigBytes(seq: 4, autoUpdate: false));
      expect(
        await s.refreshRemoteConfig(force: true),
        const Err<Object?>(SecurityFailure.rollback()),
      );
      expect(s.remoteConfigOf(await s.state())?.seq, 5);
    });

    test('expired config is ignored and defaults apply', () async {
      final s = service(now: DateTime.utc(2026, 5));
      await serveConfig(
        remoteConfigBytes(
          expiresAt: '2026-04-01T00:00:00Z',
          minSupported: '9.0.0',
        ),
      );
      expect(await s.refreshRemoteConfig(), const Ok<Object?>(null));
      final policy = s.policyOf(await s.state());
      expect(policy.config, isNull);
      expect(policy.updateRequired, isFalse);
    });

    test('stored config expires later and defaults apply', () async {
      await serveConfig(
        remoteConfigBytes(expiresAt: '2026-07-01T00:00:00Z', autoUpdate: false),
      );
      await service().refreshRemoteConfig();
      final later = service(now: DateTime.utc(2026, 8));
      expect(later.remoteConfigOf(await later.state()), isNull);
    });

    test('fetched at most once per 12 h unless forced', () async {
      final s = service();
      await serveConfig(remoteConfigBytes());
      await s.refreshRemoteConfig();
      await s.refreshRemoteConfig();
      expect(http.count('$cdn/remote_config.json'), 1);
      await s.refreshRemoteConfig(force: true);
      expect(http.count('$cdn/remote_config.json'), 2);
    });

    test('bad signature keeps the last valid config', () async {
      final s = service();
      await serveConfig(remoteConfigBytes(seq: 2));
      await s.refreshRemoteConfig();
      final next = remoteConfigBytes(seq: 3, autoUpdate: false);
      http
        ..serve('$cdn/remote_config.json', next)
        ..serve(
          '$cdn/remote_config.json.sig',
          await keys.contentA.sign(remoteConfigBytes(seq: 2)),
        );
      expect(
        await s.refreshRemoteConfig(force: true),
        const Err<Object?>(SecurityFailure.badSignature()),
      );
      expect(s.remoteConfigOf(await s.state())?.seq, 2);
    });

    test('config with URL is rejected', () async {
      final s = service();
      await serveConfig(
        remoteConfigBytes(
          notice: {
            'id': 'n',
            'severity': 'info',
            'text': {'en': 'see https://evil.test'},
            'show_on_versions': <String>[],
          },
        ),
      );
      expect(
        await s.refreshRemoteConfig(),
        const Err<Object?>(ContentIntegrityFailed('remote_config')),
      );
    });

    test('min_supported_version above app requires update', () async {
      final s = service(appVersion: '1.0.0');
      await serveConfig(remoteConfigBytes(minSupported: '1.2.0'));
      await s.refreshRemoteConfig();
      expect(s.policyOf(await s.state()).updateRequired, isTrue);
      expect(SemVer.parse('1.0.0+3'), const SemVer(1, 0, 0));
    });
  });
}
