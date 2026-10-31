import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/feed.dart';
import 'package:prosoche/features/gate/gate_deck.dart';

final _date = LocalDate(2026, 10, 29);

ContentCardId _q(int n) => ContentCardId.quote('q_$n');

DailySetCard _quote(int pos, int n) =>
    DailySetCard(pos: pos, cardId: _q(n), slot: Slot.quote);

void main() {
  test('skips intro, attaches it to the next card', () {
    final deck = GateDeck(
      cards: [
        DailySetCard(pos: 1, cardId: IntroCardId(_date), slot: Slot.intro),
        _quote(2, 1),
      ],
      cursor: 0,
    );
    final first = deck.next()!;
    expect(first, isA<SetGateItem>());
    expect(first.cardId, _q(1));
    expect(first.autoSeenBefore.map((c) => c.pos), [1]);
  });

  test('starts after the cursor', () {
    final deck = GateDeck(
      cards: [_quote(1, 1), _quote(2, 2), _quote(3, 3)],
      cursor: 2,
    );
    expect(deck.inSet, isTrue);
    expect(deck.next()!.cardId, _q(3));
    expect(deck.inSet, isFalse);
    expect(deck.next(), isNull, reason: 'no extra cards');
  });

  test('free reading cycles extra cards not in the set', () {
    final deck = GateDeck(
      cards: [_quote(1, 1)],
      cursor: 0,
      extra: [_q(1), _q(7), _q(8), IntroCardId(_date)],
    );
    expect(deck.next()!.cardId, _q(1));
    final free = deck.next()!;
    expect(free, isA<FreeReadingItem>());
    expect(free.cardId, _q(7));
    expect(deck.next()!.cardId, _q(8));
    expect(deck.next()!.cardId, _q(7), reason: 'dokola');
  });

  test('intro at the end is attached to the first free card', () {
    final deck = GateDeck(
      cards: [
        DailySetCard(pos: 1, cardId: IntroCardId(_date), slot: Slot.intro),
      ],
      cursor: 0,
      extra: [_q(5)],
    );
    final free = deck.next()!;
    expect(free, isA<FreeReadingItem>());
    expect(free.autoSeenBefore.map((c) => c.pos), [1]);
  });
}
