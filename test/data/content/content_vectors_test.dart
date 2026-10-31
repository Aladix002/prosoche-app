// Testovacie vektory z prosoche-content/tests/vectors (kopia
// v test/fixtures/content_vectors, len verejne kluce). Kazdy pripad musi dat
// rovnaky vysledok ako pipeline/sign.py (`expect`) a logika appky
// (`app_expect`).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/content/content_documents.dart';
import 'package:prosoche/data/content/content_pack_service.dart';
import 'package:prosoche/data/content/db_archive.dart';
import 'package:prosoche/data/content/sem_ver.dart';
import 'package:prosoche/data/content/signature_verifier.dart';
import 'package:prosoche/data/content/trusted_keys.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:sqlite3/sqlite3.dart';

const _root = 'test/fixtures/content_vectors';

/// AppFailure.code -> nazov vo vektoroch (06 C.2).
const _vectorName = {
  'security.malformed_signature': 'malformedSignature',
  'security.unknown_alg': 'unknownAlgorithm',
  'security.unknown_key': 'unknownKey',
  'security.wrong_key_role': 'wrongKeyRole',
  'security.bad_signature': 'badSignature',
  'data.content_integrity.sha256': 'dbHashMismatch',
  'data.content_integrity.manifest': 'invalidManifest',
};

Uint8List _read(String rel) => File(p.join(_root, rel)).readAsBytesSync();

Map<String, Object?> get _doc =>
    jsonDecode(File(p.join(_root, 'cases.json')).readAsStringSync())
        as Map<String, Object?>;

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

/// Overenie podpisu a (pri `gz`) hashov ako `sign.py verify`.
Future<String> _expect(Map<String, Object?> c, Directory tmp) async {
  final payload = _read(c['payload']! as String);
  final verified = await SignatureVerifier(_keys()).verify(
    payload,
    _read(c['sig']! as String),
    allowed: {
      for (final r in (c['allowed_roles']! as List).cast<String>())
        KeyRole.fromWire(r)!,
    },
  );
  if (verified case Err(:final failure)) return _vectorName[failure.code]!;
  final parsed = ContentManifest.parse(payload);
  if (parsed case Err(:final failure)) return _vectorName[failure.code]!;
  final manifest = parsed.valueOrNull!;
  final gz = c['gz'] as String?;
  if (gz != null) {
    final file = File(p.join(_root, gz));
    final out = File(p.join(tmp.path, '${c['name']}.db'));
    final r = await checkArchive(
      file,
      manifest.db,
    ).then2((_) => inflateArchive(file, out, manifest.db));
    if (r case Err(:final failure)) return _vectorName[failure.code]!;
    expect(out.lengthSync(), manifest.db.size);
    // Rozbalena db je platna content.db v1 a sedi s manifestom.
    final db = sqlite3.open(out.path, mode: OpenMode.readOnly);
    addTearDown(db.close);
    final meta = {
      for (final r in db.select('SELECT key, value FROM meta'))
        r['key'] as String: r['value'] as String,
    };
    expect(meta['sections_sha256'], manifest.sectionsSha256);
    expect(meta['dev_content'], manifest.devContent ? '1' : '0');
    expect(meta['schema_version'], '${ContentDb.contractVersion}');
  }
  return 'ok';
}

/// Rozhodnutie appky nad overenym manifestom.
String _appResult(Map<String, Object?> c, Map<String, Object?> app) {
  final m = ContentManifest.parse(_read(c['payload']! as String)).valueOrNull!;
  final outcome = ContentPackService.decide(
    m,
    appVersion: SemVer.parse(app['app_version'] as String? ?? '1.0.0'),
    installedVersion: app['installed_content_version'] as int?,
    allowDevContent: app['allow_dev_content']! as bool,
  );
  return outcome?.name ?? 'download';
}

void main() {
  final cases = (_doc['cases']! as List).cast<Map<String, Object?>>();

  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('vectors'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('vectors are present and manifest only', () {
    expect(cases, hasLength(19));
    expect(cases.map((c) => c['kind']).toSet(), {'manifest'});
  });

  for (final c in cases) {
    test('${c['name']}: ${c['expect']}', () async {
      expect(await _expect(c, tmp), c['expect']);
      final app = c['app_expect'] as Map<String, Object?>?;
      if (app != null) expect(_appResult(c, app), app['result']);
    });
  }

  test('manifest_ok carries v1 fields', () {
    final m = ContentManifest.parse(_read('cases/manifest_ok/manifest.json'))
        .valueOrNull!;
    expect(m.disabledIds, {'quote:meditations.2.1.a'});
    expect(m.contentVersion, _doc['content_version']);
    expect(m.sectionsSha256, _doc['sections_sha256']);
    expect(m.devContent, isTrue);
    expect(m.minAppVersion, SemVer.parse('1.0.0'));
  });

  test('dev key in the app matches the vectors (content-dev)', () {
    final doc = jsonDecode(
      File(p.join(_root, 'public_keys.json')).readAsStringSync(),
    ) as Map<String, Object?>;
    final dev = (doc['keys']! as List).cast<Map<String, Object?>>().firstWhere(
      (k) => k['kid'] == 'content-dev',
    );
    expect(kDevTrustedKeys.single.publicKeyB64, dev['public_key_b64']);
  });
}
