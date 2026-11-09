import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';

void main() {
  test('contains every fixed key', () {
    expect(SettingsKeys.all.map((k) => k.name).toSet(), {
      'onboarding.completed',
      'onboarding.step',
      'age_confirmed_16',
      'install_id',
      'ui.locale',
      'display.theme',
      'reader.scale',
      'intention.text',
      'intention.preset',
      'feed.cards_count',
      'card.seen_dwell_ms',
      'simple_mode',
      'notif.morning.enabled',
      'notif.morning.time',
      'notif.evening.enabled',
      'notif.evening.time',
      'notif.private_lockscreen',
      'practice.birth_year',
      'content.update_wifi_only',
      'blocker.enabled',
      'gate.ask_intent',
      'gate.rising_friction',
      'gate.practice_first',
      'gate.practice_first.until',
      'analytics_opt_in',
      'crash_reports',
    });
    expect(SettingsKeys.all.map((k) => k.name).toSet(), hasLength(26));
  });

  test('defaults', () {
    expect(SettingsKeys.onboardingCompleted.defaultValue, isFalse);
    expect(SettingsKeys.notifEveningEnabled.defaultValue, isFalse);
    expect(SettingsKeys.notifEveningTime.defaultValue, '21:00');
    expect(SettingsKeys.practiceBirthYear.defaultValue, isNull);
    expect(SettingsKeys.onboardingStep.defaultValue, 'welcome');
    expect(SettingsKeys.feedCardsCount.defaultValue, 12);
    expect(SettingsKeys.cardSeenDwellMs.defaultValue, 2500);
    expect(SettingsKeys.notifMorningTime.defaultValue, '07:30');
    expect(SettingsKeys.notifPrivateLockscreen.defaultValue, isTrue);
    expect(SettingsKeys.analyticsOptIn.defaultValue, isFalse);
    expect(SettingsKeys.crashReports.defaultValue, isFalse);
    expect(SettingsKeys.gateAskIntent.defaultValue, isTrue);
    expect(SettingsKeys.gateRisingFriction.defaultValue, isTrue);
    expect(SettingsKeys.gatePracticeFirst.defaultValue, isFalse);
    expect(SettingsKeys.gatePracticeFirstUntil.defaultValue, '10:00');
    expect(SettingsKeys.installId.defaultValue, isNull);
    expect(SettingsKeys.intentionText.defaultValue, isNull);
    expect(SettingsKeys.onboardingSteps, contains('intention'));
    expect(SettingsKeys.onboardingSteps, isNot(contains('location')));
  });

  test('every default encodes and decodes to itself', () {
    for (final key in SettingsKeys.all) {
      final text = key.encode(key.defaultValue);
      expect(key.decode(text), key.defaultValue, reason: key.name);
      expect(key.read(null), key.defaultValue, reason: key.name);
      expect(key.read('{broken'), key.defaultValue, reason: key.name);
    }
  });

  group('validation', () {
    test('feed.cards_count allows 8, 12, 16', () {
      final k = SettingsKeys.feedCardsCount;
      expect(k.read('16'), 16);
      expect(k.read('10'), 12);
      expect(() => k.encode(10), throwsArgumentError);
    });

    test('dwell range', () {
      expect(SettingsKeys.cardSeenDwellMs.read('60000'), 60000);
      expect(SettingsKeys.cardSeenDwellMs.read('60001'), 2500);
    });

    test('strings with allowed values and patterns', () {
      expect(SettingsKeys.onboardingStep.read('"privacy"'), 'privacy');
      expect(SettingsKeys.onboardingStep.read('"x"'), 'welcome');
      expect(SettingsKeys.notifMorningTime.read('"05:45"'), '05:45');
      expect(SettingsKeys.notifMorningTime.read('"24:00"'), '07:30');
      expect(SettingsKeys.displayTheme.read('"dark"'), 'dark');
      expect(SettingsKeys.uiLocale.read('"en"'), 'en');
      expect(SettingsKeys.uiLocale.read('5'), isNull);
    });

    test('wrong JSON type and null fall back to default', () {
      expect(SettingsKeys.simpleMode.read('"true"'), isFalse);
      expect(SettingsKeys.simpleMode.read('null'), isFalse);
      expect(
        () => SettingsKeys.simpleMode.decode('null'),
        throwsFormatException,
      );
    });
  });

  group('SettingKey kinds', () {
    test('optionalInt with validator', () {
      final k = SettingKey.optionalInt('x.n', isValid: (v) => v > 0);
      expect(k.read('5'), 5);
      expect(k.read('0'), isNull);
      expect(k.read('null'), isNull);
      expect(k.encode(null), 'null');
      expect(() => k.encode(-1), throwsArgumentError);
    });

    test('decimal range', () {
      final k = SettingKey.decimal('x.d', defaultValue: 1, min: 0.5, max: 3);
      expect(k.read('2'), 2.0);
      expect(k.read('9'), 1.0);
    });

    test('json value', () {
      final k = SettingKey.json<Map<String, int>>(
        'x.map',
        defaultValue: const {},
        fromJson: (json) => json is Map<String, Object?>
            ? {for (final e in json.entries) e.key: e.value! as int}
            : throw const FormatException('map'),
        toJson: (v) => v,
      );
      expect(k.decode(k.encode({'a': 1})), {'a': 1});
      expect(k.read('[1]'), isEmpty);
    });
  });

  test('SettingKey equality is by name', () {
    expect(
      SettingKey.boolean('a', defaultValue: true),
      SettingKey.boolean('a', defaultValue: false),
    );
    expect(
      SettingsKeys.simpleMode.hashCode,
      SettingKey.boolean('simple_mode', defaultValue: true).hashCode,
    );
    expect(SettingsKeys.simpleMode.toString(), 'SettingKey(simple_mode)');
  });
}
