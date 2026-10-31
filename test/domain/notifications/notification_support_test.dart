import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/common/local_date.dart';
import 'package:prosoche/domain/notifications/notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tzdata.initializeTimeZones();
  final utc = tz.getLocation('UTC');

  PlannedNotification morning(LocalDate day, {int hour = 7}) =>
      PlannedNotification(
        kind: NotificationKind.morning,
        day: day,
        at: tz.TZDateTime(utc, day.year, day.month, day.day, hour),
        cardMinutes: 10,
      );

  group('NotificationIds', () {
    test('deterministic and distinct per day and slot', () {
      final d = LocalDate(2026, 11, 3);
      final ids = {
        NotificationIds.of(NotificationKind.morning, d),
        NotificationIds.of(NotificationKind.openApp, d),
        NotificationIds.of(NotificationKind.morning, d.addDays(1)),
      };
      expect(ids, hasLength(3));
      expect(
        NotificationIds.of(NotificationKind.morning, d),
        NotificationIds.of(NotificationKind.morning, d),
      );
      expect(ids.every(NotificationIds.isPlanned), isTrue);
    });

    test('rejects invalid input', () {
      expect(
        () =>
            NotificationIds.of(NotificationKind.morning, LocalDate(2019, 1, 1)),
        throwsArgumentError,
      );
      expect(
        () => PlannedNotification(
          kind: NotificationKind.openApp,
          day: LocalDate(2019, 12, 31),
          at: tz.TZDateTime(utc, 2019),
        ),
        throwsArgumentError,
      );
    });

    test('immediate notification ids are outside the planned range', () {
      expect(NotificationIds.isPlanned(0), isFalse);
      expect(NotificationIds.isPlanned(-5), isFalse);
      expect(NotificationIds.isPlanned(NotificationIds.plannedLimit), isFalse);
      expect(NotificationIds.isPlanned(2000000001), isFalse);
    });
  });

  group('PlannedNotification', () {
    test('equality by id and fingerprint', () {
      final d = LocalDate(2026, 11, 3);
      expect(morning(d), morning(d));
      expect(morning(d).hashCode, morning(d).hashCode);
      expect(morning(d) == morning(d, hour: 8), isFalse);
      expect(morning(d).toString(), contains('morning'));
      expect(morning(d).deepLink, 'prosoche://today');
    });
  });

  group('diffNotifications', () {
    final d = LocalDate(2026, 11, 3);
    String payload(PlannedNotification n) => 'v1|${n.fingerprint}';

    test('schedules new, cancels stale, keeps same', () {
      final keep = morning(d);
      final changed = morning(d.addDays(1));
      final fresh = morning(d.addDays(2));
      final stale = morning(d.addDays(-1));
      final diff = diffNotifications(
        pending: [
          PendingNotification(keep.id, payload(keep)),
          PendingNotification(changed.id, 'v1|old'),
          PendingNotification(stale.id, payload(stale)),
          const PendingNotification(2000000001, 'gate'),
        ],
        planned: [keep, changed, fresh],
        payloadOf: payload,
      );
      expect(diff.cancel, [stale.id, changed.id]..sort());
      expect(diff.schedule, [changed, fresh]);
      expect(diff.unchanged, 1);
      expect(diff.isEmpty, isFalse);
    });

    test('pending without payload is replaced', () {
      final n = morning(d);
      final diff = diffNotifications(
        pending: [PendingNotification(n.id, null)],
        planned: [n],
        payloadOf: payload,
      );
      expect(diff.cancel, [n.id]);
      expect(diff.schedule, [n]);
    });

    test('PendingNotification value semantics', () {
      expect(
        const PendingNotification(1, 'a'),
        const PendingNotification(1, 'a'),
      );
      expect(
        const PendingNotification(1, 'a').hashCode,
        const PendingNotification(1, 'a').hashCode,
      );
      expect(const PendingNotification(1, 'a').toString(), contains('1'));
    });
  });
}
