import 'package:meta/meta.dart';

/// Hijri datum (rok, mesiac 1..12, den 1..30) bez vazby na gregoriansky den.
///
/// Prevod z/na `LocalDate` robi `IslamicCalendar` (Umm al-Qura + offset).
/// Textovy tvar je `YYYY-MM-DD` v hijri cislach, napr. `1448-09-01`.
@immutable
final class HijriDate implements Comparable<HijriDate> {
  factory HijriDate(int year, int month, int day) {
    RangeError.checkValueInInterval(year, 1, 9999, 'year');
    RangeError.checkValueInInterval(month, 1, 12, 'month');
    RangeError.checkValueInInterval(day, 1, 30, 'day');
    return HijriDate._(year, month, day);
  }

  const HijriDate._(this.year, this.month, this.day);

  final int year;

  /// 1 = Muharram ... 9 = Ramadan ... 12 = Dhul Hijja.
  final int month;

  final int day;

  @override
  int compareTo(HijriDate other) =>
      (year - other.year) * 10000 +
      (month - other.month) * 100 +
      (day - other.day);

  @override
  bool operator ==(Object other) =>
      other is HijriDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
