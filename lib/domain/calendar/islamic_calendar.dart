import 'package:hijri/hijri_array.dart' show ummAlquraDateArray;
import 'package:meta/meta.dart';
import 'package:sakina/domain/calendar/hijri_date.dart';
import 'package:sakina/domain/common/local_date.dart';

/// Hijri kalendar Umm al-Qura s pouzivatelskym posunom (plan 7.5).
///
/// `hijriOf(d) = UmmAlQura(d - offset dni)`. Posun meni mapovanie na
/// gregoriansky kalendar, nie dlzku mesiacov (tie su vzdy podla Umm al-Qura).
/// Pri `offset = +1` su hijri udalosti o den NESKOR (komunita zacala mesiac
/// o den neskor nez Umm al-Qura), docs/02 A9: "Given offset +1, Then
/// 1. Ramadan 1448 sa zobrazi o den neskor nez pri offsete 0".
/// Vzorec `hijri = UmmAlQura(gregorian) + userOffset` z plan 7.5 a
/// docs/03 4.4 sa vyklada prave takto (rozhodnutie hlavneho agenta).
/// Rucne pozorovanie mesiaca: +1 = "zacali sme o den neskor".
///
/// Data: tabulka zaciatkov mesiacov z balicka `hijri` 3.0.1
/// (`ummAlquraDateArray`, MCJDN, 1356-1500 AH). Prevodna logika je vlastna
/// (binarne vyhladavanie), balik sa pouziva len ako zdroj dat.
@immutable
final class IslamicCalendar {
  IslamicCalendar({this.offset = 0}) {
    RangeError.checkValueInInterval(offset, minOffset, maxOffset, 'offset');
  }

  static const minOffset = -2;
  static const maxOffset = 2;

  /// Prvy a posledny podporovany hijri rok (rozsah tabulky Umm al-Qura).
  static const firstYear = 1356;
  static const lastYear = 1500;

  /// Posun v dnoch (`settings.hijri.offset`), -2..+2.
  final int offset;

  IslamicCalendar withOffset(int offset) => IslamicCalendar(offset: offset);

  /// Hijri datum gregorianskeho dna [date] vratane posunu.
  ///
  /// Mimo rozsahu tabulky ([firstYear]..[lastYear]) hodi [RangeError].
  HijriDate hijriOf(LocalDate date) {
    final mcjdn = _mcjdn(date) - offset;
    // Posledny index k, pre ktory start[k] <= mcjdn.
    var lo = 0;
    var hi = _starts.length - 1;
    if (mcjdn < _starts[lo] || mcjdn >= _starts[hi]) {
      throw RangeError(
        'Date $date (offset $offset) is outside Umm al-Qura '
        'table $firstYear-$lastYear AH',
      );
    }
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (_starts[mid] <= mcjdn) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final (year, month) = _yearMonth(lo);
    return HijriDate(year, month, mcjdn - _starts[lo] + 1);
  }

  /// Gregoriansky den, na ktory pripada [date] pri tomto posune.
  ///
  /// Hodi [RangeError], ak den v mesiaci neexistuje (30. v 29-dnovom
  /// mesiaci) alebo je rok mimo tabulky.
  LocalDate gregorianOf(HijriDate date) {
    final k = _index(date.year, date.month);
    final length = _starts[k + 1] - _starts[k];
    RangeError.checkValueInInterval(date.day, 1, length, 'day');
    return _epoch.addDays(_starts[k] + date.day - 1 + offset - _epochMcjdn);
  }

  /// Pocet dni hijri mesiaca (29 alebo 30) podla Umm al-Qura.
  int monthLength(int year, int month) {
    final k = _index(year, month);
    return _starts[k + 1] - _starts[k];
  }

  /// Vsetky gregorianske dni hijri mesiaca v poradi (pre obrazovku kalendara).
  List<LocalDate> daysOfMonth(int year, int month) {
    final first = gregorianOf(HijriDate(year, month, 1));
    return [
      for (var i = 0; i < monthLength(year, month); i++) first.addDays(i),
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is IslamicCalendar && other.offset == offset;

  @override
  int get hashCode => offset.hashCode;

  @override
  String toString() => 'IslamicCalendar(offset: $offset)';

  static const List<int> _starts = ummAlquraDateArray;

  /// Index mesiaca v tabulke; tabulka zacina 1. Muharram 1356.
  static int _index(int year, int month) {
    RangeError.checkValueInInterval(year, firstYear, lastYear, 'year');
    RangeError.checkValueInInterval(month, 1, 12, 'month');
    return (year - firstYear) * 12 + month - 1;
  }

  static (int, int) _yearMonth(int index) =>
      (firstYear + index ~/ 12, index % 12 + 1);

  static final _epoch = LocalDate(1970, 1, 1);

  /// Modified Chronological Julian Day Number 1. 1. 1970 (CJDN 2440588).
  static const _epochMcjdn = 40588;

  static int _mcjdn(LocalDate date) => date.daysSince(_epoch) + _epochMcjdn;
}
