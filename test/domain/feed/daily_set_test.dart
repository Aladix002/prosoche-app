import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/feed.dart';

void main() {
  final date = LocalDate(2026, 10, 29);

  DailySet sample() => DailySet(
    date: date,
    phase: DayPhase.morning,
    contentVersion: '2026.11.1',
    tz: 'Europe/Bratislava',
    cards: [
      DailySetCard(pos: 1, cardId: IntroCardId(date), slot: Slot.intro),
      DailySetCard(
        pos: 2,
        cardId: ContentCardId.quote('q_0001'),
        slot: Slot.quote,
      ),
      DailySetCard(
        pos: 3,
        cardId: ContentCardId(CardType.practice, 'morning'),
        slot: Slot.practice,
      ),
    ],
  );

  test('cards_json round trip', () {
    final s = sample();
    final back = DailySet.decode(s.encode(), date: date);
    expect(back, s);
    expect(back.hashCode, s.hashCode);
    expect(back.cards.first.hashCode, s.cards.first.hashCode);
    expect(back.toString(), contains('quote:q_0001'));
    expect(back.cards[1].toString(), contains('quote:q_0001'));
  });

  test('json shape follows docs/02 0.3', () {
    final json = sample().toJson();
    expect(json['v'], 1);
    expect(json['generator_version'], 1);
    expect(json['content_version'], '2026.11.1');
    expect(json['tz'], 'Europe/Bratislava');
    expect(json['phase'], 'morning');
    final cards = json['cards']! as List<Object?>;
    expect(cards[0], {
      'pos': 1,
      'card_id': 'intro:2026-10-29',
      'slot': 'intro',
    });
    expect(cards[1], {'pos': 2, 'card_id': 'quote:q_0001', 'slot': 'quote'});
  });

  test('n counts all cards, done is N+1 outside cards', () {
    final s = sample();
    expect(s.n, 3);
    expect(s.contentCards, s.cards);
    expect(s.doneCardId, DoneCardId(date));
  });

  test('optional keys omitted', () {
    final s = DailySet(
      date: date,
      phase: DayPhase.day,
      cards: [
        DailySetCard(pos: 1, cardId: IntroCardId(date), slot: Slot.intro),
      ],
    );
    expect(s.toJson().containsKey('tz'), isFalse);
    expect(s.toJson().containsKey('content_version'), isFalse);
    expect(DailySet.decode(s.encode(), date: date), s);
    expect(s, isNot(sample()));
  });

  group('validation', () {
    test('rejects done card and bad pos', () {
      expect(
        () => DailySetCard(pos: 1, cardId: DoneCardId(date), slot: Slot.intro),
        throwsArgumentError,
      );
      expect(
        () => DailySetCard(pos: 0, cardId: IntroCardId(date), slot: Slot.intro),
        throwsRangeError,
      );
      expect(
        () => DailySet(
          date: date,
          phase: DayPhase.day,
          cards: [
            DailySetCard(pos: 2, cardId: IntroCardId(date), slot: Slot.intro),
          ],
        ),
        throwsArgumentError,
      );
    });

    Map<String, Object?> base() => sample().toJson();

    void bad(Map<String, Object?> json) => expect(
      () => DailySet.fromJson(json, date: date),
      throwsFormatException,
    );

    test('rejects malformed json', () {
      bad(base()..['v'] = 2);
      bad(base()..['phase'] = 'noon');
      bad(base()..remove('cards'));
      bad(base()..['cards'] = [1]);
      bad(base()..['tz'] = 1);
      bad(
        base()
          ..['cards'] = [
            {'pos': 1, 'card_id': 'intro:2026-10-29', 'slot': 'x'},
          ],
      );
      bad(
        base()
          ..['cards'] = [
            {'pos': 1, 'card_id': 'ayah:2255', 'slot': 'quote'},
          ],
      );
      expect(() => DailySet.decode('[]', date: date), throwsFormatException);
    });
  });
}
