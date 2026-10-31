import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/domain/common/common.dart';

/// sha256 Uthmani textu pribalenej content.db (plan 17.3), algoritmus
/// `meta.surah_hash_algo`: sha256(utf8(join('\n', text_uthmani ORDER BY
/// id))). Zdroj: `prosoche-content` build 2026102901 (Tanzil Uthmani 1.1).
const kUthmaniSha256 =
    'c787f3002b99299f4481a0874912fb5c2da9ed17fa763da23a1acbdee1660f58';

/// Kontrola integrity content.db pri prvom starte a po aktualizacii
/// (plan 17.3). Konstanty su parametre kvoli testom na malom fixture.
class ContentIntegrityChecker {
  const ContentIntegrityChecker({
    this.expectedAyahCount = AyahId.totalAyahs,
    this.expectedUthmaniSha256 = kUthmaniSha256,
    this.allowDevContent = false,
  });

  final int expectedAyahCount;
  final String expectedUthmaniSha256;

  /// Ci prijat build s `meta.dev_content = '1'` (example/placeholder obsah).
  /// V produkcii vzdy false (kontrakt v2).
  final bool allowDevContent;

  /// Hash podla `meta.surah_hash_algo`.
  static String uthmaniSha256(List<String> textsInOrder) =>
      sha256.convert(utf8.encode(textsInOrder.join('\n'))).toString();

  /// [Ok] alebo [Err] s [ContentIntegrityFailed] (`schema_version`,
  /// `dev_content`, `ayah_count`, `uthmani_hash`).
  Future<Result<void>> check(ContentDb db) async {
    final dao = db.contentMetaDao;
    final schema = await dao.metaValue('schema_version');
    if (schema != '${ContentDb.contractVersion}') {
      return const Err(ContentIntegrityFailed('schema_version'));
    }
    if (!allowDevContent && await dao.metaValue('dev_content') != '0') {
      return const Err(ContentIntegrityFailed('dev_content'));
    }
    if (await dao.ayahCount() != expectedAyahCount) {
      return const Err(ContentIntegrityFailed('ayah_count'));
    }
    final hash = uthmaniSha256(await dao.uthmaniTextsInOrder());
    if (hash != expectedUthmaniSha256) {
      return const Err(ContentIntegrityFailed('uthmani_hash'));
    }
    return const Ok(null);
  }
}
