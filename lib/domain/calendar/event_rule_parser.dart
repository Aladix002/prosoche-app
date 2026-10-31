import 'dart:convert';

import 'package:prosoche/domain/calendar/event_rule.dart';
import 'package:prosoche/domain/common/event_effect.dart';

/// Chyba v `rule_json`. [message] obsahuje id pravidla a cestu ku klucu,
/// napr. `rule 'jumuah': when.all[1]: unknown key 'hijri_mnth' (allowed: ...)`.
class EventRuleFormatException extends FormatException {
  EventRuleFormatException(this.ruleId, this.path, String problem)
    : super(
        '${ruleId == null ? 'rule' : "rule '$ruleId'"}'
        '${path.isEmpty ? '' : ': $path'}: $problem',
      );

  final String? ruleId;

  /// Cesta k chybnemu klucu, napr. `when.all[1]`.
  final String path;
}

/// Parser gramatiky `rule_json` (docs/03 4.4, plan 7.5, docs/02 D2).
///
/// Tvar je plochy JSON objekt:
/// ```json
/// {"id": "jumuah", "when": {"weekday": 5}, "phase": "day",
///  "priority": 50, "category": "core", "merge": "slots",
///  "mode": "ramadan", "intro": "intro.jumuah",
///  "cards": {"event_card_slot": 2, "ayah_slots": [3, 4], "surah": 18,
///            "cursor": "event_cursor.jumuah"},
///  "quests": {"read": "read_kahf"},
///  "forbid_tags": ["siyam"], "boost_tags": {"dhikr": 2.0},
///  "notifications": ["notif.jumuah_kahf_eve"]}
/// ```
/// Kazdy neznamy kluc (aj vo vnutri `when`) je chyba.
abstract final class EventRuleParser {
  static const topLevelKeys = {
    'id',
    'when',
    'phase',
    'priority',
    'category',
    'merge',
    'mode',
    'intro',
    'cards',
    'quests',
    'forbid_tags',
    'boost_tags',
    'notifications',
  };

  static const atomKeys = {
    'all',
    'any',
    'not',
    'hijri_month',
    'hijri_day',
    'hijri_month_day',
    'weekday',
    'days_before',
    'event_active',
    'pref',
    'user_flag',
    'quest_progress',
  };

  /// Najvyssia pozicia karty v sade (karty 1-12, docs/03 4.4 bod 2).
  static const maxCardPosition = 12;

  /// Najvyssi nasobok `boost_tags` (docs/03 4.4 bod 4).
  static const maxBoost = 6.0;

  static final idPattern = RegExp(r'^[a-z0-9_]{1,64}$');
  static final _refPattern = RegExp(r'^[a-z0-9_.]{1,128}$');

  /// Parsuje text `rule_json`. Ak je zadane [id] (stlpec `islamic_event.id`),
  /// JSON nemusi obsahovat `id`; ak ho obsahuje, musi sa zhodovat.
  static EventRule parseString(String source, {String? id}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (e) {
      throw EventRuleFormatException(id, '', 'invalid JSON: ${e.message}');
    }
    return parse(decoded, id: id);
  }

  /// Parsuje dekodovany `rule_json`.
  static EventRule parse(Object? json, {String? id}) {
    if (json is! Map<String, Object?>) {
      throw EventRuleFormatException(id, '', 'expected JSON object');
    }
    final jsonId = json['id'];
    if (jsonId != null && jsonId is! String) {
      throw EventRuleFormatException(id, 'id', 'expected string');
    }
    final ruleId = (jsonId as String?) ?? id;
    final p = _Ctx(ruleId);
    if (ruleId == null) throw p.error('', "missing 'id'");
    if (id != null && jsonId != null && id != jsonId) {
      throw p.error('id', "'$jsonId' does not match column id '$id'");
    }
    if (!idPattern.hasMatch(ruleId)) {
      throw p.error('id', 'must match [a-z0-9_]{1,64}');
    }
    p.onlyKeys(json, topLevelKeys, '');
    if (!json.containsKey('when')) throw p.error('', "missing 'when'");

    final category = p.enumValue(
      json['category'],
      EventCategory.values,
      (c) => c.wire,
      'category',
      EventCategory.core,
    );
    final merge = p.enumValue(
      json['merge'],
      EventMerge.values,
      (m) => m.wire,
      'merge',
      EventMerge.slots,
    );
    final mode = json['mode'] == null
        ? null
        : p.enumValue(
            json['mode'],
            EventMode.values,
            (m) => m.wire,
            'mode',
            EventMode.ramadan,
          );

    final EventEffect effect;
    try {
      effect = EventEffect.fromJson(json);
    } on FormatException catch (e) {
      throw p.error('cards/quests', e.message);
    }
    for (final pos in [?effect.eventCardSlot, ...effect.ayahSlots]) {
      if (pos > maxCardPosition) {
        throw p.error('cards', 'slot $pos out of range 1..$maxCardPosition');
      }
    }
    for (final (key, value) in effect.quests.entries.map(
      (e) => (e.key.wire, e.value),
    )) {
      if (!_refPattern.hasMatch(value)) {
        throw p.error('quests.$key', 'invalid quest id');
      }
    }

    if (!category.canOverride) {
      final forbidden = [
        if (!effect.isEmpty || effect.surah != null) 'cards/quests',
        if (mode != null) 'mode',
        if (merge == EventMerge.exclusive) 'merge: exclusive',
      ];
      if (forbidden.isNotEmpty) {
        throw p.error(
          '',
          '${category.wire} event cannot override (${forbidden.join(', ')})',
        );
      }
    }

    return EventRule(
      id: ruleId,
      when: p.condition(json['when'], 'when'),
      phase: p.enumValue(
        json['phase'],
        EventPhase.values,
        (e) => e.wire,
        'phase',
        EventPhase.day,
      ),
      priority: p.intValue(json['priority'], 'priority') ?? 0,
      category: category,
      merge: merge,
      mode: mode,
      effect: effect,
      intro: p.ref(json['intro'], 'intro'),
      forbidTags: p.tags(json['forbid_tags'], 'forbid_tags'),
      boostTags: p.boosts(json['boost_tags'], 'boost_tags'),
      notifications: p.refList(json['notifications'], 'notifications'),
    );
  }

