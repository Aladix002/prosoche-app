import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/streak/streak.dart';

// D-02: kalendarny den preskoceny letom na vychod (rozhodnutie Wave 1).
void main() {
  const policy = StreakPolicy();
  final d1 = LocalDate(2026, 10, 27);
  final skipped = LocalDate(2026, 10, 28);

  StreakEvaluation run(Map<LocalDate, DayActivity> activity) => policy.evaluate(
    state: StreakState(
      current: 4,
      longest: 4,
      graceLeft: 2,
      lastEvaluatedDate: d1.addDays(-1),
    ),
    now: DateTime(2026, 10, 29, 10),
    activity: activity,
  );

  test('skipped day without activity is neither missed nor logged', () {
    final e = run({
      d1: DayActivity(setCompletedAt: DateTime(2026, 10, 27, 9)),
      skipped: DayActivity(skippedByTravel: true),
    });
    expect(e.state.current, 5);
    expect(e.state.graceLeft, 2);
    expect(e.state.lastEvaluatedDate, skipped);
    expect(e.entries.map((x) => x.date), [d1]);
  });

  test('skipped day with activity still counts as done', () {
    final e = run({
      d1: DayActivity(setCompletedAt: DateTime(2026, 10, 27, 9)),
      skipped: DayActivity(
        questsDoneAt: [DateTime(2026, 10, 28, 8)],
        skippedByTravel: true,
      ),
    });
    expect(e.state.current, 6);
    expect(e.entries.last.status, DayStatus.done);
  });

  test('without the flag the same day uses a grace day', () {
    final e = run({d1: DayActivity(setCompletedAt: DateTime(2026, 10, 27, 9))});
    expect(e.state.graceLeft, 1);
    expect(e.entries.last.status, DayStatus.grace);
  });
}
