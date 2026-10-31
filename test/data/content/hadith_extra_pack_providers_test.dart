import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prosoche/app/content_wiring.dart';
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/content/content_pack_service.dart';
import 'package:prosoche/data/content/content_providers.dart';
import 'package:prosoche/data/content/hadith_extra_pack_providers.dart';
import 'package:prosoche/data/repositories/cards/hadith_extra_repository.dart';

import 'content_test_helpers.dart';
import 'hadith_extra_pack_test_helpers.dart';

const v1 = 2026010100;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late Directory dir;
  late TestKeys keys;
  late FakeHttpClient http;
  late ContentPackService content;
  late ProviderContainer container;
  late Uint8List pack;

  setUpAll(() async => keys = await TestKeys.create());

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('pack_providers');
    dir = Directory(p.join(tmp.path, 'content'));
    http = FakeHttpClient();
    pack = packDbBytes(tmp, v1);
    final packGz = gzip.encode(pack);
    final db = contentDbWithPack(
      tmp,
      v1,
      packSha: sha(pack),
      packSize: pack.length,
    );
    final bundled = MemoryBundledSource(db);
    final m = manifestWithPack(
      contentVersion: v1,
      db: db,
      gz: gzip.encode(db),
      pack: pack,
      packGz: packGz,
    );
    http
      ..serve('$cdn/manifest.json', m)
      ..serve('$cdn/manifest.json.sig', await keys.contentA.sign(m))
      ..serve(packUrl(v1), packGz);
    content = buildService(
      dir: dir,
      bundled: bundled,
      http: http,
      keys: keys,
      log: RingBufferLog(),
    );
    container = ProviderContainer(
      overrides: [
        ...contentOverrides(supportDir: tmp),
        contentPackServiceProvider.overrideWithValue(content),
        contentDirectoryProvider.overrideWithValue(() async => dir),
        contentHttpClientProvider.overrideWithValue(http),
        bundledContentSourceProvider.overrideWithValue(bundled),
        contentEndpointsProvider.overrideWithValue(endpoints),
        trustedKeysProvider.overrideWithValue(keys.set),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    tmp.deleteSync(recursive: true);
  });

  test('status, download and explanations through the app wiring', () async {
    final statuses = <HadithExtraPackStatus>[];
    container.listen(
      hadithExtraPackStatusProvider,
      (_, next) => statuses.addAll([?next.value]),
      fireImmediately: true,
    );
    expect(
      await container.read(hadithExtraPackStatusProvider.future),
      const HadithExtraNotDownloaded(),
    );
    final repoBefore = container.read(hadithExtraPackRepositoryProvider);
    expect(await container.read(hadithExtraProvider((11, 'en')).future), null);

    final service = container.read(hadithExtraPackServiceProvider);
    expect(await service.download(), const Ok<void>(null));
    await pumpEventQueue();

    expect(statuses.first, const HadithExtraNotDownloaded());
    expect(statuses, contains(isA<HadithExtraDownloading>()));
    expect(statuses.last, HadithExtraReady(sizeBytes: pack.length));
    // Repozitar sa po zmene pripravenosti vymeni, null sa neulozi.
    expect(
      container.read(hadithExtraPackRepositoryProvider),
      isNot(same(repoBefore)),
    );
    final e = await container.read(hadithExtraProvider((11, 'en')).future);
    expect(e!.explanation, '[PLACEHOLDER explanation 11]');
    expect(e.hints, contains('[PLACEHOLDER hint 2]'));

    await service.delete();
    await pumpEventQueue();
    expect(await container.read(hadithExtraProvider((11, 'en')).future), null);
  });
}
