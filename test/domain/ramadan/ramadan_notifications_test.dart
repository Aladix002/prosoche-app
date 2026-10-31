import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/domain/calendar/calendar.dart';
import 'package:sakina/domain/common/local_date.dart';
import 'package:sakina/domain/notifications/notifications.dart';
import 'package:sakina/domain/prayer/calc_settings.dart';
import 'package:sakina/domain/prayer/prayer.dart';
import 'package:sakina/domain/prayer/prayer_schedule.dart';
import 'package:sakina/domain/ramadan/ramadan.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Notifikacie v Ramadane (docs/04 1.10): suhur zluceny s rannou, iftar
/// s maghribom, rozpocet 64 aj na Androide (docs/02 D17).
void main() {
  tzdata.initializeTimeZones();
  final ba = tz.getLocation('Europe/Bratislava');
  final bratislava = PrayerSchedule(
    lat: 48.15,
    lng: 17.11,
    zone: ba,
    settings: CalcSettings(method: PrayerMethod.muslimWorldLeague),
  );
  const planner = NotificationPlanner();
  final calendar = IslamicCalendar();

  NotificationPlanInput input(
    DateTime now,
    Set<LocalDate> fasting, {
    PrayerSchedule? schedule,
    tz.Location? zone,
    bool paused = false,
  }) => NotificationPlanInput(
    now: now,
    deviceZone: zone ?? ba,
    schedule: schedule ?? bratislava,
    prayersPaused: paused,
    fastingDays: fasting,
  );

  group('ramadanFastingDays', () {
    test('calculated 1448 season inside the window', () {
      final days = ramadanFastingDays(
        calendar: calendar,
        from: LocalDate(2027, 2, 5),
        days: 6,
      );
      expect(days, {
        LocalDate(2027, 2, 8),
        LocalDate(2027, 2, 9),
        LocalDate(2027, 2, 10),
      });
    });

    test('confirmed start and the end of the season', () {
      final stored = RamadanConfirmation(
        hijriYear: 1448,
        startDate: LocalDate(2027, 2, 7),
        source: SeasonSource.userConfirmed,
        lengthDays: 30,
      );
      final start = ramadanFastingDays(
        calendar: calendar,
        from: LocalDate(2027, 2, 5),
        days: 3,
        stored: stored,
      );
      expect(start, {LocalDate(2027, 2, 7)});
      final end = ramadanFastingDays(
        calendar: calendar,
        from: LocalDate(2027, 3, 7),
        days: 5,
        stored: stored,
      );
      expect(end.last, LocalDate(2027, 3, 8)); // 30. den = 8. 3.
      expect(end, hasLength(2));
    });

    test('outside the season: empty', () {
      expect(
        ramadanFastingDays(
          calendar: calendar,
          from: LocalDate(2026, 10, 29),
          days: 12,
        ),
        isEmpty,
      );
    });
  });

  group('NotificationPlanner with fasting days', () {
    final now = tz.TZDateTime(ba, 2027, 2, 9, 0, 1);
    final fasting = ramadanFastingDays(
      calendar: calendar,
      from: LocalDate(2027, 2, 9),
      days: 12,
    );

    test('maghrib becomes iftar with the same id', () {
      final normal = planner.plan(input(now, const {}));
      final ramadan = planner.plan(input(now, fasting));
      final iftars = ramadan.items.where(
        (n) => n.kind == NotificationKind.iftar,
      );
      expect(iftars, isNotEmpty);
      for (final n in iftars) {
        expect(n.prayer, Prayer.maghrib);
        expect(n.channel, NotificationChannel.prayer);
        expect(n.deepLink, 'mursa://prayer?p=maghrib');
        final twin = normal.items.singleWhere((m) => m.id == n.id);
        expect(twin.prayer, Prayer.maghrib);
        expect(twin.at, n.at);
      }
      expect(
        ramadan.items.where(
          (n) =>
              n.kind == NotificationKind.prayer && n.prayer == Prayer.maghrib,
        ),
        isEmpty,
      );
    });

    test('suhur replaces the morning reminder: fajr - 45 min, same id', () {
      final normal = planner.plan(input(now, const {}));
      final ramadan = planner.plan(input(now, fasting));
      final suhurs = ramadan.items.where(
        (n) => n.kind == NotificationKind.suhur,
      );
      expect(suhurs, isNotEmpty);
      expect(
        ramadan.items.where((n) => n.kind == NotificationKind.morning),
        isEmpty,
      );
      for (final n in suhurs) {
        final fajr = bratislava.day(n.day)[Prayer.fajr];
        expect(n.at, fajr.subtract(const Duration(minutes: 45)));
        expect(n.cardMinutes, 45);
        expect(n.deepLink, 'mursa://today');
        expect(normal.items.where((m) => m.id == n.id), hasLength(1));
      }
    });

    test('same daily count, budget <= 64, idempotent', () {
      final normal = planner.plan(input(now, const {}));
      final ramadan = planner.plan(input(now, fasting));
      expect(ramadan.length, normal.length);
      expect(ramadan.length, lessThanOrEqualTo(64));
      expect(planner.plan(input(now, fasting)).items, ramadan.items);
      expect(ramadan.items.map((n) => n.id).toSet(), hasLength(ramadan.length));
    });

    test('budget holds with a 14 day horizon (Android)', () {
      const long = NotificationPlanner(days: 14);
      final plan = long.plan(
        input(
          now,
          ramadanFastingDays(
            calendar: calendar,
            from: LocalDate(2027, 2, 9),
            days: 14,
          ),
        ),
      );
      expect(plan.length, lessThanOrEqualTo(64));
      expect(plan.dropped, greaterThan(0));
      expect(
        plan.items.where((n) => n.kind == NotificationKind.openApp),
        hasLength(1),
      );
    });

    test('open-app reminder replaces the suhur of the last day', () {
      final plan = planner.plan(input(now, fasting));
      final last = plan.items.singleWhere(
        (n) => n.kind == NotificationKind.openApp,
      );
      expect(fasting, contains(last.day));
      expect(
        plan.items.where(
          (n) => n.kind == NotificationKind.suhur && n.day == last.day,
        ),
        isEmpty,
      );
    });

    test('custom suhur lead and paused prayers', () {
      final custom = planner.plan(
        NotificationPlanInput(
          now: now,
          deviceZone: ba,
          schedule: bratislava,
          fastingDays: fasting,
          suhurLeadMinutes: 20,
        ),
      );
      final s = custom.items.firstWhere(
        (n) => n.kind == NotificationKind.suhur,
      );
      expect(
        s.at,
        bratislava
            .day(s.day)[Prayer.fajr]
            .subtract(const Duration(minutes: 20)),
      );
      // Pozastavene modlitby (zmena zony): ranna ostava, bez suhur/iftar.
      final paused = planner.plan(input(now, fasting, paused: true));
      expect(
        paused.items.where(
          (n) =>
              n.kind == NotificationKind.suhur ||
              n.kind == NotificationKind.iftar,
        ),
        isEmpty,
      );
      expect(
        paused.items.where((n) => n.kind == NotificationKind.morning),
        isNotEmpty,
      );
    });

    test('DST: suhur is 45 real minutes before fajr (New York 2025)', () {
      final ny = tz.getLocation('America/New_York');
      final nySchedule = PrayerSchedule(
        lat: 40.71,
        lng: -74.01,
        zone: ny,
        settings: CalcSettings(method: PrayerMethod.northAmerica),
      );
      final from = LocalDate(2025, 3, 6);
      final days = ramadanFastingDays(calendar: calendar, from: from, days: 12);
      final plan = planner.plan(
        input(
          tz.TZDateTime(ny, 2025, 3, 6, 0, 1),
          days,
          schedule: nySchedule,
          zone: ny,
        ),
      );
      expect(plan.length, lessThanOrEqualTo(64));
      final dstDay = LocalDate(2025, 3, 9);
      final suhur = plan.items.singleWhere(
        (n) => n.kind == NotificationKind.suhur && n.day == dstDay,
      );
      final fajr = nySchedule.day(dstDay)[Prayer.fajr];
      expect(fajr.difference(suhur.at), const Duration(minutes: 45));
    });
  });
}
