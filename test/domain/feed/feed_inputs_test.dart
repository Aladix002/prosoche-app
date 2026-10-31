import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/feed.dart';

void main() {
  test('FeedPools checks pool types', () {
    final quote = FeedCandidate(id: ContentCardId.quote('a'));
    expect(
      () => FeedPools({
        CardType.passage: [quote],
      }),
      throwsArgumentError,
    );
    final pools = FeedPools.quotes([quote]);
    expect(pools.of(CardType.quote), [quote]);
    expect(pools.of(CardType.practice), isEmpty);
    expect(pools.isEmpty, isFalse);
    expect(FeedPools().isEmpty, isTrue);
  });

  test('FeedPrefs validates cards count', () {
    expect(() => FeedPrefs(cardsCount: 10), throwsArgumentError);
    expect(FeedPrefs().cardsCount, 12);
  });

  test('FeedInputs rejects negative inactiveDays', () {
    expect(
      () => FeedInputs(
        date: LocalDate(2026, 1, 1),
        seed: 1,
        generatedAtLocalTime: DateTime(2026),
        prefs: FeedPrefs(),
        pools: FeedPools(),
        inactiveDays: -1,
      ),
      throwsRangeError,
    );
  });
}
