import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:sakina/data/observability/posthog_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('config: EU host, no person profiles, no replay/autocapture', () {
    final c = buildPostHogConfig('phc_test');
    expect(c.projectToken, 'phc_test');
    expect(c.host, 'https://eu.i.posthog.com');
    expect(c.personProfiles, PostHogPersonProfiles.never);
    expect(c.sessionReplay, isFalse);
    expect(c.captureApplicationLifecycleEvents, isFalse);
    expect(c.surveys, isFalse);
    expect(c.preloadFeatureFlags, isFalse);
    expect(c.sendFeatureFlagEvent, isFalse);
    expect(c.capturePushNotificationOpened, isFalse);
    expect(c.capturePushNotificationSubscriptions, isFalse);
    expect(c.rageClickConfig.enabled, isFalse);
    expect(c.errorTrackingConfig.captureFlutterErrors, isFalse);
    expect(c.errorTrackingConfig.capturePlatformDispatcherErrors, isFalse);
    expect(c.errorTrackingConfig.captureNativeExceptions, isFalse);
    expect(c.beforeSend, [posthogGuard]);
  });

  group('posthogGuard', () {
    test('drops events outside the allowlist', () {
      expect(posthogGuard(PostHogEvent(event: r'$screen')), isNull);
      expect(posthogGuard(PostHogEvent(event: 'prayer_logged')), isNull);
    });

    test('re-filters properties, strips person props, disables GeoIP', () {
      final out = posthogGuard(
        PostHogEvent(
          event: 'gate_shown',
          properties: {
            'cards_required': 3,
            'app': 'com.instagram.android',
            'flavor': 'prod',
          },
          userProperties: {'email': 'a@b.c'},
          userPropertiesSetOnce: {'city': 'x'},
        ),
      )!;
      expect(out.properties, {
        'flavor': 'prod',
        'cards_required': 3,
        r'$geoip_disable': true,
      });
      expect(out.userProperties, isNull);
      expect(out.userPropertiesSetOnce, isNull);
    });
  });

  group('PostHogTransport over the method channel', () {
    const channel = MethodChannel('posthog_flutter');
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('start sets up EU config and opts in; capture is guarded', () async {
      var wiped = 0;
      final t = PostHogTransport('phc_test', wipeDisk: () async => wiped++);
      await t.start();
      final setup = calls.firstWhere((c) => c.method == 'setup');
      final args = setup.arguments as Map<Object?, Object?>;
      expect(args['host'], 'https://eu.i.posthog.com');
      expect(args['personProfiles'], 'never');
      expect(args['sessionReplay'], false);
      expect(calls.map((c) => c.method), contains('enable'));

      await t.capture('screen_view', {'screen': 'today'});
      final capture = calls.lastWhere((c) => c.method == 'capture');
      final args2 = capture.arguments as Map<Object?, Object?>;
      final props = args2['properties']! as Map<Object?, Object?>;
      expect(props['screen'], 'today');
      expect(props[r'$geoip_disable'], true);

      calls.clear();
      await t.stop(wipe: true);
      expect(calls.map((c) => c.method), ['disable', 'reset', 'close']);
      expect(wiped, 1);

      calls.clear();
      await t.stop(wipe: false);
      expect(calls.map((c) => c.method), ['disable', 'close']);
      expect(wiped, 1);
    });
  });

  test('deletePosthogQueues removes native disk queues only', () async {
    final tmp = await Directory.systemTemp.createTemp('ph');
    addTearDown(() => tmp.delete(recursive: true));
    for (final d in [...posthogQueueDirs, 'other']) {
      await Directory('${tmp.path}/$d/x').create(recursive: true);
    }
    await deletePosthogQueues(tmp);
    final left = tmp.listSync().map((e) => e.path.split('/').last).toList();
    expect(left, ['other']);
    await deletePosthogQueues(tmp);
  });
}
