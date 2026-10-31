import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/repositories/infra/time_providers.dart';
import 'package:prosoche/data/repositories/prayer/city_repository.dart';
import 'package:prosoche/data/repositories/prayer/prayer_repository.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/prayer/calc_settings.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:prosoche/domain/prayer/prayer_schedule.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:timezone/timezone.dart' as tz;

import '../harness.dart';

void main() {
  late Harness h;
  final thu = LocalDate(2026, 10, 29);

  setUp(() async => h = await Harness.create());
  tearDown(() => h.dispose());

  final bratislava = PrayerLocation(
    lat: 48.15,
    lng: 17.11,
    country: 'SK',
    tz: 'Europe/Bratislava',
    city: 'Bratislava',
  );
  final karachi = PrayerLocation(
    lat: 24.86,
    lng: 67.01,
    country: 'PK',
    tz: 'Asia/Karachi',
  );

  group('settings', () {
    test('no location = no config', () async {
      expect(await h.prayer.config(), isNull);
    });

    test('saving location writes country asr when not stored', () async {
      await h.prayer.saveLocation(karachi);
      final c = (await h.prayer.config())!;
      expect(c.settings.method, PrayerMethod.karachi);
      expect(c.settings.asr, AsrMadhab.hanafi);
      expect(h.prayerChanges, 1);

      // Ulozene asr sa pri dalsej zmene polohy nemeni.
      await h.prayer.saveLocation(bratislava);
      expect((await h.prayer.config())!.settings.asr, AsrMadhab.hanafi);
      await h.prayer.saveLocation(bratislava, resetAsr: true);
      expect((await h.prayer.config())!.settings.asr, AsrMadhab.shafi);
    });

    test('manual method keeps asr', () async {
      await h.prayer.setMethod(PrayerMethod.egyptian);
      await h.prayer.saveLocation(karachi);
      final c = (await h.prayer.config())!;
      expect(c.settings.method, PrayerMethod.egyptian);
      expect(c.settings.asr, AsrMadhab.shafi);
      await h.prayer.setMethod(null);
      expect(await h.settings.get(SettingsKeys.prayerMethod), isNull);
    });

    test('asr, high latitude rule and adjust', () async {
      await h.prayer.saveLocation(bratislava);
      await h.prayer.setAsr(AsrMadhab.hanafi);
      await h.prayer.setHighLatRule(HighLatRule.seventhOfNight);
      await h.prayer.setAdjust(Prayer.fajr, 2);
      var s = (await h.prayer.config())!.settings;
      expect(s.asr, AsrMadhab.hanafi);
      expect(s.highLatRule, HighLatRule.seventhOfNight);
      expect(s.adjust, {Prayer.fajr: 2});
      await h.prayer.setAdjust(Prayer.fajr, 0);
      await h.prayer.setHighLatRule(null);
      s = (await h.prayer.config())!.settings;
      expect(s.adjust, isEmpty);
      expect(s.highLatRule, HighLatRule.middleOfNight);
      expect(h.prayerChanges, 6);
      expect(() => h.prayer.setAdjust(Prayer.sunrise, 1), throwsArgumentError);
      expect(() => h.prayer.setAdjust(Prayer.asr, 31), throwsRangeError);
    });

    test('watchConfig emits on change', () async {
      final configs = h.prayer.watchConfig().where((c) => c != null);
      await h.prayer.saveLocation(bratislava);
      final c = await configs.first;
      expect(c!.location, bratislava);
      expect(c, PrayerConfig(bratislava, c.settings));
      expect(c.hashCode, PrayerConfig(bratislava, c.settings).hashCode);
    });
  });

  group('prayer_log', () {
    test('set, watch and clear', () async {
      await h.prayer.setStatus(thu, Prayer.asr, PrayerStatus.onTime);
      await h.prayer.setStatus(thu, Prayer.isha, PrayerStatus.qada);
      expect(await h.prayer.watchLog(thu).first, {
        Prayer.asr: PrayerStatus.onTime,
        Prayer.isha: PrayerStatus.qada,
      });
      await h.prayer.clearStatus(thu, Prayer.asr);
      expect(await h.prayer.watchLog(thu).first, {
        Prayer.isha: PrayerStatus.qada,
      });
      expect(
        () => h.prayer.setStatus(thu, Prayer.sunrise, PrayerStatus.late),
        throwsArgumentError,
      );
    });
  });

  group('PrayerTracker', () {
    late PrayerSchedule schedule;
    setUp(() async {
      ensureTimeZoneData();
      await h.prayer.saveLocation(bratislava);
      schedule = (await h.prayer.config())!.schedule;
    });

    DateTime at(LocalDate d, Prayer p, {int plusMinutes = 0}) =>
        schedule.day(d)[p].add(Duration(minutes: plusMinutes));

    test('on time before the next prayer, late after, future disabled', () {
      expect(
        PrayerTracker.statusForTap(
          schedule,
          thu,
          Prayer.asr,
          at(thu, Prayer.asr, plusMinutes: 9),
        ),
        PrayerStatus.onTime,
      );
      expect(
        PrayerTracker.statusForTap(
          schedule,
          thu,
          Prayer.asr,
          at(thu, Prayer.maghrib, plusMinutes: 1),
        ),
        PrayerStatus.late,
      );
      expect(
        PrayerTracker.statusForTap(
          schedule,
          thu,
          Prayer.isha,
          at(thu, Prayer.asr),
        ),
        isNull,
      );
      expect(
        PrayerTracker.statusForTap(
          schedule,
          thu,
          Prayer.fajr,
          at(thu, Prayer.sunrise, plusMinutes: 1),
        ),
        PrayerStatus.late,
      );
      expect(
        PrayerTracker.statusForTap(
          schedule,
          thu,
          Prayer.isha,
          at(thu.addDays(1), Prayer.fajr, plusMinutes: -5),
        ),
        PrayerStatus.onTime,
      );
      for (final p in [Prayer.dhuhr, Prayer.maghrib]) {
        expect(
          PrayerTracker.statusForTap(schedule, thu, p, at(thu, p)),
          PrayerStatus.onTime,
        );
      }
      expect(
        PrayerTracker.statusForTap(null, thu, Prayer.fajr, DateTime(2026)),
        PrayerStatus.onTime,
      );
      expect(
        () => PrayerTracker.statusForTap(
          schedule,
          thu,
          Prayer.sunrise,
          DateTime(2026),
        ),
        throwsArgumentError,
      );
    });

    test('after midnight before fajr the tracker shows yesterday', () {
      final zone = tz.getLocation('Europe/Bratislava');
      final night = tz.TZDateTime(zone, 2026, 10, 30, 1);
      expect(PrayerTracker.trackerDate(schedule, night), thu);
      final morning = tz.TZDateTime(zone, 2026, 10, 30, 9);
      expect(PrayerTracker.trackerDate(schedule, morning), thu.addDays(1));
      expect(
        PrayerTracker.trackerDate(null, DateTime(2026, 10, 30, 1)),
        thu.addDays(1),
      );
    });

    test('day boundaries for the feed phase', () {
      final b = PrayerTracker.dayBoundaries(schedule, thu)!;
      expect(b.fajr.isBefore(b.dhuhr), isTrue);
      expect(b.asr.isBefore(b.isha), isTrue);
    });
  });

  group('CityRepository', () {
    test('search and nearest with country names', () async {
      final repo = ContentCityRepository(Future.value(h.content));
      final found = await repo.search('Bra');
      expect(found.single.label, 'Bratislava, Slovakia');
      expect(found.single.toPrayerLocation().tz, 'Europe/Bratislava');
      expect(await repo.search('  '), isEmpty);
      final near = (await repo.nearest(48.2, 17.1))!;
      expect(near.name, 'Bratislava');
      expect(near, found.single);
      expect(near.hashCode, found.single.hashCode);
      expect('$near', contains('Bratislava'));
      expect(await repo.nearest(-80, -170), isNull);
    });
  });
}
