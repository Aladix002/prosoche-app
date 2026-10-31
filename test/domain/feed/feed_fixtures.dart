import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/feed.dart';

/// Testovacie fixtures FeedGeneratora. Ziadny obsah, len ID a metadata
/// (PLAN_VYVOJA 5.5): tagy, jazyky a eventy su vymyslene placeholdery.

const allLangs = ['en', 'ar', 'id', 'ur', 'bn', 'tr'];

final friday = LocalDate(2026, 10, 30);
final thursday = LocalDate(2026, 10, 29);

/// Hadisy 1..40: vsetky en/ar, id parne, tr kazdy treti, bn kazdy piaty,
/// ur ziadny. 39 a 40 maju nepovoleny stupen.
final List<FeedCandidate> hadiths = [
  for (var i = 1; i <= 40; i++)
    FeedCandidate(
      id: HadithCardId(i),
      langs: {
        'en',
        'ar',
        if (i.isEven) 'id',
        if (i % 3 == 0) 'tr',
        if (i % 5 == 0) 'bn',
      },
      tags: ['tag_${i % 4}'],
      grade: i >= 39 ? 'daif' : (i.isEven ? 'sahih' : 'hasan'),
    ),
];

/// Hadisy pre testovaci event `ramadan_fixture`.
final List<FeedCandidate> ramadanHadiths = [
  for (var i = 101; i <= 105; i++)
    FeedCandidate(
      id: HadithCardId(i),
      langs: allLangs,
      seasons: const {'ramadan_fixture'},
      grade: 'sahih',
    ),
];

/// Dua 1..21: 1-7 rano, 8-14 vecer, 15-21 kedykolvek; en/ar/tr.
final List<FeedCandidate> duas = [
  for (var i = 1; i <= 21; i++)
    FeedCandidate(
      id: DuaCardId(i),
      langs: const {'en', 'ar', 'tr'},
      timeOfDay: i <= 7
          ? TimeOfDayFacet.morning
          : i <= 14
          ? TimeOfDayFacet.evening
          : TimeOfDayFacet.any,
    ),
];

/// Zamyslenia 1..20: en a id; 20 nema review.
final List<FeedCandidate> reflections = [
  for (var i = 1; i <= 20; i++)
    FeedCandidate(
      id: ReflectionCardId(i),
      langs: const {'en', 'id', 'tr'},
      tags: ['tag_${i % 4}'],
      reviewed: i != 20,
    ),
];

/// Mena 1..99: en, ar, ur; id len neparne.
final List<FeedCandidate> names = [
  for (var i = 1; i <= 99; i++)
    FeedCandidate(
      id: NameCardId(i),
      langs: {'en', 'ar', 'ur', if (i.isOdd) 'id'},
    ),
];

/// Lemy 1..200 (rank = id), vyznam v en/ar/id/tr, 30 korenov.
final lemmaIndex = InMemoryLemmaIndex(
  [
    for (var i = 1; i <= 200; i++)
      LemmaInfo(
        lemmaId: i,
        rank: i,
        root: 'r${i % 30}',
        langs: const {'en', 'ar', 'id', 'tr'},
      ),
  ],
  occurrences: {
    for (var s = 1; s <= 114; s++)
      for (var a = 1; a <= AyahId.ayahCount(s); a++)
        AyahId(s, a): [(s * 7 + a) % 150 + 20, (s + a * 3) % 150 + 20],
  },
);

const eventTextLangs = {
  'jumuah_fixture': {'en', 'ar', 'id'},
  'ramadan_fixture': {'en', 'ar', 'id', 'ur', 'tr'},
};

/// Testovacie pravidla v tvare docs/02 D2 (nie produkcne eventy).
final jumuah = ActiveEvent(
  id: 'jumuah_fixture',
  priority: 50,
  effect: EventEffect(
    eventCardSlot: 2,
    ayahSlots: const [3, 4],
    surah: 18,
    cursor: 'event_cursor.jumuah_fixture',
  ),
);

final ramadan = ActiveEvent(
  id: 'ramadan_fixture',
  priority: 100,
  mode: 'ramadan',
  effect: EventEffect(eventCardSlot: 2),
);

FeedPools pools({
  List<SrsDue> due = const [],
  Set<int> srs = const {},
  LemmaIndex? lemmas,
  bool withLemmas = true,
}) => FeedPools(
  hadiths: [...hadiths, ...ramadanHadiths],
  duas: duas,
  reflections: reflections,
  names: names,
  eventTextLangs: eventTextLangs,
  lemmas: withLemmas ? (lemmas ?? lemmaIndex) : null,
  dueSrs: due,
  srsLemmaIds: srs,
);

FeedInputs inputs({
  LocalDate? date,
  int seed = 1,
  String lang = 'en',
  int hour = 13,
  int cardsCount = 12,
  bool shorterSet = false,
  int inactiveDays = 0,
  bool wordsEnabled = true,
  AyahId? readingPosition,
  List<ActiveEvent> events = const [],
  FeedPools? pools_,
  FeedHistory? history,
}) {
  final d = date ?? thursday;
  return FeedInputs(
    date: d,
    seed: seed,
    generatedAtLocalTime: DateTime(d.year, d.month, d.day, hour),
    prefs: FeedPrefs(
      lang: lang,
      cardsCount: cardsCount,
      shorterSet: shorterSet,
    ),
    pools: pools_ ?? pools(),
    history: history,
    readingPosition: readingPosition ?? AyahId(2, 250),
    activeEvents: events,
    wordsEnabled: wordsEnabled,
    inactiveDays: inactiveDays,
    contentVersion: '2026.11.1',
    tz: 'Europe/Bratislava',
  );
}

/// Ci ma karta text v jazyku [lang] podla fixtures.
bool hasText(DailySetCard card, String lang) {
  Set<String> langsOf(List<FeedCandidate> pool) =>
      pool.firstWhere((c) => c.id == card.cardId).langs;
  return switch (card.cardId) {
    IntroCardId() =>
      card.eventId == null || eventTextLangs[card.eventId]!.contains(lang),
    AyahCardId() || KhatmCardId() => true,
    EventCardId(:final eventId) => eventTextLangs[eventId]!.contains(lang),
    HadithCardId() => langsOf([...hadiths, ...ramadanHadiths]).contains(lang),
    DuaCardId() => langsOf(duas).contains(lang),
    ReflectionCardId() => langsOf(reflections).contains(lang),
    NameCardId() => langsOf(names).contains(lang),
    WordCardId(:final lemmaId) || QuizCardId(:final lemmaId) =>
      lemmaIndex.lemma(lemmaId)!.langs.contains(lang),
    DoneCardId() => false,
  };
}
