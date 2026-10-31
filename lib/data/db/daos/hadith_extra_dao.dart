import 'package:drift/drift.dart';
import 'package:sakina/data/db/hadith_extra_db.dart';

part 'hadith_extra_dao.g.dart';

/// Vysvetlivky a poznamky k hadisom z balika hadith_extra.db (C-06, D-05).
@DriftAccessor(tables: [ExtraMeta, ExtraSources, HadithExplanations])
class HadithExtraDao extends DatabaseAccessor<HadithExtraDb>
    with _$HadithExtraDaoMixin {
  HadithExtraDao(super.attachedDatabase);

  /// Riadok pre hadis [hadithId] v jazyku [lang], alebo `null`.
  Future<HadithExplanationRow?> explanationFor(int hadithId, String lang) =>
      (select(hadithExplanations)
            ..where((t) => t.hadithId.equals(hadithId) & t.lang.equals(lang)))
          .getSingleOrNull();

  Future<String?> metaValue(String key) async => (await (select(
    extraMeta,
  )..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<ExtraSourceRow?> source(String id) =>
      (select(extraSources)..where((t) => t.id.equals(id))).getSingleOrNull();
}
