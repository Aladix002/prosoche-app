import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/domain/prayer/calc_settings.dart';
import 'package:sakina/domain/prayer/country_defaults.dart';
import 'package:sakina/domain/prayer/prayer.dart';
import 'package:sakina/domain/settings/settings_repository.dart';

import '../../fakes/in_memory_settings_repository.dart';

void main() {
  group('PrayerMethod', () {
    test('keys are adhan_dart CalculationMethod names except jakim', () {
      final adhanNames = adhan.CalculationMethod.values.map((m) => m.name);
      for (final m in PrayerMethod.values) {
        if (m == PrayerMethod.jakim) {
          expect(adhanNames, isNot(contains(m.key)));
        } else {
          expect(adhanNames, contains(m.key), reason: m.key);
        }
        expect(PrayerMethod.tryParse(m.key), m);
      }
    });

    test('tryParse unknown or null', () {
      expect(PrayerMethod.tryParse('nope'), isNull);
      expect(PrayerMethod.tryParse(null), isNull);
    });

    test('every method builds adhan parameters', () {
      for (final m in PrayerMethod.values) {
        final p = CalcSettings(method: m).toAdhan();
        expect(p.fajrAngle, greaterThan(0), reason: m.key);
      }
    });

    test('indonesian and jakim add 2 min ihtiyat', () {
      final id = CalcSettings(method: PrayerMethod.indonesian).toAdhan();
      expect(id.methodAdjustments, {
        adhan.Prayer.fajr: 2,
        adhan.Prayer.sunrise: -2,
        adhan.Prayer.dhuhr: 3,
        adhan.Prayer.asr: 2,
        adhan.Prayer.maghrib: 2,
        adhan.Prayer.isha: 2,
      });
      final my = CalcSettings(method: PrayerMethod.jakim).toAdhan();
      expect((my.fajrAngle, my.ishaAngle), (18, 18));
      expect(my.methodAdjustments[adhan.Prayer.sunrise], -2);
      expect(my.methodAdjustments[adhan.Prayer.dhuhr], 3);
    });
  });

  test('AsrMadhab.parse', () {
    expect(AsrMadhab.parse('hanafi'), AsrMadhab.hanafi);
    expect(AsrMadhab.parse('shafi'), AsrMadhab.shafi);
    expect(AsrMadhab.parse('x'), AsrMadhab.shafi);
    expect(AsrMadhab.hanafi.key, 'hanafi');
  });

  test('HighLatRule keys and default', () {
    expect(HighLatRule.values.map((r) => r.key), [
      'middle_of_night',
      'seventh_of_night',
      'twilight_angle',
    ]);
    expect(HighLatRule.tryParse('twilight_angle'), HighLatRule.twilightAngle);
    expect(HighLatRule.tryParse('nope'), isNull);
    expect(HighLatRule.defaultFor(59.9), HighLatRule.middleOfNight);
    expect(HighLatRule.defaultFor(21.4), HighLatRule.middleOfNight);
  });

  group('CalcSettings.resolve', () {
    test('null method falls back to country default', () {
      final s = CalcSettings.resolve(lat: 41, country: 'TR');
      expect(s.method, PrayerMethod.turkiye);
      expect(s.asr, AsrMadhab.shafi);
      expect(s.highLatRule, HighLatRule.middleOfNight);
      expect(s.adjust, isEmpty);
    });

    test('unknown method falls back to country default', () {
      final s = CalcSettings.resolve(lat: 48, country: 'SK', method: 'x');
      expect(s.method, PrayerMethod.muslimWorldLeague);
    });

    test('explicit values win', () {
      final s = CalcSettings.resolve(
        lat: 51.5,
        country: 'GB',
        method: 'karachi',
        asr: 'hanafi',
        highLatRule: 'seventh_of_night',
        adjust: const {'fajr': -3, 'isha': 5, 'bogus': 9},
      );
      expect(
        s,
        CalcSettings(
          method: PrayerMethod.karachi,
          asr: AsrMadhab.hanafi,
          highLatRule: HighLatRule.seventhOfNight,
          adjust: const {Prayer.fajr: -3, Prayer.isha: 5},
        ),
      );
      final p = s.toAdhan();
      expect(p.madhab, adhan.Madhab.hanafi);
      expect(p.highLatitudeRule, adhan.HighLatitudeRule.seventhOfTheNight);
      expect(p.polarCircleResolution, adhan.PolarCircleResolution.aqrabYaum);
      expect(p.adjustments[adhan.Prayer.fajr], -3);
      expect(p.adjustments[adhan.Prayer.dhuhr], 0);
    });
  });

  group('CalcSettings value semantics', () {
    final a = CalcSettings(
      method: PrayerMethod.egyptian,
      adjust: const {Prayer.asr: 1},
    );
    test('equal and hash', () {
      final b = CalcSettings(
        method: PrayerMethod.egyptian,
        adjust: const {Prayer.asr: 1},
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(CalcSettings(method: PrayerMethod.egyptian)));
      expect(
        a,
        isNot(
          CalcSettings(
            method: PrayerMethod.egyptian,
            adjust: const {Prayer.asr: 2},
          ),
        ),
      );
    });

    test('adjust is unmodifiable', () {
      expect(() => a.adjust[Prayer.fajr] = 1, throwsUnsupportedError);
    });

    test('toString', () {
      expect(a.toString(), contains('egyptian'));
      expect(a.toString(), contains('middle_of_night'));
    });
  });

  group('CalcSettings.load', () {
    test('null without location', () async {
      expect(await CalcSettings.load(InMemorySettingsRepository()), isNull);
    });

    test('reads prayer.* keys', () async {
      final repo = InMemorySettingsRepository();
      final location = PrayerLocation(
        lat: 24.8607,
        lng: 67.0011,
        country: 'PK',
        tz: 'Asia/Karachi',
        city: 'Karachi',
      );
      await repo.set(SettingsKeys.prayerLocation, location);
      await repo.set(SettingsKeys.prayerAsr, 'hanafi');
      await repo.set(SettingsKeys.prayerAdjust, {'maghrib': 2});

      final (loc, s) = (await CalcSettings.load(repo))!;
      expect(loc, location);
      expect(loc.lat, 24.86);
      expect(s.method, CountryDefaults.forCountry('PK').method);
      expect(s.asr, AsrMadhab.hanafi);
      expect(s.highLatRule, HighLatRule.middleOfNight);
      expect(s.adjust, {Prayer.maghrib: 2});

      await repo.set(SettingsKeys.prayerMethod, 'muslimWorldLeague');
      await repo.set(SettingsKeys.prayerHighLatRule, 'twilight_angle');
      final (_, s2) = (await CalcSettings.load(repo))!;
      expect(s2.method, PrayerMethod.muslimWorldLeague);
      expect(s2.highLatRule, HighLatRule.twilightAngle);
    });
  });
}
