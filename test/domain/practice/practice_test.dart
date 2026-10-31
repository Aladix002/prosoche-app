import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/practice/practice.dart';

void main() {
  final today = LocalDate(2026, 10, 31);

  group('LifeInWeeks', () {
    test('weeks lived and remaining', () {
      final w = LifeInWeeks(birthYear: 1990, today: today);
      expect(w.totalWeeks, 80 * 52);
      expect(w.birth, LocalDate(1990, 7, 1));
      expect(w.livedWeeks, today.daysSince(LocalDate(1990, 7, 1)) ~/ 7);
      expect(w.remainingWeeks, w.totalWeeks - w.livedWeeks);
      expect(w.fraction, closeTo(w.livedWeeks / w.totalWeeks, 1e-9));
    });

    test('bounds', () {
      expect(
        LifeInWeeks(birthYear: 2026, today: LocalDate(2026, 3, 1)).livedWeeks,
        0,
      );
      expect(
        LifeInWeeks(birthYear: 1910, today: today, years: 90).livedWeeks,
        90 * 52,
      );
      expect(
        () => LifeInWeeks(birthYear: 2027, today: today),
        throwsArgumentError,
      );
      expect(
        () => LifeInWeeks(birthYear: 1800, today: today),
        throwsArgumentError,
      );
      expect(
        () => LifeInWeeks(birthYear: 1990, today: today, years: 0),
        throwsArgumentError,
      );
      expect(LifeInWeeks.isValidBirthYear(1906, today), isTrue);
      expect(LifeInWeeks.isValidBirthYear(1905, today), isFalse);
    });
  });

  test('questionsIn keeps the text of each question', () {
    expect(
      questionsIn(
        'Go back over the day. Ask three questions: What did I do well? '
        'Where did I fall short? What will I do differently tomorrow?\n\n'
        'Write one line.',
      ),
      [
        'What did I do well?',
        'Where did I fall short?',
        'What will I do differently tomorrow?',
      ],
    );
    expect(questionsIn('No questions here.'), isEmpty);
    expect(questionsIn('?'), isEmpty);
  });

  test('rotate is deterministic per day and wraps', () {
    final ids = ['a', 'b', 'c', 'd', 'e'];
    expect(rotate(ids, 0, 2), ['a', 'b']);
    expect(rotate(ids, 1, 2), ['c', 'd']);
    expect(rotate(ids, 2, 2), ['e', 'a']);
    expect(rotate(ids, 7, 9), hasLength(5));
    expect(rotate(<String>[], 3, 2), isEmpty);
    expect(rotate(ids, 3, 0), isEmpty);
  });

  test('routine tags', () {
    expect(RoutineKind.morning.tag, 'morning');
    expect(RoutineKind.evening.tag, 'evening');
  });
}
