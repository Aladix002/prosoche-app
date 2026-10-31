import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/notifications/local_notifications_platform.dart';
import 'package:prosoche/data/notifications/notification_platform.dart';
import 'package:prosoche/data/notifications/notification_service.dart';
import 'package:prosoche/domain/notifications/notifications.dart';
import 'package:timezone/timezone.dart' as tz;

const _channel = MethodChannel('dexterous.com/flutter/local_notifications');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  NotificationService.ensureTimeZones();
  final ba = tz.getLocation('Europe/Bratislava');

  late List<MethodCall> calls;

  ScheduledNotification notification(
    NotificationChannel channel, {
    bool private = true,
  }) => ScheduledNotification(
    id: 42,
    channel: channel,
    channelName: 'Daily',
    channelDescription: 'desc',
    at: tz.TZDateTime(ba, 2030, 1, 1, 12),
    title: 'Prosoche · 12:00',
    body: 'Reminder',
    payload: '{"v":1}',
    private: private,
  );

  group('android', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
            calls.add(call);
            switch (call.method) {
              case 'pendingNotificationRequests':
                return [
                  {'id': 7, 'title': 't', 'body': 'b', 'payload': 'p'},
                ];
              case 'zonedSchedule':
                final args = call.arguments as Map<Object?, Object?>;
                if (args['id'] == 13) throw PlatformException(code: 'other');
                return null;
              case 'initialize':
              case 'requestNotificationsPermission':
              case 'areNotificationsEnabled':
                return true;
            }
            return null;
          });
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null);
    });

    test('initialize, pending, cancel and permissions', () async {
      final platform = LocalNotificationsPlatform();
      String? tapped;
      await platform.initialize(onTap: (p) => tapped = p);
      expect(calls.single.method, 'initialize');
      expect(tapped, isNull);
      expect(await platform.pending(), [const PendingNotification(7, 'p')]);
      await platform.cancel(7);
      expect(calls.last.method, 'cancel');
      expect(await platform.requestPermission(), isTrue);
      expect(await platform.areEnabled(), isTrue);
      await LocalNotificationsPlatform().initialize();
    });

    test('every reminder is inexact (inexactAllowWhileIdle)', () async {
      final platform = LocalNotificationsPlatform();
      await platform.schedule(notification(NotificationChannel.daily));
      final args = calls.single.arguments as Map<Object?, Object?>;
      final specifics = args['platformSpecifics']! as Map;
      expect(specifics['scheduleMode'], 'inexactAllowWhileIdle');
      expect(specifics['channelId'], 'daily');
      expect(args['title'], 'Prosoche · 12:00');
      expect(args['payload'], '{"v":1}');
    });

    test('other platform errors are rethrown', () async {
      final platform = LocalNotificationsPlatform();
      final n = ScheduledNotification(
        id: 13,
        channel: NotificationChannel.system,
        channelName: 'x',
        channelDescription: 'x',
        at: tz.TZDateTime(ba, 2030),
        title: 't',
        body: 'b',
        payload: '',
        private: false,
      );
      await expectLater(
        platform.schedule(n),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  group('details', () {
    test('system channel: silent, private visibility', () {
      final d = LocalNotificationsPlatform.details(
        notification(NotificationChannel.system),
      ).android!;
      expect(d.channelId, 'system');
      expect(d.importance, Importance.low);
      expect(d.playSound, isFalse);
      expect(d.visibility, NotificationVisibility.private);
    });

    test('daily channel: low importance, silent, public when allowed', () {
      final d = LocalNotificationsPlatform.details(
        notification(NotificationChannel.daily, private: false),
      ).android!;
      expect(d.channelId, 'daily');
      expect(d.importance, Importance.low);
      expect(d.playSound, isFalse);
      expect(d.visibility, NotificationVisibility.public);
    });
  });

  group('non-android', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    });
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('permission unknown off Android/iOS', () async {
      final platform = LocalNotificationsPlatform();
      expect(await platform.requestPermission(), isFalse);
      expect(await platform.areEnabled(), isFalse);
    });
  });
}
