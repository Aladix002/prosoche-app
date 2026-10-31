import 'dart:convert';

import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/data/repositories/catalog/content_rules.dart';
import 'package:prosoche/data/repositories/infra/curated_id.dart';
import 'package:prosoche/domain/calendar/calendar.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/feed.dart';
import 'package:prosoche/domain/quests/quests.dart';

/// Stav kuratovaneho obsahu, ktory appka pouziva (draft a in_review nie).
const approvedStatus = 'approved';

/// Kuratovany obsah z content.db pre enginy: pravidla eventov, sablony
/// questov a pooly kandidatov FeedGeneratora (docs/03 3.3, 7.3).
///
/// Nacitava sa raz na instanciu (content.db je iba na citanie); po
/// aktualizacii obsahu vznikne nova instancia s novou db. Neplatne riadky sa
/// preskocia a zalogi sa len ich pocet (bez ID a obsahu, docs/06 C.7).
class ContentCatalog {
  ContentCatalog(this._db, {this._logger});

  final Future<ContentDb> _db;
  final AppLogger? _logger;

  Future<List<EventRule>>? _rules;
  Future<List<QuestTemplate>>? _templates;
  Future<_Pools>? _pools;
  Future<String?>? _contentVersion;

  Future<ContentDb> get db => _db;

  /// `meta.content_version`.
  Future<String?> contentVersion() => _contentVersion ??= _db.then(
    (db) => db.contentMetaDao.metaValue('content_version'),
  );

  /// Schvalene pravidla eventov. Neplatne pravidlo sa vynecha; ak sada ako
  /// celok neprejde validaciou (cyklus, odkaz na chybajuci event), vynechaju
  /// sa vsetky pravidla s problemom postupne.
  Future<List<EventRule>> eventRules() => _rules ??= _loadRules();

  Future<List<EventRule>> _loadRules() async {
    final db = await _db;
    final rows = await db.curatedDao.activeIslamicEvents();
    var skipped = 0;
    final rules = <EventRule>[];
    for (final r in rows) {
      if (r.status != approvedStatus) continue;
      try {
        rules.add(
          parseEventRow(
            id: r.id,
            priority: r.priority,
            category: r.category,
            ruleJson: r.ruleJson,
            questOverridesJson: r.questOverridesJson,
            cardOverridesJson: r.cardOverridesJson,
          ),
        );
      } on FormatException {
        skipped++;
      }
    }
    // Sada musi prejst validaciou ako celok (odkazy medzi eventmi).
    while (rules.isNotEmpty) {
      try {
        EventRuleParser.validateSet(rules);
        break;
      } on EventRuleFormatException catch (e) {
        final bad = e.ruleId;
        final before = rules.length;
        rules.removeWhere((r) => r.id == bad);
        if (rules.length == before) rules.clear();
        skipped++;
      }
    }
    _report('event_rule', skipped);
    return List.unmodifiable(rules);
  }

  /// Schvalene sablony questov s jazykmi `quest_text`.
  Future<List<QuestTemplate>> questTemplates() =>
      _templates ??= _loadTemplates();

