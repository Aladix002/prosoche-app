import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/domain/calendar/calendar.dart';
import 'package:sakina/domain/common/local_date.dart';
import 'package:sakina/domain/ramadan/ramadan.dart';

/// Umm al-Qura 1448: 29. Shaban = 6. 2. 2027, Shaban ma 30 dni,
/// 1. Ramadan = 8. 2. 2027, Ramadan 29 dni, Eid = 9. 3. 2027.
void main() {
  final calendar = IslamicCalendar();
  final resolver = RamadanSeasonResolver(calendar);

  group('RamadanSeason', () {
    final season = RamadanSeason(
      hijriYear: 1448,
      startDate: LocalDate(2027, 2, 8),
      lengthDays: 30,
      source: SeasonSource.calc,
    );

    test('dayOf, lastDay, eidDate', () {
      expect(season.dayOf(LocalDate(2027, 2, 7)), isNull);
      expect(season.dayOf(LocalDate(2027, 2, 8)), 1);
      expect(season.dayOf(LocalDate(2027, 3, 9)), 30);
      expect(season.dayOf(LocalDate(2027, 3, 10)), isNull);
      expect(season.lastDay, LocalDate(2027, 3, 9));
      expect(season.eidDate, LocalDate(2027, 3, 10));
      expect(season.isFastingDay(LocalDate(2027, 2, 20)), isTrue);
    });

    test('night 27 is the evening of day 26 (docs/04 1.1)', () {
      final day26 = LocalDate(2027, 3, 5);
      expect(season.dayOf(day26), 26);
      expect(season.nightOfDate(day26, afterMaghrib: false), 26);
      expect(season.nightOfDate(day26, afterMaghrib: true), 27);
    });

    test('night 1 is the evening before the first fast', () {
      final eve = LocalDate(2027, 2, 7);
      expect(season.nightOfDate(eve, afterMaghrib: false), isNull);
      expect(season.nightOfDate(eve, afterMaghrib: true), 1);
    });

    test('length must be 29 or 30', () {
      expect(
        () => RamadanSeason(
          hijriYear: 1448,
          startDate: LocalDate(2027, 2, 8),
          lengthDays: 31,
          source: SeasonSource.calc,
        ),
        throwsRangeError,
      );
    });

    test('equality and toString', () {
      final same = RamadanSeason(
        hijriYear: 1448,
        startDate: LocalDate(2027, 2, 8),
        lengthDays: 30,
        source: SeasonSource.calc,
      );
      expect(season, same);
      expect(season.hashCode, same.hashCode);
      expect(season.toString(), contains('2027-02-08'));
    });
  });

  group('RamadanSeasonResolver', () {
    test('calculated 1448 season from Umm al-Qura', () {
      final s = resolver.resolve(1448);
      expect(s.startDate, LocalDate(2027, 2, 8));
      expect(s.lengthDays, 29);
      expect(s.eidDate, LocalDate(2027, 3, 9));
      expect(s.source, SeasonSource.calc);
      expect(s.lengthConfirmed, isFalse);
      expect(resolver.questionDay(1448), LocalDate(2027, 2, 6));
      expect(resolver.upcomingFrom(1448), LocalDate(2027, 2, 2));
    });

    test('global offset +1 shifts the start one day later', () {
      final shifted = RamadanSeasonResolver(IslamicCalendar(offset: 1));
      expect(shifted.resolve(1448).startDate, LocalDate(2027, 2, 9));
      final earlier = RamadanSeasonResolver(IslamicCalendar(offset: -1));
      expect(earlier.resolve(1448).startDate, LocalDate(2027, 2, 7));
    });

    test('known starts 1446-1448', () {
      expect(resolver.calcStart(1446), LocalDate(2025, 3, 1));
      expect(resolver.calcStart(1447), LocalDate(2026, 2, 18));
      expect(resolver.resolve(1447).lengthDays, 30);
    });

    test('stored confirmation wins, other years are ignored', () {
      final stored = RamadanConfirmation(
        hijriYear: 1448,
        startDate: LocalDate(2027, 2, 9),
        source: SeasonSource.userConfirmed,
        lengthDays: 30,
      );
      final s = resolver.resolve(1448, stored: stored);
      expect(s.startDate, LocalDate(2027, 2, 9));
      expect(s.lengthDays, 30);
      expect(s.lengthConfirmed, isTrue);
      expect(s.source, SeasonSource.userConfirmed);
      expect(resolver.resolve(1449, stored: stored).source, SeasonSource.calc);
    });

    test('confirmed start does not move with the global offset', () {
      final stored = RamadanConfirmation(
        hijriYear: 1448,
        startDate: LocalDate(2027, 2, 9),
        source: SeasonSource.userConfirmed,
      );
      for (final offset in [-2, 0, 2]) {
        final r = RamadanSeasonResolver(IslamicCalendar(offset: offset));
        expect(
          r.resolve(1448, stored: stored).startDate,
          LocalDate(2027, 2, 9),
        );
      }
    });
  });

  group('ramadanSeasonYearOf', () {
    test('Shaban to Shawwal only', () {
      expect(ramadanSeasonYearOf(calendar, LocalDate(2026, 12, 15)), isNull);
      expect(ramadanSeasonYearOf(calendar, LocalDate(2027, 2, 2)), 1448);
      expect(ramadanSeasonYearOf(calendar, LocalDate(2027, 3, 20)), 1448);
      expect(ramadanSeasonYearOf(calendar, LocalDate(2027, 5, 1)), isNull);
    });

    test('outside the Umm al-Qura table is null, no throw', () {
      expect(ramadanSeasonYearOf(calendar, LocalDate(1900, 1, 1)), isNull);
      expect(ramadanSeasonYearOf(calendar, LocalDate(2100, 1, 1)), isNull);
    });
  });

  group('RamadanConfirmation', () {
    final key = RamadanConfirmation.settingKey;

    test('json round trip through the setting key', () {
      final c = RamadanConfirmation(
        hijriYear: 1448,
        startDate: LocalDate(2027, 2, 7),
        source: SeasonSource.userConfirmed,
      );
      expect(key.name, 'ramadan.season');
      expect(key.read(key.encode(c)), c);
      final withLength = c.withLength(29);
      expect(key.read(key.encode(withLength)), withLength);
      expect(withLength.hashCode, isNot(c.hashCode));
      expect(withLength.toString(), contains('29'));
    });

    test('missing or invalid value = null (default)', () {
      expect(key.read(null), isNull);
      expect(key.read('null'), isNull);
      for (final raw in [
        '[]',
        '{"year":1448}',
        '{"year":1448,"start":"2027-02-30","source":"calc"}',
        '{"year":1448,"start":"2027-02-07","source":"moon"}',
        '{"year":1448,"start":"2027-02-07","source":"calc","length":31}',
      ]) {
        expect(key.read(raw), isNull, reason: raw);
      }
    });
  });

  group('FastEntry', () {
    test('wire values', () {
      expect(FastEntry.notFasted.wire, 'not_fasted');
      expect(FastEntry.tryParse('excused'), FastEntry.excused);
      expect(FastEntry.tryParse('done'), isNull);
      expect(FastEntry.tryParse(null), isNull);
    });
  });
}
