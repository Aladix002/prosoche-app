import 'dart:math';

import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/feed_inputs.dart';

/// Cooldown opakovania obsahu v dnoch (docs/03 P7).
abstract final class FeedCooldowns {
  static const general = 365;
}

/// Deterministicky vyber jednej karty z poolu (docs/03 3.3).
///
/// 1. Tvrde filtre: `disabled_ids` a uz pouzite karty.
/// 2. Vazeny nahodny vyber cez `Random(seed + salt)` z poloziek po cooldowne.
///    Vaha = `weight` x 3 (tema dna) x 2 (`time_of_day`) x LRU.
/// 3. Ked je vsetko v cooldowne, vyberie sa najdavnejsie pouzita polozka
///    (pri `freshOnly` nic).
final class CardSelector {
  CardSelector({
    required this.date,
    required this.seed,
    this.lastShown = const {},
    this.disabled = const {},
  });

  final LocalDate date;
  final int seed;
  final Map<CardId, LocalDate> lastShown;
  final Set<CardId> disabled;

  /// Kandidati po tvrdych filtroch, zoradeni podla `card_id`.
  List<FeedCandidate> eligible(
    Iterable<FeedCandidate> pool, {
    Set<CardId> exclude = const {},
  }) =>
      pool
          .where((c) => !disabled.contains(c.id) && !exclude.contains(c.id))
          .toList()
        ..sort((a, b) => a.id.format().compareTo(b.id.format()));

  /// Vyberie kartu alebo null, ak po tvrdych filtroch nic neostalo.
  FeedCandidate? pick(
    Iterable<FeedCandidate> pool, {
    required int salt,
    Set<CardId> exclude = const {},
    String? themeTag,
    TimeOfDayFacet? timeOfDay,
    bool freshOnly = false,
  }) {
    final all = eligible(pool, exclude: exclude);
    if (all.isEmpty) return null;
    final fresh = all.where(_cooledDown).toList();
    if (fresh.isEmpty) return freshOnly ? null : _leastRecent(all);
    final rng = Random(mixSeed(seed, salt));
    return _weighted(fresh, rng, themeTag, timeOfDay);
  }

  bool _cooledDown(FeedCandidate c) {
    final last = lastShown[c.id];
    return last == null || date.daysSince(last) >= FeedCooldowns.general;
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
