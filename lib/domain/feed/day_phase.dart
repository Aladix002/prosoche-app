import 'package:meta/meta.dart';

/// Cast dna pri prvom otvoreni dna (plan 7.1, docs/02 D13).
///
/// Ovplyvnuje vahu kariet s fasetou `time_of_day`. Uklada sa do
/// `cards_json`, takze sa sada pocas dna nemeni.
enum DayPhase {
  /// Od 05:00 do 12:00.
  morning('morning'),

  /// Od 12:00 do 17:00.
  day('day'),

  /// Od 17:00 do 21:00.
  evening('evening'),

  /// Od 21:00 do 05:00.
  night('night');

  DayPhase(this.wire);

  final String wire;

  static DayPhase? fromWire(String wire) {
    for (final p in values) {
      if (p.wire == wire) return p;
    }
    return null;
  }

  /// Faza pre lokalny cas [localTime]. Bez [boundaries] plati
  /// [DayBoundaries.fallback].
  static DayPhase resolve(DateTime localTime, {DayBoundaries? boundaries}) {
    final b = boundaries ?? DayBoundaries.fallback(localTime);
    if (localTime.isBefore(b.morning)) return night;
    if (localTime.isBefore(b.day)) return morning;
    if (localTime.isBefore(b.evening)) return day;
    if (localTime.isBefore(b.night)) return evening;
    return night;
  }
}

/// Zaciatky faz dna v lokalnom case.
@immutable
final class DayBoundaries {
  DayBoundaries({
    required this.morning,
    required this.day,
    required this.evening,
    required this.night,
  }) {
    if (!(morning.isBefore(day) &&
        day.isBefore(evening) &&
        evening.isBefore(night))) {
      throw ArgumentError('Expected morning < day < evening < night');
    }
  }

  /// Pevne hodiny 05:00, 12:00, 17:00, 21:00 v dni [date].
  factory DayBoundaries.fallback(DateTime date) {
    DateTime at(int hour) => DateTime(date.year, date.month, date.day, hour);
    return DayBoundaries(
      morning: at(5),
      day: at(12),
      evening: at(17),
      night: at(21),
    );
  }

  final DateTime morning;
  final DateTime day;
  final DateTime evening;
  final DateTime night;
}
