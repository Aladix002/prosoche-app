import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:prosoche/data/notifications/notification_platform.dart';
import 'package:prosoche/domain/notifications/notifications.dart';

/// [NotificationPlatform] nad `flutter_local_notifications`.
///
/// Po restarte zariadenia naplanovane notifikacie obnovi receiver pluginu
/// `ScheduledNotificationBootReceiver` (AndroidManifest, BOOT_COMPLETED).
final class LocalNotificationsPlatform implements NotificationPlatform {
  LocalNotificationsPlatform([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Mala ikona notifikacie (docasne ikona appky, vid handoff P-02).
  static const androidIcon = '@mipmap/ic_launcher';

  /// Kod chyby pluginu pri presnom alarme bez povolenia.
  static const exactNotPermittedCode = 'exact_alarms_not_permitted';

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> initialize({void Function(String? payload)? onTap}) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(androidIcon),
        // Povolenie sa ziada az v onboardingu (O4), nie pri starte.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: onTap == null
          ? null
          : (response) => onTap(response.payload),
    );
  }

  @override
  Future<List<PendingNotification>> pending() async => [
    for (final r in await _plugin.pendingNotificationRequests())
      PendingNotification(r.id, r.payload),
  ];

  @override
  Future<void> schedule(
    ScheduledNotification notification, {
    required bool exact,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: notification.id,
        scheduledDate: notification.at,
        notificationDetails: details(notification),
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        title: notification.title,
        body: notification.body,
        payload: notification.payload,
      );
    } on PlatformException catch (e) {
      if (e.code == exactNotPermittedCode) {
        throw const ExactAlarmNotPermittedException();
      }
      rethrow;
    }
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<bool> canScheduleExact() async {
    final android = _android;
    if (android == null) return true;
    return await android.canScheduleExactNotifications() ?? false;
  }

  @override
  Future<bool> requestExactAlarms() async {
    final android = _android;
    if (android == null) return true;
    return await android.requestExactAlarmsPermission() ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    final android = _android;
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return await _ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<bool> areEnabled() async {
    final android = _android;
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = await _ios?.checkPermissions();
    return ios?.isEnabled ?? false;
  }

  /// Nastavenie kanala a viditelnosti (docs/01 7.5). Pripomienky su
  /// tiche (nizka dolezitost, bez zvuku a vibracie).
  static NotificationDetails details(ScheduledNotification n) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          n.channel.name,
          n.channelName,
          channelDescription: n.channelDescription,
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
          category: AndroidNotificationCategory.reminder,
          visibility: n.private
              ? NotificationVisibility.private
              : NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(presentSound: false),
      );
}