  Future<List<QuestTemplate>> _loadTemplates() async {
    final db = await _db;
    final langs = await _langs(db, 'quest_text', 'quest_id');
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

  /// Pooly kandidatov pre FeedGenerator. Slovicka (lemy, SRS) sa v MVP
  /// nepouzivaju (`FEATURE_WORDS`, X-01), preto `lemmas` je null.
  Future<FeedPools> feedPools() async =>
      (await (_pools ??= _loadPools())).pools;

  /// Index `dua.id` (TEXT) <-> cislo v `DuaCardId`.
  Future<CuratedIdIndex> duaIds() async =>
      (await (_pools ??= _loadPools())).duaIds;

  /// Index `reflection.id` (TEXT) <-> cislo v `ReflectionCardId`.
  Future<CuratedIdIndex> reflectionIds() async =>
      (await (_pools ??= _loadPools())).reflectionIds;

  Future<_Pools> _loadPools() async {
    final db = await _db;

    final hadithLangs = await _langs(db, 'hadith_text', 'hadith_id');
    final hadithRows = await db
        .customSelect('SELECT id, grade, tags FROM hadith ORDER BY id')
        .get();
    final hadiths = [
      for (final r in hadithRows)
        if (r.read<int>('id') > 0)
          FeedCandidate(
            id: HadithCardId(r.read<int>('id')),
            langs: hadithLangs['${r.read<int>('id')}'] ?? const {},
            tags: stringList(r.readNullable<String>('tags')),
            grade: r.read<String>('grade'),
          ),
    ];

    final duaLangs = await _langs(db, 'dua_text', 'dua_id');
    final duaRows = await db
        .customSelect('SELECT id, category, time_of_day FROM dua ORDER BY id')
        .get();
    final duaIds = CuratedIdIndex(duaRows.map((r) => r.read<String>('id')));
    final duas = [
      for (final r in duaRows)
        if (duaIds.number(r.read<String>('id')) case final n?)
          FeedCandidate(
            id: DuaCardId(n),
            langs: duaLangs[r.read<String>('id')] ?? const {},
            tags: [r.read<String>('category')],
            timeOfDay: _timeOfDay(r.read<String>('time_of_day')),
          ),
    ];

    final reflLangs = await _langs(db, 'reflection_text', 'reflection_id');
    final reflRows = (await db.curatedDao.activeReflections())
        .where((r) => r.status == approvedStatus)
        .toList();
    final reflIds = CuratedIdIndex(reflRows.map((r) => r.id));
    final reflections = [
      for (final r in reflRows)
        if (reflIds.number(r.id) case final n?)
          FeedCandidate(
            id: ReflectionCardId(n),
            langs: reflLangs[r.id] ?? const {},
            tags: stringList(r.tags),
            seasons: stringList(r.season),
            timeOfDay: _timeOfDay(_facet(r.facetsJson, 'time_of_day')),
            reviewed: r.reviewedBy != null,
          ),
    ];

    final nameLangs = await _langs(db, 'name_text', 'name_id');
    final nameRows = await db
        .customSelect('SELECT id FROM name_of_allah ORDER BY id')
        .get();
    final names = [
      for (final r in nameRows)
        if (r.read<int>('id') case final id when id >= 1 && id <= 99)
          FeedCandidate(
            id: NameCardId(id),
            langs: nameLangs['$id'] ?? const {},
          ),
    ];

    final eventLangs = await _langs(db, 'islamic_event_text', 'event_id');
    _report('curated_id_collision', duaIds.collisions + reflIds.collisions);
    return _Pools(
      FeedPools(
        hadiths: hadiths,
        duas: duas,
        reflections: reflections,
        names: names,
        eventTextLangs: eventLangs,
      ),
      duaIds,
      reflIds,
    );
  }

  /// `{id -> {lang}}` z textovej tabulky (`*_text`).
  static Future<Map<String, Set<String>>> _langs(
    ContentDb db,
    String table,
    String idColumn,
  ) async {
    final out = <String, Set<String>>{};
    final rows = await db
        .customSelect('SELECT $idColumn AS id, lang FROM $table')
        .get();
    for (final r in rows) {
      final id = r.data['id'].toString();
      (out[id] ??= {}).add(r.read<String>('lang'));
    }
    return out;
  }

  static TimeOfDayFacet _timeOfDay(String? wire) => TimeOfDayFacet.values
      .firstWhere((t) => t.wire == wire, orElse: () => TimeOfDayFacet.any);

  static String? _facet(String? facetsJson, String key) {
    if (facetsJson == null) return null;
    try {
      final facets = jsonDecode(facetsJson);
      return facets is Map<String, Object?> && facets[key] is String
          ? facets[key]! as String
          : null;
    } on FormatException {
      return null;
    }
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

class _Pools {
  _Pools(this.pools, this.duaIds, this.reflectionIds);

  final FeedPools pools;
  final CuratedIdIndex duaIds;
  final CuratedIdIndex reflectionIds;
}
