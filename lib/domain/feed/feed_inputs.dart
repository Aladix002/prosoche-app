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

  static TimeOfDayFacet fromWire(String? wire) =>
      values.firstWhere((t) => t.wire == wire, orElse: () => any);

  static TimeOfDayFacet fromPhase(DayPhase phase) => switch (phase) {
    DayPhase.morning => morning,
    DayPhase.day => day,
    DayPhase.evening => evening,
    DayPhase.night => night,
  };
}

/// Kandidat obsahu pre jeden slot sady (citat, uryvok, cvicenie, ...).
///
/// Data layer sem mapuje riadky content.db (`ContentCatalog.feedPools`).
@immutable
final class FeedCandidate {
  FeedCandidate({
    required this.id,
    List<String> tags = const [],
    this.weight = 1,
    this.timeOfDay = TimeOfDayFacet.any,
  }) : tags = List.unmodifiable(tags) {
    if (weight <= 0) throw ArgumentError.value(weight, 'weight', 'must be > 0');
  }

  final ContentCardId id;

  /// Temy, prva je hlavna (docs/03 3.1).
  final List<String> tags;

  final double weight;
  final TimeOfDayFacet timeOfDay;

  CardType get type => id.type;

  @override
  String toString() => 'FeedCandidate($id)';
}

/// Pouzivatelske nastavenia pre sadu.
@immutable
final class FeedPrefs {
  FeedPrefs({this.cardsCount = 12, this.shorterSet = false}) {
    if (!allowedCardsCounts.contains(cardsCount)) {
      throw ArgumentError.value(cardsCount, 'cardsCount', 'must be 8/12/16');
    }
  }

  /// `feed.cards_count` (docs/02 0.7).
  static const allowedCardsCounts = {8, 12, 16};

  final int cardsCount;

  /// Pouzivatel prijal "shorter set" (plati len ak je dostupna, docs/01 D6).
  final bool shorterSet;
}

/// Historia z `user.db` a `disabled_ids` z manifestu obsahu.
@immutable
final class FeedHistory {
  FeedHistory({
    Map<CardId, LocalDate> lastShown = const {},
    Set<CardId> disabledIds = const {},
  }) : lastShown = Map.unmodifiable(lastShown),
       disabledIds = Set.unmodifiable(disabledIds);

  /// Posledne zobrazenie karty (z `daily_set`) pre cooldowny.
  final Map<CardId, LocalDate> lastShown;

  /// `disabled_ids` z remote configu: nikdy sa nevyberu.
  final Set<CardId> disabledIds;
}

/// Pooly kandidatov z content.db podla typu karty.
@immutable
final class FeedPools {
  FeedPools([Map<CardType, List<FeedCandidate>> byType = const {}])
    : byType = Map.unmodifiable({
        for (final MapEntry(:key, :value) in byType.entries)
          key: List<FeedCandidate>.unmodifiable(value),
      }) {
    for (final MapEntry(:key, :value) in this.byType.entries) {
      for (final c in value) {
        if (c.type != key) {
          throw ArgumentError.value(c.id, 'byType', 'expected ${key.wire}');
        }
      }
    }
  }

  /// Len citaty (S-01).
  factory FeedPools.quotes(List<FeedCandidate> quotes) =>
      FeedPools({CardType.quote: quotes});

  final Map<CardType, List<FeedCandidate>> byType;

  List<FeedCandidate> of(CardType type) => byType[type] ?? const [];

  bool get isEmpty => byType.values.every((l) => l.isEmpty);
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
    this.inactiveDays = 0,
    this.contentVersion,
    this.tz,
  }) : history = history ?? FeedHistory() {
    RangeError.checkNotNegative(inactiveDays, 'inactiveDays');
  }

  /// `activeSetDate` (docs/02 0.1).
  final LocalDate date;

  /// `feedSeed(date, installId)`.
  final int seed;

  /// Cas prveho otvorenia dna (urci [DayPhase]).
  final DateTime generatedAtLocalTime;

  /// Hranice faz dna; null = [DayBoundaries.fallback].
  final DayBoundaries? dayBoundaries;

  final FeedPrefs prefs;

  /// Pocet dni bez otvorenia appky pred [date].
  final int inactiveDays;

  final FeedPools pools;
  final FeedHistory history;
  final String? contentVersion;
  final String? tz;
}
