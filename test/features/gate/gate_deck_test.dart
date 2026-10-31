import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/feed.dart';
import 'package:prosoche/features/gate/gate_deck.dart';

final _date = LocalDate(2026, 10, 29);

DailySetCard _ayah(int pos, int surah, int ayah, {bool khatm = true}) =>
    DailySetCard(
      pos: pos,
      cardId: AyahCardId(AyahId(surah, ayah)),
      slot: Slot.ayah,
      khatm: khatm,
    );

void main() {
  test('skips intro and event, attaches them to the next card', () {
    final deck = GateDeck(
      cards: [
        DailySetCard(pos: 1, cardId: IntroCardId(_date), slot: Slot.intro),
        DailySetCard(
          pos: 2,
          cardId: EventCardId('example', _date),
          slot: Slot.event,
        ),
        _ayah(3, 18, 1),
      ],
      cursor: 0,
      readingPosition: null,
    );
    final first = deck.next();
    expect(first, isA<SetGateItem>());
    expect(first.cardId, AyahCardId(AyahId(18, 1)));
    expect(first.autoSeenBefore.map((c) => c.pos), [1, 2]);
  });

  test('starts after the cursor', () {
    final deck = GateDeck(
      cards: [_ayah(1, 2, 1), _ayah(2, 2, 2), _ayah(3, 2, 3)],
      cursor: 2,
      readingPosition: AyahId(2, 2),
    );
    expect(deck.inSet, isTrue);
    expect(deck.next().cardId, AyahCardId(AyahId(2, 3)));
    expect(deck.inSet, isFalse);
  });

  test('at most one quiz per gate', () {
    final deck = GateDeck(
      cards: [
        DailySetCard(pos: 1, cardId: QuizCardId(5, 'ar2mean'), slot: Slot.srs),
        DailySetCard(pos: 2, cardId: QuizCardId(6, 'ar2mean'), slot: Slot.srs),
        DailySetCard(pos: 3, cardId: HadithCardId(9), slot: Slot.hadithDua),
      ],
      cursor: 0,
      readingPosition: null,
    );
    expect(deck.next().cardId, QuizCardId(5, 'ar2mean'));
    expect(deck.next().cardId, HadithCardId(9));
  });

  test('free reading continues after the last khatm verse of the set', () {
    final deck = GateDeck(
      cards: [
        _ayah(1, 2, 7),
        _ayah(2, 3, 1, khatm: false),
        DailySetCard(pos: 3, cardId: KhatmCardId(1), slot: Slot.ayah),
      ],
      cursor: 0,
      readingPosition: AyahId(2, 6),
    );
    expect(deck.next().cardId, AyahCardId(AyahId(2, 7)));
    expect(deck.next().cardId, AyahCardId(AyahId(3, 1)));
    final free = deck.next();
    expect(free, isA<FreeReadingItem>());
    expect((free as FreeReadingItem).ayah, AyahId(2, 8));
    // Koncova khatm karta sa oznaci seen pred prvym volnym versom.
    expect(free.autoSeenBefore.map((c) => c.pos), [3]);
    expect(deck.next().cardId, AyahCardId(AyahId(2, 9)));
  });

  test('free reading without position starts at 1:1, after 114:6 again', () {
    final fresh = GateDeck(cards: const [], cursor: 0, readingPosition: null);
    expect(fresh.next().cardId, const AyahCardId(AyahId.first));
    expect(fresh.next().cardId, AyahCardId(AyahId.first.next));

    final end = GateDeck(
      cards: const [],
      cursor: 0,
      readingPosition: AyahId(114, 5),
    );
    expect(end.next().cardId, const AyahCardId(AyahId.last));
    expect(end.next().cardId, const AyahCardId(AyahId.first));
  });

  test('counted types are the reading cards of docs/02 A4', () {
    expect(GateDeck.counted, isNot(contains(CardType.intro)));
    expect(GateDeck.counted, isNot(contains(CardType.event)));
    expect(GateDeck.counted, isNot(contains(CardType.done)));
    expect(GateDeck.counted, isNot(contains(CardType.khatm)));
    expect(GateDeck.counted, hasLength(7));
  });
}
