import 'package:meta/meta.dart';
import 'package:sakina/domain/notifications/notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Hotova notifikacia na naplanovanie (text uz je vybrany a prelozeny).
@immutable
final class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.channel,
    required this.channelName,
    required this.channelDescription,
    required this.at,
    required this.title,
    required this.body,
    required this.payload,
    required this.private,
  });

  final int id;
  final NotificationChannel channel;
  final String channelName;
  final String channelDescription;
  final tz.TZDateTime at;
  final String title;
  final String body;
  final String payload;

  /// Sukromny rezim: neutralny text a `VISIBILITY_PRIVATE` (docs/01 D8).
  final bool private;
}

/// Presny alarm nie je povoleny (Android 12+ bez `SCHEDULE_EXACT_ALARM`).
final class ExactAlarmNotPermittedException implements Exception {
  const ExactAlarmNotPermittedException();

  @override
  String toString() => 'ExactAlarmNotPermittedException';
}

/// Tenka vrstva nad systemovymi notifikaciami (flutter_local_notifications).
///
/// Oddelena kvoli testom: `NotificationService` testuje logiku nad
/// fake implementaciou, `LocalNotificationsPlatform` kanal pluginu.
abstract interface class NotificationPlatform {
  /// Inicializacia pluginu. [onTap] dostane payload kliknutej notifikacie.
  Future<void> initialize({void Function(String? payload)? onTap});

  /// Cakajuce naplanovane notifikacie.
  Future<List<PendingNotification>> pending();

  /// Naplanuje [notification]. Pri [exact] bez povolenia hodi
  /// [ExactAlarmNotPermittedException].
  Future<void> schedule(
    ScheduledNotification notification, {
    required bool exact,
  });

  Future<void> cancel(int id);

  /// Smie appka planovat presne alarmy (iOS vzdy true).
  Future<bool> canScheduleExact();

  /// Otvori systemovu obrazovku `ACTION_REQUEST_SCHEDULE_EXACT_ALARM`.
  Future<bool> requestExactAlarms();

  /// Runtime povolenie notifikacii (Android 13+ `POST_NOTIFICATIONS`, iOS).
  Future<bool> requestPermission();

  /// Su notifikacie appky zapnute.
  Future<bool> areEnabled();
}
