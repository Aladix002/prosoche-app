import 'package:timezone/timezone.dart' as tz;

/// Stav casovej zony zariadenia oproti poslednej potvrdenej.
enum TimeZoneStatus {
  /// Este nic nebolo potvrdene; aktualna zona sa ulozi ako potvrdena.
  firstRun,

  /// Zona je rovnaka (alebo ma rovnake pravidla, napr. Bratislava a Praha).
  unchanged,

  /// Nova zona: modlitby sa pozastavia do potvrdenia polohy (docs/01 5.6).
  changed,
}

/// Zisti, ci sa zmenila casova zona zariadenia (plan 8.1, docs/01 D7).
///
/// Zony s inym nazvom, ale rovnakym posunom pocas celeho roka (vratane
/// letneho casu) sa beru ako rovnake, aby cesta Bratislava - Praha
/// nepozastavila modlitby. Nezname zony sa porovnavaju len podla nazvu.
TimeZoneStatus checkTimeZone({
  required String? confirmedZone,
  required String deviceZone,
  required DateTime now,
}) {
  if (confirmedZone == null) return TimeZoneStatus.firstRun;
  if (confirmedZone == deviceZone) return TimeZoneStatus.unchanged;
  final tz.Location a;
  final tz.Location b;
  try {
    a = tz.getLocation(confirmedZone);
    b = tz.getLocation(deviceZone);
  } on tz.LocationNotFoundException {
    return TimeZoneStatus.changed;
  }
  for (var week = 0; week <= 53; week++) {
    final t = now.add(Duration(days: 7 * week)).millisecondsSinceEpoch;
    if (a.timeZone(t).offset != b.timeZone(t).offset) {
      return TimeZoneStatus.changed;
    }
  }
  return TimeZoneStatus.unchanged;
}
