// Pomocky pre testy D-05: content.db s meta balika, hadith_extra.db
// (placeholder fixture z D-01) a manifest s `packs` ako prosoche-content
// `build_manifest` + `pack_entry`.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/data/content/content_pack_service.dart';
import 'package:prosoche/data/content/hadith_extra_pack_service.dart';
import 'package:prosoche/data/content/trusted_keys.dart';
import 'package:prosoche/data/db/content_db.dart';

import '../db/fixtures/content_fixture.dart';
import '../db/fixtures/hadith_extra_fixture.dart';
import 'content_test_helpers.dart';

/// Bajty fixture content.db s `content_version` a meta balika.
Uint8List contentDbWithPack(
  Directory tmp,
  int contentVersion, {
  String? packSha,
  int? packSize,
}) {
  final file = File(p.join(tmp.path, 'cdb_${contentVersion}_$packSha.db'));
  if (file.existsSync()) file.deleteSync();
  final db = buildContentFixture(file.path);
  void meta(String k, String v) =>
      db.execute('UPDATE meta SET value = ? WHERE key = ?', [v, k]);
  meta('content_version', '$contentVersion');
  if (packSha != null) meta('hadith_extra_sha256', packSha);
  if (packSize != null) meta('hadith_extra_size', '$packSize');
  db.close();
  final bytes = file.readAsBytesSync();
  file.deleteSync();
  return bytes;
}

/// Bajty fixture hadith_extra.db pre `content_version`.
Uint8List packDbBytes(
  Directory tmp,
  int contentVersion, {
  Map<String, String> meta = const {},
  int? userVersion,
}) {
  final file = File(p.join(tmp.path, 'pack_${contentVersion}_${meta.length}'));
  if (file.existsSync()) file.deleteSync();
  final db = buildHadithExtraFixture(file.path, {
    'content_version': '$contentVersion',
    ...meta,
  });
  if (userVersion != null) db.execute('PRAGMA user_version = $userVersion');
  db.close();
  final bytes = file.readAsBytesSync();
  file.deleteSync();
  return bytes;
}

String packUrl(int cv) => 'https://cdn.test/packs/$cv/hadith_extra.db.gz';
String packFallbackUrl(int cv) =>
    'https://fallback.test/packs/$cv/hadith_extra.db.gz';

/// Manifest s `packs` (poradie klucov ako `build_manifest`).
Uint8List manifestWithPack({
  required int contentVersion,
  required List<int> db,
  required List<int> gz,
  List<int>? pack,
  List<int>? packGz,
  int packSchemaVersion = 1,
}) => utf8.encode(
  const JsonEncoder.withIndent('  ').convert({
    'schema': 1,
    'content_version': contentVersion,
    'schema_version': ContentDb.contractVersion,
    'min_app_version': '0.1.0',
    'created_at': '2026-01-01T00:00:00Z',
    'kid': 'test-content-a',
    'db': {
      'url': 'https://cdn.test/db/$contentVersion/content.db.gz',
      'fallback_url': 'https://fallback.test/db/$contentVersion/content.db.gz',
      'compression': 'gzip',
      'sha256': sha(db),
      'size': db.length,
      'gz_sha256': sha(gz),
      'gz_size': gz.length,
    },
    if (pack != null && packGz != null)
      'packs': [
        {
          'id': 'hadith_extra',
          'url': packUrl(contentVersion),
          'fallback_url': packFallbackUrl(contentVersion),
          'compression': 'gzip',
          'sha256': sha(pack),
          'size': pack.length,
          'gz_sha256': sha(packGz),
          'gz_size': packGz.length,
          'schema_version': packSchemaVersion,
          'optional': true,
        },
      ],
    'uthmani_sha256': fixtureUthmaniSha256(),
    'disabled_ids': <String>[],
    'sources': [
      {'id': 'fx-uthmani', 'kind': 'quran_text', 'lang': 'ar', 'version': '1'},
    ],
  }),
);

HadithExtraPackService buildPackService({
  required Directory dir,
  required ContentPackService content,
  required MemoryBundledSource bundled,
  required FakeHttpClient http,
  required TrustedKeySet keys,
  required RingBufferLog log,
  ContentEndpoints endpoints = endpoints,
  List<Duration>? delays,
  HadithExtraInspector? inspect,
}) => HadithExtraPackService(
  directory: () async => dir,
  content: content,
  http: http,
  keys: keys,
  bundled: bundled,
  logger: testLogger(log),
  endpoints: endpoints,
  inspect: inspect ?? readHadithExtraMeta,
  delay: (d) async => delays?.add(d),
);
