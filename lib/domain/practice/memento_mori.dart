import 'package:meta/meta.dart';
import 'package:prosoche/domain/common/common.dart';

/// Tyzdne zivota (memento mori): kolko tyzdnov z [years] rokov uz uplynulo.
///
/// Vstupom je len rok narodenia (volitelne, zostava v zariadeni); den
/// narodenia sa berie ako 1. jul daneho roka. Nie je to predpoved, len
/// pomocka na zamyslenie.
@immutable
final class LifeInWeeks {
  LifeInWeeks({required this.birthYear, required this.today, this.years = 80}) {
    if (years < 1 || years > 120) {
      throw ArgumentError.value(years, 'years', 'must be 1..120');
    }
    if (!isValidBirthYear(birthYear, today)) {
      throw ArgumentError.value(birthYear, 'birthYear', 'out of range');
    }
  }

  static const weeksPerYear = 52;

  /// Rok narodenia je v rozsahu [today.year - 120, today.year].
  static bool isValidBirthYear(int year, LocalDate today) =>
      year <= today.year && year >= today.year - 120;

  final int birthYear;
  final LocalDate today;
  final int years;

  LocalDate get birth => LocalDate(birthYear, 7, 1);

  int get totalWeeks => years * weeksPerYear;

  /// Uplynule tyzdne (0..[totalWeeks]).
  int get livedWeeks {
    final days = today.daysSince(birth);
    if (days <= 0) return 0;
    final w = days ~/ 7;
    return w > totalWeeks ? totalWeeks : w;
  }

  int get remainingWeeks => totalWeeks - livedWeeks;

  double get fraction => livedWeeks / totalWeeks;
}
