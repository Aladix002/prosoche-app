import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/data/repositories/catalog/content_rules.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/feed.dart';
import 'package:prosoche/domain/quests/quests.dart';

/// Stav kuratovaneho obsahu, ktory appka pouziva (draft a in_review nie).
const approvedStatus = 'approved';

/// Kuratovany obsah z content.db pre enginy: sablony questov a pooly
/// kandidatov FeedGeneratora (docs/03 3.3, 7.3).
///
/// Nacitava sa raz na instanciu (content.db je iba na citanie); po
/// aktualizacii obsahu vznikne nova instancia s novou db. Neplatne riadky sa
/// preskocia a zalogi sa len ich pocet (bez ID a obsahu, docs/06 C.7).
///
/// F-01: [feedPools] doplni pooly dalsich typov kariet (`passage`,
/// `practice`, `prompt`, `concept`, `author`) podla kontraktu C-01.
class ContentCatalog {
  ContentCatalog(this._db, {this._logger});

  final Future<ContentDb> _db;
  final AppLogger? _logger;

  Future<List<QuestTemplate>>? _templates;
  Future<FeedPools>? _pools;
  Future<String?>? _contentVersion;

  Future<ContentDb> get db => _db;

  /// `meta.content_version`.
  Future<String?> contentVersion() => _contentVersion ??= _db.then(
    (db) => db.contentMetaDao.metaValue('content_version'),
  );

  /// Schvalene sablony questov s jazykmi `quest_text`.
  Future<List<QuestTemplate>> questTemplates() =>
      _templates ??= _loadTemplates();

  Future<List<QuestTemplate>> _loadTemplates() async {
    final db = await _db;
    final langs = <String, Set<String>>{};
    for (final r in await db.select(db.questTexts).get()) {
      (langs[r.questId] ??= {}).add(r.lang);
    }
    var skipped = 0;
    final out = <QuestTemplate>[];
    for (final r in await db.curatedDao.activeQuestTemplates()) {
      if (r.status != approvedStatus) continue;
      try {
        out.add(
          parseQuestRow(
            id: r.id,
            slot: r.slot,
            ruleJson: r.ruleJson,
            langs: langs[r.id] ?? const {},
            weight: r.weight,
            cooldownDays: r.cooldownDays,
            facetsJson: r.facetsJson,
          ),
        );
      } on FormatException {
        skipped++;
        // Sablona s nekonzistentnymi parametrami (QuestTemplate hadze
        // ArgumentError) je chyba obsahu, nie appky.
        // ignore: avoid_catching_errors
      } on ArgumentError {
        skipped++;
      }
    }
    _report('quest_template', skipped);
    return List.unmodifiable(out);
  }

  /// Pooly kandidatov pre FeedGenerator (S-01: len schvalene citaty).
  Future<FeedPools> feedPools() => _pools ??= _loadPools();

  Future<FeedPools> _loadPools() async {
    final db = await _db;
    var skipped = 0;
    final quotes = <FeedCandidate>[];
    for (final r in await db.curatedDao.activeQuotes()) {
      if (r.status != approvedStatus) continue;
      if (!CardId.keyPattern.hasMatch(r.id) || r.weight <= 0) {
        skipped++;
        continue;
      }
      quotes.add(
        FeedCandidate(
          id: ContentCardId.quote(r.id),
          tags: stringList(r.tags),
          weight: r.weight,
          timeOfDay: TimeOfDayFacet.fromWire(r.timeOfDay),
        ),
      );
    }
    _report('quote', skipped);
    return FeedPools.quotes(quotes);
  }

  void _report(String type, int skipped) {
    if (skipped > 0) {
      _logger?.warn('catalog', 'skipped invalid content rows', {
        'type': type,
        'attempt': skipped,
      });
    }
  }
}
