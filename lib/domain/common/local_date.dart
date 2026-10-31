import 'package:meta/meta.dart';

/// Kalendarny datum bez casu a casovej zony ("den sady", docs/02 0.1).
///
/// Vznika z lokalneho casu zariadenia vyhradne cez `Clock`. Aritmetika ide
/// cez UTC, takze nezavisi od DST.
/// Textovy tvar je ISO `YYYY-MM-DD` (pouziva sa v `card_id` a v DB).
@immutable
final class LocalDate implements Comparable<LocalDate> {
  factory LocalDate(int year, int month, int day) {
    if (!isValid(year, month, day)) {
      throw ArgumentError('Invalid date $year-$month-$day');
    }
    return LocalDate._(year, month, day);
  }

  const LocalDate._(this.year, this.month, this.day);

  /// Datum z lokalnych zloziek [dateTime] (cas sa zahodi).
  factory LocalDate.fromDateTime(DateTime dateTime) =>
      LocalDate._(dateTime.year, dateTime.month, dateTime.day);

  /// Parsuje presne `YYYY-MM-DD`. Pri chybe hodi [FormatException].
  factory LocalDate.parse(String text) {
    final m = _iso.firstMatch(text);
    if (m == null) throw FormatException('Expected YYYY-MM-DD', text);
    final (y, mo, d) = (int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    if (!isValid(y, mo, d)) {
      throw FormatException('Invalid calendar date', text);
    }
    return LocalDate._(y, mo, d);
  }

  /// Ci [year]-[month]-[day] je existujuci datum (napr. nie 2026-02-30).
  static bool isValid(int year, int month, int day) {
    final d = DateTime.utc(year, month, day);
    return d.year == year && d.month == month && d.day == day;
  }

  /// Ako [LocalDate.parse], ale pri chybe vrati null.
  static LocalDate? tryParse(String text) {
    try {
      return LocalDate.parse(text);
    } on FormatException {
      return null;
    }
  }

  static final _iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  /// 1 = pondelok ... 7 = nedela ([DateTime.monday] ... [DateTime.sunday]).
  int get weekday => _utc.weekday;

  LocalDate addDays(int days) =>
      LocalDate.fromDateTime(_utc.add(Duration(days: days)));

  /// Pocet dni od [other] po tento datum (zaporny, ak je [other] neskor).
  int daysSince(LocalDate other) => _utc.difference(other._utc).inDays;

  bool isBefore(LocalDate other) => compareTo(other) < 0;
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  /// Polnoc tohto dna v lokalnej zone zariadenia.
  DateTime toLocalDateTime() => DateTime(year, month, day);

  @override
  int compareTo(LocalDate other) =>
      (year - other.year) * 10000 +
      (month - other.month) * 100 +
      (day - other.day);

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// ISO tvar `YYYY-MM-DD`.
  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
