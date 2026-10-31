import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/domain/common/common.dart';

void main() {
  // Tvar z docs/02 D2 (pravidlo jumuah, testovacia fixture).
  final jumuah = <String, Object?>{
    'id': 'jumuah',
    'when': {'weekday': 5},
    'cards': {
      'event_card_slot': 2,
      'ayah_slots': [3, 4],
      'surah': 18,
      'cursor': 'event_cursor.jumuah',
    },
    'quests': {'read': 'read_kahf'},
  };

  test('parses docs/02 D2 shape and ignores rule keys', () {
    final e = EventEffect.fromJson(jumuah);
    expect(e.eventCardSlot, 2);
    expect(e.ayahSlots, [3, 4]);
    expect(e.surah, 18);
    expect(e.cursor, 'event_cursor.jumuah');
    expect(e.quests, {QuestSlot.read: 'read_kahf'});
    expect(e.isEmpty, isFalse);
  });

  test('toJson round trip', () {
    final e = EventEffect.fromJson(jumuah);
    expect(e.toJson(), {'cards': jumuah['cards'], 'quests': jumuah['quests']});
    expect(EventEffect.fromJson(e.toJson()), e);
    expect(EventEffect.fromJson(e.toJson()).hashCode, e.hashCode);
  });

  test('quest only effect', () {
    final e = EventEffect.fromJson(const {
      'quests': {'act': 'fast_white_day'},
    });
    expect(e.eventCardSlot, isNull);
    expect(e.toJson(), {
      'quests': {'act': 'fast_white_day'},
    });
    expect(e, isNot(EventEffect.empty));
  });

  test('empty', () {
    expect(EventEffect.fromJson(const {'id': 'x'}), EventEffect.empty);
    expect(EventEffect.empty.isEmpty, isTrue);
    expect(EventEffect.empty.toJson(), isEmpty);
    expect(EventEffect.empty.toString(), contains('EventEffect'));
  });

  test('lists are unmodifiable', () {
    final e = EventEffect.fromJson(jumuah);
    expect(() => e.ayahSlots.add(5), throwsUnsupportedError);
    expect(() => e.quests[QuestSlot.act] = 'x', throwsUnsupportedError);
  });

  group('rejects', () {
    for (final (name, json) in <(String, Map<String, Object?>)>[
      (
        'unknown card key',
        {
          'cards': {
            'slots': [2],
          },
        },
      ),
      (
        'unknown quest slot',
        {
          'quests': {'pray': 'x'},
        },
      ),
      ('cards not object', {'cards': 2}),
      (
        'wrong type',
        {
          'cards': {'event_card_slot': '2'},
        },
      ),
      (
        'non-int slot',
        {
          'cards': {
            'ayah_slots': ['3'],
            'surah': 18,
            'cursor': 'event_cursor.x',
          },
        },
      ),
      (
        'quest not string',
        {
          'quests': {'read': 1},
        },
      ),
      (
        'slot < 1',
        {
          'cards': {'event_card_slot': 0},
        },
      ),
      (
        'ayah slot < 1',
        {
          'cards': {
            'ayah_slots': [0],
            'surah': 18,
            'cursor': 'event_cursor.x',
          },
        },
      ),
      (
        'duplicate slot',
        {
          'cards': {
            'event_card_slot': 3,
            'ayah_slots': [3, 4],
            'surah': 18,
            'cursor': 'event_cursor.x',
          },
        },
      ),
      (
        'ayah slots without cursor',
        {
          'cards': {
            'ayah_slots': [3],
            'surah': 18,
          },
        },
      ),
      (
        'surah out of range',
        {
          'cards': {'surah': 115},
        },
      ),
      (
        'cursor outside event_cursor',
        {
          'cards': {'cursor': 'reader.last_ayah_id'},
        },
      ),
    ]) {
      test(name, () {
        expect(() => EventEffect.fromJson(json), throwsFormatException);
      });
    }

    test('invalid constructor args', () {
      expect(() => EventEffect(eventCardSlot: 0), throwsArgumentError);
      expect(() => EventEffect(ayahSlots: const [3]), throwsArgumentError);
    });
  });

  test('ActiveEvent equality and defaults', () {
    final effect = EventEffect.fromJson(jumuah);
    final a = ActiveEvent(id: 'jumuah', effect: effect);
    expect(a.priority, 0);
    expect(a.mode, isNull);
    expect(a, ActiveEvent(id: 'jumuah', effect: EventEffect.fromJson(jumuah)));
    expect(a.hashCode, ActiveEvent(id: 'jumuah', effect: effect).hashCode);
    expect(a, isNot(ActiveEvent(id: 'jumuah', effect: effect, priority: 1)));
    final r = ActiveEvent(
      id: 'ramadan',
      effect: EventEffect.empty,
      priority: 100,
      mode: 'ramadan',
    );
    expect(r.toString(), 'ActiveEvent(ramadan, priority: 100, mode: ramadan)');
  });

  test('Slot and QuestSlot wire names', () {
    for (final s in Slot.values) {
      expect(Slot.fromWire(s.wire), s);
    }
    for (final q in QuestSlot.values) {
      expect(QuestSlot.fromWire(q.wire), q);
    }
    expect(Slot.fromWire('x'), isNull);
    expect(QuestSlot.fromWire('x'), isNull);
    expect(
      ['intro', 'ayah', 'word', 'srs', 'reflection'].map(Slot.fromWire),
      everyElement(isNotNull),
    );
  });
}
