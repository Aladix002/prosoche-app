import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';

void main() {
  test('contains every fixed key from docs/02 0.7', () {
    expect(SettingsKeys.all.map((k) => k.name).toSet(), {
      'onboarding.completed',
      'onboarding.step',
      'age_confirmed_16',
      'install_id',
      'ui.locale',
      'display.translit',
      'display.translation',
      'display.theme',
      'display.arabic_scale',
      'niyyah.text',
      'niyyah.preset',
      'feed.cards_count',
      'card.seen_dwell_ms',
      'simple_mode',
      'prayer.location',
      'prayer.method',
      'prayer.asr',
      'prayer.high_lat_rule',
      'prayer.adjust',
      'hijri.offset',
      'notif.morning.enabled',
      'notif.morning.time',
      'notif.private_lockscreen',
      'notif.confirmed_tz',
      'audio.reciter',
      'audio.wifi_only',
      'content.update_wifi_only',
      'blocker.enabled',
      'blocker.prayer_lock_minutes',
      'analytics_opt_in',
      'crash_reports',
      'ramadan.season',
      'reader.last_ayah_id',
      'names.cursor',
      'journey.last_khatm_seen',
    });
    expect(SettingsKeys.all.length, SettingsKeys.all.toSet().length);
  });

  test('defaults from docs/02 0.7', () {
    expect(SettingsKeys.onboardingCompleted.defaultValue, isFalse);
    expect(SettingsKeys.onboardingStep.defaultValue, 'language');
    expect(SettingsKeys.displayTranslation.defaultValue, isTrue);
    expect(SettingsKeys.displayArabicScale.defaultValue, 1.0);
    expect(SettingsKeys.feedCardsCount.defaultValue, 12);
    expect(SettingsKeys.cardSeenDwellMs.defaultValue, 2500);
    expect(SettingsKeys.prayerAsr.defaultValue, 'shafi');
    expect(SettingsKeys.prayerAdjust.defaultValue, isEmpty);
    expect(SettingsKeys.notifMorningTime.defaultValue, '07:30');
    expect(SettingsKeys.notifPrivateLockscreen.defaultValue, isTrue);
    expect(SettingsKeys.audioReciter.defaultValue, 'Alafasy_128kbps');
    expect(SettingsKeys.contentUpdateWifiOnly.defaultValue, isTrue);
    expect(SettingsKeys.blockerPrayerLockMinutes.defaultValue, 15);
    expect(SettingsKeys.analyticsOptIn.defaultValue, isFalse);
    expect(SettingsKeys.crashReports.defaultValue, isFalse);
    expect(SettingsKeys.displayTheme.defaultValue, 'system');
    expect(SettingsKeys.ramadanSeason.defaultValue, isNull);
    expect(SettingsKeys.readerLastAyahId.defaultValue, 1001);
    expect(SettingsKeys.namesCursor.defaultValue, 1);
    expect(SettingsKeys.journeyLastKhatmSeen.defaultValue, 0);
    expect(SettingsKeys.installId.defaultValue, isNull);
    expect(SettingsKeys.prayerLocation.defaultValue, isNull);
  });

  test('every default encodes and decodes to itself', () {
    for (final key in SettingsKeys.all) {
      final text = key.encode(key.defaultValue);
      expect(key.decode(text), key.defaultValue, reason: key.name);
      expect(key.read(null), key.defaultValue, reason: key.name);
      expect(key.read('{broken'), key.defaultValue, reason: key.name);
    }
  });

  test('families', () {
    expect(SettingsKeys.translation('en').name, 'translation.en');
    expect(SettingsKeys.translation('en').defaultValue, isNull);
    expect(SettingsKeys.notifPrayer('fajr').name, 'notif.prayer.fajr');
    expect(SettingsKeys.notifPrayer('isha').defaultValue, isTrue);
    expect(SettingsKeys.eventCursor('jumuah').name, 'event_cursor.jumuah');
    for (final k in [
      SettingsKeys.translation('ur'),
      SettingsKeys.notifPrayer('asr'),
      SettingsKeys.eventCursor('jumuah'),
    ]) {
      expect(
        SettingsKeys.familyPrefixes.any(k.name.startsWith),
        isTrue,
        reason: k.name,
      );
    }
    expect(() => SettingsKeys.translation('EN'), throwsArgumentError);
    expect(() => SettingsKeys.notifPrayer('sunrise'), throwsArgumentError);
    expect(() => SettingsKeys.eventCursor('a.b'), throwsArgumentError);
  });

  group('validation', () {
    test('feed.cards_count allows 8, 12, 16', () {
      final k = SettingsKeys.feedCardsCount;
      for (final v in [8, 12, 16]) {
        expect(k.decode(k.encode(v)), v);
      }
      expect(() => k.encode(10), throwsArgumentError);
      expect(k.read('10'), 12);
    });

    test('hijri.offset -2..2', () {
      final k = SettingsKeys.hijriOffset;
      expect(k.read('-2'), -2);
      expect(k.read('3'), 0);
      expect(() => k.encode(-3), throwsArgumentError);
    });

    test('names.cursor 1..99 and reader.last_ayah_id range', () {
      expect(SettingsKeys.namesCursor.read('99'), 99);
      expect(SettingsKeys.namesCursor.read('100'), 1);
      expect(SettingsKeys.readerLastAyahId.read('114006'), 114006);
      expect(SettingsKeys.readerLastAyahId.read('999'), 1001);
    });

    test('event cursor must be a valid ayah', () {
      final k = SettingsKeys.eventCursor('jumuah');
      expect(k.read('18001'), 18001);
      expect(k.read('18111'), isNull);
      expect(k.read('null'), isNull);
      expect(() => k.encode(18111), throwsArgumentError);
      expect(k.encode(null), 'null');
    });

    test('translation source id must be positive', () {
      final k = SettingsKeys.translation('id');
      expect(k.read('3'), 3);
      expect(k.read('0'), isNull);
    });

    test('strings with allowed values and patterns', () {
      expect(SettingsKeys.prayerAsr.read('"hanafi"'), 'hanafi');
      expect(SettingsKeys.prayerAsr.read('"maliki"'), 'shafi');
      expect(SettingsKeys.onboardingStep.read('"privacy"'), 'privacy');
      expect(SettingsKeys.onboardingStep.read('"x"'), 'language');
      expect(SettingsKeys.notifMorningTime.read('"05:45"'), '05:45');
      expect(SettingsKeys.notifMorningTime.read('"24:00"'), '07:30');
      expect(SettingsKeys.uiLocale.read('"ar"'), 'ar');
      expect(SettingsKeys.uiLocale.read('5'), isNull);
    });

    test('wrong JSON type and null fall back to default', () {
      expect(SettingsKeys.simpleMode.read('"true"'), isFalse);
      expect(SettingsKeys.simpleMode.read('null'), isFalse);
      expect(
        () => SettingsKeys.simpleMode.decode('null'),
        throwsFormatException,
      );
      expect(SettingsKeys.displayArabicScale.read('2'), 2.0);
      expect(SettingsKeys.displayArabicScale.read('9'), 1.0);
    });

    test('prayer.adjust', () {
      final k = SettingsKeys.prayerAdjust;
      final v = {'fajr': -2, 'isha': 5};
      expect(k.decode(k.encode(v)), v);
      expect(k.read('{"fajr": 61}'), isEmpty);
      expect(k.read('{"sunrise": 1}'), isEmpty);
      expect(k.read('[1]'), isEmpty);
      expect(() => k.encode({'dhuhr': 100}), throwsArgumentError);
    });

    test('prayer.location', () {
      final k = SettingsKeys.prayerLocation;
      final loc = PrayerLocation(
        lat: 48.14816,
        lng: 17.10674,
        city: 'Bratislava',
        country: 'SK',
        tz: 'Europe/Bratislava',
      );
      expect(k.decode(k.encode(loc)), loc);
      expect(k.read('{"lat": 1}'), isNull);
      expect(k.read('5'), isNull);
    });
  });

  test('SettingKey equality is by name', () {
    expect(SettingsKeys.translation('en'), SettingsKeys.translation('en'));
    expect(
      SettingsKeys.translation('en').hashCode,
      SettingsKeys.translation('en').hashCode,
    );
    expect(SettingsKeys.simpleMode.toString(), 'SettingKey(simple_mode)');
  });
}
