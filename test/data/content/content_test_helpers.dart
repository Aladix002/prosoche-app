// Spolocne pomocky pre testy lib/data/content: testovacie kluce (generovane
// v teste zo seedu), podpisovanie, fixture content.db, fake siet a assety.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/content/bundled_content.dart';
import 'package:prosoche/data/content/content_http_client.dart';
import 'package:prosoche/data/content/content_pack_service.dart';
import 'package:prosoche/data/content/sem_ver.dart';
import 'package:prosoche/data/content/trusted_keys.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/data/db/content_integrity.dart';

import '../db/fixtures/content_fixture.dart';

final _ed = Ed25519();

/// Testovaci kluc (seed v kode, len pre testy).
class TestKey {
  TestKey._(this.kid, this.role, this.pair, this.publicKey);

  static Future<TestKey> create(String kid, KeyRole role, int seed) async {
    final pair = await _ed.newKeyPairFromSeed(List<int>.filled(32, seed));
    final pub = await pair.extractPublicKey();
    return TestKey._(kid, role, pair, Uint8List.fromList(pub.bytes));
  }

  final String kid;
  final KeyRole role;
  final SimpleKeyPair pair;
  final Uint8List publicKey;

  TrustedKey get trusted => TrustedKey(kid, base64Encode(publicKey), role);

  /// Obalka `.sig` (docs/06 B.2).
  Future<Uint8List> sign(List<int> payload, {String? asKid}) async {
    final sig = await _ed.sign(payload, keyPair: pair);
    return utf8.encode(
      jsonEncode({
        'alg': 'Ed25519',
        'kid': asKid ?? kid,
        'sig': base64Encode(sig.bytes),
      }),
    );
  }
}

class TestKeys {
  TestKeys._(this.root, this.contentA, this.contentB);

  static Future<TestKeys> create() async => TestKeys._(
    await TestKey.create('test-root-1', KeyRole.root, 1),
    await TestKey.create('test-content-a', KeyRole.content, 2),
    await TestKey.create('test-content-b', KeyRole.content, 3),
  );

  final TestKey root;
  final TestKey contentA;
  final TestKey contentB;

  TrustedKeySet get set =>
      TrustedKeySet([root.trusted, contentA.trusted, contentB.trusted]);
}

/// Integrita nad malym fixture (dev obsah povoleny).
ContentIntegrityChecker fixtureIntegrity() =>
    const ContentIntegrityChecker(allowDevContent: true);

/// Bajty fixture content.db s danou `meta.content_version`.
Uint8List fixtureDbBytes(
  Directory tmp,
  int contentVersion, {
  bool corruptText = false,
}) {
  final file = File(p.join(tmp.path, 'fx_${contentVersion}_$corruptText.db'));
  if (file.existsSync()) file.deleteSync();
  final db = buildContentFixture(file.path)
    ..execute("UPDATE meta SET value = ? WHERE key = 'content_version'", [
      '$contentVersion',
    ]);
  if (corruptText) {
    db.execute('DELETE FROM card');
  }
  db.close();
  final bytes = file.readAsBytesSync();
  file.deleteSync();
  return bytes;
}

String sha(List<int> b) => sha256.convert(b).toString();

/// `meta.sections_sha256` fixture (rovnaka pre kazdu `content_version`).
String fixtureSectionsSha256() {
  final db = buildContentFixture();
  try {
    return db
            .select("SELECT value FROM meta WHERE key = 'sections_sha256'")
            .single['value']
        as String;
  } finally {
    db.close();
  }
}

