import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/data/notifications/notification_background.dart';
import 'package:prosoche/data/notifications/notification_service.dart';
import 'package:prosoche/data/notifications/notification_triggers.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:workmanager/workmanager.dart';

import '../../fakes/in_memory_settings_repository.dart';
import 'fake_notification_platform.dart';

class _MockWorkmanager extends Mock implements Workmanager;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationTriggers', () {
    late InMemorySettingsRepository settings;
    late int runs;
    late NotificationTriggers triggers;
    late RingBufferLog log;
    var fail = false;

    setUp(() {
      settings = InMemorySettingsRepository();
      runs = 0;
      fail = false;
      log = RingBufferLog();
      triggers = NotificationTriggers(
        settings: settings,
        reschedule: () async {
          runs++;
          if (fail) throw StateError('boom');
        },
        debounce: const Duration(milliseconds: 20),
        logger: AppLogger(sinks: [log], echoToConsole: false),
      );
    });

    tearDown(() => triggers.dispose());

    test('start reschedules once', () async {
      await triggers.start();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(runs, 1);
    });

    test('settings changes are debounced into one run', () async {
      await triggers.start();
      await settings.set(SettingsKeys.notifMorningTime, '08:00');
      await settings.set(SettingsKeys.notifPrivateLockscreen, false);
      await settings.set(SettingsKeys.notifPrayer('fajr'), false);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(runs, 2);
    });

    test('unrelated settings do not reschedule', () async {
      await triggers.start();
      await settings.set(SettingsKeys.simpleMode, true);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(runs, 1);
    });

    test('app resume reschedules', () async {
      await triggers.start();
      TestWidgetsFlutterBinding.instance
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
        ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(runs, 2);
    });

    test('errors are logged, not thrown', () async {
      fail = true;
      await triggers.start();
      expect(runs, 1);
      expect(log.entries.single.msg, 'reschedule failed');
    });

    test('watched keys cover location, method and notification keys', () {
      final names = NotificationTriggers.watchedKeys.map((k) => k.name);
      expect(
        names,
        containsAll([
          'prayer.location',
          'notif.prayer.isha',
          'notif.morning.time',
          'notif.private_lockscreen',
        ]),
      );
    });
  });

  group('NotificationBackground', () {
    test('handles its task names only', () {
      expect(NotificationBackground.handles('notificationsReschedule'), isTrue);
      expect(
        NotificationBackground.handles(NotificationBackground.uniqueName),
        isTrue,
      );
      expect(NotificationBackground.handles('contentUpdate'), isFalse);
    });

    test('registers a 12 h periodic task with update policy', () async {
      final wm = _MockWorkmanager();
      when(
        () => wm.registerPeriodicTask(
          any(),
          any(),
          frequency: any(named: 'frequency'),
          existingWorkPolicy: any(named: 'existingWorkPolicy'),
        ),
      ).thenAnswer((_) async {});
      when(() => wm.cancelByUniqueName(any())).thenAnswer((_) async {});
      await NotificationBackground.register(wm);
      verify(
        () => wm.registerPeriodicTask(
          NotificationBackground.uniqueName,
          NotificationBackground.taskName,
          frequency: const Duration(hours: 12),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        ),
      ).called(1);
      await NotificationBackground.cancel(wm);
      verify(() => wm.cancelByUniqueName(NotificationBackground.uniqueName))
          .called(1);
    });

    test('run reschedules and reports success or failure', () async {
      final platform = FakeNotificationPlatform();
      final log = RingBufferLog();
      final ok = await NotificationBackground.run(
        () async => NotificationService(
          settings: InMemorySettingsRepository(),
          platform: platform,
          timeZones: MemoryTimeZoneStore(),
          deviceZone: () async => 'Europe/Bratislava',
        ),
      );
      expect(ok, isTrue);
      expect(platform.scheduled, isNotEmpty);

      final failed = await NotificationBackground.run(
        () async => throw StateError('no db'),
        logger: AppLogger(sinks: [log], echoToConsole: false),
      );
      expect(failed, isFalse);
      expect(log.entries.single.kv['type'], 'StateError');
    });
  });
}
