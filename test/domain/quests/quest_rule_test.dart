import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/quests.dart';

final _day = LocalDate(2026, 10, 29);

CardActivity _ev(
  String card, {
  CardAction action = CardAction.seen,
  CardContext context = CardContext.feed,
  int minute = 0,
  LocalDate? date,
}) => CardActivity(
  date: date ?? _day,
  cardId: CardId.parse(card),
  action: action,
  context: context,
  ts: DateTime(2026, 10, 29, 8, minute),
);

void main() {
  group('QuestRule.fromJson', () {
    test('parses the plan example', () {
      final rule = QuestRule.fromJson(const {
        'count': {'type': 'ayah', 'action': 'seen', 'min': 10},
      });
      expect(rule.types, {CardType.ayah});
      expect(rule.actions, {CardAction.seen});
      expect(rule.contexts, isNull);
      expect(rule.target(const {}), 10);
    });

    test('parses lists, context, surah and param target', () {
      final rule = QuestRule.fromJson(const {
        'count': {
          'type': ['ayah'],
          'action': ['seen', 'answered'],
          'context': ['feed', 'reader'],
          'surah': 18,
          'min': {'param': 'n'},
        },
      });
      expect(rule.actions, {CardAction.seen, CardAction.answered});
      expect(rule.contexts, {CardContext.feed, CardContext.reader});
      expect(rule.surah, 18);
      expect(rule.target(const {'n': 15}), 15);
      expect(() => rule.target(const {}), throwsArgumentError);
      expect(() => rule.target(const {'n': 0}), throwsArgumentError);
    });

    test('round-trips through toJson', () {
      for (final json in <Map<String, Object?>>[
        {
          'count': {'type': 'ayah', 'min': 10},
        },
        {
          'count': {
            'type': ['dua', 'hadith'],
            'action': ['answered', 'seen'],
            'context': 'gate',
            'min': {'param': 'n'},
          },
        },
        {
          'count': {'type': 'ayah', 'surah': 18, 'min': 110},
        },
      ]) {
        final rule = QuestRule.fromJson(json);
        expect(rule.toJson(), json);
        expect(QuestRule.fromJson(rule.toJson()), rule);
        expect(QuestRule.fromJson(json).hashCode, rule.hashCode);
        expect(rule.toString(), contains('count'));
      }
    });

    test('rejects unknown keys and bad values with a clear error', () {
      const bad = <Map<String, Object?>>[
        {'sum': <String, Object?>{}},
        {'count': 3},
        {
          'count': {'type': 'ayah', 'min': 1, 'extra': true},
        },
        {
          'count': {'min': 1},
        },
        {
          'count': {'type': 'verse', 'min': 1},
        },
        {
          'count': {'type': <Object?>[], 'min': 1},
        },
        {
          'count': {'type': 7, 'min': 1},
        },
        {
          'count': {'type': 'ayah', 'action': 'read', 'min': 1},
        },
        {
          'count': {'type': 'ayah', 'context': 'web', 'min': 1},
        },
        {
          'count': {'type': 'ayah', 'surah': '18', 'min': 1},
        },
        {
          'count': {'type': 'ayah', 'surah': 115, 'min': 1},
        },
        {
          'count': {'type': 'hadith', 'surah': 18, 'min': 1},
        },
        {
          'count': {'type': 'ayah', 'min': 0},
        },
        {
          'count': {'type': 'ayah', 'min': '10'},
        },
        {
          'count': {'type': 'ayah'},
        },
      ];
      for (final json in bad) {
        expect(
          () => QuestRule.fromJson(json),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              startsWith('rule'),
            ),
          ),
          reason: '$json',
        );
      }
    });
  });

  group('QuestRule constructor', () {
    test('validates arguments', () {
      expect(
        () => QuestRule(types: const {}, min: const QuestTarget.fixed(1)),
        throwsArgumentError,
      );
      expect(
        () => QuestRule(
          types: const {CardType.ayah},
          actions: const {},
          min: const QuestTarget.fixed(1),
        ),
        throwsArgumentError,
      );
      expect(
        () => QuestRule(
          types: const {CardType.ayah},
          contexts: const {},
          min: const QuestTarget.fixed(1),
        ),
        throwsArgumentError,
      );
    });
  });

  group('matches and progress', () {
    final rule = QuestRule.fromJson(const {
      'count': {
        'type': 'ayah',
        'context': ['feed', 'reader'],
        'surah': 18,
        'min': 2,
      },
    });

    test('filters by type, action, context and surah', () {
      expect(rule.matches(_ev('ayah:18001')), isTrue);
      expect(
        rule.matches(_ev('ayah:18001', context: CardContext.reader)),
        isTrue,
      );
      expect(
        rule.matches(_ev('ayah:18001', context: CardContext.gate)),
        isFalse,
      );
      expect(
        rule.matches(_ev('ayah:18001', action: CardAction.saved)),
        isFalse,
      );
      expect(rule.matches(_ev('ayah:2255')), isFalse);
      expect(rule.matches(_ev('hadith:3')), isFalse);
    });

    test('counts distinct cards of the day and reports completion time', () {
      final events = [
        _ev('ayah:18002', minute: 9),
        _ev('ayah:18001', minute: 1),
        _ev('ayah:18001', context: CardContext.reader, minute: 2),
        _ev('ayah:18003', date: _day.addDays(-1), minute: 3),
      ];
      final p = countProgress(rule, 2, _day, events);
      expect(p.isComplete, isTrue);
      expect(p.current, 2);
      expect(p.completedAt, DateTime(2026, 10, 29, 8, 9));

      final partial = countProgress(rule, 2, _day, events.skip(1));
      expect(partial, const QuestProgress(current: 1, target: 2));
      expect(partial.isComplete, isFalse);
      expect(
        partial.hashCode,
        const QuestProgress(current: 1, target: 2).hashCode,
      );
      expect(partial.toString(), contains('1/2'));
    });
  });

  test('wire enums parse and reject unknown values', () {
    for (final a in CardAction.values) {
      expect(CardAction.fromWire(a.wire), a);
    }
    for (final c in CardContext.values) {
      expect(CardContext.fromWire(c.wire), c);
    }
    for (final s in QuestStatus.values) {
      expect(QuestStatus.fromWire(s.wire), s);
    }
    expect(CardAction.fromWire('x'), isNull);
    expect(CardContext.fromWire('x'), isNull);
    expect(QuestStatus.fromWire('x'), isNull);
  });

  test('CardActivity value semantics', () {
    final a = _ev('ayah:1001');
    expect(a, _ev('ayah:1001'));
    expect(a.hashCode, _ev('ayah:1001').hashCode);
    expect(a, isNot(_ev('ayah:1002')));
    expect(a.type, CardType.ayah);
    expect(a.toString(), contains('ayah:1001'));
  });
}
