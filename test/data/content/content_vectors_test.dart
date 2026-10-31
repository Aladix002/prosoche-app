// Testovacie vektory zo prosoche-content/tests/vectors (len testovacie kluce),
// kopia v test/fixtures/content_vectors. Kazdy pripad musi dat rovnaky
// vysledok ako pipeline/sign.py (`expect`) a logika appky (`app_expect`).
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

const _root = 'test/fixtures/content_vectors';

/// AppFailure.code -> nazov vo vektoroch (06 C.2).
const _vectorName = {
  'security.malformed_signature': 'malformedSignature',
  'security.unknown_alg': 'unknownAlgorithm',
  'security.unknown_key': 'unknownKey',
  'security.wrong_key_role': 'wrongKeyRole',
  'security.revoked_key': 'revokedKey',
  'security.bad_signature': 'badSignature',
  'data.content_integrity.sha256': 'dbHashMismatch',
  'data.content_integrity.manifest': 'invalidManifest',
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

/// Overenie podpisu a (pri manifeste s `gz`) hashov ako `sign.py verify`.
Future<String> _expect(Map<String, Object?> c, Directory tmp) async {
  final payload = _read(c['payload']! as String);
  final verified = await SignatureVerifier(_keys()).verify(
    payload,
    _read(c['sig']! as String),
    allowed: {
      for (final r in (c['allowed_roles']! as List).cast<String>())
        KeyRole.fromWire(r)!,
    },
    revoked: {...(c['revoked']! as List).cast<String>()},
  );
  if (verified case Err(:final failure)) return _vectorName[failure.code]!;
  final gz = c['gz'] as String?;
  if (c['kind'] == 'manifest') {
    final parsed = ContentManifest.parse(payload);
    if (parsed case Err(:final failure)) return _vectorName[failure.code]!;
    final manifest = parsed.valueOrNull!;
    if (gz != null) {
      final file = File(p.join(_root, gz));
      final out = File(p.join(tmp.path, '${c['name']}.db'));
      final r = await checkArchive(
        file,
        manifest.db,
      ).then2((_) => inflateArchive(file, out, manifest.db));
      if (r case Err(:final failure)) return _vectorName[failure.code]!;
      expect(out.lengthSync(), manifest.db.size);
    }
    final pack = c['pack'] as Map<String, Object?>?;
    if (pack != null) {
      // Balik stahuje D-05; tu len rovnake overenie ako pri db.
      final info = manifest.packs[pack['id']];
      if (info == null) return 'unknownPack';
      final file = File(p.join(_root, pack['gz']! as String));
      final out = File(p.join(tmp.path, '${c['name']}.pack.db'));
      final r = await checkArchive(
        file,
        info.archive,
      ).then2((_) => inflateArchive(file, out, info.archive));
      if (r is Err) return 'packHashMismatch';
      expect(out.lengthSync(), info.archive.size);
    }
  }
  return 'ok';
}

/// Rozhodnutie appky nad overenym dokumentom.
String _appResult(Map<String, Object?> c, Map<String, Object?> app) {
  final payload = _read(c['payload']! as String);
  switch (c['kind']) {
    case 'manifest':
      final m = ContentManifest.parse(payload).valueOrNull!;
      final outcome = ContentPackService.decide(
        m,
        appVersion: SemVer.parse(app['app_version'] as String? ?? '1.0.0'),
        installedVersion: app['installed_content_version'] as int?,
      );
      return outcome!.name;
    case 'remote_config':
      final rc = RemoteConfig.parse(payload).valueOrNull!;
      return rc.isExpiredAt(DateTime.parse(app['now']! as String))
          ? 'expired'
          : 'ok';
  }
  throw StateError('unknown kind ${c['kind']}');
}

void main() {
  final cases =
      ((jsonDecode(File(p.join(_root, 'cases.json')).readAsStringSync())
                  as Map<String, Object?>)['cases']!
              as List)
          .cast<Map<String, Object?>>();

  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('vectors'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('vectors are present', () => expect(cases, hasLength(26)));

  for (final c in cases) {
    test('${c['name']}: ${c['expect']}', () async {
      expect(await _expect(c, tmp), c['expect']);
      final app = c['app_expect'] as Map<String, Object?>?;
      if (app != null) expect(_appResult(c, app), app['result']);
    });
  }

  test('manifest_pack_ok carries packs', () {
    final m = ContentManifest.parse(
      _read('cases/manifest_pack_ok/manifest.json'),
    ).valueOrNull!;
    final pack = m.packs['hadith_extra']!;
    expect(m.packs.keys, ['hadith_extra']);
    expect(pack.id, 'hadith_extra');
    expect(pack.optional, isTrue);
    expect(pack.schemaVersion, 1);
    expect(pack.archive.size, 456);
  });

  test('verified documents parse', () async {
    for (final c in cases.where((c) => c['expect'] == 'ok')) {
      final payload = _read(c['payload']! as String);
      final parsed = switch (c['kind']) {
        'manifest' => ContentManifest.parse(payload).isOk,
        'remote_config' => RemoteConfig.parse(payload).isOk,
        _ => Revocations.parse(payload, rootKids: ['test-root-1']).isOk,
      };
      expect(parsed, isTrue, reason: '${c['name']}');
    }
  });

  test('manifest_ok carries disabled_ids', () {
    final m = ContentManifest.parse(_read('cases/manifest_ok/manifest.json'))
        .valueOrNull!;
    expect(m.disabledIds, {'hadith:1234'});
    expect(m.contentVersion, 2026010101);
    expect(m.minAppVersion, SemVer.parse('1.0.0'));
  });
}
