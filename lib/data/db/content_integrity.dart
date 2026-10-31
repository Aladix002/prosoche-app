import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/db/content_db.dart';

/// Kontrola integrity content.db pri prvom starte a po aktualizacii
/// (plan 17.3): verzia schemy, `dev_content` a neprazdny obsah.
///
/// F-01 moze pridat hash textov podla kontraktu C-01 (ako `uthmani_sha256`
/// v Murse).
class ContentIntegrityChecker {
  const ContentIntegrityChecker({this.allowDevContent = false});

  /// Ci prijat build s `meta.dev_content = '1'` (example/placeholder obsah).
  /// V produkcii vzdy false.
  final bool allowDevContent;

  /// [Ok] alebo [Err] s [ContentIntegrityFailed] (`schema_version`,
  /// `dev_content`, `empty`).
  Future<Result<void>> check(ContentDb db) async {
    final dao = db.contentMetaDao;
    final schema = await dao.metaValue('schema_version');
    if (schema != '${ContentDb.contractVersion}') {
      return const Err(ContentIntegrityFailed('schema_version'));
    }
    if (!allowDevContent && await dao.metaValue('dev_content') != '0') {
      return const Err(ContentIntegrityFailed('dev_content'));
    }
    if (await dao.quoteCount() == 0) {
      return const Err(ContentIntegrityFailed('empty'));
    }
    return const Ok(null);
  }
}
