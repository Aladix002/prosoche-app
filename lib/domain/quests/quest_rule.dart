import 'package:meta/meta.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/card_activity.dart';

/// Podmienka auto-splnenia questu z `quest_template.rule_json`
/// (plan 7.2, docs/02 D3).
///
/// Gramatika (v1 pozna len `count`):
/// ```json
/// {"count": {
///   "type": "ayah" | ["hadith", "dua"],      // povinne, typ karty (0.2)
///   "action": "seen" | ["seen", "answered"], // default "seen"
///   "context": ["feed", "reader"],           // volitelne, default vsetky
///   "surah": 18,                             // volitelne, len pre ayah
///   "min": 10 | {"param": "n"}               // povinne, >= 1
/// }}
/// ```
/// Pocitaju sa **rozne** `card_id` v dany den (opakovany `seen` tej istej
/// karty v inom kontexte sa nezapocita dvakrat).
@immutable
final class QuestRule {
  QuestRule({
    required Set<CardType> types,
    required this.min,
    Set<CardAction> actions = const {CardAction.seen},
    Set<CardContext>? contexts,
    this.surah,
  }) : types = Set.unmodifiable(types),
       actions = Set.unmodifiable(actions),
       contexts = contexts == null ? null : Set.unmodifiable(contexts) {
    final problem = _problem(types, actions, contexts, surah, min);
    if (problem != null) throw ArgumentError(problem);
  }

  /// Parsuje `rule_json`. Neznamy kluc alebo zly typ hodi
  /// [FormatException] s cestou k chybe.
  factory QuestRule.fromJson(Map<String, Object?> json) {
    _onlyKeys(json, const {'count'}, 'rule');
    final count = switch (json['count']) {
      final Map<String, Object?> m => m,
      _ => throw const FormatException('rule.count: expected object'),
    };
    _onlyKeys(count, const {
      'type',
      'action',
      'context',
      'surah',
      'min',
    }, 'rule.count');
    final types = _enumSet(count['type'], 'type', CardType.fromWire);
    if (types == null) throw const FormatException('rule.count.type: missing');
    final actions = _enumSet(count['action'], 'action', CardAction.fromWire);
    final contexts = _enumSet(
      count['context'],
      'context',
      CardContext.fromWire,
    );
    final surah = switch (count['surah']) {
      null => null,
      final int s => s,
      _ => throw const FormatException('rule.count.surah: expected int'),
    };
    final min = switch (count['min']) {
      final int n => QuestTarget.fixed(n),
      {'param': final String p} => QuestTarget.param(p),
      _ => throw const FormatException(
        'rule.count.min: expected int or {"param": name}',
      ),
    };
    final resolvedActions = actions ?? const {CardAction.seen};
    final problem = _problem(types, resolvedActions, contexts, surah, min);
    if (problem != null) throw FormatException('rule.count: $problem');
    return QuestRule(
      types: types,
      actions: resolvedActions,
      contexts: contexts,
      surah: surah,
      min: min,
    );
  }

  final Set<CardType> types;
  final Set<CardAction> actions;

  /// null = vsetky kontexty.
  final Set<CardContext>? contexts;

  /// Len versy tejto sury (napr. 18 pre al-Kahf).
  final int? surah;

  final QuestTarget min;

  /// Ciel po dosadeni parametrov [params] (napr. `{n: 10}`).
  ///
  /// Chybajuci alebo neplatny parameter hodi [ArgumentError].
  int target(Map<String, int> params) {
    final n = switch (min) {
      QuestTarget(fixed: final f?) => f,
      QuestTarget(:final param) => params[param],
    };
    if (n == null || n < 1) {
      throw ArgumentError.value(params, 'params', 'missing ${min.param} >= 1');
    }
    return n;
  }

  /// Ci [activity] spada pod tuto podmienku.
  bool matches(CardActivity activity) {
    if (!types.contains(activity.type)) return false;
    if (!actions.contains(activity.action)) return false;
    if (contexts != null && !contexts!.contains(activity.context)) {
      return false;
    }
    if (surah != null) {
      final id = activity.cardId;
      if (id is! AyahCardId || id.ayahId.surah != surah) return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
    'count': {
      'type': _wires(types.map((t) => t.wire)),
      if (!(actions.length == 1 && actions.contains(CardAction.seen)))
        'action': _wires(actions.map((a) => a.wire)),
      if (contexts != null) 'context': _wires(contexts!.map((c) => c.wire)),
      'surah': ?surah,
      'min': min.toJson(),
    },
  };

  @override
  bool operator ==(Object other) =>
      other is QuestRule &&
      _setEq(other.types, types) &&
      _setEq(other.actions, actions) &&
      (other.contexts == null) == (contexts == null) &&
      (contexts == null || _setEq(other.contexts!, contexts!)) &&
      other.surah == surah &&
      other.min == min;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(types),
    Object.hashAllUnordered(actions),
    contexts == null ? null : Object.hashAllUnordered(contexts!),
    surah,
    min,
  );

  @override
  String toString() => 'QuestRule(${toJson()})';

  static String? _problem(
    Set<CardType> types,
    Set<CardAction> actions,
    Set<CardContext>? contexts,
    int? surah,
    QuestTarget min,
  ) {
    if (types.isEmpty) return 'types must not be empty';
    if (actions.isEmpty) return 'actions must not be empty';
    if (contexts != null && contexts.isEmpty) {
      return 'contexts must not be empty';
    }
    if (min case QuestTarget(fixed: final n?) when n < 1) {
      return 'min must be >= 1';
    }
    if (surah != null) {
      if (surah < 1 || surah > AyahId.surahCount) {
        return 'surah must be 1..114';
      }
      if (!types.every((t) => t == CardType.ayah)) {
        return 'surah filter needs type ayah';
      }
    }
    return null;
  }

  static Object _wires(Iterable<String> wires) {
    final list = wires.toList()..sort();
    return list.length == 1 ? list.single : list;
  }

  static bool _setEq<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);

  static void _onlyKeys(Map<String, Object?> m, Set<String> ok, String path) {
    final unknown = m.keys.where((k) => !ok.contains(k)).toList();
    if (unknown.isNotEmpty) {
      throw FormatException('$path: unknown key(s) ${unknown.join(', ')}');
    }
  }

  static Set<T>? _enumSet<T>(
    Object? raw,
    String name,
    T? Function(String) parse,
  ) {
    final list = switch (raw) {
      null => null,
      final String s => [s],
      final List<Object?> l when l.isNotEmpty => l,
      _ => throw FormatException('rule.count.$name: expected string or list'),
    };
    if (list == null) return null;
    return {
      for (final v in list)
        if (v is String && parse(v) != null)
          parse(v) as T
        else
          throw FormatException('rule.count.$name: unknown value $v'),
    };
  }
}

/// Ciel podmienky: pevne cislo alebo parameter sablony (`{param: n}`).
@immutable
final class QuestTarget {
  const QuestTarget.fixed(int this.fixed) : param = null;
  const QuestTarget.param(String this.param) : fixed = null;

  final int? fixed;
  final String? param;

  Object toJson() => fixed ?? {'param': param};

  @override
  bool operator ==(Object other) =>
      other is QuestTarget && other.fixed == fixed && other.param == param;

  @override
  int get hashCode => Object.hash(fixed, param);
}
