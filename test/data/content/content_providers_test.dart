import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prosoche/core/flavor/flavor.dart';
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/content/bundled_content.dart';
import 'package:prosoche/data/content/content_http_client.dart';
import 'package:prosoche/data/content/content_pack_service.dart';
import 'package:prosoche/data/content/content_providers.dart';
import 'package:prosoche/data/content/remote_config_policy.dart';
import 'package:prosoche/data/content/sem_ver.dart';

import 'content_test_helpers.dart';

const v1 = 2026010100;
const v2 = 2026020100;

class _Bundle extends CachingAssetBundle {
  _Bundle(this.assets);

  final Map<String, Uint8List> assets;

  @override
  Future<ByteData> load(String key) async {
    final bytes = assets[key];
    if (bytes == null) throw FlutterError('Unable to load asset: $key');
    return ByteData.sublistView(bytes);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late TestKeys keys;
  late FakeHttpClient http;
  late ContentPackService service;
  late ProviderContainer container;

  setUpAll(() async => keys = await TestKeys.create());

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('content_providers');
    http = FakeHttpClient();
    service = buildService(
      dir: Directory(p.join(tmp.path, 'content')),
      bundled: MemoryBundledSource(fixtureDbBytes(tmp, v1)),
      http: http,
      keys: keys,
      log: RingBufferLog(),
    );
    container = ProviderContainer(
      overrides: [contentPackServiceProvider.overrideWithValue(service)],
    );
  });

  tearDown(() async {
    container.dispose();
    tmp.deleteSync(recursive: true);
  });

  test('contentDatabaseProvider opens verified db and reopens after '
      'update', () async {
    final db = await container.read(contentDatabaseProvider.future);
    expect(await db.contentMetaDao.metaValue('content_version'), '$v1');

    final dbBytes = fixtureDbBytes(tmp, v2);
    final gz = gzip.encode(dbBytes);
    final manifest = manifestBytes(
      contentVersion: v2,
      db: dbBytes,
      gz: gz,
      disabledIds: ['quote:q_0007'],
    );
    http
      ..serve('$cdn/manifest.json', manifest)
      ..serve('$cdn/manifest.json.sig', await keys.contentA.sign(manifest))
      ..serve('https://cdn.test/db/$v2/content.db.gz', gz);
    final sub = container.listen(disabledContentIdsProvider, (_, _) {});
    expect(
      await service.checkForUpdate(),
      const Ok(ContentUpdateOutcome.updated),
    );
    await pumpEventQueue();

    final reopened = await container.read(contentDatabaseProvider.future);
    expect(identical(reopened, db), isFalse);
    expect(await reopened.contentMetaDao.metaValue('content_version'), '$v2');
    expect(sub.read(), {'quote:q_0007'});
  });

  test('contentDatabaseProvider fails when no valid db exists', () async {
    final broken = buildService(
      dir: Directory(p.join(tmp.path, 'broken')),
      bundled: MemoryBundledSource(null),
      http: http,
      keys: keys,
      log: RingBufferLog(),
    );
    final c = ProviderContainer(
      overrides: [contentPackServiceProvider.overrideWithValue(broken)],
    );
    addTearDown(c.dispose);
    await expectLater(
      c.read(contentDatabaseProvider.future),
      throwsA(
        isA<ContentUnavailableException>().having(
          (e) => e.toString(),
          'code',
          contains('data.db_corrupted.content'),
        ),
      ),
    );
  });

  test('remoteConfigPolicyProvider uses defaults, then config', () async {
    expect(
      container
          .read(remoteConfigPolicyProvider)
          .isFeatureEnabled(RemoteFeature.contentAutoUpdate),
      isTrue,
    );
    final sub = container.listen(remoteConfigPolicyProvider, (_, _) {});
    await container.read(contentPackStateProvider.future);
    final cfg = remoteConfigBytes(autoUpdate: false);
    http
      ..serve('$cdn/remote_config.json', cfg)
      ..serve('$cdn/remote_config.json.sig', await keys.contentA.sign(cfg));
    await service.refreshRemoteConfig();
    await pumpEventQueue();
    expect(sub.read().isFeatureEnabled(RemoteFeature.contentAutoUpdate), false);
    expect(container.read(disabledContentIdsProvider), isEmpty);
  });

  test('default providers', () {
    final c = ProviderContainer(
      overrides: [flavorProvider.overrideWithValue(Flavor.prod)],
    );
    addTearDown(c.dispose);
    expect(c.read(appVersionProvider), const SemVer(0, 1, 0));
    expect(c.read(contentEndpointsProvider).isEmpty, isTrue);
    expect(c.read(trustedKeysProvider).isEmpty, isTrue);
    expect(c.read(contentIntegrityCheckerProvider).allowDevContent, isFalse);
    expect(c.read(contentHttpClientProvider), isA<IoContentHttpClient>());
    expect(
      c.read(bundledContentSourceProvider),
      isA<AssetBundledContentSource>(),
    );
    expect(c.read(contentDirectoryProvider), isA<Function>());
    expect(c.read(contentPackServiceProvider), isA<ContentPackService>());

    final dev = ProviderContainer();
    addTearDown(dev.dispose);
    expect(dev.read(trustedKeysProvider).kids, ['content-dev']);
    expect(dev.read(contentIntegrityCheckerProvider).allowDevContent, isTrue);
  });

  test('AssetBundledContentSource reads assets', () async {
    final db = Uint8List.fromList([1, 2, 3]);
    final source = AssetBundledContentSource(
      _Bundle({AssetBundledContentSource.dbArchiveAsset: db}),
    );
    expect(await source.loadDbArchive(), db);
    expect(await source.loadManifest(), isNull);
    final withManifest = AssetBundledContentSource(
      _Bundle({AssetBundledContentSource.manifestAsset: db}),
    );
    expect(await withManifest.loadManifest(), db);
  });
}
