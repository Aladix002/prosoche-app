import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/logging/app_logger.dart';
import 'package:sakina/data/observability/allowlist_analytics.dart';

import 'fakes.dart';

void main() {
  late FakeTransport transport;
  late RingBufferLog ring;
  late AllowlistAnalytics analytics;

  setUp(() {
    transport = FakeTransport();
    ring = RingBufferLog();
    analytics = AllowlistAnalytics(
      transport,
      superProperties: () => {
        'app_version': '1.0.0',
        'locale': 'en',
        'flavor': 'prod',
        'content_version': 3,
        'install_id': 'secret',
      },
      logger: AppLogger(
        sinks: [ring],
        minLevel: LogLevel.trace,
        echoToConsole: false,
      ),
      maxQueue: 3,
    );
  });

  test('disabled by default: events are neither sent nor queued', () async {
    analytics.track('screen_view', {'screen': 'today'});
    expect(analytics.isEnabled, isFalse);
    expect(analytics.queuedCount, 0);
    await analytics.enable();
    expect(transport.sent, isEmpty);
  });

  test('enabled: sends sanitized event with super properties', () async {
    await analytics.enable();
    analytics.track('card_action', {
      'type': 'ayah',
      'action': 'save',
      'card_id': 'ayah:2:255',
    });
    await pumpEventQueue();
    expect(transport.starts, 1);
    expect(transport.sent.single.$1, 'card_action');
    expect(transport.sent.single.$2, {
      'app_version': '1.0.0',
      'locale': 'en',
      'flavor': 'prod',
      'content_version': 3,
      'type': 'ayah',
      'action': 'save',
    });
  });

  test('unknown events are dropped', () async {
    await analytics.enable();
    analytics.track('prayer_logged', {'slot': 'fajr'});
    await pumpEventQueue();
    expect(transport.sent, isEmpty);
    expect(ring.entries.last.msg, 'unknown event dropped');
  });

  test('consented events wait for enable and are then sent', () async {
    analytics.enqueueConsented([
      ('onboarding_step', {'step': 'language', 'skipped': false}),
      ('onboarding_completed', {'notif_granted': true, 'city': 'Bratislava'}),
    ]);
    expect(analytics.queuedCount, 2);
    await analytics.enable();
    await pumpEventQueue();
    expect(transport.sent.map((e) => e.$1), [
      'onboarding_step',
      'onboarding_completed',
    ]);
    expect(transport.sent.last.$2.containsKey('city'), isFalse);
    expect(analytics.queuedCount, 0);
  });

  test('queue is capped to maxQueue (oldest dropped)', () {
    analytics.enqueueConsented([
      for (var i = 0; i < 5; i++) ('gate_apps_selected', {'count': i}),
    ]);
    expect(analytics.queuedCount, 3);
  });

  test('disable clears the queue and wipes the started SDK', () async {
    await analytics.enable();
    await analytics.disable();
    analytics.enqueueConsented([
      ('screen_view', {'screen': 'today'}),
    ]);
    await analytics.disable();
    expect(analytics.queuedCount, 0);
    expect(transport.stops, [true]);
    analytics.track('screen_view', {'screen': 'today'});
    await pumpEventQueue();
    expect(transport.sent, isEmpty);
  });

  test('disable without start does not touch the SDK', () async {
    await analytics.disable();
    expect(transport.stops, isEmpty);
  });

  test('disable(wipe: false) keeps SDK state', () async {
    await analytics.enable();
    await analytics.disable(wipe: false);
    expect(transport.stops, [false]);
  });

  test('enable is idempotent', () async {
    await analytics.enable();
    await analytics.enable();
    expect(transport.starts, 1);
  });

  test('start failure keeps analytics off and clears the queue', () async {
    transport.startError = StateError('boom');
    analytics.enqueueConsented([
      ('screen_view', {'screen': 'today'}),
    ]);
    await analytics.enable();
    expect(analytics.isEnabled, isFalse);
    expect(analytics.queuedCount, 0);
    expect(ring.entries.last.msg, 'start failed');
  });

  test('disable during start stops the SDK right after start', () async {
    final starting = analytics.enable();
    analytics.track('screen_view', {'screen': 'today'});
    await analytics.disable();
    await starting;
    await pumpEventQueue();
    expect(transport.sent, isEmpty);
    expect(transport.stops, [true]);
    expect(analytics.isEnabled, isFalse);
  });

  test('capture and stop errors are logged, not thrown', () async {
    transport
      ..captureError = StateError('net')
      ..stopError = StateError('stop');
    await analytics.enable();
    analytics.track('screen_view', {'screen': 'today'});
    await pumpEventQueue();
    expect(ring.entries.last.msg, 'capture failed');
    await analytics.disable();
    expect(ring.entries.last.msg, 'stop failed');
  });
}
