import 'package:prosoche/data/notifications/notification_platform.dart';
import 'package:prosoche/domain/notifications/notifications.dart';

/// [NotificationPlatform] v pamati: drzi naplanovane notifikacie ako system.
class FakeNotificationPlatform implements NotificationPlatform {
  final Map<int, ScheduledNotification> scheduled = {};
  final Map<int, bool> exactById = {};
  final List<String> calls = [];

  bool exactAllowed = true;

  /// Simuluje odobratie povolenia medzi kontrolou a planovanim.
  bool throwOnExact = false;
  bool enabled = true;
  bool grant = true;
  bool initialized = false;

  @override
  Future<void> initialize({void Function(String? payload)? onTap}) async {
    initialized = true;
  }

  @override
  Future<List<PendingNotification>> pending() async => [
    for (final n in scheduled.values) PendingNotification(n.id, n.payload),
  ];

  @override
  Future<void> schedule(
    ScheduledNotification notification, {
    required bool exact,
  }) async {
    if (exact && throwOnExact) throw const ExactAlarmNotPermittedException();
    calls.add('schedule ${notification.id}');
    scheduled[notification.id] = notification;
    exactById[notification.id] = exact;
  }

  @override
  Future<void> cancel(int id) async {
    calls.add('cancel $id');
    scheduled.remove(id);
    exactById.remove(id);
  }

  @override
  Future<bool> canScheduleExact() async => exactAllowed;

  @override
  Future<bool> requestExactAlarms() async => grant;

  @override
  Future<bool> requestPermission() async => grant;

  @override
  Future<bool> areEnabled() async => enabled;
}