/// Manifest ako `prosoche-content/pipeline/manifest.py` `build_manifest`.
Uint8List manifestBytes({
  required int contentVersion,
  required List<int> db,
  required List<int> gz,
  String minApp = '0.1.0',
  int schemaVersion = ContentDb.contractVersion,
  List<String> disabledIds = const [],
  String kid = 'test-content-a',
  String? sectionsSha256,
  bool devContent = true,
}) => utf8.encode(
  const JsonEncoder.withIndent('  ').convert({
    'schema': 1,
    'content_version': contentVersion,
    'schema_version': schemaVersion,
    'min_app_version': minApp,
    'created_at': '2026-01-01T00:00:00Z',
    'kid': kid,
    'db': {
      'url': 'https://cdn.test/db/$contentVersion/content.db.gz',
      'fallback_url': 'https://fallback.test/db/$contentVersion/content.db.gz',
      'compression': 'gzip',
      'sha256': sha(db),
      'size': db.length,
      'gz_sha256': sha(gz),
      'gz_size': gz.length,
    },
    'sections_sha256': sectionsSha256 ?? fixtureSectionsSha256(),
    'dev_content': devContent,
    'disabled_ids': disabledIds,
    'sources': [
      {'id': 'fx-text', 'kind': 'text', 'version': 'fx1'},
    ],
  }),
);

/// Odpoved fake servera.
typedef Handler = FutureOr<ContentHttpResponse> Function();

ContentHttpResponse ok(List<int> body, {int chunk = 64 * 1024}) =>
    ContentHttpResponse(200, _chunks(body, chunk));

ContentHttpResponse status(int code) =>
    ContentHttpResponse(code, const Stream.empty());

/// Prerusene spojenie po [after] bajtoch.
ContentHttpResponse interrupted(List<int> body, int after) =>
    ContentHttpResponse(200, () async* {
      yield body.sublist(0, after);
      throw const ContentHttpException(Offline());
    }());

Stream<List<int>> _chunks(List<int> body, int chunk) async* {
  for (var i = 0; i < body.length; i += chunk) {
    yield body.sublist(i, i + chunk > body.length ? body.length : i + chunk);
  }
}

/// Fake siet: URL -> handler, inak 404.
class FakeHttpClient implements ContentHttpClient {
  final routes = <String, Handler>{};
  final requests = <String>[];
  bool closed = false;

  void serve(String url, List<int> body) => routes[url] = () => ok(body);

  @override
  Future<ContentHttpResponse> get(Uri url) async {
    requests.add(url.toString());
    final h = routes[url.toString()];
    if (h == null) return status(404);
    return await h();
  }

  int count(String url) => requests.where((r) => r == url).length;

  @override
  void close() => closed = true;
}

/// Pribalena db v pamati; [loadDbArchive] vrati `gzip.encode(db)`, alebo
/// [archive], ak je nastaveny (napr. poskodeny gzip).
class MemoryBundledSource implements BundledContentSource {
  MemoryBundledSource(this.db, [this.manifest]);

  Uint8List? db;
  Uint8List? manifest;
  Uint8List? archive;

  @override
  Future<Uint8List> loadDbArchive() async {
    if (archive case final a?) return a;
    final raw = db ?? (throw StateError('no asset'));
    return Uint8List.fromList(gzip.encode(raw));
  }

  @override
  Future<Uint8List?> loadManifest() async => manifest;
}

const endpoints = ContentEndpoints([
  'https://cdn.test/latest/{file}',
  'https://mirror.test/latest/{file}',
]);

const cdn = 'https://cdn.test/latest';
const mirror = 'https://mirror.test/latest';

AppLogger testLogger(RingBufferLog log) =>
    AppLogger(sinks: [log], echoToConsole: false, minLevel: LogLevel.trace);

List<String> failureCodes(RingBufferLog log) => [
  for (final e in log.entries)
    if (e.kv['code'] case final String c) c,
];

ContentPackService buildService({
  required Directory dir,
  required BundledContentSource bundled,
  required FakeHttpClient http,
  required TestKeys keys,
  required RingBufferLog log,
  String appVersion = '0.1.0',
  ContentEndpoints endpoints = endpoints,
  List<Duration>? delays,
}) => ContentPackService(
  directory: () async => dir,
  bundled: bundled,
  http: http,
  keys: keys.set,
  appVersion: SemVer.parse(appVersion),
  logger: testLogger(log),
  endpoints: endpoints,
  integrity: fixtureIntegrity(),
  delay: (d) async => delays?.add(d),
);
