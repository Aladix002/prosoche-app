import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/common/local_date.dart';

void main() {
  test('parse and format ISO', () {
    final d = LocalDate.parse('2026-03-09');
    expect((d.year, d.month, d.day), (2026, 3, 9));
    expect(d.toString(), '2026-03-09');
    expect(LocalDate(987, 1, 2).toString(), '0987-01-02');
  });

  test('rejects invalid text and dates', () {
    for (final s in ['2026-3-9', '2026-02-30', '2026-13-01', 'x', '']) {
      expect(() => LocalDate.parse(s), throwsFormatException, reason: s);
      expect(LocalDate.tryParse(s), isNull);
    }
    expect(() => LocalDate(2026, 2, 29), throwsArgumentError);
    expect(LocalDate(2028, 2, 29).day, 29);
    expect(LocalDate.isValid(2026, 4, 31), isFalse);
  });

  test('fromDateTime drops time', () {
    expect(
      LocalDate.fromDateTime(DateTime(2026, 10, 29, 23, 59)),
      LocalDate(2026, 10, 29),
    );
    expect(LocalDate(2026, 10, 29).toLocalDateTime(), DateTime(2026, 10, 29));
  });

  test('arithmetic ignores DST (last Sunday of March and October)', () {
    final march = LocalDate(2026, 3, 28);
    expect(march.addDays(1), LocalDate(2026, 3, 29));
    expect(march.addDays(2), LocalDate(2026, 3, 30));
    expect(LocalDate(2026, 10, 25).addDays(1), LocalDate(2026, 10, 26));
    expect(LocalDate(2026, 12, 31).addDays(1), LocalDate(2027, 1, 1));
    expect(LocalDate(2027, 1, 1).addDays(-1), LocalDate(2026, 12, 31));
    expect(LocalDate(2027, 1, 1).daysSince(LocalDate(2026, 1, 1)), 365);
    expect(LocalDate(2026, 1, 1).daysSince(LocalDate(2026, 1, 8)), -7);
  });

  test('weekday: 2026-10-30 is Friday', () {
    expect(LocalDate(2026, 10, 30).weekday, DateTime.friday);
  });

  test('ordering and equality', () {
    final a = LocalDate(2026, 1, 31);
    final b = LocalDate(2026, 2, 1);
    final c = LocalDate(2027, 1, 1);
    expect(a.isBefore(b), isTrue);
    expect(b.isAfter(a), isTrue);
    expect(c.compareTo(b), greaterThan(0));
    expect(a.compareTo(LocalDate(2026, 1, 31)), 0);
    expect([c, a, b]..sort(), [a, b, c]);
    expect({a, LocalDate.parse('2026-01-31')}, hasLength(1));
  });
}