  /// Parsuje vsetky pravidla a overi sadu ako celok ([validateSet]).
  static List<EventRule> parseAll(Iterable<Object?> rules) {
    final parsed = [for (final r in rules) parse(r)];
    validateSet(parsed);
    return parsed;
  }

  /// Overi, ze id su unikatne, odkazy (`event_active`, `days_before`) vedu
  /// na existujuce eventy a zavislosti nemaju cyklus.
  static void validateSet(List<EventRule> rules) {
    final byId = <String, EventRule>{};
    for (final r in rules) {
      if (byId.containsKey(r.id)) {
        throw EventRuleFormatException(r.id, 'id', 'duplicate id');
      }
      byId[r.id] = r;
    }
    for (final r in rules) {
      for (final dep in r.dependencies) {
        if (!byId.containsKey(dep)) {
          throw EventRuleFormatException(
            r.id,
            'when',
            "references unknown event '$dep'",
          );
        }
      }
    }
    // DFS: 0 = nenavstiveny, 1 = na zasobniku, 2 = hotovy.
    final state = <String, int>{};
    void visit(String id, List<String> stack) {
      if (state[id] == 2) return;
      if (state[id] == 1) {
        final cycle = [...stack.sublist(stack.indexOf(id)), id];
        throw EventRuleFormatException(
          id,
          'when',
          'dependency cycle ${cycle.join(' -> ')}',
        );
      }
      state[id] = 1;
      for (final dep in byId[id]!.dependencies) {
        visit(dep, [...stack, id]);
      }
      state[id] = 2;
    }

    for (final r in rules) {
      visit(r.id, const []);
    }
  }
}

final class _Ctx {
  _Ctx(this.ruleId);

  final String? ruleId;

  EventRuleFormatException error(String path, String problem) =>
      EventRuleFormatException(ruleId, path, problem);

  void onlyKeys(Map<String, Object?> m, Set<String> allowed, String path) {
    for (final key in m.keys) {
      if (!allowed.contains(key)) {
        throw error(
          path,
          "unknown key '$key' (allowed: ${allowed.join(', ')})",
        );
      }
    }
  }

  T enumValue<T>(
    Object? raw,
    List<T> values,
    String Function(T) wire,
    String path,
    T fallback,
  ) {
    if (raw == null) return fallback;
    for (final v in values) {
      if (wire(v) == raw) return v;
    }
    throw error(
      path,
      "unknown value '$raw' (allowed: ${values.map(wire).join(', ')})",
    );
  }

  int? intValue(Object? raw, String path) => switch (raw) {
    null => null,
    final int v => v,
    _ => throw error(path, 'expected integer'),
  };

  String? ref(Object? raw, String path) => switch (raw) {
    null => null,
    final String s when EventRuleParser._refPattern.hasMatch(s) => s,
    _ => throw error(path, 'expected id [a-z0-9_.]'),
  };

  String requiredRef(Object? raw, String path) =>
      ref(raw, path) ?? (throw error(path, 'expected id [a-z0-9_.]'));

  List<String> refList(Object? raw, String path) => switch (raw) {
    null => const [],
    final List<Object?> l => [
      for (final (i, v) in l.indexed) requiredRef(v, '$path[$i]'),
    ],
    _ => throw error(path, 'expected list of ids'),
  };

  Set<String> tags(Object? raw, String path) {
    final list = switch (raw) {
      null => const <Object?>[],
      final List<Object?> l => l,
      _ => throw error(path, 'expected list of tags'),
    };
    return {
      for (final (i, t) in list.indexed)
        if (t is String && EventRuleParser.idPattern.hasMatch(t))
          t
        else
          throw error('$path[$i]', 'expected tag [a-z0-9_]'),
    };
  }

