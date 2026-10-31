import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/domain/feed/feed.dart';

void main() {
  DateTime at(int h, [int m = 0]) => DateTime(2026, 10, 29, h, m);

  test('fallback hours', () {
    expect(DayPhase.resolve(at(4, 59)), DayPhase.night);
    expect(DayPhase.resolve(at(5)), DayPhase.morning);
    expect(DayPhase.resolve(at(11, 59)), DayPhase.morning);
    expect(DayPhase.resolve(at(12)), DayPhase.day);
    expect(DayPhase.resolve(at(15)), DayPhase.evening);
    expect(DayPhase.resolve(at(20)), DayPhase.night);
  });

  test('prayer boundaries', () {
    final b = DayBoundaries(
      fajr: at(6),
      dhuhr: at(11, 40),
      asr: at(14),
      isha: at(18, 30),
    );
    expect(DayPhase.resolve(at(5, 30), boundaries: b), DayPhase.night);
    expect(DayPhase.resolve(at(11, 45), boundaries: b), DayPhase.day);
    expect(DayPhase.resolve(at(18), boundaries: b), DayPhase.evening);
    expect(DayPhase.resolve(at(18, 31), boundaries: b), DayPhase.night);
  });

  test('boundaries must be ordered', () {
    expect(
      () =>
          DayBoundaries(fajr: at(12), dhuhr: at(6), asr: at(14), isha: at(20)),
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
  });
}
