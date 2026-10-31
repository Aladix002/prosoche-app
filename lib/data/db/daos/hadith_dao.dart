import 'package:drift/drift.dart';
import 'package:sakina/data/db/content_db.dart';

part 'hadith_dao.g.dart';

/// Hadisy HadeethEnc (B5, FeedGenerator slot 9).
@DriftAccessor(tables: [Hadiths, HadithTexts])
class HadithDao extends DatabaseAccessor<ContentDb> with _$HadithDaoMixin {
  HadithDao(super.attachedDatabase);

  Future<HadithRow?> hadith(int id) =>
      (select(hadiths)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<HadithTextRow?> hadithText(int id, String lang) =>
      (select(hadithTexts)
            ..where((t) => t.hadithId.equals(id) & t.lang.equals(lang)))
          .getSingleOrNull();

  /// ID vsetkych hadisov (zoradene), volitelne len s tagom [tag]
  /// (`hadith.tags` je JSON pole, vyber podla eventu).
  Future<List<int>> hadithIds({String? tag}) {
    if (tag == null) {
      return (selectOnly(hadiths)
            ..addColumns([hadiths.id])
            ..orderBy([OrderingTerm.asc(hadiths.id)]))
          .map((r) => r.read(hadiths.id)!)
          .get();
    }
    return customSelect(
      'SELECT id FROM hadith WHERE tags IS NOT NULL AND EXISTS '
      '(SELECT 1 FROM json_each(hadith.tags) WHERE value = ?) ORDER BY id',
      variables: [Variable.withString(tag)],
      readsFrom: {hadiths},
    ).map((r) => r.read<int>('id')).get();
  }
}
