import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/db/content_db.dart';

/// Kontrola integrity content.db pri instalacii (pribalenej aj stiahnutej),
/// podla kontraktu prosoche-content kap. 2 a 8:
///
/// 1. `meta.schema_version` = [ContentDb.contractVersion],
/// 2. `meta.dev_content` = `0`, ak [allowDevContent] je false (prod),
/// 3. aspon jedna sekcia a jedna karta,
/// 4. `section.sha256 = sha256(utf8(text))` pre kazdu sekciu,
/// 5. `meta.sections_sha256` = sha256 zo `"<key>\t<sha256>\n"` vsetkych
///    sekcii v poradi `section.id` (a rovna sa `expectedSectionsSha256`
///    z podpisaneho manifestu, ak je zadany).
///
/// Kody chyb (`ContentIntegrityFailed.check`): `schema_version`,
/// `dev_content`, `empty`, `section_sha256`, `sections_sha256`.
class ContentIntegrityChecker {
  const ContentIntegrityChecker({this.allowDevContent = false});

  /// Ci prijat build s `meta.dev_content = '1'` (karty `status = draft`).
  /// V prod flavore vzdy false.
  final bool allowDevContent;

  Future<Result<void>> check(
    ContentDb db, {
    String? expectedSectionsSha256,
  }) async {
    final dao = db.contentMetaDao;
    final meta = await dao.allMeta();
    if (meta['schema_version'] != '${ContentDb.contractVersion}') {
      return const Err(ContentIntegrityFailed('schema_version'));
    }
    if (!allowDevContent && meta['dev_content'] != '0') {
      return const Err(ContentIntegrityFailed('dev_content'));
    }
    if (await dao.cardCount() == 0 || await dao.sectionCount() == 0) {
      return const Err(ContentIntegrityFailed('empty'));
    }
    final digest = sectionsDigest(await dao.sectionHashes());
    if (digest == null) {
      return const Err(ContentIntegrityFailed('section_sha256'));
    }
    final declared = meta['sections_sha256'];
    if (digest != declared ||
        (expectedSectionsSha256 != null && expectedSectionsSha256 != digest)) {
      return const Err(ContentIntegrityFailed('sections_sha256'));
    }
    return const Ok(null);
  }

  /// `sections_sha256` z `(key, sha256, text)` v poradi `section.id`; null,
  /// ak niektora sekcia nesedi so svojim `sha256`.
  static String? sectionsDigest(Iterable<(String, String, String)> sections) {
    final out = StringBuffer();
    for (final (key, hash, text) in sections) {
      if (sha256.convert(utf8.encode(text)).toString() != hash) return null;
      out.write('$key\t$hash\n');
    }
    return sha256.convert(utf8.encode(out.toString())).toString();
  }
}
