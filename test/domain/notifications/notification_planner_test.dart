import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/common/local_date.dart';
import 'package:prosoche/domain/notifications/notifications.dart';
import 'package:prosoche/domain/prayer/calc_settings.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:prosoche/domain/prayer/prayer_schedule.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

PrayerSchedule _schedule(double lat, double lng, String zone) => PrayerSchedule(
  lat: lat,
  lng: lng,
  zone: tz.getLocation(zone),
  settings: CalcSettings(method: PrayerMethod.muslimWorldLeague),
);

late tz.Location _ba;
late PrayerSchedule _bratislava;

NotificationPlanInput _input(
  DateTime now, {
  PrayerSchedule? schedule,
  bool noSchedule = false,
  tz.Location? deviceZone,
  Set<Prayer>? enabled,
  bool paused = false,
  Set<LocalDate> excused = const {},
  bool morning = true,
  TimeOfDayHm morningTime = TimeOfDayHm.morningDefault,
  Map<LocalDate, String> events = const {},
}) => NotificationPlanInput(
  now: now,
  deviceZone: deviceZone ?? _ba,
  schedule: noSchedule ? null : schedule ?? _bratislava,
  enabledPrayers: enabled ?? {...Prayer.salah},
  prayersPaused: paused,
  excusedDays: excused,
  morningEnabled: morning,
  morningTime: morningTime,
  eventNames: events,
);

