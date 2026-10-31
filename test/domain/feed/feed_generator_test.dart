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

  test('layout: intro and quotes for 8/12/16', () {
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
