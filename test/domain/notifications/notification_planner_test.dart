import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/common/local_date.dart';
import 'package:prosoche/domain/notifications/notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

late tz.Location _ba;

NotificationPlanInput _input(
  DateTime now, {
  tz.Location? deviceZone,
  bool morning = true,
  TimeOfDayHm morningTime = TimeOfDayHm.morningDefault,
}) => NotificationPlanInput(
  now: now,
  deviceZone: deviceZone ?? _ba,
  morningEnabled: morning,
  morningTime: morningTime,
);

void main() {
  tzdata.initializeTimeZones();
  _ba = tz.getLocation('Europe/Bratislava');
  const planner = NotificationPlanner();

  // Utorok 3. 11. 2026, 06:00 v Bratislave.
  final now = tz.TZDateTime(_ba, 2026, 11, 3, 6);

  Iterable<PlannedNotification> mornings(NotificationPlan p) =>
      p.items.where((n) => n.kind == NotificationKind.morning);

  group('window and open-app reminder', () {
    test('10 days: 9 mornings + open-app on the last day', () {
      final plan = planner.plan(_input(now));
      expect(mornings(plan), hasLength(9));
      final last = plan.items.last;
      expect(last.kind, NotificationKind.openApp);
      expect(last.day, LocalDate(2026, 11, 12));
      expect(plan.length, 10);
      expect(plan.dropped, 0);
      expect(last.channel, NotificationChannel.system);
      expect(mornings(plan).first.channel, NotificationChannel.daily);
    });

    test('after the morning time today is skipped', () {
      final plan = planner.plan(_input(tz.TZDateTime(_ba, 2026, 11, 3, 9)));
      expect(mornings(plan).first.day, LocalDate(2026, 11, 4));
    });

    test('everything is in the future, sorted, unique ids', () {
      final plan = planner.plan(_input(now));
      expect(plan.items.every((n) => n.at.isAfter(now)), isTrue);
      final times = plan.items.map((n) => n.at).toList();
      expect(times, [...times]..sort());
      expect(plan.items.map((n) => n.id).toSet(), hasLength(plan.length));
    });

    test('small budget keeps earliest and the open-app reminder', () {
      final plan = const NotificationPlanner(maxPending: 4).plan(_input(now));
      // 3 ranne v rozpocte, posledna z nich ustupi vyzve na otvorenie.
      expect(plan.length, 3);
      expect(plan.dropped, 7);
      expect(plan.items.last.kind, NotificationKind.openApp);
    });

    test('without open-app reminder all mornings stay', () {
      final plan = const NotificationPlanner(openAppReminder: false)
          .plan(_input(now));
      expect(mornings(plan), hasLength(10));
      expect(
        plan.items.where((n) => n.kind == NotificationKind.openApp),
        isEmpty,
      );
    });

    test('morning disabled: nothing is planned', () {
      final plan = planner.plan(_input(now, morning: false));
      expect(plan.items, isEmpty);
    });
  });

  group('idempotency', () {
    test('same input gives identical plan', () {
      final a = planner.plan(_input(now));
      final b = planner.plan(_input(now));
      expect(b.items, a.items);
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

  group('DST and zones', () {
    test('morning stays at 07:30 local across the October switch', () {
      final start = tz.TZDateTime(_ba, 2026, 10, 20, 8);
      final plan = planner.plan(_input(start));
      final list = mornings(plan);
      expect(list.length, 8);
      for (final n in list) {
        final local = tz.TZDateTime.from(n.at, _ba);
        expect((local.hour, local.minute), (7, 30), reason: '$n');
      }
      expect(list.map((n) => n.at.timeZoneOffset).toSet(), hasLength(2));
    });

    test('morning time inside the spring gap still fires once', () {
      final start = tz.TZDateTime(_ba, 2027, 3, 27, 8);
      final plan = planner.plan(
        _input(start, morningTime: const TimeOfDayHm(2, 30)),
      );
      final onSwitch = plan.items.where((n) => n.day == LocalDate(2027, 3, 28));
      expect(onSwitch, hasLength(1));
    });

    test('morning follows the device zone', () {
      final ny = tz.getLocation('America/New_York');
      final plan = planner.plan(_input(now, deviceZone: ny));
      final first = mornings(plan).first;
      final local = tz.TZDateTime.from(first.at, ny);
      expect((local.hour, local.minute), (7, 30));
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
