import 'package:meta/meta.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/day_phase.dart';

/// Faseta `time_of_day` (docs/03 3.2).
enum TimeOfDayFacet {
  morning('morning'),
  day('day'),
  evening('evening'),
  night('night'),
  any('any');

  TimeOfDayFacet(this.wire);

  final String wire;

  static TimeOfDayFacet fromPhase(DayPhase phase) => switch (phase) {
    DayPhase.morning => morning,
    DayPhase.day => day,
    DayPhase.evening => evening,
    DayPhase.night => night,
  };
}

/// Kandidat kuratorovaneho obsahu: hadis, dua, zamyslenie alebo meno Allaha.
///
/// Data layer (D-02) sem mapuje riadky `content.db` vratane `langs_ready`
/// (jazyky, v ktorych ma polozka vsetky texty, docs/03 7.3).
@immutable
final class FeedCandidate {
  FeedCandidate({
    required this.id,
    required Iterable<String> langs,
    List<String> tags = const [],
    Iterable<String> seasons = const [],
    this.weight = 1,
    this.timeOfDay = TimeOfDayFacet.any,
    this.grade,
    this.reviewed = true,
  }) : langs = Set.unmodifiable(langs),
       tags = List.unmodifiable(tags),
       seasons = Set.unmodifiable(seasons) {
    if (id is! HadithCardId &&
        id is! DuaCardId &&
        id is! ReflectionCardId &&
        id is! NameCardId) {
      throw ArgumentError.value(id, 'id', 'hadith, dua, reflection or name');
    }
    if (weight <= 0) throw ArgumentError.value(weight, 'weight', 'must be > 0');
  }

  final CardId id;

  /// `langs_ready`.
  final Set<String> langs;

  /// Temy, prva je hlavna (docs/03 3.1).
  final List<String> tags;

  /// Id eventov, pocas ktorych sa polozka smie pouzit (prazdne = vzdy).
  final Set<String> seasons;

  final double weight;
  final TimeOfDayFacet timeOfDay;

  /// Stupen hadisu (`sahih`, `hasan`, ...); len pre hadis.
  final String? grade;

  /// Zamyslenie ma `reviewed_by` (docs/02 B8).
  final bool reviewed;

  @override
  String toString() => 'FeedCandidate($id)';
}

/// Lema pre kartu slova a kviz.
@immutable
final class LemmaInfo {
  LemmaInfo({
    required this.lemmaId,
    required this.rank,
    required Iterable<String> langs,
    this.root,
  }) : langs = Set.unmodifiable(langs);

  final int lemmaId;

  /// Poradie podla frekvencie (1 = najcastejsia).
  final int rank;

  /// Koren (null = bez korena).
  final String? root;

  /// Jazyky, v ktorych ma lema vyznam (`lemma_meaning`).
  final Set<String> langs;
}

/// Pristup k lemam pre FeedGenerator (implementuje data layer).
abstract interface class LemmaIndex {
  /// Lemy slov versa [ayah] v poradi vyskytu.
  List<LemmaInfo> lemmasInAyah(AyahId ayah);

  /// Vsetky lemy podla `rank` vzostupne.
  List<LemmaInfo> get byRank;

  LemmaInfo? lemma(int lemmaId);
}

/// [LemmaIndex] nad pamatou (testy, male datasety).
final class InMemoryLemmaIndex implements LemmaIndex {
  InMemoryLemmaIndex(
    Iterable<LemmaInfo> lemmas, {
    Map<AyahId, List<int>> occurrences = const {},
  }) : _byId = {for (final l in lemmas) l.lemmaId: l},
       _occurrences = Map.unmodifiable(occurrences) {
    _byRank = _byId.values.toList()
      ..sort((a, b) {
        final r = a.rank.compareTo(b.rank);
        return r != 0 ? r : a.lemmaId.compareTo(b.lemmaId);
      });
  }

  final Map<int, LemmaInfo> _byId;
  final Map<AyahId, List<int>> _occurrences;
  late final List<LemmaInfo> _byRank;

  @override
  List<LemmaInfo> lemmasInAyah(AyahId ayah) => [
    for (final id in _occurrences[ayah] ?? const <int>[]) ?_byId[id],
  ];

  @override
  List<LemmaInfo> get byRank => _byRank;

  @override
  LemmaInfo? lemma(int lemmaId) => _byId[lemmaId];
}

/// Due SRS polozka pri generovani sady (`due <= koniec dna`, docs/02 B4).
@immutable
final class SrsDue {
  const SrsDue({
    required this.lemmaId,
    required this.due,
    this.reps = 0,
    this.seenInContext = false,
  });

  final int lemmaId;
  final LocalDate due;
  final int reps;

  /// Lema ma vyskyt vo verse, ktory pouzivatel videl (qtype `context`).
  final bool seenInContext;
}

/// Pouzivatelske nastavenia pre sadu.
@immutable
final class FeedPrefs {
  FeedPrefs({
    required this.lang,
    this.cardsCount = 12,
    this.shorterSet = false,
  }) {
    if (!allowedCardsCounts.contains(cardsCount)) {
      throw ArgumentError.value(cardsCount, 'cardsCount', 'must be 8/12/16');
    }
  }

