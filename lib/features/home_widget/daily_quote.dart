import 'dart:math';

import 'package:prosoche/domain/common/common.dart';

// W-01: vyber citatu dna pre widget na ploche. Cisty Dart, bez Fluttera.
//
// Citat dna zavisi len od datumu a poolu kratkych citatov z content.db,
// takze je rovnaky pre vsetky widgety a stabilny pocas celeho dna (aj bez
// dennej sady, ktoru vytvara az otvorenie appky).

/// Najdlhsi text citatu, ktory sa do widgetu vybera. Cely citat sa
/// zmesti aj do najmensej velkosti (2x2) bez skracovania, preto sa text
/// nikdy nekrati uprostred vety (content.db: 66 z 132 citatov).
const widgetQuoteMaxChars = 140;

/// Kandidat poolu: id karty a jej text.
typedef WidgetQuoteCandidate = ({String id, String text});

/// Pool citatov pre widget: karty typu `quote` s textom do
/// [widgetQuoteMaxChars] znakov, bez [disabled], zoradene podla id (poradie
/// nezavisi od poradia riadkov v db).
List<String> widgetQuotePool(
  Iterable<WidgetQuoteCandidate> quotes, {
  Set<String> disabled = const {},
}) {
  final ids = [
    for (final q in quotes)
      if (q.id.startsWith('quote:') &&
          !disabled.contains(q.id) &&
          q.text.trim().isNotEmpty &&
          q.text.trim().length <= widgetQuoteMaxChars)
        q.id,
  ]..sort();
  return ids;
}

final _epoch = LocalDate(1970, 1, 1);

/// Index citatu dna v poole velkosti [poolSize].
///
/// Dni sa delia na cykly dlzky [poolSize]; v kazdom cykle je pool
/// premiesany so seedom cyklu, takze sa citat neopakuje skor, nez sa
/// vystriedaju vsetky. Deterministicke: rovnaky datum a pool = rovnaky
/// citat.
int dailyQuoteIndex(LocalDate date, int poolSize) {
  if (poolSize <= 0) throw RangeError.value(poolSize, 'poolSize');
  final day = date.daysSince(_epoch);
  final cycle = day ~/ poolSize;
  final order = List<int>.generate(poolSize, (i) => i)
    ..shuffle(Random(_seed('widget|$cycle')));
  return order[day % poolSize];
}

/// Id citatu dna z [pool] (null = prazdny pool).
String? dailyQuoteId(LocalDate date, List<String> pool) =>
    pool.isEmpty ? null : pool[dailyQuoteIndex(date, pool.length)];

/// FNV-1a 32 bit (rovnaky postup ako `feedSeed`).
int _seed(String s) {
  var h = 0x811c9dc5;
  for (final unit in s.codeUnits) {
    h ^= unit;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h & 0x7fffffff;
}
