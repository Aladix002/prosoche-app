import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/calendar/event_rule.dart';
import 'package:prosoche/domain/calendar/event_rule_parser.dart';
import 'package:prosoche/domain/common/common.dart';

import 'fixtures/event_rules_fixture.dart';

Matcher _ruleError(String ruleId, String text) => throwsA(
  isA<EventRuleFormatException>()
      .having((e) => e.ruleId, 'ruleId', ruleId)
      .having((e) => e.message, 'message', contains(text)),
);

Map<String, Object?> _rule(Map<String, Object?> extra) => {
  'id': 'x',
  'when': {'weekday': 5},
  ...extra,
};

void main() {
  group('valid rules', () {
    test('all fixture rules parse as a set', () {
      final rules = EventRuleParser.parseAll(fixtureRules);
      expect(rules, hasLength(fixtureRules.length));
      expect(rules.map((r) => r.id).toSet(), hasLength(rules.length));
    });

    test('jumuah: docs/02 D2 shape and defaults', () {
      final r = EventRuleParser.parseString('''
        {"id": "jumuah", "when": {"weekday": 5},
         "cards": {"event_card_slot": 2, "ayah_slots": [3, 4], "surah": 18,
                   "cursor": "event_cursor.jumuah"},
         "quests": {"read": "read_kahf"}}
      ''');
      expect(r.id, 'jumuah');
      expect(r.when, isA<WeekdayCondition>());
      expect(r.phase, EventPhase.day);
      expect(r.priority, 0);
      expect(r.category, EventCategory.core);
      expect(r.merge, EventMerge.slots);
      expect(r.mode, isNull);
      expect(r.effect.eventCardSlot, 2);
      expect(r.effect.ayahSlots, [3, 4]);
      expect(r.effect.quests, {QuestSlot.read: 'read_kahf'});
      expect(r.intro, isNull);
      expect(r.forbidTags, isEmpty);
      expect(r.boostTags, isEmpty);
      expect(r.notifications, isEmpty);
      expect(r.toString(), 'EventRule(jumuah, priority: 0)');
    });

    test('all optional keys', () {
      final r = EventRuleParser.parse({
        'id': 'ramadan',
        'when': {'hijri_month': 9},
        'phase': 'both',
        'priority': 100,
        'category': 'core',
        'merge': 'exclusive',
        'mode': 'ramadan',
        'intro': 'intro.ramadan',
        'forbid_tags': ['siyam_nafl'],
        'boost_tags': {'quran': 2, 'dua': 1.5},
        'notifications': ['notif.a', 'notif.b'],
      });
      expect(r.phase, EventPhase.both);
      expect(r.merge, EventMerge.exclusive);
      expect(r.mode, EventMode.ramadan);
      expect(r.intro, 'intro.ramadan');
      expect(r.forbidTags, {'siyam_nafl'});
      expect(r.boostTags, {'quran': 2.0, 'dua': 1.5});
      expect(r.notifications, ['notif.a', 'notif.b']);
      expect(r.effect.isEmpty, isTrue);
    });

    test('id from DB column when JSON has none', () {
      final r = EventRuleParser.parseString(
        '{"when": {"hijri_day": [13, 14, 15]}}',
        id: 'white_days',
      );
      expect(r.id, 'white_days');
      final m = (r.when as HijriDayCondition).days;
      expect(m, IntSetMatcher(const {13, 14, 15}));
      expect(m.hashCode, IntSetMatcher(const {15, 14, 13}).hashCode);
      expect(m.toString(), '{13, 14, 15}');
    });

    test('condition tree', () {
      final r = EventRuleParser.parse(
        _rule({
          'when': {
            'any': [
              {
                'not': {'event_active': 'y'},
              },
              {
                'hijri_day': {'gte': 20, 'lte': 30},
              },
              {
                'hijri_month_day': [
                  [12, 13],
                ],
              },
              {
                'days_before': {'event': 'y', 'n': 1},
              },
              {'pref': 'show_optional_days'},
              {'user_flag': 'fasting_enabled'},
              {
                'quest_progress': {'id': 'shawwal6', 'lt': 6},
              },
            ],
          },
        }),
      );
      final any = r.when as AnyCondition;
      expect(any.children, hasLength(7));
      expect(r.dependencies, {'y'});
      final range = (any.children[1] as HijriDayCondition).days;
      expect(range, const IntRangeMatcher(20, 30));
      expect(range.hashCode, const IntRangeMatcher(20, 30).hashCode);
      expect(range.toString(), '20..30');
      expect((any.children[2] as HijriMonthDayCondition).days, {(12, 13)});
      expect(
        (any.children[5] as UserFlagCondition).flag,
        UserFlag.fastingEnabled,
      );
      final q = any.children[6] as QuestProgressCondition;
      expect((q.questId, q.lt), ('shawwal6', 6));
    });
  });

  group('rejects with a clear error', () {
    test('unknown top-level key', () {
      expect(
        () => EventRuleParser.parse(_rule({'colour': 'red'})),
        _ruleError('x', "unknown key 'colour' (allowed: id, when,"),
      );
    });

    test('unknown condition key names the path', () {
      expect(
        () => EventRuleParser.parse(
          _rule({
            'when': {
              'all': [
                {'hijri_month': 9},
                {
                  'hijri_day_in': [13],
                },
              ],
            },
          }),
        ),
        _ruleError('x', "when.all[1]: unknown key 'hijri_day_in'"),
      );
    });

    test('unknown key inside cards (EventEffect)', () {
      expect(
        () => EventRuleParser.parse(
          _rule({
            'cards': {'pool': 'x'},
          }),
        ),
        _ruleError('x', 'cards/quests: cards: unknown key(s) pool'),
      );
    });

    test('unknown key inside ranges and objects', () {
      expect(
        () => EventRuleParser.parse(
          _rule({
            'when': {
              'hijri_day': {'gte': 1, 'lt': 3},
            },
          }),
        ),
        _ruleError('x', "when.hijri_day: unknown key 'lt'"),
      );
      expect(
        () => EventRuleParser.parse(
          _rule({
            'when': {
              'days_before': {'event': 'y', 'n': 1, 'm': 2},
            },
          }),
        ),
        _ruleError('x', "unknown key 'm'"),
      );
      expect(
        () => EventRuleParser.parse(
          _rule({
            'when': {
              'quest_progress': {'id': 'q', 'gt': 1},
            },
          }),
        ),
        _ruleError('x', "unknown key 'gt'"),
      );
    });

    final cases = <String, (Object?, String)>{
      'not an object': ('nope', 'expected JSON object'),
      'missing when': ({'id': 'x'}, "missing 'when'"),
      'bad id': (
        {
          'id': 'Bad-Id',
          'when': {'weekday': 5},
        },
        'must match',
      ),
      'id not a string': (
        {
          'id': 5,
          'when': {'weekday': 5},
        },
        'id: expected string',
      ),
      'two keys in one condition': (
        _rule({
          'when': {'hijri_month': 9, 'weekday': 5},
        }),
        'exactly one key per condition',
      ),
      'empty condition': (
        _rule({'when': <String, Object?>{}}),
        'empty condition',
      ),
      'condition not an object': (
        _rule({'when': 5}),
        'expected condition object',
      ),
      'empty all': (
        _rule({
          'when': {'all': <Object?>[]},
        }),
        'non-empty list of conditions',
      ),
      'month out of range': (
        _rule({
          'when': {'hijri_month': 13},
        }),
        'when.hijri_month: 13 out of range 1..12',
      ),
      'day out of range in list': (
        _rule({
          'when': {
            'hijri_day': [1, 31],
          },
        }),
        'when.hijri_day[1]: 31 out of range 1..30',
      ),
      'weekday range not allowed': (
        _rule({
          'when': {
            'weekday': {'gte': 1, 'lte': 3},
          },
        }),
        'expected int or non-empty [int]',
      ),
      'weekday string': (
        _rule({
          'when': {'weekday': 'friday'},
        }),
        'expected int or non-empty [int]',
      ),
      'range gte > lte': (
        _rule({
          'when': {
            'hijri_day': {'gte': 5, 'lte': 1},
          },
        }),
        'gte > lte',
      ),
      'range value not int': (
        _rule({
          'when': {
            'hijri_day': {'gte': 'a', 'lte': 1},
          },
        }),
        'when.hijri_day.gte: expected integer',
      ),
      'month_day bad pair': (
        _rule({
          'when': {
            'hijri_month_day': [
              [13, 1],
            ],
          },
        }),
        'expected [month 1..12, day 1..30]',
      ),
      'month_day empty': (
        _rule({
          'when': {'hijri_month_day': <Object?>[]},
        }),
        'non-empty list of [month, day]',
      ),
      'days_before not object': (
        _rule({
          'when': {'days_before': 1},
        }),
        'expected {event, n}',
      ),
      'days_before bad event': (
        _rule({
          'when': {
            'days_before': {'event': 1, 'n': 1},
          },
        }),
        'days_before.event: expected event id',
      ),
      'user_flag unknown': (
        _rule({
          'when': {'user_flag': 'sick'},
        }),
        "unknown value 'sick' (allowed: excused, fasting_enabled)",
      ),
      'pref missing value': (
        _rule({
          'when': {'pref': null},
        }),
        'when.pref: expected id',
      ),
      'quest_progress not object': (
        _rule({
          'when': {'quest_progress': 1},
        }),
        'expected {id, lt}',
      ),
      'quest_progress lt': (
        _rule({
          'when': {
            'quest_progress': {'id': 'q', 'lt': 0},
          },
        }),
        'lt: expected integer >= 1',
      ),
      'unknown phase': (
        _rule({'phase': 'night'}),
        "phase: unknown value 'night' (allowed: day, eve, both)",
      ),
      'unknown category': (
        _rule({'category': 'opt'}),
        "unknown value 'opt' (allowed: core, optional, info)",
      ),
      'unknown merge': (
        _rule({'merge': 'replace'}),
        "merge: unknown value 'replace'",
      ),
      'unknown mode': (
        _rule({'mode': 'hajj'}),
        "mode: unknown value 'hajj' (allowed: ramadan)",
      ),
      'priority not int': (
        _rule({'priority': 'high'}),
        'priority: expected integer',
      ),
      'slot > 12': (
        _rule({
          'cards': {'event_card_slot': 13},
        }),
        'slot 13 out of range 1..12',
      ),
      'invalid quest id': (
        _rule({
          'quests': {'act': 'Bad Id'},
        }),
        'quests.act: invalid quest id',
      ),
      'intro not id': (_rule({'intro': 3}), 'intro: expected id'),
      'forbid_tags not list': (
        _rule({'forbid_tags': 'siyam'}),
        'expected list of tags',
      ),
      'forbid_tags bad tag': (
        _rule({
          'forbid_tags': ['Siyam'],
        }),
        'forbid_tags[0]: expected tag',
      ),
      'boost_tags not object': (
        _rule({
          'boost_tags': ['dua'],
        }),
        'expected object tag -> number',
      ),
      'boost_tags > 6': (
        _rule({
          'boost_tags': {'dua': 7},
        }),
        'boost_tags.dua: expected number in (0, 6.0]',
      ),
      'boost_tags bad tag': (
        _rule({
          'boost_tags': {'Dua': 2},
        }),
        'boost_tags.Dua: expected tag',
      ),
      'notifications not list': (
        _rule({'notifications': 'n'}),
        'expected list of ids',
      ),
      'notifications bad id': (
        _rule({
          'notifications': ['ok', 'Not OK'],
        }),
        'notifications[1]: expected id',
      ),
      'optional event with override': (
        _rule({
          'category': 'optional',
          'quests': {'act': 'a'},
        }),
        'optional event cannot override (cards/quests)',
      ),
      'info event with mode and exclusive': (
        _rule({'category': 'info', 'mode': 'ramadan', 'merge': 'exclusive'}),
        'info event cannot override (mode, merge: exclusive)',
      ),
    };
    for (final MapEntry(key: name, value: (json, message)) in cases.entries) {
      test(name, () {
        expect(
          () => EventRuleParser.parse(json),
          throwsA(
            isA<EventRuleFormatException>().having(
              (e) => e.message,
              'message',
              contains(message),
            ),
          ),
        );
      });
    }

    test('missing id without column id', () {
      expect(
        () => EventRuleParser.parse({
          'when': {'weekday': 5},
        }),
        throwsA(
          isA<EventRuleFormatException>()
              .having((e) => e.ruleId, 'ruleId', isNull)
              .having((e) => e.message, 'message', "rule: missing 'id'"),
        ),
      );
    });

    test('id mismatch with column', () {
      expect(
        () => EventRuleParser.parse(_rule({}), id: 'y'),
        _ruleError('x', "'x' does not match column id 'y'"),
      );
    });

    test('invalid JSON text', () {
      expect(
        () => EventRuleParser.parseString('{', id: 'x'),
        _ruleError('x', 'invalid JSON'),
      );
    });

    test('is a FormatException with path', () {
      try {
        EventRuleParser.parse(_rule({'phase': 1}));
        fail('expected exception');
      } on FormatException catch (e) {
        expect(e, isA<EventRuleFormatException>());
        expect((e as EventRuleFormatException).path, 'phase');
      }
    });
  });

  group('rule set', () {
    Map<String, Object?> dep(String id, Map<String, Object?> when) => {
      'id': id,
      'when': when,
    };

    test('duplicate id', () {
      expect(
        () => EventRuleParser.parseAll([_rule({}), _rule({})]),
        _ruleError('x', 'duplicate id'),
      );
    });

    test('unknown reference', () {
      expect(
        () => EventRuleParser.parseAll([
          dep('a', {'event_active': 'ghost'}),
        ]),
        _ruleError('a', "references unknown event 'ghost'"),
      );
    });

    test('dependency cycle', () {
      expect(
        () => EventRuleParser.parseAll([
          dep('a', {'event_active': 'b'}),
          dep('b', {
            'days_before': {'event': 'c', 'n': 1},
          }),
          dep('c', {
            'not': {'event_active': 'a'},
          }),
        ]),
        throwsA(
          isA<EventRuleFormatException>().having(
            (e) => e.message,
            'message',
            contains('dependency cycle a -> b -> c -> a'),
          ),
        ),
      );
    });

    test('self reference is a cycle', () {
      expect(
        () => EventRuleParser.parseAll([
          dep('a', {
            'days_before': {'event': 'a', 'n': 1},
          }),
        ]),
        _ruleError('a', 'dependency cycle a -> a'),
      );
    });

    test('shared dependency (diamond) is fine', () {
      final rules = EventRuleParser.parseAll([
        dep('base', {'hijri_month': 9}),
        dep('l', {'event_active': 'base'}),
        dep('r', {'event_active': 'base'}),
        dep('top', {
          'all': [
            {'event_active': 'l'},
            {'event_active': 'r'},
          ],
        }),
      ]);
      expect(rules.last.dependencies, {'l', 'r'});
    });
  });
}
