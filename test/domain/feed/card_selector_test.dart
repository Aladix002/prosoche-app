import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/feed.dart';

void main() {
  final today = LocalDate(2026, 10, 29);

  ContentCardId id(int n) => ContentCardId.quote('q_$n');

  FeedCandidate q(
    int n, {
    List<String> tags = const [],
    TimeOfDayFacet tod = TimeOfDayFacet.any,
  }) => FeedCandidate(id: id(n), tags: tags, timeOfDay: tod);

  CardSelector selector({
    Map<CardId, LocalDate> lastShown = const {},
    Set<CardId> disabled = const {},
    int seed = 7,
  }) => CardSelector(
    date: today,
    seed: seed,
    lastShown: lastShown,
    disabled: disabled,
  );

  test('hard filters: disabled and excluded', () {
    final s = selector(disabled: {id(2)});
    final pool = [q(2), q(3), q(5)];
    final exclude = {id(5)};
    expect(s.eligible(pool, exclude: exclude).map((c) => c.id), [id(3)]);
    expect(s.pick(pool, salt: 1, exclude: exclude)!.id, id(3));
    expect(s.pick([q(2)], salt: 1), isNull);
  });

  test('cooldown 365 days, then least recently used', () {
    final s = selector(
      lastShown: {
        id(1): today.addDays(-100),
        id(2): today.addDays(-300),
        id(3): today.addDays(-366),
      },
    );
    expect(s.pick([q(1), q(2), q(3)], salt: 1)!.id, id(3));
    // Vsetko v cooldowne -> najdavnejsie pouzita.
    expect(s.pick([q(1), q(2)], salt: 1)!.id, id(2));
    expect(s.pick([q(2), q(1)], salt: 1)!.id, id(2));
    expect(FeedCooldowns.general, 365);
  });

  test('deterministic for same seed and salt', () {
    final pool = [for (var i = 1; i <= 30; i++) q(i)];
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
          q(1),
          q(2, tags: ['calm']),
        ],
        id(2),
        theme: 'calm',
      ),
      greaterThan(250),
    );
    expect(
      hits(
        [q(1), q(2, tod: TimeOfDayFacet.morning)],
        id(2),
        tod: TimeOfDayFacet.morning,
      ),
      greaterThan(220),
    );
    expect(
      hits([q(1), q(2)], id(2), lastShown: {id(1): today.addDays(-366)}),
      greaterThan(200),
    );
  });

  test('candidate validates weight', () {
    expect(() => FeedCandidate(id: id(1), weight: 0), throwsArgumentError);
    expect(q(1).type, CardType.quote);
    expect(q(1).toString(), contains('quote:q_1'));
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
