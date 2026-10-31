import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/data/repositories/catalog/content_rules.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/feed.dart';
import 'package:prosoche/domain/quests/quests.dart';

/// Obsah z content.db v1 pre enginy: pooly kandidatov FeedGeneratora podla
/// typu karty (kontrakt kap. 6).
///
/// Karty `status = draft` sa pouzivaju: db s draftami (`dev_content = 1`)
/// prijme len dev flavor (ContentIntegrityChecker), prod db ich nema.
///
/// Nacitava sa raz na instanciu (content.db je iba na citanie); po
/// aktualizacii obsahu vznikne nova instancia s novou db. Neplatne riadky sa
/// preskocia a zalogi sa len ich pocet (bez ID a obsahu, docs/06 C.7).
class ContentCatalog {
  ContentCatalog(this._db, {this._logger});

  final Future<ContentDb> _db;
  final AppLogger? _logger;

  Future<FeedPools>? _pools;
  Future<String?>? _contentVersion;

  Future<ContentDb> get db => _db;

  /// `meta.content_version`.
  Future<String?> contentVersion() => _contentVersion ??= _db.then(
    (db) => db.contentMetaDao.metaValue('content_version'),
  );

  /// Sablony questov. content.db v1 ich nema: questy dna su genericke
  /// (`read` citaty a uryvky, `learn` pojem alebo autor, `act` cvicenie
  /// s potvrdenim pouzivatela, texty z ARB).
  Future<List<QuestTemplate>> questTemplates() async => const [];

  /// Pooly kandidatov pre FeedGenerator (vsetky typy kariet).
  Future<FeedPools> feedPools() => _pools ??= _loadPools();

  Future<FeedPools> _loadPools() async {
    final db = await _db;
    var skipped = 0;
    final byType = <CardType, List<FeedCandidate>>{};
    for (final r in await db.cardDao.allCards()) {
      final id = CardId.tryParse(r.id);
      if (id is! ContentCardId || id.type.wire != r.type) {
        skipped++;
        continue;
      }
      final tags = stringList(r.tags);
      (byType[id.type] ??= []).add(
        FeedCandidate(
          id: id,
          tags: tags,
          timeOfDay: TimeOfDayFacet.fromTags(tags),
        ),
      );
    }
    _report(skipped);
    return FeedPools(byType);
  }

  void _report(int skipped) {
    if (skipped > 0) {
      _logger?.warn('catalog', 'skipped invalid content rows', {
        'type': 'card',
        'attempt': skipped,
      });
    }
  }
}
