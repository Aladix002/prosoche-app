import 'dart:math';

import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/feed/feed_inputs.dart';

/// Cooldowny opakovania obsahu v dnoch (docs/03 P7).
abstract final class FeedCooldowns {
  static const general = 365;
  static const jumuahPool = 35;
  static const jumuahEventId = 'jumuah';

  static int of(FeedCandidate c) =>
      c.seasons.contains(jumuahEventId) ? jumuahPool : general;
}

/// Deterministicky vyber jednej karty z poolu (docs/03 3.3).
///
/// 1. Tvrde filtre: `langs_ready` pre jazyk, `disabled_ids`, uz pouzite
///    karty, `season` musi sediet s aktivnym eventom alebo byt prazdny.
/// 2. Override eventu: polozky so `season` aktivneho eventu (podla priority)
///    maju prednost pred vseobecnym poolom.
/// 3. Vazeny nahodny vyber cez `Random(seed + salt)` z poloziek po cooldowne.
///    Vaha = `weight` x 3 (tema dna) x 2 (`time_of_day`) x LRU.
/// 4. Ked je vsetko v cooldowne, vyberie sa najdavnejsie pouzita polozka.
final class CardSelector {
  CardSelector({
    required this.date,
    required this.seed,
    required this.lang,
    required List<ActiveEvent> activeEvents,
    this.lastShown = const {},
    this.disabled = const {},
  }) : _eventOrder = sortEvents(activeEvents).map((e) => e.id).toList();

  final LocalDate date;
  final int seed;
  final String lang;
  final Map<CardId, LocalDate> lastShown;
  final Set<CardId> disabled;
  final List<String> _eventOrder;

  /// Eventy podla `priority` zostupne, pri zhode podla `id` (docs/03 4.4).
  static List<ActiveEvent> sortEvents(Iterable<ActiveEvent> events) =>
      events.toList()..sort((a, b) {
        final p = b.priority.compareTo(a.priority);
        return p != 0 ? p : a.id.compareTo(b.id);
      });

  /// Ci karta s textom v [langs] smie byt v sade.
  bool isReady(CardId id, Set<String> langs) =>
      langs.contains(lang) && !disabled.contains(id);

  /// Kandidati po tvrdych filtroch, zoradeni podla `card_id`.
  List<FeedCandidate> eligible(
    Iterable<FeedCandidate> pool, {
    Set<CardId> exclude = const {},
  }) =>
      pool
          .where(
            (c) =>
                isReady(c.id, c.langs) &&
                !exclude.contains(c.id) &&
                (c.seasons.isEmpty || c.seasons.any(_eventOrder.contains)),
          )
          .toList()
        ..sort((a, b) => a.id.format().compareTo(b.id.format()));

  /// Ci ma pool polozku pre aktivny event (override slotu).
  bool hasOverride(
    Iterable<FeedCandidate> pool, {
    Set<CardId> exclude = const {},
  }) => eligible(pool, exclude: exclude).any((c) => c.seasons.isNotEmpty);

  /// Vyberie kartu alebo null, ak po tvrdych filtroch nic neostalo.
  FeedCandidate? pick(
    Iterable<FeedCandidate> pool, {
    required int salt,
    Set<CardId> exclude = const {},
    String? themeTag,
    TimeOfDayFacet? timeOfDay,
  }) {
    final all = eligible(pool, exclude: exclude);
    if (all.isEmpty) return null;
    final tiers = [
      for (final event in _eventOrder)
        all.where((c) => c.seasons.contains(event)).toList(),
      all.where((c) => c.seasons.isEmpty).toList(),
    ];
    final rng = Random(mixSeed(seed, salt));
    for (final tier in tiers) {
      final fresh = tier.where(_cooledDown).toList();
      if (fresh.isEmpty) continue;
      return _weighted(fresh, rng, themeTag, timeOfDay);
    }
    return _leastRecent(all);
  }

  bool _cooledDown(FeedCandidate c) {
    final last = lastShown[c.id];
    return last == null || date.daysSince(last) >= FeedCooldowns.of(c);
  }

  FeedCandidate _weighted(
    List<FeedCandidate> pool,
    Random rng,
    String? themeTag,
    TimeOfDayFacet? timeOfDay,
  ) {
    final weights = [
      for (final c in pool)
        c.weight *
            (themeTag != null && c.tags.contains(themeTag) ? 3 : 1) *
            (timeOfDay != null && c.timeOfDay == timeOfDay ? 2 : 1) *
            _lru(c),
    ];
    final total = weights.fold<double>(0, (a, b) => a + b);
    var r = rng.nextDouble() * total;
    for (var i = 0; i < pool.length; i++) {
      r -= weights[i];
      if (r < 0) return pool[i];
    }
    return pool.last;
  }

  /// Nikdy nepouzite = 2, inak 1..2 podla dni od posledneho zobrazenia.
  double _lru(FeedCandidate c) {
    final last = lastShown[c.id];
    if (last == null) return 2;
    return 1 + min(max(date.daysSince(last), 0), 365) / 365;
  }

  FeedCandidate _leastRecent(List<FeedCandidate> pool) {
    var best = pool.first;
    for (final c in pool.skip(1)) {
      final a = lastShown[c.id];
      final b = lastShown[best.id];
      if (b != null && (a == null || a.isBefore(b))) best = c;
    }
    return best;
  }
}

/// Zmiesa seed sady a salt slotu do 31-bitoveho seedu pre `Random`.
int mixSeed(int seed, int salt) {
  var h = (seed ^ 0x5bd1e995) & 0xffffffff;
  h = (h * 0x01000193 + salt * 0x9e3779b1) & 0xffffffff;
  h ^= h >> 15;
  h = (h * 0x2c1b3c6d) & 0xffffffff;
  h ^= h >> 12;
  return h & 0x7fffffff;
}

/// Seed dennej sady `hash(datum + installId)` (plan 3.1), FNV-1a 32 bit.
///
/// Nezavisi od `String.hashCode`, takze je stabilny medzi behmi a platformami.
int feedSeed(LocalDate date, String installId) {
  var h = 0x811c9dc5;
  for (final unit in '$date|$installId'.codeUnits) {
    h ^= unit;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h & 0x7fffffff;
}
