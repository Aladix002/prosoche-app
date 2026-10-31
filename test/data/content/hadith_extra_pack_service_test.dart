import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/content/content_pack_service.dart';
import 'package:prosoche/data/content/hadith_extra_pack_service.dart';

import 'content_test_helpers.dart';
import 'hadith_extra_pack_test_helpers.dart';

const v1 = 2026010100;
const v2 = 2026020100;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late Directory dir;
  late TestKeys keys;
  late FakeHttpClient http;
  late RingBufferLog log;
  late List<Duration> delays;
  late Uint8List pack1;
  late Uint8List pack1Gz;
  late Uint8List db1;
  late MemoryBundledSource bundled;
  late ContentPackService content;
  late HadithExtraPackService service;

  setUpAll(() async => keys = await TestKeys.create());

  /// Manifest pre content.db [db] (+ balik), podpisany a na CDN.
  Future<Uint8List> publish({
    required int cv,
    required Uint8List db,
    Uint8List? pack,
    Uint8List? packGz,
    int packSchemaVersion = 1,
    bool serveDb = false,
  }) async {
    final gz = Uint8List.fromList(gzip.encode(db));
    final m = manifestWithPack(
      contentVersion: cv,
      db: db,
      gz: gz,
      pack: pack,
      packGz: packGz,
      packSchemaVersion: packSchemaVersion,
    );
    http
      ..serve('$cdn/manifest.json', m)
      ..serve('$cdn/manifest.json.sig', await keys.contentA.sign(m));
    if (serveDb) http.serve('https://cdn.test/db/$cv/content.db.gz', gz);
    if (packGz != null) http.serve(packUrl(cv), packGz);
    return m;
  }

  HadithExtraPackService build({
    ContentEndpoints endpoints = endpoints,
    HadithExtraInspector? inspect,
  }) => buildPackService(
    dir: dir,
    content: content,
    bundled: bundled,
    http: http,
    keys: keys.set,
    log: log,
    endpoints: endpoints,
    delays: delays,
    inspect: inspect,
  );

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('hadith_extra_pack');
    dir = Directory(p.join(tmp.path, 'support', 'content'));
    http = FakeHttpClient();
    log = RingBufferLog();
    delays = [];
    pack1 = packDbBytes(tmp, v1);
    pack1Gz = Uint8List.fromList(gzip.encode(pack1));
    db1 = contentDbWithPack(
      tmp,
      v1,
      packSha: sha(pack1),
      packSize: pack1.length,
    );
    bundled = MemoryBundledSource(db1);
    content = buildService(
      dir: dir,
      bundled: bundled,
      http: http,
      keys: keys,
      log: log,
      delays: delays,
    );
    service = build();
  });

  tearDown(() async {
    await service.dispose();
    await content.dispose();
    tmp.deleteSync(recursive: true);
  });

  File packFile() => File(p.join(dir.path, HadithExtraPackService.fileName));
  File contentDb() => File(p.join(dir.path, ContentPackService.dbFileName));
  List<String> leftovers() => [
    for (final f in dir.listSync())
      if (f.path.endsWith('.part') || f.path.endsWith('.next'))
        p.basename(f.path),
  ];

  test('not downloaded: repository returns null', () async {
    expect(await service.status(), const HadithExtraNotDownloaded());
    expect(await service.repository.explanationFor(11, 'en'), isNull);
    expect(const HadithExtraNotDownloaded().canDownload, isTrue);
  });

  test('download verifies, installs and opens the pack', () async {
    await publish(cv: v1, db: db1, pack: pack1, packGz: pack1Gz);
    final events = <HadithExtraPackStatus>[];
    final sub = service.changes.listen(events.add);
    expect(await service.status(), const HadithExtraNotDownloaded());

    expect(await service.download(), const Ok<void>(null));

    await pumpEventQueue();
    await sub.cancel();
    expect(packFile().readAsBytesSync(), pack1);
    expect(leftovers(), isEmpty);
    expect(await service.status(), HadithExtraReady(sizeBytes: pack1.length));
    final downloading = events.whereType<HadithExtraDownloading>().toList();
    expect(downloading.first.progress, isNull);
    expect(downloading.last.progress, 1.0);
    expect(events.last, isA<HadithExtraReady>());
    final e = await service.repository.explanationFor(11, 'en');
    expect(e!.explanation, '[PLACEHOLDER explanation 11]');

    // Uz pripraveny balik sa znova nestahuje.
    final before = http.requests.length;
    expect(await service.download(), const Ok<void>(null));
    expect(http.requests.length, before);
  });

  test('concurrent downloads share one run', () async {
    await publish(cv: v1, db: db1, pack: pack1, packGz: pack1Gz);
    final a = service.download();
    final b = service.download();
    expect(identical(a, b), isTrue);
    await a;
    expect(http.count(packUrl(v1)), 1);
  });

  test('pack hash mismatch drops the pack, content.db untouched', () async {
    await publish(cv: v1, db: db1, pack: pack1, packGz: pack1Gz);
    expect(await service.status(), const HadithExtraNotDownloaded());
    final contentBefore = contentDb().readAsBytesSync();
    final corrupt = Uint8List.fromList(pack1Gz)..[20] ^= 0xff;
    http
      ..serve(packUrl(v1), corrupt)
      ..serve(packFallbackUrl(v1), corrupt);

    final r = await service.download();

    expect(r, const Err<void>(packHashMismatch));
    expect(await service.status(), const HadithExtraFailed(packHashMismatch));
    expect(packFile().existsSync(), isFalse);
    expect(leftovers(), isEmpty);
    expect(contentDb().readAsBytesSync(), contentBefore);
    expect((await content.state()).rejectedVersion, isNull);
    // Druhy nesulad = stop (docs/06 C.6).
    expect(http.count(packUrl(v1)), 2);
    expect(await service.repository.explanationFor(11, 'en'), isNull);
  });

  test('gzip ok but inflated db differs from manifest', () async {
    final other = Uint8List.fromList(gzip.encode([...pack1, 0]));
    final m = manifestWithPack(
      contentVersion: v1,
      db: db1,
      gz: gzip.encode(db1),
      pack: pack1,
      packGz: other,
    );
    http
      ..serve('$cdn/manifest.json', m)
      ..serve('$cdn/manifest.json.sig', await keys.contentA.sign(m))
      ..serve(packUrl(v1), other);
    expect(await service.download(), const Err<void>(packHashMismatch));
    expect(leftovers(), isEmpty);
  });

  test('interrupted download keeps the old pack', () async {
    final old = packDbBytes(tmp, v1 - 1);
    dir.createSync(recursive: true);
    packFile().writeAsBytesSync(old);
    expect(await service.status(), const HadithExtraStale());
    await publish(cv: v1, db: db1, pack: pack1, packGz: pack1Gz);
    for (final url in [packUrl(v1), packFallbackUrl(v1)]) {
      http.routes[url] = () => interrupted(pack1Gz, 10);
    }

    final r = await service.download();

    expect(r, const Err<void>(Offline()));
    expect(packFile().readAsBytesSync(), old);
    expect(leftovers(), isEmpty);
    expect(await service.status(), const HadithExtraFailed(Offline()));
    expect(await service.repository.explanationFor(11, 'en'), isNull);
    expect(http.count(packUrl(v1)), 3);
    expect(http.count(packFallbackUrl(v1)), 3);
    expect(delays, hasLength(4));
  });

  test('fallback url after 404', () async {
    await publish(cv: v1, db: db1, pack: pack1, packGz: pack1Gz);
    http
      ..routes.remove(packUrl(v1))
      ..serve(packFallbackUrl(v1), pack1Gz);
    expect(await service.download(), const Ok<void>(null));
    expect(http.count(packUrl(v1)), 1);
  });

  test('pack becomes stale after content.db update', () async {
    await publish(cv: v1, db: db1, pack: pack1, packGz: pack1Gz);
    expect(await service.download(), const Ok<void>(null));
    expect(await service.repository.explanationFor(11, 'en'), isNotNull);

    final pack2 = packDbBytes(tmp, v2);
    final pack2Gz = Uint8List.fromList(gzip.encode(pack2));
    final db2 = contentDbWithPack(
      tmp,
      v2,
      packSha: sha(pack2),
      packSize: pack2.length,
    );
    await publish(cv: v2, db: db2, pack: pack2, packGz: pack2Gz, serveDb: true);
    final stale = service.changes.firstWhere((s) => s is HadithExtraStale);

    expect(
      await content.checkForUpdate(),
      const Ok(ContentUpdateOutcome.updated),
    );

    expect(await stale, const HadithExtraStale());
    expect(await service.repository.explanationFor(11, 'en'), isNull);
    expect(packFile().readAsBytesSync(), pack1);

    // Ponuka stiahnut znova: novy balik k novej content.db.
    expect(await service.download(), const Ok<void>(null));
    expect(packFile().readAsBytesSync(), pack2);
    expect(await service.status(), HadithExtraReady(sizeBytes: pack2.length));
    expect(await service.repository.explanationFor(11, 'en'), isNotNull);
  });

  test('remote manifest newer than content.db', () async {
    final db2 = contentDbWithPack(tmp, v2, packSha: sha(pack1), packSize: 1);
    await publish(cv: v2, db: db2, pack: pack1, packGz: pack1Gz);
    expect(
      await service.download(),
      const Err<void>(packContentVersionMismatch),
    );
  });

  test('bad signature, no bundled manifest', () async {
    final m = await publish(cv: v1, db: db1, pack: pack1, packGz: pack1Gz);
    final badA = await keys.contentB.sign([...m, 1]);
    final badB = await keys.contentB.sign([0]);
    http
      ..serve('$cdn/manifest.json.sig', badA)
      ..serve('$mirror/manifest.json', m)
      ..serve('$mirror/manifest.json.sig', badB);
    expect(
      await service.download(),
      const Err<void>(SecurityFailure.badSignature()),
    );
    expect(http.count(packUrl(v1)), 0);
  });

  test('offline manifest is a network failure', () async {
    expect(await service.download(), const Err<void>(HttpStatus(404)));
    expect(await service.status(), const HadithExtraFailed(HttpStatus(404)));
  });

  test('manifest too large', () async {
    http
      ..serve('$cdn/manifest.json', Uint8List(2 << 20))
      ..serve('$mirror/manifest.json', Uint8List(2 << 20));
    expect(
      await service.download(),
      const Err<void>(ContentIntegrityFailed('size')),
    );
  });

  test('bundled manifest without CONTENT_REPO', () async {
    bundled.manifest = manifestWithPack(
      contentVersion: v1,
      db: db1,
      gz: gzip.encode(db1),
      pack: pack1,
      packGz: pack1Gz,
    );
    http.serve(packUrl(v1), pack1Gz);
    await service.dispose();
    service = build(endpoints: ContentEndpoints.none);
    expect(await service.download(), const Ok<void>(null));
    expect(http.requests, [packUrl(v1)]);
  });

  test('manifest without packs', () async {
    await publish(cv: v1, db: db1);
    expect(await service.download(), const Err<void>(unknownPack));
  });

  test('manifest pack differs from content.db meta', () async {
    final other = packDbBytes(tmp, v1, meta: {'row_count': '9'});
    await publish(
      cv: v1,
      db: db1,
      pack: other,
      packGz: Uint8List.fromList(gzip.encode(other)),
    );
    expect(await service.download(), const Err<void>(packHashMismatch));
    expect(http.count(packUrl(v1)), 0);
  });

  test('unsupported pack schema is not downloaded', () async {
    await publish(
      cv: v1,
      db: db1,
      pack: pack1,
      packGz: pack1Gz,
      packSchemaVersion: 2,
    );
    expect(await service.download(), const Err<void>(packSchemaMismatch));
    expect(http.count(packUrl(v1)), 0);
  });

  group('pack contents', () {
    Future<Result<void>> withPack(Uint8List pack) async {
      final db = contentDbWithPack(
        tmp,
        v1,
        packSha: sha(pack),
        packSize: pack.length,
      );
      bundled.db = db;
      await publish(
        cv: v1,
        db: db,
        pack: pack,
        packGz: Uint8List.fromList(gzip.encode(pack)),
      );
      return await service.download();
    }

    test('user_version mismatch', () async {
      expect(
        await withPack(packDbBytes(tmp, v1, userVersion: 2)),
        const Err<void>(packSchemaMismatch),
      );
      expect(packFile().existsSync(), isFalse);
      expect(leftovers(), isEmpty);
    });

    test('pack_id mismatch', () async {
      expect(
        await withPack(packDbBytes(tmp, v1, meta: {'pack_id': 'other'})),
        const Err<void>(packSchemaMismatch),
      );
    });

    test('content_version mismatch', () async {
      expect(
        await withPack(packDbBytes(tmp, v1 - 1)),
        const Err<void>(packContentVersionMismatch),
      );
    });

    test('not a database', () async {
      expect(
        await withPack(Uint8List.fromList(List.filled(600, 7))),
        const Err<void>(packHashMismatch),
      );
    });
  });

  test('content.db without pack meta: unavailable', () async {
    bundled.db = contentDbWithPack(tmp, v1);
    expect(await service.status(), const HadithExtraUnavailable());
    expect(const HadithExtraUnavailable().canDownload, isFalse);
    expect(await service.download(), const Err<void>(unknownPack));
  });

  test('content.db missing: failed', () async {
    bundled.db = null;
    expect(
      await service.status(),
      const HadithExtraFailed(DbCorrupted('content')),
    );
    expect(await service.download(), const Err<void>(DbCorrupted('content')));
  });

  test('pushed pack without marker is verified once', () async {
    dir.createSync(recursive: true);
    packFile().writeAsBytesSync(pack1);
    expect(await service.status(), HadithExtraReady(sizeBytes: pack1.length));
    final marker = File(p.join(dir.path, HadithExtraPackService.markerName));
    expect(marker.readAsStringSync(), sha(pack1));
    expect(await service.repository.explanationFor(11, 'en'), isNotNull);

    // Novy start: marker sedi, hash sa nepocita.
    await service.dispose();
    service = build();
    expect(await service.refresh(), isA<HadithExtraReady>());

    // Iny marker a iny obsah = zastaraly.
    marker.writeAsStringSync('x');
    final bytes = Uint8List.fromList(pack1)..[pack1.length - 1] ^= 1;
    packFile().writeAsBytesSync(bytes);
    expect(await service.refresh(), const HadithExtraStale());
  });

  test('delete removes the pack, content.db stays', () async {
    await publish(cv: v1, db: db1, pack: pack1, packGz: pack1Gz);
    await service.download();
    final contentBefore = contentDb().readAsBytesSync();

    expect(await service.delete(), const HadithExtraNotDownloaded());

    expect(packFile().existsSync(), isFalse);
    expect(
      File(p.join(dir.path, HadithExtraPackService.markerName)).existsSync(),
      isFalse,
    );
    expect(contentDb().readAsBytesSync(), contentBefore);
    expect(await service.repository.explanationFor(11, 'en'), isNull);
  });

  test('status values', () {
    const d = HadithExtraDownloading(receivedBytes: 5, totalBytes: 10);
    expect(d.progress, 0.5);
    expect(const HadithExtraDownloading(totalBytes: 0).progress, isNull);
    expect(d, const HadithExtraDownloading(receivedBytes: 5, totalBytes: 10));
    expect(d.hashCode, Object.hash(5, 10));
    expect(
      {
        const HadithExtraUnavailable(),
        const HadithExtraNotDownloaded(),
        const HadithExtraStale(),
        const HadithExtraReady(sizeBytes: 1),
        const HadithExtraFailed(Offline()),
      }.map((s) => s.hashCode).toSet(),
      hasLength(5),
    );
    expect(const HadithExtraReady(sizeBytes: 1).isReady, isTrue);
    expect(const HadithExtraStale().canDownload, isTrue);
    expect(const HadithExtraFailed(Offline()).canDownload, isTrue);
    expect(d.canDownload, isFalse);
    expect(const HadithExtraBase(contentVersion: 1).announced, isFalse);
  });
}