void main() {
  tzdata.initializeTimeZones();
  _ba = tz.getLocation('Europe/Bratislava');
  _bratislava = _schedule(48.15, 17.11, 'Europe/Bratislava');
  const planner = NotificationPlanner();

  // Utorok 3. 11. 2026, 06:00 v Bratislave (pred fajr ~05:00? nie, po).
  final now = tz.TZDateTime(_ba, 2026, 11, 3, 6);

  group('budget and window', () {
    test('10 days: 50 prayers + 9 mornings + open-app = 60 (<= 64)', () {
      final midnight = tz.TZDateTime(_ba, 2026, 11, 3, 0, 1);
      final plan = planner.plan(_input(midnight));
      expect(plan.prayers, hasLength(50));
      expect(
        plan.items.where((n) => n.kind == NotificationKind.morning),
        hasLength(9),
      );
      expect(
        plan.items.where((n) => n.kind == NotificationKind.openApp),
        hasLength(1),
      );
      expect(plan.length, 60);
      expect(plan.dropped, 0);
    });

    test('never more than 64 notifications, on any platform', () {
      const big = NotificationPlanner(days: 20);
      final plan = big.plan(_input(now));
      expect(plan.length, lessThanOrEqualTo(64));
      expect(plan.dropped, greaterThan(0));
      // Ponechane su najskorsie.
      final kept = plan.items.where((n) => n.kind != NotificationKind.openApp);
      final latestKept = kept.map((n) => n.at).reduce((a, b) {
        return a.isAfter(b) ? a : b;
      });
      expect(latestKept.isBefore(now.add(const Duration(days: 14))), isTrue);
    });

    test('custom small budget keeps earliest and the open-app reminder', () {
      const small = NotificationPlanner(maxPending: 8);
      final plan = small.plan(_input(now));
      expect(plan.length, lessThanOrEqualTo(8));
      expect(plan.items.last.kind, isNot(NotificationKind.morning));
      expect(
        plan.items.where((n) => n.kind == NotificationKind.openApp),
        hasLength(1),
      );
    });

    test('everything is in the future and inside 10 days', () {
      final plan = planner.plan(_input(now));
      final end = tz.TZDateTime(_ba, 2026, 11, 13);
      for (final n in plan.items) {
        expect(n.at.isAfter(now), isTrue, reason: '$n');
        expect(n.at.isBefore(end), isTrue, reason: '$n');
      }
    });

    test('sorted by time and ids are unique', () {
      final plan = planner.plan(_input(now));
      final ids = plan.items.map((n) => n.id).toSet();
      expect(ids, hasLength(plan.length));
      for (var i = 1; i < plan.length; i++) {
        expect(plan.items[i].at.isBefore(plan.items[i - 1].at), isFalse);
      }
    });

    test('without open-app reminder the budget is the full 64', () {
      const noOpen = NotificationPlanner(days: 20, openAppReminder: false);
      final plan = noOpen.plan(_input(now));
      expect(plan.length, 64);
      expect(plan.items.any((n) => n.kind == NotificationKind.openApp), false);
    });
  });

  group('idempotency', () {
    test('same input gives identical plan', () {
      final a = planner.plan(_input(now));
      final b = planner.plan(_input(now));
      expect(b.items, a.items);
      expect(b.items.map((n) => n.id), a.items.map((n) => n.id));
    });

    test('later run keeps ids of the remaining notifications', () {
      final a = planner.plan(_input(now));
      final later = now.add(const Duration(hours: 12));
      final b = planner.plan(_input(later));
      final aById = {for (final n in a.items) n.id: n};
      final common = b.items.where((n) => aById.containsKey(n.id));
      expect(common, isNotEmpty);
      for (final n in common) {
        if (n.kind == NotificationKind.openApp) continue;
        expect(n.fingerprint, aById[n.id]!.fingerprint);
      }
    });

    test('applying the diff twice changes nothing', () {
      final plan = planner.plan(_input(now));
      String payload(PlannedNotification n) => n.fingerprint;
      final first = diffNotifications(
        pending: const [],
        planned: plan.items,
        payloadOf: payload,
      );
      expect(first.schedule, hasLength(plan.length));
      final pending = [
        for (final n in first.schedule) PendingNotification(n.id, payload(n)),
      ];
      final second = diffNotifications(
        pending: pending,
        planned: planner.plan(_input(now)).items,
        payloadOf: payload,
      );
      expect(second.isEmpty, isTrue);
      expect(second.unchanged, plan.length);
    });
  });

  group('time zone change', () {
    test('paused prayers: only morning reminders, old prayers cancelled', () {
      final before = planner.plan(_input(now));
      final istanbul = tz.getLocation('Europe/Istanbul');
      final after = planner.plan(
        _input(now, deviceZone: istanbul, paused: true),
      );
      expect(after.prayers, isEmpty);
      expect(
        after.items.every((n) => n.kind == NotificationKind.morning),
        isTrue,
      );
      final diff = diffNotifications(
        pending: [
          for (final n in before.items)
            PendingNotification(n.id, n.fingerprint),
        ],
        planned: after.items,
        payloadOf: (n) => n.fingerprint,
      );
      for (final n in before.prayers) {
        expect(diff.cancel, contains(n.id));
      }
    });

    test('morning follows the device zone', () {
      final istanbul = tz.getLocation('Europe/Istanbul');
      final plan = planner.plan(_input(now, deviceZone: istanbul));
      final morning = plan.items.firstWhere(
        (n) => n.kind == NotificationKind.morning,
      );
      final local = tz.TZDateTime.from(morning.at, istanbul);
      expect((local.hour, local.minute), (7, 30));
    });

    test('keeping old location in a new zone plans same instants', () {
      final istanbul = tz.getLocation('Europe/Istanbul');
      final a = planner.plan(_input(now));
      final b = planner.plan(_input(now, deviceZone: istanbul));
      final aPrayers = {for (final n in a.prayers) n.id: n.at};
      for (final n in b.prayers) {
        if (aPrayers[n.id] case final at?) {
          expect(n.at.isAtSameMomentAs(at), isTrue);
        }
      }
    });
  });

  group('DST', () {
    test('morning stays at 07:30 local across the October switch', () {
      final start = tz.TZDateTime(_ba, 2026, 10, 20, 8);
      final plan = planner.plan(_input(start));
      final mornings = plan.items.where(
        (n) => n.kind == NotificationKind.morning,
      );
      // Dnesna uz bola, posledna je nahradena vyzvou na otvorenie.
      expect(mornings.length, 8);
      for (final n in mornings) {
        final local = tz.TZDateTime.from(n.at, _ba);
        expect((local.hour, local.minute), (7, 30), reason: '$n');
      }
      final offsets = mornings.map((n) => n.at.timeZoneOffset).toSet();
      expect(offsets, hasLength(2));
    });

    test('prayer times do not jump by an hour at the March switch', () {
      final start = tz.TZDateTime(_ba, 2027, 3, 25, 8);
      final plan = planner.plan(_input(start));
      final dhuhrs = plan.items
          .where((n) => n.prayer == Prayer.dhuhr)
          .map((n) => tz.TZDateTime.from(n.at, _ba))
          .toList();
      for (var i = 1; i < dhuhrs.length; i++) {
        final a = dhuhrs[i - 1].hour * 60 + dhuhrs[i - 1].minute;
        final b = dhuhrs[i].hour * 60 + dhuhrs[i].minute;
        // Medzi dnami max par minut, aj ked sa posunie letny cas.
        expect((b - a).abs() <= 2 || (b - a - 60).abs() <= 2, isTrue);
      }
      // Po prechode je dhuhr okolo 12:5x letneho casu, nie 11:5x.
      expect(dhuhrs.last.hour, 12);
    });

    test('morning time inside the spring gap still fires once', () {
      final start = tz.TZDateTime(_ba, 2027, 3, 27, 8);
      final plan = planner.plan(
        _input(start, noSchedule: true, morningTime: const TimeOfDayHm(2, 30)),
      );
      final onSwitch = plan.items.where((n) => n.day == LocalDate(2027, 3, 28));
      expect(onSwitch, hasLength(1));
    });
  });

  group('content selection', () {
    test('friday dhuhr is jumuah', () {
      final plan = planner.plan(_input(now));
      final jumuah = plan.items
          .where((n) => n.kind == NotificationKind.jumuah)
          .toList();
      expect(jumuah, isNotEmpty);
      for (final n in jumuah) {
        expect(n.day.weekday, DateTime.friday);
        expect(n.prayer, Prayer.dhuhr);
      }
      expect(
        plan.items.where(
          (n) =>
              n.kind == NotificationKind.prayer &&
              n.prayer == Prayer.dhuhr &&
              n.day.weekday == DateTime.friday,
        ),
        isEmpty,
      );
    });

    test('excused days silently skip prayers but keep the morning', () {
      final excused = LocalDate(2026, 11, 5);
      final plan = planner.plan(_input(now, excused: {excused}));
      expect(plan.prayers.where((n) => n.day == excused), isEmpty);
      expect(
        plan.items.where(
          (n) => n.kind == NotificationKind.morning && n.day == excused,
        ),
        hasLength(1),
      );
    });

    test('disabled prayers are not planned', () {
      final plan = planner.plan(
        _input(now, enabled: {Prayer.fajr, Prayer.isha}),
      );
      expect(plan.prayers.map((n) => n.prayer).toSet(), {
        Prayer.fajr,
        Prayer.isha,
      });
    });

    test('no prayers enabled: no open-app reminder', () {
      final plan = planner.plan(_input(now, enabled: {}));
      expect(plan.prayers, isEmpty);
      expect(plan.items.any((n) => n.kind == NotificationKind.openApp), false);
    });

    test('without location only the morning reminder', () {
      final plan = planner.plan(_input(now, noSchedule: true));
      expect(plan.prayers, isEmpty);
      expect(plan.length, 10);
    });

    test('morning disabled: no mornings, open-app at default time', () {
      final plan = planner.plan(_input(now, morning: false));
      expect(plan.items.any((n) => n.kind == NotificationKind.morning), false);
      final open = plan.items.singleWhere(
        (n) => n.kind == NotificationKind.openApp,
      );
      expect(open.day, LocalDate(2026, 11, 12));
      expect((open.at.hour, open.at.minute), (7, 30));
    });

    test('open-app replaces the last morning', () {
      final plan = planner.plan(_input(now));
      final open = plan.items.singleWhere(
        (n) => n.kind == NotificationKind.openApp,
      );
      expect(
        plan.items.where(
          (n) => n.kind == NotificationKind.morning && n.day == open.day,
        ),
        isEmpty,
      );
      expect(open.deepLink, 'prosoche://today');
    });

    test('event day uses the event morning variant', () {
      final day = LocalDate(2026, 11, 6);
      final plan = planner.plan(_input(now, events: {day: 'Test event'}));
      final n = plan.items.singleWhere((n) => n.day == day && !n.kind.isPrayer);
      expect(n.kind, NotificationKind.morningEvent);
      expect(n.eventName, 'Test event');
      expect(n.channel, NotificationChannel.daily);
    });

    test('isha after midnight belongs to the previous day', () {
      // Oslo v juni: isha je po polnoci (middle_of_night).
      final oslo = tz.getLocation('Europe/Oslo');
      final schedule = _schedule(59.91, 10.75, 'Europe/Oslo');
      final june = tz.TZDateTime(oslo, 2026, 6, 20, 12);
      final plan = planner.plan(
        _input(june, schedule: schedule, deviceZone: oslo),
      );
      final ishas = plan.items.where((n) => n.prayer == Prayer.isha).toList();
      expect(ishas, isNotEmpty);
      final afterMidnight = ishas.where(
        (n) => tz.TZDateTime.from(n.at, oslo).hour < 12,
      );
      for (final n in afterMidnight) {
        final local = LocalDate.fromDateTime(tz.TZDateTime.from(n.at, oslo));
        expect(n.day, local.addDays(-1));
      }
    });

    test('prayer deep link points to the prayer', () {
      final plan = planner.plan(_input(now));
      final asr = plan.items.firstWhere((n) => n.prayer == Prayer.asr);
      expect(asr.deepLink, 'prosoche://prayer?p=asr');
      expect(asr.channel, NotificationChannel.prayer);
    });
  });

  group('TimeOfDayHm', () {
    test('parse and format', () {
      expect(TimeOfDayHm.parse('07:30'), TimeOfDayHm.morningDefault);
      expect(TimeOfDayHm.parse('23:05').toString(), '23:05');
      expect(
        TimeOfDayHm.parse('07:30').hashCode,
        TimeOfDayHm.morningDefault.hashCode,
      );
      expect(() => TimeOfDayHm.parse('7:30'), throwsFormatException);
      expect(() => TimeOfDayHm.parse('24:00'), throwsFormatException);
    });
  });
}
