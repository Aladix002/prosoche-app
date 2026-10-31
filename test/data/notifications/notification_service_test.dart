import 'dart:ui';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/l10n/generated/app_localizations.dart';
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/data/notifications/notification_platform.dart';
import 'package:prosoche/data/notifications/notification_service.dart';
import 'package:prosoche/data/notifications/notification_texts.dart';
import 'package:prosoche/domain/common/local_date.dart';
import 'package:prosoche/domain/notifications/notifications.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../fakes/in_memory_settings_repository.dart';
import 'fake_notification_platform.dart';

void main() {
  NotificationService.ensureTimeZones();
  final ba = tz.getLocation('Europe/Bratislava');
  // Utorok 3. 11. 2026, 06:00 v Bratislave.
  final now = tz.TZDateTime(ba, 2026, 11, 3, 6);

  late InMemorySettingsRepository settings;
  late FakeNotificationPlatform platform;
  late MemoryTimeZoneStore zones;
  late String deviceZone;
  late RingBufferLog log;
  late NotificationService service;
  late Set<LocalDate> excused;

  NotificationService build({Locale system = const Locale('en')}) =>
      NotificationService(
        settings: settings,
        platform: platform,
        timeZones: zones,
        deviceZone: () async => deviceZone,
        clock: Clock.fixed(now),
        logger: AppLogger(sinks: [log], echoToConsole: false),
        systemLocale: () async => system,
        excusedDays: () async => excused,
      );

  setUp(() async {
    settings = InMemorySettingsRepository();
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
    platform = FakeNotificationPlatform();
    zones = MemoryTimeZoneStore();
    deviceZone = 'Europe/Bratislava';
    log = RingBufferLog();
    excused = {};
    service = build();
  });

  Iterable<ScheduledNotification> prayers() => platform.scheduled.values.where(
    (n) => n.channel == NotificationChannel.prayer,
  );

  group('reschedule', () {
    test('first run schedules the whole plan and records the zone', () async {
      final r = await service.reschedule();
      expect(r.planned, platform.scheduled.length);
      expect(r.planned, lessThanOrEqualTo(64));
      expect(r.scheduled, r.planned);
      expect(r.cancelled, 0);
      expect(r.exact, isTrue);
      expect(r.prayersPaused, isFalse);
      expect(r.dropped, 0);
      expect(r.deviceZone, 'Europe/Bratislava');
      expect(zones.zone, 'Europe/Bratislava');
      expect(prayers(), isNotEmpty);
      expect(platform.exactById.values.every((e) => e), isTrue);
      expect(log.entries.last.kv['status'], 'exact');
    });

    test('second run is a no-op (idempotent)', () async {
      await service.reschedule();
      platform.calls.clear();
      final r = await service.reschedule();
      expect(r.scheduled, 0);
      expect(r.cancelled, 0);
      expect(platform.calls, isEmpty);
    });

    test('parallel calls run one after another', () async {
      final results = await Future.wait([
        service.reschedule(),
        service.reschedule(),
      ]);
      expect(results.first.scheduled, greaterThan(0));
      expect(results.last.scheduled, 0);
    });

    test('immediate notifications outside the planned range survive', () async {
      platform.scheduled[2000000001] = ScheduledNotification(
        id: 2000000001,
        channel: NotificationChannel.system,
        channelName: 'x',
        channelDescription: 'x',
        at: now,
        title: 'Gate is paused',
        body: 'x',
        payload: '',
        private: false,
      );
      await service.reschedule();
      expect(platform.scheduled.containsKey(2000000001), isTrue);
    });

    test('changing morning time reschedules only mornings', () async {
      await service.reschedule();
      platform.calls.clear();
      await settings.set(SettingsKeys.notifMorningTime, '08:15');
      final r = await service.reschedule();
      // 8 rannych (dnesna 07:30 este pride, posledna je vyzva) + vyzva.
      expect(r.scheduled, lessThanOrEqualTo(11));
      expect(r.scheduled, greaterThan(0));
      final morning = platform.scheduled.values.firstWhere(
        (n) => n.channel == NotificationChannel.daily,
      );
      expect((morning.at.hour, morning.at.minute), (8, 15));
    });

    test('disabling a prayer cancels its notifications', () async {
      await service.reschedule();
      await settings.set(SettingsKeys.notifPrayer('asr'), false);
      final r = await service.reschedule();
      expect(r.cancelled, greaterThan(0));
      expect(prayers().any((n) => n.body.contains('Asr')), isFalse);
    });

    test('excused days skip prayers', () async {
      excused = {LocalDate(2026, 11, 4)};
      await service.reschedule();
      final onDay = prayers().where(
        (n) => tz.TZDateTime.from(n.at, ba).day == 4,
      );
      expect(onDay, isEmpty);
    });

    test('without location only daily reminders', () async {
      await settings.reset(SettingsKeys.prayerLocation);
      await service.reschedule();
      expect(prayers(), isEmpty);
      expect(platform.scheduled, isNotEmpty);
    });

    test('unknown device zone falls back to UTC and logs', () async {
      deviceZone = 'Mars/Olympus';
      zones.zone = 'Mars/Olympus';
      final r = await service.reschedule();
      expect(r.planned, greaterThan(0));
      expect(log.entries.any((e) => e.kv['code'] == 'tz_unknown'), isTrue);
    });
  });

  group('time zone change', () {
    test('pauses prayers until confirmed, morning stays', () async {
      await service.reschedule();
      final before = prayers().length;
      expect(before, greaterThan(0));

      deviceZone = 'Europe/Istanbul';
      final paused = await service.reschedule();
      expect(paused.prayersPaused, isTrue);
      expect(paused.cancelled, greaterThanOrEqualTo(before));
      expect(prayers(), isEmpty);
      expect(
        platform.scheduled.values.where(
          (n) => n.channel == NotificationChannel.daily,
        ),
        isNotEmpty,
      );
      expect(log.entries.last.kv['status'], 'tz_paused');

      final confirmed = await service.confirmTimeZone();
      expect(confirmed.prayersPaused, isFalse);
      expect(zones.zone, 'Europe/Istanbul');
      expect(prayers(), hasLength(before));
    });

    test('zone with the same rules does not pause', () async {
      await service.reschedule();
      deviceZone = 'Europe/Prague';
      final r = await service.reschedule();
      expect(r.prayersPaused, isFalse);
    });
  });

  group('exact alarms', () {
    test('inexact fallback when not allowed, exact after grant', () async {
      platform.exactAllowed = false;
      final inexact = await service.reschedule();
      expect(inexact.exact, isFalse);
      expect(platform.exactById.values.every((e) => !e), isTrue);
      expect(log.entries.last.kv['status'], 'inexact');

      platform.exactAllowed = true;
      final exact = await service.reschedule();
      expect(exact.exact, isTrue);
      expect(exact.scheduled, exact.planned);
      expect(platform.exactById.values.every((e) => e), isTrue);
    });

    test('permission revoked mid-run falls back to inexact', () async {
      platform.throwOnExact = true;
      final r = await service.reschedule();
      expect(r.exact, isFalse);
      expect(platform.scheduled, isNotEmpty);
      expect(platform.exactById.values.every((e) => !e), isTrue);
    });

    test('permission requests are logged without data', () async {
      expect(await service.requestExactAlarms(), isTrue);
      platform.grant = false;
      expect(await service.requestPermission(), isFalse);
      expect(await service.canScheduleExact(), isTrue);
      expect(await service.areEnabled(), isTrue);
      final kv = log.entries.map((e) => e.kv).toList();
      expect(
        kv,
        contains(equals({'permission': 'exact_alarm', 'granted': true})),
      );
      expect(
        kv,
        contains(equals({'permission': 'notifications', 'granted': false})),
      );
    });
  });

  group('texts', () {
    test('private mode (default) uses neutral text', () async {
      await service.reschedule();
      for (final n in prayers()) {
        expect(n.title, startsWith('Prosoche · '));
        expect(n.body, 'Reminder');
        expect(n.private, isTrue);
      }
      final daily = platform.scheduled.values.firstWhere(
        (n) => n.channel == NotificationChannel.daily,
      );
      expect(daily.title, 'Prosoche');
      expect(daily.body, 'Your daily reminder');
    });

    test('standard mode names the prayer and time', () async {
      await settings.set(SettingsKeys.notifPrivateLockscreen, false);
      await service.reschedule();
      final asr = prayers().firstWhere((n) => n.body.contains('Asr'));
      final local = tz.TZDateTime.from(asr.at, ba);
      final hm =
          '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
      expect(asr.title, 'Asr · $hm');
      expect(asr.body, "It's time for Asr.");
      expect(asr.private, isFalse);
      expect(asr.channelName, 'Prayer times');
      expect(prayers().where((n) => n.title.startsWith("Jumu'ah")), isNotEmpty);
      final morning = platform.scheduled.values.firstWhere(
        (n) => n.channel == NotificationChannel.daily,
      );
      expect(morning.title, 'Good morning');
      expect(morning.body, "Today's cards are ready. About 10 minutes.");
      final open = platform.scheduled.values.singleWhere(
        (n) => n.channel == NotificationChannel.system,
      );
      expect(open.title, 'Prayer reminders paused soon');
      expect(open.body, contains('Prosoche'));
    });

    test('switching private mode re-renders all notifications', () async {
      await service.reschedule();
      await settings.set(SettingsKeys.notifPrivateLockscreen, false);
      final r = await service.reschedule();
      expect(r.scheduled, r.planned);
    });

    test('payload carries the deep link', () async {
      await service.reschedule();
      final n = prayers().first;
      expect(
        NotificationService.deepLinkOf(n.payload),
        startsWith('prosoche://prayer?p='),
      );
      expect(NotificationService.deepLinkOf(null), isNull);
      expect(NotificationService.deepLinkOf(''), isNull);
      expect(NotificationService.deepLinkOf('not json'), isNull);
      expect(NotificationService.deepLinkOf('{"v":1}'), isNull);
    });

    test('ui.locale wins over system locale, unsupported falls back', () async {
      await settings.set(SettingsKeys.uiLocale, 'xx');
      service = build(system: const Locale('ar'));
      await service.reschedule();
      expect(prayers().first.body, 'Reminder');
      await settings.reset(SettingsKeys.uiLocale);
      await service.reschedule();
      expect(platform.scheduled, isNotEmpty);
    });

    test('no notification text names Allah, in any locale or mode', () async {
      final zone = tz.getLocation('Europe/Bratislava');
      final day = LocalDate(2026, 11, 6);
      final at = tz.TZDateTime(zone, 2026, 11, 6, 12);
      final samples = [
        for (final p in Prayer.salah)
          PlannedNotification(
            kind: NotificationKind.prayer,
            day: day,
            at: at,
            prayer: p,
          ),
        PlannedNotification(
          kind: NotificationKind.jumuah,
          day: day,
          at: at,
          prayer: Prayer.dhuhr,
        ),
        PlannedNotification(
          kind: NotificationKind.morning,
          day: day,
          at: at,
          cardMinutes: 1,
        ),
        PlannedNotification(
          kind: NotificationKind.morningEvent,
          day: day,
          at: at,
          eventName: 'Test',
        ),
        PlannedNotification(kind: NotificationKind.openApp, day: day, at: at),
      ];
      for (final locale in AppLocalizations.supportedLocales) {
        final texts = await NotificationTexts.load(locale);
        for (final n in samples) {
          for (final private in [true, false]) {
            final (title, body) = texts.render(n, private: private);
            expect(title, isNotEmpty);
            expect(body, isNotEmpty);
            expect(
              NotificationContentPolicy.allows(title) &&
                  NotificationContentPolicy.allows(body),
              isTrue,
              reason: '$locale $n $private: $title / $body',
            );
          }
        }
        for (final c in NotificationChannel.values) {
          expect(texts.channelName(c), isNotEmpty);
          expect(texts.channelDescription(c), isNotEmpty);
        }
      }
    });

    test('event name with the name of Allah falls back to private', () async {
      final texts = await NotificationTexts.load(const Locale('en'));
      final n = PlannedNotification(
        kind: NotificationKind.morningEvent,
        day: LocalDate(2026, 11, 6),
        at: tz.TZDateTime(ba, 2026, 11, 6, 7, 30),
        eventName: 'Allah test',
      );
      expect(texts.render(n, private: false), (
        'Prosoche',
        'Your daily reminder',
      ));
      expect(texts.localeName, 'en');
    });
  });
}
