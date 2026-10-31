import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/feed/feed.dart';

void main() {
  DateTime at(int h, [int m = 0]) => DateTime(2026, 10, 29, h, m);

  test('fallback hours', () {
    expect(DayPhase.resolve(at(4, 59)), DayPhase.night);
    expect(DayPhase.resolve(at(5)), DayPhase.morning);
    expect(DayPhase.resolve(at(11, 59)), DayPhase.morning);
    expect(DayPhase.resolve(at(12)), DayPhase.day);
    expect(DayPhase.resolve(at(17)), DayPhase.evening);
    expect(DayPhase.resolve(at(21)), DayPhase.night);
  });

  test('custom boundaries', () {
    final b = DayBoundaries(
      morning: at(6),
      day: at(11, 40),
      evening: at(14),
      night: at(18, 30),
    );
    expect(DayPhase.resolve(at(5, 30), boundaries: b), DayPhase.night);
    expect(DayPhase.resolve(at(11, 45), boundaries: b), DayPhase.day);
    expect(DayPhase.resolve(at(18), boundaries: b), DayPhase.evening);
    expect(DayPhase.resolve(at(18, 31), boundaries: b), DayPhase.night);
  });

  test('boundaries must be ordered', () {
    expect(
      () => DayBoundaries(
        morning: at(12),
        day: at(6),
        evening: at(14),
        night: at(20),
      ),
      throwsArgumentError,
    );
  });

  test('wire values', () {
    for (final p in DayPhase.values) {
      expect(DayPhase.fromWire(p.wire), p);
    }
    expect(DayPhase.fromWire('noon'), isNull);
    expect(TimeOfDayFacet.fromPhase(DayPhase.morning), TimeOfDayFacet.morning);
    expect(TimeOfDayFacet.fromPhase(DayPhase.day), TimeOfDayFacet.day);
    expect(TimeOfDayFacet.fromPhase(DayPhase.evening), TimeOfDayFacet.evening);
    expect(TimeOfDayFacet.fromPhase(DayPhase.night), TimeOfDayFacet.night);
    expect(TimeOfDayFacet.fromWire('evening'), TimeOfDayFacet.evening);
    expect(TimeOfDayFacet.fromWire(null), TimeOfDayFacet.any);
    expect(TimeOfDayFacet.fromWire('x'), TimeOfDayFacet.any);
  });
}
