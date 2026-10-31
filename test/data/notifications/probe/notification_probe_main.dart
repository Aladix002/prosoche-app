// Rucne overenie P-02 na emulatore/zariadeni (nie je to unit test).
//
//   flutter build apk --debug --flavor devLite \
//     -t test/data/notifications/probe/notification_probe_main.dart
//   adb install -r build/app/outputs/flutter-apk/app-devlite-debug.apk
//   adb shell am start -n app.mursa.dev/app.mursa.MainActivity
//
// Naplanuje plan pre Bratislavu (NotificationService, standardne texty)
// a dve testovacie notifikacie o +1 a +4 minuty mimo rozsahu planu.
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:sakina/data/notifications/notifications.dart';
import 'package:sakina/domain/notifications/notifications.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../fakes/in_memory_settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(home: _Probe(run: _run())));
}

Future<String> _run() async {
  NotificationService.ensureTimeZones();
  final platform = LocalNotificationsPlatform();
  await platform.initialize();
  final permission = await platform.requestPermission();
  final settings = InMemorySettingsRepository();
  await settings.set(
    SettingsKeys.prayerLocation,
    PrayerLocation(
      lat: 48.15,
      lng: 17.11,
      country: 'SK',
      tz: 'Europe/Bratislava',
      city: 'Bratislava',
    ),
  );
  await settings.set(SettingsKeys.notifPrivateLockscreen, false);
  final zone = (await FlutterTimezone.getLocalTimezone()).identifier;
  final service = NotificationService(
    settings: settings,
    platform: platform,
    timeZones: SharedPrefsTimeZoneStore(),
    deviceZone: () async => zone,
  );
  final result = await service.reschedule();

  final exact = await platform.canScheduleExact();
  final now = tz.TZDateTime.now(tz.getLocation(zone));
  for (final (id, minutes) in [(2000000101, 1), (2000000104, 4)]) {
    await platform.schedule(
      ScheduledNotification(
        id: id,
        channel: NotificationChannel.system,
        channelName: 'App messages',
        channelDescription: 'P-02 probe',
        at: now.add(Duration(minutes: minutes)),
        title: 'P-02 probe +$minutes min',
        body: 'Scheduled at ${now.hour}:${now.minute}',
        payload: '',
        private: false,
      ),
      exact: exact,
    );
  }
  final pending = await platform.pending();
  return 'zone=$zone permission=$permission exact=$exact\n'
      'planned=${result.planned} scheduled=${result.scheduled} '
      'paused=${result.prayersPaused}\npending=${pending.length}';
}

class _Probe extends StatelessWidget {
  const _Probe({required this.run});

  final Future<String> run;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: FutureBuilder<String>(
        future: run,
        builder: (context, snap) => Text(
          snap.hasError ? 'P02 ERROR ${snap.error}' : 'P02 ${snap.data ?? '-'}',
        ),
      ),
    ),
  );
}
