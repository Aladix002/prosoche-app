// Vektory manifest_pack_* (prosoche-content tests/vectors, kopia
// v test/fixtures/content_vectors) cez HadithExtraPackService.download():
// rovnaky vysledok ako `pipeline/sign.py verify_pack`.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/content/hadith_extra_pack_service.dart';
import 'package:prosoche/data/content/trusted_keys.dart';
import 'package:prosoche/data/db/content_db.dart';

import 'content_test_helpers.dart';
import 'hadith_extra_pack_test_helpers.dart';

const _root = 'test/fixtures/content_vectors';

/// AppFailure.code -> nazov vo vektoroch.
const _vectorName = {
  'security.bad_signature': 'badSignature',
  'data.content_integrity.manifest': 'invalidManifest',
  'data.content_integrity.pack_unknown': 'unknownPack',
  'data.content_integrity.pack_sha256': 'packHashMismatch',
};

Uint8List _read(String rel) => File(p.join(_root, rel)).readAsBytesSync();

TrustedKeySet _keys() {
  final doc = jsonDecode(
    File(p.join(_root, 'public_keys.json')).readAsStringSync(),
  ) as Map<String, Object?>;
  return TrustedKeySet([
    for (final k in (doc['keys']! as List).cast<Map<String, Object?>>())
      TrustedKey(
        k['kid']! as String,
        k['public_key_b64']! as String,
        KeyRole.fromWire(k['role'] as String?)!,
      ),
  ]);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final cases =
      ((jsonDecode(File(p.join(_root, 'cases.json')).readAsStringSync())
                  as Map<String, Object?>)['cases']!
              as List)
          .cast<Map<String, Object?>>()
          .where((c) => (c['name']! as String).startsWith('manifest_pack_'))
          .toList();

  // Spravny balik z vektorov (nie je to SQLite, obsah overuje inspector).
  final pack = gzip.decode(_read('hadith_extra.db.gz'));
  final okManifest = jsonDecode(
    utf8.decode(_read('cases/manifest_pack_ok/manifest.json')),
  ) as Map<String, Object?>;
  final cv = okManifest['content_version']! as int;
  final packUrl =
      ((okManifest['packs']! as List).single as Map<String, Object?>)['url']!
          as String;

  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('pack_vectors'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('all pack vectors are present', () => expect(cases, hasLength(5)));

  for (final c in cases) {
    test('${c['name']}: ${c['expect']}', () async {
      expect(c['revoked'], isEmpty);
      final dir = Directory(p.join(tmp.path, 'content'));
      final log = RingBufferLog();
      final http = FakeHttpClient()
        ..serve('$cdn/manifest.json', _read(c['payload']! as String))
        ..serve('$cdn/manifest.json.sig', _read(c['sig']! as String))
        ..serve(
          packUrl,
          _read((c['pack']! as Map<String, Object?>)['gz']! as String),
        );
      final bundled = MemoryBundledSource(
        contentDbWithPack(tmp, cv, packSha: sha(pack), packSize: pack.length),
      );
      final content = buildService(
        dir: dir,
        bundled: bundled,
        http: http,
        keys: await TestKeys.create(),
        log: log,
      );
      final service = buildPackService(
        dir: dir,
        content: content,
        bundled: bundled,
        http: http,
        keys: _keys(),
        log: log,
        inspect: (_) async => HadithExtraPackMeta(
          userVersion: 1,
          meta: {
            'pack_id': 'hadith_extra',
            'schema_version': '1',
            'base_schema_version': '${ContentDb.contractVersion}',
            'content_version': '$cv',
          },
        ),
      );
      final contentDb = File(p.join(dir.path, 'content.db'));

      final r = await service.download();

      final got = switch (r) {
        Ok() => 'ok',
        Err(:final failure) => _vectorName[failure.code] ?? failure.code,
      };
      expect(got, c['expect'], reason: c['note'] as String?);
      final packFile = File(p.join(dir.path, 'hadith_extra.db'));
      expect(packFile.existsSync(), got == 'ok');
      if (got == 'ok') expect(packFile.readAsBytesSync(), pack);
      // content.db ostava platna aj pri chybe balika.
      expect(contentDb.existsSync(), isTrue);
      expect((await content.state()).installedVersion, cv);
      await service.dispose();
      await content.dispose();
    });
  }
}
