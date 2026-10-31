import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/feed/feed.dart';

void main() {
  test('FeedCandidate validates type and weight', () {
    expect(
      () => FeedCandidate(id: AyahCardId(AyahId(1, 1)), langs: const {'en'}),
      throwsArgumentError,
    );
    expect(
      () => FeedCandidate(id: DuaCardId(1), langs: const {'en'}, weight: 0),
      throwsArgumentError,
    );
    expect(
      FeedCandidate(id: DuaCardId(1), langs: const {}).toString(),
      contains('dua:1'),
    );
  });

  test('FeedPools checks pool types', () {
    final dua = FeedCandidate(id: DuaCardId(1), langs: const {'en'});
    expect(() => FeedPools(hadiths: [dua]), throwsArgumentError);
    expect(() => FeedPools(names: [dua]), throwsArgumentError);
    expect(() => FeedPools(reflections: [dua]), throwsArgumentError);
    expect(FeedPools(duas: [dua]).duas, [dua]);
  });

  test('FeedPrefs and FeedHistory validate ranges', () {
    expect(() => FeedPrefs(lang: 'en', cardsCount: 10), throwsArgumentError);
    expect(FeedPrefs(lang: 'en').cardsCount, 12);
    expect(() => FeedHistory(namesCursor: 0), throwsRangeError);
    expect(() => FeedHistory(namesCursor: 100), throwsRangeError);
    expect(() => FeedHistory(completedKhatms: -1), throwsRangeError);
  });

  test('FeedInputs rejects negative inactiveDays', () {
    expect(
      () => FeedInputs(
        date: LocalDate(2026, 1, 1),
        seed: 1,
        generatedAtLocalTime: DateTime(2026),
        prefs: FeedPrefs(lang: 'en'),
        pools: FeedPools(),
        inactiveDays: -1,
      ),
      throwsRangeError,
    );
  });

  test('InMemoryLemmaIndex', () {
    final index = InMemoryLemmaIndex(
      [
        LemmaInfo(lemmaId: 2, rank: 5, langs: const {'en'}),
        LemmaInfo(lemmaId: 1, rank: 5, langs: const {'en'}),
        LemmaInfo(lemmaId: 3, rank: 1, langs: const {'en'}),
      ],
      occurrences: {
        AyahId(1, 1): [3, 99, 1],
      },
    );
    expect(index.byRank.map((l) => l.lemmaId), [3, 1, 2]);
    expect(index.lemmasInAyah(AyahId(1, 1)).map((l) => l.lemmaId), [3, 1]);
    expect(index.lemmasInAyah(AyahId(1, 2)), isEmpty);
    expect(index.lemma(2)!.rank, 5);
    expect(index.lemma(9), isNull);
  });
}
