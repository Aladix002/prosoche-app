import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/data/observability/analytics.dart';

void main() {
  // docs/02 0.6: nic z tohto nesmie odist v analytike.
  const forbidden = {
    'card_id',
    'ayah_id',
    'surah',
    'surah_name',
    'prayer',
    'prayer_status',
    'status',
    'app',
    'app_name',
    'package',
    'package_name',
    'lat',
    'lng',
    'latitude',
    'longitude',
    'city',
    'location',
    'timezone',
    'install_id',
    'text',
  };

  test('schema has exactly the events of TECHNICKY_PLAN 19 and docs/02 '
      'D19', () {
    expect(AnalyticsSchema.events.keys.toSet(), {
      'onboarding_step',
      'onboarding_completed',
      'screen_view',
      'permission_result',
      'daily_set_started',
      'daily_set_completed',
      'card_action',
      'gate_apps_selected',
      'gate_shown',
      'gate_passed',
      'gate_emergency',
      'gate_dismissed',
      'quest_completed',
      'quiz_session_completed',
      'audio_play',
      'feature_used',
      'backup_exported',
      'backup_imported',
      'content_updated',
    });
    expect(AnalyticsSchema.superProperties, {
      'app_version',
      'content_version',
      'locale',
      'flavor',
    });
  });

  test('no event allows content ids, prayer state, app names or location', () {
    for (final entry in AnalyticsSchema.events.entries) {
      expect(entry.value.intersection(forbidden), isEmpty, reason: entry.key);
    }
    expect(AnalyticsSchema.superProperties.intersection(forbidden), isEmpty);
  });

  test('disallowed property is dropped, allowed one is kept', () {
    final out = AnalyticsSchema.sanitize('card_action', {
      'type': 'ayah',
      'action': 'save',
      'card_id': 'ayah:2:255',
      'ayah_id': 262,
    });
    expect(out, {'type': 'ayah', 'action': 'save'});
  });

  test('every forbidden key is dropped from every event', () {
    final props = {for (final k in forbidden) k: 'x'};
    for (final event in AnalyticsSchema.events.keys) {
      expect(AnalyticsSchema.sanitize(event, props), isEmpty, reason: event);
    }
    expect(AnalyticsSchema.sanitizeSuper(props), isEmpty);
  });

  test('unknown event yields no properties', () {
    expect(AnalyticsSchema.isKnownEvent('prayer_logged'), isFalse);
    expect(AnalyticsSchema.sanitize('prayer_logged', {'step': 'a'}), isEmpty);
  });

  test('string values must be short identifiers, not free text', () {
    bool ok(String key, Object? v) => AnalyticsSchema.isValidValue(key, v);
    expect(ok('type', 'ayah'), isTrue);
    expect(ok('type', 'Al-Fatiha'), isFalse);
    expect(ok('type', 'some free text'), isFalse);
    expect(ok('type', 'com.instagram.android'), isFalse);
    expect(ok('type', ''), isFalse);
    expect(ok('type', 'a' * 49), isFalse);
    expect(ok('screen', 'quran_reader'), isTrue);
    expect(ok('screen', '/quran/read/2'), isFalse);
    expect(ok('screen', 'quran_reader_2'), isFalse);
    expect(ok('from_version', '2026.11.1'), isTrue);
    expect(ok('app_version', '1.2.0+10'), isTrue);
    expect(ok('app_version', 'v1'), isFalse);
    expect(ok('count', 3), isTrue);
    expect(ok('duration_s', 1.5), isTrue);
    expect(ok('duration_s', double.nan), isFalse);
    expect(ok('granted', true), isTrue);
    expect(ok('count', null), isFalse);
    expect(ok('count', const [1]), isFalse);
    expect(ok('count', const {'a': 1}), isFalse);
  });

  test('NoopAnalytics accepts anything and does nothing', () {
    const NoopAnalytics().track('anything', {'card_id': 'x'});
  });
}
