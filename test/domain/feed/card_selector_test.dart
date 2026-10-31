import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/feed/feed.dart';

void main() {
  final today = LocalDate(2026, 10, 29);

  FeedCandidate h(
    int id, {
    Set<String> langs = const {'en'},
    Set<String> seasons = const {},
    List<String> tags = const [],
    TimeOfDayFacet tod = TimeOfDayFacet.any,
  }) => FeedCandidate(
    id: HadithCardId(id),
    langs: langs,
    seasons: seasons,
    tags: tags,
    timeOfDay: tod,
    grade: 'sahih',
  );

  ActiveEvent event(String id, int priority) =>
      ActiveEvent(id: id, priority: priority, effect: EventEffect.empty);

  CardSelector selector({
    Map<CardId, LocalDate> lastShown = const {},
    Set<CardId> disabled = const {},
    List<ActiveEvent> events = const [],
    int seed = 7,
  }) => CardSelector(
    date: today,
    seed: seed,
    lang: 'en',
    activeEvents: events,
    lastShown: lastShown,
    disabled: disabled,
  );

  test('hard filters: language, disabled, excluded, season', () {
    final s = selector(disabled: {HadithCardId(2)});
    final pool = [
      h(1, langs: {'tr'}),
      h(2),
      h(3),
      h(4, seasons: {'ramadan'}),
      h(5),
    ];
    final exclude = {HadithCardId(5)};
    expect(s.eligible(pool, exclude: exclude).map((c) => c.id), [
      HadithCardId(3),
    ]);
    expect(s.pick(pool, salt: 1, exclude: exclude)!.id, HadithCardId(3));
    expect(
      s.pick([
        h(1, langs: {'tr'}),
      ], salt: 1),
      isNull,
    );
  });

  test('event season overrides general pool, by priority', () {
    final s = selector(events: [event('jumuah', 50), event('ramadan', 100)]);
    final pool = [
      h(1),
      h(2, seasons: {'jumuah'}),
      h(3, seasons: {'ramadan'}),
    ];
    expect(s.hasOverride(pool), isTrue);
    for (var salt = 0; salt < 20; salt++) {
      expect(s.pick(pool, salt: salt)!.id, HadithCardId(3));
    }
    expect(selector().hasOverride(pool), isFalse);
  });

  test('cooldown 365 days, jumuah pool 35, then least recently used', () {
    final s = selector(
      events: [event('jumuah', 50)],
      lastShown: {
        HadithCardId(1): today.addDays(-100),
        HadithCardId(2): today.addDays(-300),
        HadithCardId(3): today.addDays(-36),
      },
    );
    expect(
      s.pick([
        h(1),
        h(2),
        h(3, seasons: {'jumuah'}),
      ], salt: 1)!.id,
      HadithCardId(3),
    );
    // Vsetko v cooldowne -> najdavnejsie pouzita.
    expect(s.pick([h(1), h(2)], salt: 1)!.id, HadithCardId(2));
    expect(s.pick([h(2), h(1)], salt: 1)!.id, HadithCardId(2));
    expect(FeedCooldowns.of(h(1)), 365);
    expect(FeedCooldowns.of(h(1, seasons: {'jumuah'})), 35);
  });

  test('deterministic for same seed and salt', () {
    final pool = [for (var i = 1; i <= 30; i++) h(i)];
    expect(
      selector(seed: 42).pick(pool, salt: 9)!.id,
      selector(seed: 42).pick(pool.reversed, salt: 9)!.id,
    );
    final picks = {
      for (var seed = 0; seed < 50; seed++)
        selector(seed: seed).pick(pool, salt: 9)!.id,
    };
    expect(picks.length, greaterThan(5));
  });

  int hits(
    List<FeedCandidate> pool,
    CardId target, {
    String? theme,
    TimeOfDayFacet? tod,
    Map<CardId, LocalDate> lastShown = const {},
  }) {
    var n = 0;
    for (var seed = 0; seed < 400; seed++) {
      final c = selector(
        seed: seed,
        lastShown: lastShown,
      ).pick(pool, salt: 1, themeTag: theme, timeOfDay: tod);
      if (c!.id == target) n++;
    }
    return n;
  }

  test('weights: theme x3, time of day x2, lru', () {
    expect(
      hits(
        [
          h(1),
          h(2, tags: ['sabr']),
        ],
        HadithCardId(2),
        theme: 'sabr',
      ),
      greaterThan(250),
    );
    expect(
      hits(
        [h(1), h(2, tod: TimeOfDayFacet.morning)],
        HadithCardId(2),
        tod: TimeOfDayFacet.morning,
      ),
      greaterThan(220),
    );
    expect(
      hits(
        [h(1), h(2)],
        HadithCardId(2),
        lastShown: {HadithCardId(1): today.addDays(-366)},
      ),
      greaterThan(200),
    );
  });

  test('sortEvents by priority then id', () {
    final sorted = CardSelector.sortEvents([
      event('b', 10),
      event('a', 10),
      event('c', 50),
    ]);
    expect(sorted.map((e) => e.id), ['c', 'a', 'b']);
  });

  test('feedSeed is stable and depends on date and install id', () {
    final s = feedSeed(today, 'abc');
    expect(feedSeed(LocalDate(2026, 10, 29), 'abc'), s);
    expect(feedSeed(today.addDays(1), 'abc'), isNot(s));
    expect(feedSeed(today, 'abd'), isNot(s));
    expect(s, inInclusiveRange(0, 0x7fffffff));
    expect(mixSeed(1, 2), mixSeed(1, 2));
    expect(mixSeed(1, 2), isNot(mixSeed(1, 3)));
  });
}