  /// `feed.cards_count` (docs/02 0.7).
  static const allowedCardsCounts = {8, 12, 16};

  /// Jazyk obsahu (`ui.locale`): `en`, `ar`, `id`, `ur`, `bn`, `tr`.
  final String lang;
  final int cardsCount;

  /// Pouzivatel prijal "shorter set" (plati len ak je dostupna, docs/01 D6).
  final bool shorterSet;
}

/// Historia a kurzory z `user.db` a `settings`.
@immutable
final class FeedHistory {
  FeedHistory({
    Map<CardId, LocalDate> lastShown = const {},
    Set<CardId> disabledIds = const {},
    this.namesCursor = 1,
    Map<String, int> eventCursors = const {},
    this.completedKhatms = 0,
  }) : lastShown = Map.unmodifiable(lastShown),
       disabledIds = Set.unmodifiable(disabledIds),
       eventCursors = Map.unmodifiable(eventCursors) {
    RangeError.checkValueInInterval(namesCursor, 1, 99, 'namesCursor');
    RangeError.checkNotNegative(completedKhatms, 'completedKhatms');
  }

  /// Posledne zobrazenie karty (z `card_event`/`daily_set`) pre cooldowny.
  final Map<CardId, LocalDate> lastShown;

  /// `disabled_ids` z remote configu: nikdy sa nevyberu.
  final Set<CardId> disabledIds;

  /// `names.cursor` = nasledujuce meno (1..99).
  final int namesCursor;

  /// `event_cursor.{id}` -> posledny zobrazeny ayah_id eventu.
  final Map<String, int> eventCursors;

  /// Pocet riadkov `khatm_log`.
  final int completedKhatms;
}

/// Pooly kandidatov z `content.db` a SRS stav z `user.db`.
@immutable
final class FeedPools {
  FeedPools({
    List<FeedCandidate> hadiths = const [],
    List<FeedCandidate> duas = const [],
    List<FeedCandidate> reflections = const [],
    List<FeedCandidate> names = const [],
    Map<String, Set<String>> eventTextLangs = const {},
    this.lemmas,
    List<SrsDue> dueSrs = const [],
    Set<int> srsLemmaIds = const {},
  }) : hadiths = List.unmodifiable(hadiths),
       duas = List.unmodifiable(duas),
       reflections = List.unmodifiable(reflections),
       names = List.unmodifiable(names),
       eventTextLangs = Map.unmodifiable(eventTextLangs),
       dueSrs = List.unmodifiable(dueSrs),
       srsLemmaIds = Set.unmodifiable(srsLemmaIds) {
    _checkType<HadithCardId>(this.hadiths, 'hadiths');
    _checkType<DuaCardId>(this.duas, 'duas');
    _checkType<ReflectionCardId>(this.reflections, 'reflections');
    _checkType<NameCardId>(this.names, 'names');
  }

  final List<FeedCandidate> hadiths;
  final List<FeedCandidate> duas;
  final List<FeedCandidate> reflections;
  final List<FeedCandidate> names;

  /// `islamic_event_text`: event id -> jazyky s textom.
  final Map<String, Set<String>> eventTextLangs;

  /// null = slovicka nie su k dispozicii (ziadne karty word/quiz).
  final LemmaIndex? lemmas;
  final List<SrsDue> dueSrs;

  /// Vsetky lemy v `srs_item`.
  final Set<int> srsLemmaIds;

  static void _checkType<T extends CardId>(
    List<FeedCandidate> pool,
    String name,
  ) {
    for (final c in pool) {
      if (c.id is! T) throw ArgumentError.value(c.id, name, 'expected $T');
    }
  }
}

/// Kompletny vstup FeedGeneratora (plan 7.1, docs/02 D13).
@immutable
final class FeedInputs {
  FeedInputs({
    required this.date,
    required this.seed,
    required this.generatedAtLocalTime,
    required this.prefs,
    required this.pools,
    FeedHistory? history,
    this.dayBoundaries,
    this.readingPosition,
    List<ActiveEvent> activeEvents = const [],
    this.wordsEnabled = true,
    this.inactiveDays = 0,
    this.contentVersion,
    this.tz,
  }) : history = history ?? FeedHistory(),
       activeEvents = List.unmodifiable(activeEvents) {
    RangeError.checkNotNegative(inactiveDays, 'inactiveDays');
  }

  /// `activeSetDate` (docs/02 0.1).
  final LocalDate date;

  /// `feedSeed(date, installId)`.
  final int seed;

  /// Cas prveho otvorenia dna (urci [DayPhase]).
  final DateTime generatedAtLocalTime;

  /// Casy modlitieb dna; null = pevne hodiny.
  final DayBoundaries? dayBoundaries;

  /// Posledny precitany vers (`reading_position`); null = pred 1:1.
  final AyahId? readingPosition;

  /// Uz vyhodnotene eventy dna (E-01).
  final List<ActiveEvent> activeEvents;

  final FeedPrefs prefs;

  /// `FEATURE_WORDS` a nastavenie `words_enabled`.
  final bool wordsEnabled;

  /// Pocet dni bez otvorenia appky pred [date].
  final int inactiveDays;

  final FeedPools pools;
  final FeedHistory history;
  final String? contentVersion;
  final String? tz;
}
