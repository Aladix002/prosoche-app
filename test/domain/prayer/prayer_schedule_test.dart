import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/common/local_date.dart';
import 'package:prosoche/domain/prayer/calc_settings.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:prosoche/domain/prayer/prayer_schedule.dart';
import 'package:prosoche/domain/settings/prayer_location.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

PrayerSchedule _schedule(
  double lat,
  double lng,
  String zone, {
  PrayerMethod method = PrayerMethod.muslimWorldLeague,
  Map<Prayer, int> adjust = const {},
}) => PrayerSchedule(
  lat: lat,
  lng: lng,
  zone: tz.getLocation(zone),
  settings: CalcSettings(method: method, adjust: adjust),
);

void _expectOrdered(PrayerDay day, PrayerDay next) {
  final times = [for (final p in Prayer.values) day[p]];
  for (var i = 1; i < times.length; i++) {
    expect(
      times[i].isAfter(times[i - 1]),
      isTrue,
      reason: '$day: ${Prayer.values[i].name}',
    );
  }
  expect(day[Prayer.isha].isAfter(next[Prayer.fajr]), isFalse, reason: '$day');
}

void main() {
  tzdata.initializeTimeZones();

  group('DST (last Sunday of March and October)', () {
    final cases = {
      'Europe/Bratislava': (48.15, 17.11),
      'Europe/London': (51.51, -0.13),
      'Europe/Sarajevo': (43.86, 18.41),
    };
    final switches = [
      (LocalDate(2026, 3, 29), 60),
      (LocalDate(2026, 10, 25), -60),
      (LocalDate(2027, 3, 28), 60),
      (LocalDate(2027, 10, 31), -60),
    ];
    for (final MapEntry(key: zone, value: (lat, lng)) in cases.entries) {
      for (final (date, shift) in switches) {
        test('$zone $date', () {
          final s = _schedule(lat, lng, zone);
          final before = s.day(date.addDays(-1));
          final on = s.day(date);
          final after = s.day(date.addDays(1));
          for (final p in Prayer.values) {
            // Okamih sa zo dna na den posunie len o par minut.
            for (final (a, b) in [(before, on), (on, after)]) {
              final drift = b[p].difference(a[p]) - const Duration(days: 1);
              expect(drift.inMinutes.abs(), lessThan(5), reason: p.name);
            }
            // Na hodinach sa cas posunie presne o hodinu (+- par minut).
            final wall = _wall(on[p]) - _wall(before[p]);
            expect((wall - shift).abs(), lessThan(5), reason: '${p.name} $on');
            final zoneOffset = s.zone
                .timeZone(on[p].millisecondsSinceEpoch)
                .offset;
            expect(on[p].timeZoneOffset, zoneOffset);
          }
        });
      }
    }
  });

  group('high latitude without exception', () {
    final cities = {
      'Oslo': (59.91, 10.75, 'Europe/Oslo'),
      'Reykjavik': (64.15, -21.94, 'Atlantic/Reykjavik'),
    };
    for (final MapEntry(key: city, value: (lat, lng, zone)) in cities.entries) {
      for (final (month, days) in [(6, 30), (12, 31)]) {
        test('$city month $month', () {
          final s = PrayerSchedule(
            lat: lat,
            lng: lng,
            zone: tz.getLocation(zone),
            settings: CalcSettings.resolve(lat: lat, country: 'NO'),
          );
          final all = s.days(LocalDate(2026, month, 1), days + 1);
          expect(all, hasLength(days + 1));
          for (var i = 0; i < days; i++) {
            _expectOrdered(all[i], all[i + 1]);
          }
        });
      }
    }

    test('inside the polar circle (Tromso) resolves to nearest day', () {
      final s = _schedule(69.65, 18.96, 'Europe/Oslo');
      for (final date in [LocalDate(2026, 6, 21), LocalDate(2026, 12, 21)]) {
        final day = s.day(date);
        expect(day.times, hasLength(Prayer.values.length));
      }
    });
  });

  group('current and next', () {
    final s = _schedule(51.51, -0.13, 'Europe/London');
    const min = Duration(minutes: 1);

    test('before fajr the current prayer is isha of the previous day', () {
      final day = LocalDate(2026, 1, 15);
      final fajr = s.day(day)[Prayer.fajr];
      final now = fajr.subtract(min);
      expect(s.current(now).prayer, Prayer.isha);
      expect(s.current(now).day, day.addDays(-1));
      expect(s.next(now), PrayerMoment(Prayer.fajr, day, fajr));
    });

    test('isha after midnight belongs to the previous day (docs/02 E2)', () {
      // Prvy letny den v Londyne, ked isha vyjde po polnoci a pred fajr.
      final day =
          [for (var d = LocalDate(2026, 5, 1); d.month < 9; d = d.addDays(1)) d]
              .firstWhere((d) {
                final isha = s.day(d)[Prayer.isha];
                return isha.day != d.day &&
                    s
                            .day(d.addDays(1))[Prayer.fajr]
                            .difference(isha)
                            .inMinutes >
                        10;
              });
      final isha = s.day(day)[Prayer.isha];
      final justBefore = s.current(isha.subtract(min));
      expect((justBefore.prayer, justBefore.day), (Prayer.maghrib, day));
      final after = s.current(isha.add(min));
      expect((after.prayer, after.day), (Prayer.isha, day));
      final next = s.next(isha);
      expect((next.prayer, next.day), (Prayer.fajr, day.addDays(1)));
    });

    test('isha is never after next fajr (middle_of_night)', () {
      // Reykjavik 2026-06-21: adhan_dart dava isha 01:30, zajtra fajr 01:29.
      final r = _schedule(64.15, -21.94, 'Atlantic/Reykjavik');
      final day = LocalDate(2026, 6, 21);
      final isha = r.day(day)[Prayer.isha];
      final fajr = r.day(day.addDays(1))[Prayer.fajr];
      expect(isha.isAfter(fajr), isFalse);
      final now = r.current(fajr);
      expect((now.prayer, now.day), (Prayer.fajr, day.addDays(1)));
    });

    test('after sunrise the next is dhuhr', () {
      final day = s.day(LocalDate(2026, 3, 1));
      final now = day[Prayer.sunrise].add(min);
      expect(s.current(now).prayer, Prayer.sunrise);
      expect(s.next(now).prayer, Prayer.dhuhr);
      expect(s.current(day[Prayer.dhuhr]).prayer, Prayer.dhuhr);
    });

    test('works with UTC instants', () {
      final day = s.day(LocalDate(2026, 7, 1));
      final now = day[Prayer.asr].toUtc().add(min);
      expect(s.current(now).prayer, Prayer.asr);
    });
  });

  test('adjust shifts single prayer by minutes', () {
    final base = _schedule(48.15, 17.11, 'Europe/Bratislava');
    final adj = _schedule(
      48.15,
      17.11,
      'Europe/Bratislava',
      adjust: {Prayer.fajr: 5, Prayer.isha: -3},
    );
    final date = LocalDate(2026, 4, 10);
    final a = base.day(date);
    final b = adj.day(date);
    expect(b[Prayer.fajr].difference(a[Prayer.fajr]).inMinutes, 5);
    expect(b[Prayer.isha].difference(a[Prayer.isha]).inMinutes, -3);
    expect(b[Prayer.dhuhr], a[Prayer.dhuhr]);
  });

  test('wrong method is detected (JAKIM fajr vs singapore 20 deg)', () {
    // JAKIM WLY01 2026-01-01: subuh 06:06 (reference/kuala_lumpur_jakim.csv).
    final wrong = _schedule(
      3.14,
      101.69,
      'Asia/Kuala_Lumpur',
      method: PrayerMethod.singapore,
    ).day(LocalDate(2026, 1, 1));
    final right = _schedule(
      3.14,
      101.69,
      'Asia/Kuala_Lumpur',
      method: PrayerMethod.jakim,
    ).day(LocalDate(2026, 1, 1));
    expect(_wall(right[Prayer.fajr]), 6 * 60 + 6);
    expect((_wall(wrong[Prayer.fajr]) - (6 * 60 + 6)).abs(), greaterThan(2));
  });

  test('forLocation uses rounded stored location and its zone', () {
    final loc = PrayerLocation(
      lat: 41.0082,
      lng: 28.9784,
      country: 'TR',
      tz: 'Europe/Istanbul',
      city: 'Istanbul',
    );
    final s = PrayerSchedule.forLocation(
      loc,
      CalcSettings.resolve(lat: loc.lat, country: loc.country),
    );
    expect((s.lat, s.lng), (41.01, 28.98));
    expect(s.zone.name, 'Europe/Istanbul');
    // Diyanet Istanbul 2026-10-29: 05:58 07:24 12:53 15:44 18:12 19:32.
    final day = s.day(LocalDate(2026, 10, 29));
    expect(day.toString(), contains('fajr 05:5'));
    expect(day.date, LocalDate(2026, 10, 29));
    expect(() => day.times[Prayer.fajr] = day[Prayer.isha], throwsA(anything));
  });

  test('PrayerMoment value semantics', () {
    final s = _schedule(21.42, 39.83, 'Asia/Riyadh');
    final now = tz.TZDateTime(s.zone, 2026, 5, 5, 12);
    final a = s.next(now);
    final b = s.next(now.add(const Duration(seconds: 1)));
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(s.current(now)));
    expect(a.toString(), contains(a.prayer.name));
  });

  test('Prayer.salah excludes sunrise', () {
    expect(Prayer.salah, hasLength(5));
    expect(Prayer.salah.every((p) => p.isSalah), isTrue);
    expect(Prayer.sunrise.isSalah, isFalse);
  });
}

int _wall(DateTime t) => t.hour * 60 + t.minute;
