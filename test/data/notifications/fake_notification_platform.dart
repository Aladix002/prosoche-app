import 'package:prosoche/data/notifications/notification_platform.dart';
import 'package:prosoche/domain/notifications/notifications.dart';

/// [NotificationPlatform] v pamati: drzi naplanovane notifikacie ako system.
/// Vsetky su nepresne (inexact, F-01).
class FakeNotificationPlatform implements NotificationPlatform {
  final Map<int, ScheduledNotification> scheduled = {};
  final List<String> calls = [];

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
  Future<void> schedule(ScheduledNotification notification) async {
    calls.add('schedule ${notification.id}');
    scheduled[notification.id] = notification;
  }

  @override
  Future<void> cancel(int id) async {
    calls.add('cancel $id');
    scheduled.remove(id);
  }

  @override
  Future<bool> requestPermission() async => grant;

  @override
  Future<bool> areEnabled() async => enabled;
}
