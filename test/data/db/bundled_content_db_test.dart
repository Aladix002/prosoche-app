import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/content/bundled_content.dart';
import 'package:prosoche/data/content/content_documents.dart';
import 'package:prosoche/data/content/db_archive.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/data/db/content_integrity.dart';

/// Realna content.db.gz z `tool/bundle_content.sh` (gitignored, v CI nie je)
/// sedi s pribalenym manifestom a po rozbaleni prejde kontrolou integrity
/// s konstantami z binarky.
void main() {
  test(
    'bundled content.db passes ContentIntegrityChecker (when bundled)',
    () async {
      final gz = File(AssetBundledContentSource.dbArchiveAsset);
      if (!gz.existsSync()) {
        markTestSkipped('assets/content/content.db.gz not bundled');
        return;
      }
      final tmp = Directory.systemTemp.createTempSync('bundled_content');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final file = File(p.join(tmp.path, 'content.db'));
      final manifest = ContentManifest.parse(
        File(AssetBundledContentSource.manifestAsset).readAsBytesSync(),
      ).valueOrNull!;
      expect(await checkArchive(gz, manifest.db), const Ok<void>(null));
      expect(await inflateArchive(gz, file, manifest.db), const Ok<void>(null));
      final db = ContentDb.openReadOnly(file);
      addTearDown(db.close);
      final dao = db.contentMetaDao;
      expect(
        await dao.metaValue('schema_version'),
        '${ContentDb.contractVersion}',
      );
      // Dev build obsahuje example kuratovany obsah (meta.dev_content = '1').
      final dev = await dao.metaValue('dev_content') == '1';
      expect(
        await ContentIntegrityChecker(allowDevContent: dev).check(db),
        const Ok<void>(null),
      );
    },
  );
}
