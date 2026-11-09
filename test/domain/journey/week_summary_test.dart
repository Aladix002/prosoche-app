import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/common/local_date.dart';
import 'package:prosoche/domain/journey/week_summary.dart';
import 'package:prosoche/domain/practice/routine.dart';

void main() {
  // Nedela 8. 11. 2026.
  final sunday = LocalDate(2026, 11, 8);

  group('WeekWindow', () {
    test('last 7 days including today', () {
      final w = WeekWindow.endingOn(sunday);
      expect(w.start, LocalDate(2026, 11, 2));
      expect(w.end, sunday);
      expect(w.start.weekday, DateTime.monday);
      expect(w.contains(LocalDate(2026, 11, 2)), isTrue);
      expect(w.contains(sunday), isTrue);
      expect(w.contains(LocalDate(2026, 11, 1)), isFalse);
      expect(w.contains(LocalDate(2026, 11, 9)), isFalse);
      expect(w.end.daysSince(w.start) + 1, WeekWindow.days);
    });

    test('crosses month and year boundaries', () {
      final w = WeekWindow.endingOn(LocalDate(2027, 1, 3));
      expect(w.start, LocalDate(2026, 12, 28));
      final m = WeekWindow.endingOn(LocalDate(2026, 3, 2));
      expect(m.start, LocalDate(2026, 2, 24));
    });

    test('local midnight bounds', () {
      final w = WeekWindow.endingOn(sunday);
      expect(w.from, DateTime(2026, 11, 2));
      expect(w.until, DateTime(2026, 11, 9));
    });

    test('equality', () {
      expect(WeekWindow.endingOn(sunday), WeekWindow.endingOn(sunday));
      expect(
        WeekWindow.endingOn(sunday).hashCode,
        WeekWindow.endingOn(sunday).hashCode,
      );
      expect(
        WeekWindow.endingOn(sunday),
        isNot(WeekWindow.endingOn(sunday.addDays(1))),
      );
      expect(WeekWindow.endingOn(sunday).toString(), contains('2026-11-02'));
    });
  });

  group('WeekSummary.compute', () {
    final window = WeekWindow.endingOn(sunday);

    WeekSummary compute(WeekActivity a, {bool gate = true, int? streak}) =>
        WeekSummary.compute(
          window: window,
          activity: a,
          gateAvailable: gate,
          streak: streak,
        );

    test('empty data', () {
      final s = compute(WeekActivity.empty, gate: false);
      expect(s.isEmpty, isTrue);
      expect(s.gate, isNull);
      expect(s.cardsRead, 0);
      expect(s.practiceDays, 0);
      expect(s.since, window.start);
      expect(s.isPartial, isFalse);
      expect(s.dayCount, 7);
    });

    test('gate enabled but unused shows zero rows, still empty', () {
      final s = compute(WeekActivity.empty);
      expect(s.gate, isNotNull);
      expect(s.gate!.paused, 0);
      expect(s.gate!.notOpened, 0);
      expect(s.isEmpty, isTrue);
    });

    test('counts gate visits inside the window only', () {
      final s = compute(
        WeekActivity(
          gateVisits: [
            // Pred oknom (nedela 1. 11. 23:59).
            GateVisit(
              at: DateTime(2026, 11, 1, 23, 59),
              outcome: GateOutcome.dismissed,
              appLabel: 'A',
            ),
            // Prva minuta okna.
            GateVisit(
              at: DateTime(2026, 11, 2),
              outcome: GateOutcome.dismissed,
              appLabel: 'A',
            ),
            GateVisit(
              at: DateTime(2026, 11, 4, 12),
              outcome: GateOutcome.passed,
              appLabel: 'B',
            ),
            GateVisit(
              at: DateTime(2026, 11, 5, 12),
              outcome: GateOutcome.emergency,
              appLabel: 'B',
            ),
            GateVisit(
              at: DateTime(2026, 11, 6, 12),
              outcome: GateOutcome.error,
            ),
            GateVisit(
              at: DateTime(2026, 11, 7, 12),
              outcome: GateOutcome.open,
              appLabel: ' ',
            ),
            // Posledna minuta okna.
            GateVisit(
              at: DateTime(2026, 11, 8, 23, 59),
              outcome: GateOutcome.dismissed,
              appLabel: 'C',
            ),
            // Po okne.
            GateVisit(
              at: DateTime(2026, 11, 9),
              outcome: GateOutcome.dismissed,
              appLabel: 'C',
            ),
          ],
        ),
      );
      expect(s.gate!.paused, 6);
      expect(s.gate!.notOpened, 2);
      // B 2x, potom A a C po 1x podla abecedy; prazdny nazov sa vynecha.
      expect(s.gate!.topApps, ['B', 'A', 'C']);
      expect(s.isEmpty, isFalse);
    });

    test('top apps are limited', () {
      final s = compute(
        WeekActivity(
          gateVisits: [
            for (final l in ['A', 'B', 'C', 'D', 'D'])
              GateVisit(
                at: DateTime(2026, 11, 3),
                outcome: GateOutcome.passed,
                appLabel: l,
              ),
          ],
        ),
      );
      expect(s.gate!.topApps, hasLength(WeekSummary.maxTopApps));
      expect(s.gate!.topApps.first, 'D');
    });

    test('gate visits without the gate feature still show (data exists)', () {
      final s = compute(
        WeekActivity(
          gateVisits: [
            GateVisit(
              at: DateTime(2026, 11, 3),
              outcome: GateOutcome.dismissed,
            ),
          ],
        ),
        gate: false,
      );
      expect(s.gate!.paused, 1);
    });

    test('cards and practice inside the window', () {
      final s = compute(
        WeekActivity(
          cardsReadByDay: {
            LocalDate(2026, 11, 1): 9,
            LocalDate(2026, 11, 2): 3,
            sunday: 4,
            LocalDate(2026, 11, 9): 9,
          },
          practice: {
            LocalDate(2026, 11, 1): const {RoutineKind.morning},
            LocalDate(2026, 11, 2): const {RoutineKind.morning},
            LocalDate(2026, 11, 3): const {
              RoutineKind.morning,
              RoutineKind.evening,
            },
            LocalDate(2026, 11, 4): const {RoutineKind.evening},
            LocalDate(2026, 11, 5): const {},
          },
        ),
        gate: false,
        streak: 5,
      );
      expect(s.cardsRead, 7);
      expect(s.practiceDays, 3);
      expect(s.morningDays, 2);
      expect(s.eveningDays, 2);
      expect(s.streak, 5);
      expect(s.isEmpty, isFalse);
    });

    test('streak alone is not empty, hidden streak is', () {
      expect(compute(WeekActivity.empty, streak: 3).isEmpty, isFalse);
      expect(compute(WeekActivity.empty, streak: 0).isEmpty, isTrue);
      expect(compute(WeekActivity.empty).streak, isNull);
    });

    test('first week starts on the first active day', () {
      final s = compute(WeekActivity(firstActiveDay: LocalDate(2026, 11, 6)));
      expect(s.since, LocalDate(2026, 11, 6));
      expect(s.isPartial, isTrue);
      expect(s.dayCount, 3);
    });

    test('first active day before or after the window', () {
      expect(
        compute(WeekActivity(firstActiveDay: LocalDate(2026, 1, 1))).since,
        window.start,
      );
      // Hodiny sa vratili spat: nikdy nie za koniec okna.
      final s = compute(WeekActivity(firstActiveDay: LocalDate(2026, 12, 1)));
      expect(s.since, sunday);
      expect(s.dayCount, 1);
    });
  });
}
