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
      expect(manifest.devContent, dev);
      expect(
        await ContentIntegrityChecker(allowDevContent: dev)
            .check(db, expectedSectionsSha256: manifest.sectionsSha256),
        const Ok<void>(null),
      );
      // C-03: schvaleny obsah (dev_content = 0) prijme aj prod flavor
      // (ContentIntegrityChecker bez allowDevContent).
      if (!dev) {
        expect(
          await const ContentIntegrityChecker().check(
            db,
            expectedSectionsSha256: manifest.sectionsSha256,
          ),
          const Ok<void>(null),
        );
      }
      // Kontrakt kap. 5: nazov "Project Gutenberg" nikde v obsahu.
      final hits = await db
          .customSelect(
            "SELECT count(*) AS n FROM card WHERE text LIKE '%Gutenberg%' "
            "OR ref LIKE '%Gutenberg%'",
          )
          .getSingle();
      expect(hits.read<int>('n'), 0);
      for (final s in await dao.allSources()) {
        expect(s.attribution, isNot(contains('Gutenberg')), reason: s.id);
        expect(s.url ?? '', isNot(contains('gutenberg')), reason: s.id);
      }
      // FTS5 je dostupne (sqlite3 s FTS5) a karty quote/passage su
      // podretazcom svojej sekcie (zvyraznenie v citacke).
      expect(await db.libraryDao.search('"attention"*'), isNotEmpty);
      final quote = (await db.cardDao.ofType('quote')).first;
      final section = await db.libraryDao.sectionByKey(quote.sectionKey!);
      expect(section!.textContent, contains(quote.textContent));

      // C-02: quote a passage koncia celou vetou (kontrakt kap. 6).
      final end = RegExp(r"""[.!?]["')\]]*$""");
      for (final type in ['quote', 'passage']) {
        for (final c in await db.cardDao.ofType(type)) {
          expect(c.textContent, matches(end), reason: c.id);
        }
      }
      // C-02: nazvy diel v Library sedia s referenciami kariet ("On Anger"),
      // nie nazvy z prekladu ("Of Anger").
      for (final w in await db.libraryDao.allWorks()) {
        expect(w.title, startsWith(w.shortRef), reason: w.id);
        expect(w.title, isNot(startsWith('Of ')), reason: w.id);
      }
      // C-02: normalizacia ws2, "--" z Longovho prepisu je em dash.
      final dashes = await db
          .customSelect(
            "SELECT count(*) AS n FROM section WHERE text LIKE '%--%'",
          )
          .getSingle();
      expect(dashes.read<int>('n'), 0);
    },
  );
}
