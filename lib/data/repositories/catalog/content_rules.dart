import 'dart:convert';

import 'package:prosoche/domain/calendar/calendar.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/quests.dart';

/// Prevod riadkov `content.db` (tvar z pipeline `prosoche-content`) na vstupy
/// domenovych enginov. Pipeline uklada `islamic_event.rule_json` ako
/// `{"when", "phase", "merge", "effects"}` a `quest_template.rule_json` ako
/// `{"when", "completion", "params"}`; domena (E-01, E-03) cita plochy tvar
/// z docs/03 4.4 a `{"count": ...}`.

/// JSON pre `EventRuleParser.parse` z riadku `islamic_event`.
///
/// `effects.*` sa vyplosti na najvyssiu uroven, `quest_overrides_json`
/// a `card_overrides_json` sa pouziju, ak `rule_json` dane kluce nema.
Map<String, Object?> eventRuleJson({
  required String id,
  required int priority,
  required String category,
  required String ruleJson,
  String? questOverridesJson,
  String? cardOverridesJson,
}) {
  final rule = _object(jsonDecode(ruleJson), 'rule_json');
  final out = <String, Object?>{
    for (final MapEntry(:key, :value) in rule.entries)
      if (key != 'effects' && value != null) key: value,
  };
  final effects = rule['effects'];
  if (effects != null) {
    for (final MapEntry(:key, :value) in _object(effects, 'effects').entries) {
      if (value != null) out[key] = value;
    }
  }
  if (questOverridesJson != null && !out.containsKey('quests')) {
    final q = jsonDecode(questOverridesJson);
    if (q != null) out['quests'] = q;
  }
  if (cardOverridesJson != null && !out.containsKey('cards')) {
    final c = jsonDecode(cardOverridesJson);
    if (c != null) out['cards'] = c;
  }
  return {...out, 'id': id, 'priority': priority, 'category': category};
}

/// Pravidlo eventu alebo [FormatException] (aj [EventRuleFormatException]).
EventRule parseEventRow({
  required String id,
  required int priority,
  required String category,
  required String ruleJson,
  String? questOverridesJson,
  String? cardOverridesJson,
}) => EventRuleParser.parse(
  eventRuleJson(
    id: id,
    priority: priority,
    category: category,
    ruleJson: ruleJson,
    questOverridesJson: questOverridesJson,
    cardOverridesJson: cardOverridesJson,
  ),
  id: id,
);

/// Metriky `completion.metric` (pipeline) -> podmienka `count`.
const Map<String, (Set<CardType>, Set<CardAction>)> completionMetrics = {
  'ayah_read': ({CardType.ayah}, {CardAction.seen}),
  'name_seen': ({CardType.name}, {CardAction.seen}),
  'lemma_learned': ({CardType.word}, {CardAction.seen}),
  'srs_reviewed': ({CardType.quiz}, {CardAction.answered}),
};

/// Sablona questu z riadku `quest_template`; [langs] = jazyky `quest_text`.
///
/// Hodi [FormatException] pri neznamom slote, metrike alebo tvare.
QuestTemplate parseQuestRow({
  required String id,
  required String slot,
  required String ruleJson,
  required Set<String> langs,
  double weight = 1,
  int? cooldownDays,
  String? facetsJson,
}) {
  final questSlot =
      QuestSlot.fromWire(slot) ?? (throw FormatException('slot', slot));
  final json = _object(jsonDecode(ruleJson), 'rule_json');
  final facets = facetsJson == null
      ? const <String, Object?>{}
      : _object(jsonDecode(facetsJson) ?? const <String, Object?>{}, 'facets');

  QuestRule? rule;
  if (json['count'] != null) {
    rule = QuestRule.fromJson({'count': json['count']});
  } else if (json['completion'] case final Map<String, Object?> completion
      when completion['mode'] == 'auto') {
    final metric = completion['metric'];
    final mapped = completionMetrics[metric];
    if (mapped == null) throw FormatException('completion.metric', '$metric');
    final target = switch (completion['target']) {
      final int n => n,
      {'param': final String p} => {'param': p},
      final t => throw FormatException('completion.target', '$t'),
    };
    rule = QuestRule.fromJson({
      'count': {
        'type': [for (final t in mapped.$1) t.wire],
        'action': [for (final a in mapped.$2) a.wire],
        'min': target,
      },
    });
  }

  final params = <String, List<int>>{};
  if (json['params'] case final Map<String, Object?> raw) {
    for (final MapEntry(:key, :value) in raw.entries) {
      if (value is! List<Object?> || value.any((v) => v is! int)) {
        throw FormatException('params.$key', '$value');
      }
      params[key] = value.cast<int>();
    }
  }

  return QuestTemplate(
    id: id,
    slot: questSlot,
    langs: langs,
    rule: questSlot == QuestSlot.act ? null : rule,
    weight: weight,
    cooldownDays: cooldownDays,
    excusedOk: facets['excused_ok'] == true,
    season: {...eventIdsIn(json['when']), ..._strings(facets['season'])},
    params: params,
  );
}

/// ID eventov v podmienke `when` (`event_active`, aj vnorene v all/any).
/// Sablona s `when` plati len pocas tychto eventov (sezona).
Set<String> eventIdsIn(Object? when) => switch (when) {
  {'event_active': final String id} => {id},
  {'all': final List<Object?> l} ||
  {'any': final List<Object?> l} => {for (final c in l) ...eventIdsIn(c)},
  _ => const {},
};

/// JSON pole retazcov (tagy, season); null alebo iny tvar = prazdne.
List<String> stringList(String? json) {
  if (json == null) return const [];
  try {
    return _strings(jsonDecode(json));
  } on FormatException {
    return const [];
  }
}

List<String> _strings(Object? raw) => switch (raw) {
  final List<Object?> l => [for (final v in l) ?(v is String ? v : null)],
  _ => const [],
};

Map<String, Object?> _object(Object? raw, String what) => switch (raw) {
  final Map<String, Object?> m => m,
  _ => throw FormatException('$what: expected object'),
};
