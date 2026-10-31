import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/feed/feed.dart';

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
        cardId: AyahCardId(AyahId(2, 255)),
        slot: Slot.ayah,
        khatm: true,
      ),
      DailySetCard(
        pos: 3,
        cardId: WordCardId(1043),
        slot: Slot.word,
        ctxAyahId: AyahId(2, 255),
      ),
      DailySetCard(
        pos: 4,
        cardId: QuizCardId(880, 'ar2mean'),
        slot: Slot.srs,
        distractors: const [12, 501, 77],
      ),
      DailySetCard(pos: 5, cardId: KhatmCardId(1), slot: Slot.khatm),
      DailySetCard(
        pos: 6,
        cardId: EventCardId('jumuah', date),
        slot: Slot.event,
      ),
      DailySetCard(pos: 7, cardId: ReflectionCardId(31), slot: Slot.reflection),
    ],
  );

  test('cards_json round trip', () {
    final s = sample();
    final back = DailySet.decode(s.encode(), date: date);
    expect(back, s);
    expect(back.hashCode, s.hashCode);
    expect(back.cards.first.hashCode, s.cards.first.hashCode);
    expect(back.toString(), contains('ayah:2255'));
    expect(back.cards[1].toString(), contains('ayah:2255'));
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
    expect(cards[1], {
      'pos': 2,
      'card_id': 'ayah:2255',
      'slot': 'ayah',
      'khatm': true,
    });
    expect(cards[2], containsPair('ctx_ayah_id', 2255));
    expect(cards[3], containsPair('distractors', [12, 501, 77]));
  });

  test('n excludes khatm, done is N+1 outside cards', () {
    final s = sample();
    expect(s.cards, hasLength(7));
    expect(s.n, 6);
    expect(s.contentCards.any((c) => c.cardId is KhatmCardId), isFalse);
    expect(s.doneCardId, DoneCardId(date));
    expect(s.cards.any((c) => c.cardId is DoneCardId), isFalse);
  });

  test('intro event_id round trip, optional keys omitted', () {
    final s = DailySet(
      date: date,
      phase: DayPhase.day,
      cards: [
        DailySetCard(
          pos: 1,
          cardId: IntroCardId(date),
          slot: Slot.intro,
          eventId: 'jumuah',
        ),
      ],
    );
    expect(s.toJson()['cards'], [
      {
        'pos': 1,
        'card_id': 'intro:2026-10-29',
        'slot': 'intro',
        'event_id': 'jumuah',
      },
    ]);
    expect(DailySet.decode(s.encode(), date: date), s);
    expect(s.toJson().containsKey('tz'), isFalse);
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

    Map<String, Object?> withCard(Map<String, Object?> card) =>
        base()..['cards'] = [card];

    test('rejects malformed json', () {
      bad(base()..['v'] = 2);
      bad(base()..['phase'] = 'noon');
      bad(base()..remove('cards'));
      bad(base()..['cards'] = [1]);
      bad(base()..['tz'] = 1);
      bad(withCard({'pos': 1, 'card_id': 'intro:2026-10-29', 'slot': 'x'}));
      bad(
        withCard({
          'pos': 1,
          'card_id': 'word:1',
          'slot': 'word',
          'ctx_ayah_id': 1999,
        }),
      );
      bad(
        withCard({
          'pos': 1,
          'card_id': 'quiz:1:ar2mean',
          'slot': 'srs',
          'distractors': ['a'],
        }),
      );
      expect(() => DailySet.decode('[]', date: date), throwsFormatException);
    });
  });
}
