import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/data/content/db_archive.dart';
import 'package:prosoche/data/content/hadith_extra_pack_service.dart';
import 'package:prosoche/data/db/content_db.dart';

import 'content_test_helpers.dart';
import 'hadith_extra_pack_test_helpers.dart';

const v1 = 2026010100;

/// Q-03: `HadithExtraPackService` cita meta content.db bez druheho
/// `ContentDb`, takze drift pri otvorenom `contentDatabaseProvider`
/// nevarovne "created multiple times".
void main() {
  late Directory tmp;
  late void Function(String) originalPrint;
  final printed = <String>[];

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('hadith_extra_warning');
    originalPrint = driftRuntimeOptions.debugPrint;
    driftRuntimeOptions
      ..dontWarnAboutMultipleDatabases = false
      ..debugPrint = printed.add;
  });

  tearDown(() {
    driftRuntimeOptions.debugPrint = originalPrint;
    printed.clear();
    tmp.deleteSync(recursive: true);
  });

  test('refresh with open content db does not warn', () async {
    final keys = await TestKeys.create();
    final dir = Directory(p.join(tmp.path, 'content'));
    final pack = packDbBytes(tmp, v1);
    final db = contentDbWithPack(
      tmp,
      v1,
      packSha: sha(pack),
      packSize: pack.length,
    );
    final http = FakeHttpClient();
    final log = RingBufferLog();
    final bundled = MemoryBundledSource(db);
    final content = buildService(
      dir: dir,
      bundled: bundled,
      http: http,
      keys: keys,
      log: log,
    );
    final service = buildPackService(
      dir: dir,
      content: content,
      bundled: bundled,
      http: http,
      keys: keys.set,
      log: log,
    );
    addTearDown(() async {
      await service.dispose();
      await content.dispose();
    });

    // Ako contentDatabaseProvider: jedno otvorene spojenie na aktivnu db.
    final file = (await content.ensureInstalled()).valueOrNull!;
    final open = ContentDb.openReadOnly(file);
    addTearDown(open.close);
    await open.contentMetaDao.metaValue('content_version');

    expect(await service.refresh(), const HadithExtraNotDownloaded());
    expect(printed.where((m) => m.contains('multiple times')), isEmpty);
  });

  test('readContentMeta returns only present keys', () async {
    final file = File(
      p.join(tmp.path, 'c.db'),
    )..writeAsBytesSync(contentDbWithPack(tmp, v1, packSha: 'ab', packSize: 3));
    expect(readContentMeta(file, ['content_version', 'missing']), {
      'content_version': '$v1',
    });
  });
}
