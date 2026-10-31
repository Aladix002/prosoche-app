import 'package:meta/meta.dart';

/// Cast dna pri prvom otvoreni dna (plan 7.1, docs/03 3.4, docs/02 D13).
///
/// Urcuje typ karty v slote 9 (rano a vecer dua, inak hadis). Uklada sa do
/// `cards_json`, takze sa sada pocas dna nemeni.
enum DayPhase {
  /// Od fajr do dhuhr.
  morning('morning'),

  /// Od dhuhr do asr.
  day('day'),

  /// Od asr do isha.
  evening('evening'),

  /// Od isha do fajr.
  night('night');

  DayPhase(this.wire);

  final String wire;

  static DayPhase? fromWire(String wire) {
    for (final p in values) {
      if (p.wire == wire) return p;
    }
    return null;
  }

  /// Faza pre lokalny cas [localTime]. Bez [boundaries] (napr. pred
  /// nastavenim polohy) sa pouziju pevne hodiny [DayBoundaries.fallback].
  static DayPhase resolve(DateTime localTime, {DayBoundaries? boundaries}) {
    final b = boundaries ?? DayBoundaries.fallback(localTime);
    if (localTime.isBefore(b.fajr)) return night;
    if (localTime.isBefore(b.dhuhr)) return morning;
    if (localTime.isBefore(b.asr)) return day;
    if (localTime.isBefore(b.isha)) return evening;
    return night;
  }
}

/// Hranice faz dna z casov modlitieb (PrayerSchedule, P-01) v lokalnom case.
@immutable
final class DayBoundaries {
  DayBoundaries({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.isha,
  }) {
    if (!(fajr.isBefore(dhuhr) && dhuhr.isBefore(asr) && asr.isBefore(isha))) {
      throw ArgumentError('Expected fajr < dhuhr < asr < isha');
    }
  }

  /// Pevne hodiny 05:00, 12:00, 15:00, 20:00 v dni [day].
  factory DayBoundaries.fallback(DateTime day) {
    DateTime at(int hour) => DateTime(day.year, day.month, day.day, hour);
    return DayBoundaries(fajr: at(5), dhuhr: at(12), asr: at(15), isha: at(20));
  }

  final DateTime fajr;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime isha;
}
