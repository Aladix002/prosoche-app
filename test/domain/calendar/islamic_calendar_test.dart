import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/domain/calendar/hijri_date.dart';
import 'package:sakina/domain/calendar/islamic_calendar.dart';
import 'package:sakina/domain/common/local_date.dart';

import 'reference_dates.dart';

void main() {
  final cal0 = IslamicCalendar();

  group('reference table (Umm al-Qura, offset 0 and +-1)', () {
    test('has >= 30 dates covering Ramadan 2020-2030', () {
      expect(umAlQuraReference.length, greaterThanOrEqualTo(30));
      final ramadanYears = {
        for (final (g, _, m, d) in umAlQuraReference)
          if (m == 9 && d == 1) LocalDate.parse(g).year,
      };
      expect(ramadanYears, containsAll([for (var y = 2020; y <= 2030; y++) y]));
    });

    for (final (iso, y, m, d) in umAlQuraReference) {
      final date = LocalDate.parse(iso);
      final expected = HijriDate(y, m, d);

      test('$iso = $expected', () {
        expect(cal0.hijriOf(date), expected);
        expect(cal0.gregorianOf(expected), date);
      });

      test('$iso with offset +1 and -1', () {
        // +1: hijri udalosti su o den neskor (docs/02 A9); -1 o den skor.
        // Dlzky mesiacov sa nemenia.
        final plus = IslamicCalendar(offset: 1);
        final minus = IslamicCalendar(offset: -1);
        expect(plus.hijriOf(date.addDays(1)), expected);
        expect(minus.hijriOf(date.addDays(-1)), expected);
        expect(plus.gregorianOf(expected), date.addDays(1));
        expect(minus.gregorianOf(expected), date.addDays(-1));
      });
    }

    test('Ramadan lengths', () {
      for (final MapEntry(key: year, value: length) in ramadanLengths.entries) {
        expect(cal0.monthLength(year, 9), length, reason: '$year');
      }
    });
  });

  group('month transition', () {
    test('last day of Ramadan 1444 (29 days) -> 1 Shawwal', () {
      final last = LocalDate(2023, 4, 20);
      expect(cal0.hijriOf(last), HijriDate(1444, 9, 29));
      expect(cal0.hijriOf(last.addDays(1)), HijriDate(1444, 10, 1));
    });

    test('30-day Ramadan 1447 ends on day 30', () {
      expect(cal0.hijriOf(LocalDate(2026, 3, 19)), HijriDate(1447, 9, 30));
      expect(cal0.hijriOf(LocalDate(2026, 3, 20)), HijriDate(1447, 10, 1));
    });

    test('year transition Dhul Hijja 1447 -> Muharram 1448', () {
      final newYear = LocalDate(2026, 6, 16);
      final prev = cal0.hijriOf(newYear.addDays(-1));
      expect(prev.year, 1447);
      expect(prev.month, 12);
      expect(prev.day, cal0.monthLength(1447, 12));
      expect(cal0.hijriOf(newYear), HijriDate(1448, 1, 1));
    });

    test('every day 2020-2031 advances by exactly one hijri day', () {
      var d = LocalDate(2020, 1, 1);
      var h = cal0.hijriOf(d);
      while (d.isBefore(LocalDate(2032, 1, 1))) {
        final next = cal0.hijriOf(d.addDays(1));
        if (next.day == 1) {
          expect(h.day, cal0.monthLength(h.year, h.month));
          expect(next.month, h.month == 12 ? 1 : h.month + 1);
          expect(next.year, h.month == 12 ? h.year + 1 : h.year);
          expect(h.day, anyOf(29, 30));
        } else {
          expect(next, HijriDate(h.year, h.month, h.day + 1));
        }
        d = d.addDays(1);
        h = next;
      }
    });

    test('offset shifts mapping, not month length', () {
      final cal2 = IslamicCalendar(offset: 2);
      final days0 = cal0.daysOfMonth(1448, 9);
      final days2 = cal2.daysOfMonth(1448, 9);
      expect(days0.length, 29);
      expect(days2.length, 29);
      expect(days0.first, LocalDate(2027, 2, 8));
      expect(days2.first, LocalDate(2027, 2, 10));
      for (final (i, d) in days2.indexed) {
        expect(cal2.hijriOf(d), HijriDate(1448, 9, i + 1));
      }
    });
  });

  group('validation', () {
    test('offset must be -2..+2', () {
      expect(() => IslamicCalendar(offset: 3), throwsRangeError);
      expect(() => IslamicCalendar(offset: -3), throwsRangeError);
      expect(IslamicCalendar(offset: -2).offset, -2);
      expect(cal0.withOffset(2), IslamicCalendar(offset: 2));
      expect(cal0.withOffset(2).hashCode, IslamicCalendar(offset: 2).hashCode);
      expect(cal0.toString(), 'IslamicCalendar(offset: 0)');
    });

    test('day 30 of a 29-day month is rejected', () {
      expect(() => cal0.gregorianOf(HijriDate(1448, 9, 30)), throwsRangeError);
    });

    test('table range 1356-1500 AH', () {
      expect(cal0.hijriOf(LocalDate(1937, 3, 14)), HijriDate(1356, 1, 1));
      expect(cal0.hijriOf(LocalDate(2077, 11, 16)), HijriDate(1500, 12, 30));
      expect(() => cal0.hijriOf(LocalDate(1937, 3, 13)), throwsRangeError);
      expect(() => cal0.hijriOf(LocalDate(2077, 11, 17)), throwsRangeError);
      expect(() => cal0.monthLength(1355, 12), throwsRangeError);
      expect(() => cal0.monthLength(1501, 1), throwsRangeError);
      expect(() => cal0.monthLength(1448, 13), throwsRangeError);
    });
  });

  group('HijriDate', () {
    test('validates ranges', () {
      expect(() => HijriDate(1448, 0, 1), throwsRangeError);
      expect(() => HijriDate(1448, 13, 1), throwsRangeError);
      expect(() => HijriDate(1448, 1, 31), throwsRangeError);
      expect(() => HijriDate(0, 1, 1), throwsRangeError);
    });

    test('equality, ordering, toString', () {
      final a = HijriDate(1448, 9, 1);
      expect(a, HijriDate(1448, 9, 1));
      expect(a.hashCode, HijriDate(1448, 9, 1).hashCode);
      expect(a.compareTo(HijriDate(1448, 8, 30)), greaterThan(0));
      expect(a.compareTo(HijriDate(1449, 1, 1)), lessThan(0));
      expect(a.toString(), '1448-09-01');
    });
  });
}
