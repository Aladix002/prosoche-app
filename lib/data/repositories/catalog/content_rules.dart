import 'dart:convert';

import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/quests.dart';

/// Prevod riadkov `content.db` (tvar z pipeline `prosoche-content`) na vstupy
/// domenovych enginov. `quest_template.rule_json` je `{"count": ...}`
/// (QuestRule) alebo `{"completion", "params"}`.

/// Metriky `completion.metric` (pipeline) -> podmienka `count`.
const Map<String, (Set<CardType>, Set<CardAction>)> completionMetrics = {
  'quote_read': ({CardType.quote, CardType.passage}, {CardAction.seen}),
  'idea_learned': ({CardType.concept, CardType.author}, {CardAction.seen}),
  'prompt_answered': ({CardType.prompt}, {CardAction.answered}),
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
    params: params,
  );
}

/// JSON pole retazcov (tagy); null alebo iny tvar = prazdne.
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
