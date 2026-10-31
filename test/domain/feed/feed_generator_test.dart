import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/feed.dart';

void main() {
  final date = LocalDate(2026, 10, 29);
  const generator = FeedGenerator();

  ContentCardId quoteId(int n) => ContentCardId.quote('q_$n');

  List<FeedCandidate> quotes(int count) => [
    for (var i = 1; i <= count; i++) FeedCandidate(id: quoteId(i)),
  ];

  FeedInputs inputs({
    int cardsCount = 12,
    FeedPools? pools,
    FeedHistory? history,
    bool shorterSet = false,
    int inactiveDays = 0,
    int seed = 3,
    DateTime? at,
  }) => FeedInputs(
    date: date,
    seed: seed,
    generatedAtLocalTime: at ?? DateTime(2026, 10, 29, 8),
    prefs: FeedPrefs(cardsCount: cardsCount, shorterSet: shorterSet),
    pools: pools ?? FeedPools.quotes(quotes(40)),
    history: history,
    inactiveDays: inactiveDays,
    contentVersion: 'v1',
    tz: 'Europe/Bratislava',
  );

  test('layout: only quotes in the pool fill every slot with quotes', () {
    for (final n in FeedPrefs.allowedCardsCounts) {
      final set = generator.generate(inputs(cardsCount: n)).set;
      expect(set.n, n);
      expect(set.cards.first.cardId, IntroCardId(date));
      expect(set.cards.first.slot, Slot.intro);
      expect(set.cards.skip(1).every((c) => c.slot == Slot.quote), isTrue);
      expect(set.cards.map((c) => c.cardId).toSet(), hasLength(n));
      expect(FeedGenerator.layouts[n], hasLength(n));
    }
  });

  FeedPools mixed() => FeedPools({
    for (final t in CardType.values.where((t) => t.isContent))
      t: [
        for (var i = 1; i <= 20; i++)
          FeedCandidate(
            id: ContentCardId(t, '${t.wire}.$i'),
            tags: [if (i == 1) 'morning', if (i == 2) 'evening'],
            timeOfDay: TimeOfDayFacet.fromTags([
              if (i == 1) 'morning',
              if (i == 2) 'evening',
            ]),
          ),
      ],
  });

  test('layout mixes every content type (12 and 16)', () {
    for (final n in [12, 16]) {
      final set = generator.generate(inputs(cardsCount: n, pools: mixed())).set;
      expect(set.n, n);
      final types = set.cards.map((c) => c.cardId.type).toSet();
      expect(types, containsAll(CardType.values.where((t) => t.isContent)));
      for (final c in set.cards) {
        expect(c.slot.cardType, c.cardId.type);
      }
      expect(
        set.cards.where((c) => c.slot == Slot.quote).length,
        greaterThanOrEqualTo(5),
        reason: 'read quest needs quotes',
      );
    }
    final small = generator.generate(inputs(cardsCount: 8, pools: mixed())).set;
    expect(small.cards.map((c) => c.slot), FeedGenerator.layouts[8]);
  });

  test('author slot is fresh-only: exhausted pool falls back to a quote', () {
    final pools = mixed();
    final history = FeedHistory(
      lastShown: {
        for (final c in pools.of(CardType.author)) c.id: date.addDays(-2),
      },
    );
    final set = generator.generate(inputs(pools: pools, history: history)).set;
    expect(
      set.cards.map((c) => c.cardId.type),
      isNot(contains(CardType.author)),
    );
    expect(set.n, 12);
    // Pojmy nie su fresh-only: najdavnejsie pouzity sa zopakuje.
    final concepts = FeedHistory(
      lastShown: {
        for (final c in pools.of(CardType.concept)) c.id: date.addDays(-2),
      },
    );
    final again = generator
        .generate(inputs(pools: pools, history: concepts))
        .set;
    expect(again.cards.map((c) => c.cardId.type), contains(CardType.concept));
  });

  test('time of day facet from tags', () {
    expect(TimeOfDayFacet.fromTags(['morning', 'x']), TimeOfDayFacet.morning);
    expect(TimeOfDayFacet.fromTags(['evening']), TimeOfDayFacet.evening);
    expect(TimeOfDayFacet.fromTags(const []), TimeOfDayFacet.any);
  });

  test('deterministic for same inputs, differs by seed', () {
    final a = generator.generate(inputs()).set;
    expect(generator.generate(inputs()).set, a);
    final b = generator.generate(inputs(seed: 99)).set;
    expect(b.cards.map((c) => c.cardId), isNot(a.cards.map((c) => c.cardId)));
    expect(a.contentVersion, 'v1');
    expect(a.tz, 'Europe/Bratislava');
    expect(a.phase, DayPhase.morning);
  });

  test('disabled ids are never picked, recent ones are avoided', () {
    final history = FeedHistory(
      disabledIds: {quoteId(1), quoteId(2)},
      lastShown: {for (var i = 3; i <= 20; i++) quoteId(i): date.addDays(-1)},
    );
    final ids = generator
        .generate(inputs(history: history))
        .set
        .cards
        .map((c) => c.cardId)
        .toSet();
    expect(ids, isNot(contains(quoteId(1))));
    expect(ids, isNot(contains(quoteId(2))));
    for (var i = 3; i <= 20; i++) {
      expect(ids, isNot(contains(quoteId(i))));
    }
  });

  test('small pool: set gets shorter, no duplicates', () {
    final set = generator
        .generate(inputs(pools: FeedPools.quotes(quotes(3))))
        .set;
    expect(set.n, 4);
    expect(set.cards.map((c) => c.pos), [1, 2, 3, 4]);
    final empty = generator.generate(inputs(pools: FeedPools())).set;
    expect(empty.cards.single.cardId, IntroCardId(date));
  });

  test('other slots fall back to quotes', () {
    // Slot bez kandidata (napr. practice) sa naplni citatom.
    final pools = FeedPools({
      CardType.quote: quotes(2),
      CardType.practice: const [],
    });
    final set = generator.generate(inputs(pools: pools)).set;
    expect(set.cards.skip(1).map((c) => c.slot).toSet(), {Slot.quote});
    expect(FeedGenerator.fallbackSlot, Slot.quote);
  });

  test('shorter set only after 7 inactive days', () {
    expect(FeedGenerator.isShorterSetAvailable(6), isFalse);
    expect(FeedGenerator.isShorterSetAvailable(7), isTrue);
    final notYet = generator.generate(
      inputs(shorterSet: true, inactiveDays: 3),
    );
    expect(notYet.set.n, 12);
    expect(notYet.shorterSetAvailable, isFalse);
    final shorter = generator.generate(
      inputs(shorterSet: true, inactiveDays: 9),
    );
    expect(shorter.set.n, FeedGenerator.shorterSetSize);
    expect(
      FeedGenerator.shorterLayout,
      hasLength(FeedGenerator.shorterSetSize),
    );
    expect(shorter.shorterSetAvailable, isTrue);
    expect(FeedGenerator.shorterLayout.first, Slot.intro);
  });

  test('phase from first open time', () {
    final evening = generator
        .generate(inputs(at: DateTime(2026, 10, 29, 19)))
        .set;
    expect(evening.phase, DayPhase.evening);
  });
}