  Map<String, double> boosts(Object? raw, String path) {
    final map = switch (raw) {
      null => const <String, Object?>{},
      final Map<String, Object?> m => m,
      _ => throw error(path, 'expected object tag -> number'),
    };
    return {
      for (final MapEntry(:key, :value) in map.entries)
        if (!EventRuleParser.idPattern.hasMatch(key))
          key: throw error('$path.$key', 'expected tag [a-z0-9_]')
        else if (value is num && value > 0 && value <= EventRuleParser.maxBoost)
          key: value.toDouble()
        else
          key: throw error(
            '$path.$key',
            'expected number in (0, ${EventRuleParser.maxBoost}]',
          ),
    };
  }

  EventCondition condition(Object? raw, String path) {
    if (raw is! Map<String, Object?>) {
      throw error(path, 'expected condition object');
    }
    onlyKeys(raw, EventRuleParser.atomKeys, path);
    if (raw.length != 1) {
      throw error(
        path,
        raw.isEmpty
            ? 'empty condition'
            : 'exactly one key per condition, got ${raw.keys.join(', ')}; '
                  'use all/any',
      );
    }
    final MapEntry(:key, :value) = raw.entries.single;
    final at = '$path.$key';
    return switch (key) {
      'all' => AllCondition(conditions(value, at)),
      'any' => AnyCondition(conditions(value, at)),
      'not' => NotCondition(condition(value, at)),
      'hijri_month' => HijriMonthCondition(
        matcher(value, at, 1, 12, allowRange: false),
      ),
      'hijri_day' => HijriDayCondition(matcher(value, at, 1, 30)),
      'hijri_month_day' => HijriMonthDayCondition(monthDays(value, at)),
      'weekday' => WeekdayCondition(
        matcher(value, at, 1, 7, allowRange: false),
      ),
      'days_before' => daysBefore(value, at),
      'event_active' => EventActiveCondition(eventId(value, at)),
      'pref' => PrefCondition(requiredRef(value, at)),
      'user_flag' => UserFlagCondition(
        enumValue(
          value ?? '',
          UserFlag.values,
          (f) => f.wire,
          at,
          UserFlag.excused,
        ),
      ),
      _ => questProgress(value, at),
    };
  }

  List<EventCondition> conditions(Object? raw, String path) {
    if (raw is! List<Object?> || raw.isEmpty) {
      throw error(path, 'expected non-empty list of conditions');
    }
    return [for (final (i, c) in raw.indexed) condition(c, '$path[$i]')];
  }

  IntMatcher matcher(
    Object? raw,
    String path,
    int min,
    int max, {
    bool allowRange = true,
  }) {
    int check(Object? v, String at) {
      if (v is! int) throw error(at, 'expected integer');
      if (v < min || v > max) throw error(at, '$v out of range $min..$max');
      return v;
    }

    switch (raw) {
      case final int v:
        return IntSetMatcher({check(v, path)});
      case final List<Object?> l when l.isNotEmpty:
        return IntSetMatcher([
          for (final (i, v) in l.indexed) check(v, '$path[$i]'),
        ]);
      case final Map<String, Object?> m when allowRange:
        onlyKeys(m, const {'gte', 'lte'}, path);
        final gte = check(m['gte'], '$path.gte');
        final lte = check(m['lte'], '$path.lte');
        if (gte > lte) throw error(path, 'gte > lte');
        return IntRangeMatcher(gte, lte);
      default:
        throw error(
          path,
          allowRange
              ? 'expected int, non-empty [int] or {gte, lte}'
              : 'expected int or non-empty [int]',
        );
    }
  }

  List<(int, int)> monthDays(Object? raw, String path) {
    if (raw is! List<Object?> || raw.isEmpty) {
      throw error(path, 'expected non-empty list of [month, day]');
    }
    return [
      for (final (i, pair) in raw.indexed)
        if (pair case [final int m, final int d]
            when m >= 1 && m <= 12 && d >= 1 && d <= 30)
          (m, d)
        else
          throw error('$path[$i]', 'expected [month 1..12, day 1..30]'),
    ];
  }

  String eventId(Object? raw, String path) => switch (raw) {
    final String s when EventRuleParser.idPattern.hasMatch(s) => s,
    _ => throw error(path, 'expected event id [a-z0-9_]'),
  };

  DaysBeforeCondition daysBefore(Object? raw, String path) {
    if (raw is! Map<String, Object?>) {
      throw error(path, 'expected {event, n}');
    }
    onlyKeys(raw, const {'event', 'n'}, path);
    return DaysBeforeCondition(
      eventId(raw['event'], '$path.event'),
      matcher(raw['n'], '$path.n', 1, 30),
    );
  }

  QuestProgressCondition questProgress(Object? raw, String path) {
    if (raw is! Map<String, Object?>) throw error(path, 'expected {id, lt}');
    onlyKeys(raw, const {'id', 'lt'}, path);
    final lt = raw['lt'];
    if (lt is! int || lt < 1) throw error('$path.lt', 'expected integer >= 1');
    return QuestProgressCondition(requiredRef(raw['id'], '$path.id'), lt);
  }
}
