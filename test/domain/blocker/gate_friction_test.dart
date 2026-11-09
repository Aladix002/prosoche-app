import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/blocker/gate_friction.dart';

void main() {
  group('GateFriction', () {
    test('grows with each opening and is capped', () {
      final steps = [for (var n = 0; n <= 8; n++) GateFriction.forOpen(n)];
      expect(
        [for (final f in steps) f.dwellFactor],
        [1.0, 1.0, 1.25, 1.5, 1.75, 2.0, 2.0, 2.0, 2.0],
      );
      expect(
        [for (final f in steps) f.extraCards],
        [0, 0, 0, 0, 1, 1, 1, 1, 1],
      );
      expect(steps.first.opens, 1);
      expect(
        GateFriction.forOpen(100).dwellFactor,
        GateFriction.maxDwellFactor,
      );
      expect(GateFriction.forOpen(100).extraCards, GateFriction.maxExtraCards);
    });

    test('first opening equals none', () {
      expect(GateFriction.forOpen(1), GateFriction.none);
      expect(GateFriction.forOpen(1).hashCode, GateFriction.none.hashCode);
      expect(GateFriction.forOpen(2), isNot(GateFriction.none));
      expect(GateFriction.forOpen(4).toString(), contains('+1'));
    });

    test('dwell is scaled and rounded up to whole seconds', () {
      const base = Duration(seconds: 4);
      expect(GateFriction.none.dwell(base), base);
      expect(GateFriction.forOpen(2).dwell(base), const Duration(seconds: 5));
      expect(GateFriction.forOpen(3).dwell(base), const Duration(seconds: 6));
      expect(GateFriction.forOpen(9).dwell(base), const Duration(seconds: 8));
      expect(
        GateFriction.forOpen(2).dwell(const Duration(milliseconds: 4500)),
        const Duration(seconds: 6),
      );
    });
  });

  group('PracticeFirstRule', () {
    const on = PracticeFirstRule(enabled: true, until: '10:00');

    bool locks(
      PracticeFirstRule rule,
      DateTime now, {
      bool selected = true,
      bool done = false,
    }) => rule.locks(now: now, appSelected: selected, morningDone: done);

    test('locks from midnight until the chosen time', () {
      expect(locks(on, DateTime(2026, 11, 9)), isTrue);
      expect(locks(on, DateTime(2026, 11, 9, 7, 30)), isTrue);
      expect(locks(on, DateTime(2026, 11, 9, 9, 59)), isTrue);
      expect(locks(on, DateTime(2026, 11, 9, 10)), isFalse);
      expect(locks(on, DateTime(2026, 11, 9, 23)), isFalse);
    });

    test('done, unselected app or off never locks', () {
      final morning = DateTime(2026, 11, 9, 7);
      expect(locks(on, morning, done: true), isFalse);
      expect(locks(on, morning, selected: false), isFalse);
      expect(
        locks(const PracticeFirstRule(enabled: false, until: '10:00'), morning),
        isFalse,
      );
    });

    test('until parsing, invalid falls back to 10:00', () {
      expect(PracticeFirstRule.parseMinutes('06:45'), 405);
      expect(PracticeFirstRule.parseMinutes('24:00'), isNull);
      expect(PracticeFirstRule.parseMinutes('7:00'), isNull);
      expect(
        const PracticeFirstRule(enabled: true, until: 'x').untilMinutes,
        600,
      );
      expect(
        const PracticeFirstRule(enabled: true, until: '12:15').untilMinutes,
        735,
      );
    });
  });
}
