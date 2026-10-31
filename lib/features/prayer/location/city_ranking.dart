import 'dart:math' as math;

import 'package:prosoche/data/repositories/repositories.dart';

/// Kolko kandidatov sa nacita z content.db pred zoradenim (prefixova
/// zhoda, najvacsie mesta prve).
const cityCandidateLimit = 120;

/// Max. pocet vysledkov vyhladavania (A7.3).
const cityResultLimit = 30;

/// Poradie vysledkov vyhladavania mesta (A7.3, rozhodnutie hlavneho
/// agenta: zhoda nazvu ma prednost pred populaciou).
///
/// [candidates] su prefixove zhody v `name`/`ascii_name` zoradene podla
/// populacie (`CityRepository.search`). Poradie:
/// 1. presna zhoda nazvu (bez ohladu na velkost pismen a diakritiku),
/// 2. skore = popularita (poradie podla populacie, logaritmicky) + blizkost
///    k referencnej zone [referenceZone] (ulozena poloha, inak zona
///    zariadenia) podla aktualneho posunu od UTC.
///
/// Blizkost vyvazi mesta podobnej velkosti: z Bratislavy "Sara" da
/// Sarajevo (UTC+1) pred Saratov (UTC+4), "Lon" stale London pred malym
/// mestom v strednej Europe. Stabilne: pri rovnosti rozhoduje poradie
/// z databazy.
List<City> rankCities(
  String query,
  List<City> candidates, {
  String? referenceZone,
  DateTime? now,
  int limit = cityResultLimit,
}) {
  final q = foldCityName(query.trim());
  final at = (now ?? DateTime.utc(2026)).millisecondsSinceEpoch;
  final ref = referenceZone == null ? null : _offsetHours(referenceZone, at);
  final scored =
      [
        for (final (i, c) in candidates.indexed)
          (
            city: c,
            index: i,
            exact: foldCityName(c.name) == q,
            score: _score(i, ref == null ? null : _offsetHours(c.tz, at), ref),
          ),
      ]..sort((a, b) {
        if (a.exact != b.exact) return a.exact ? -1 : 1;
        final byScore = b.score.compareTo(a.score);
        return byScore != 0 ? byScore : a.index.compareTo(b.index);
      });
  return [for (final s in scored.take(limit)) s.city];
}

double _score(int rank, double? offset, double? reference) {
  final popularity = -math.log(rank + 1) / math.ln2;
  if (offset == null || reference == null) return popularity;
  final delta = (offset - reference).abs();
  // Rovnaky posun +1,5, o hodinu vedla +0,75, dalej nic.
  final proximity = delta < 0.01
      ? 1.5
      : delta <= 1
      ? 0.75
      : 0.0;
  return popularity + proximity;
}

double? _offsetHours(String zone, int at) {
  final l = tryTimeZone(zone);
  return l == null
      ? null
      : l.timeZone(at).offset.inMilliseconds / Duration.millisecondsPerHour;
}

/// Male pismena bez diakritiky (latinka), na porovnanie nazvov miest.
String foldCityName(String s) {
  final out = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    final ch = String.fromCharCode(r);
    out.write(_fold[ch] ?? ch);
  }
  return out.toString();
}

final Map<String, String> _fold = () {
  const groups = {
    'a': 'àáâãäåāăą',
    'c': 'çćĉċč',
    'd': 'ďđ',
    'e': 'èéêëēĕėęě',
    'g': 'ĝğġģ',
    'h': 'ĥħ',
    'i': 'ìíîïĩīĭįı',
    'j': 'ĵ',
    'k': 'ķ',
    'l': 'ĺļľŀł',
    'n': 'ñńņňŉ',
    'o': 'òóôõöøōŏő',
    'r': 'ŕŗř',
    's': 'śŝşšș',
    't': 'ţťŧț',
    'u': 'ùúûüũūŭůűų',
    'w': 'ŵ',
    'y': 'ýÿŷ',
    'z': 'źżž',
  };
  return {
    for (final MapEntry(:key, :value) in groups.entries)
      for (final ch in value.split('')) ch: key,
  };
}();
