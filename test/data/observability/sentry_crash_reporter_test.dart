import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/logging/app_logger.dart';
import 'package:sakina/data/observability/observability_config.dart';
import 'package:sakina/data/observability/sentry_crash_reporter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('configureSentry: no PII, screenshots, replay or tracing', () {
    final o = SentryFlutterOptions();
    configureSentry(
      o,
      const ObservabilityConfig(
        sentryDsn: 'https://key@o1.ingest.de.sentry.io/1',
        sentryEnvironment: 'prod',
        sentryRelease: 'sakina@1.0.0+10',
        sentryDist: '10',
      ),
    );
    expect(o.dsn, 'https://key@o1.ingest.de.sentry.io/1');
    expect(o.environment, 'prod');
    expect(o.release, 'sakina@1.0.0+10');
    expect(o.dist, '10');
    expect(o.sendDefaultPii, isFalse);
    expect(o.attachScreenshot, isFalse);
    expect(o.attachViewHierarchy, isFalse);
    expect(o.replay.sessionSampleRate, 0.0);
    expect(o.replay.onErrorSampleRate, 0.0);
    expect(o.tracesSampleRate, 0.0);
    expect(o.enableAutoSessionTracking, isTrue);
    expect(o.enableUserInteractionBreadcrumbs, isFalse);
    expect(o.enableAutoNativeBreadcrumbs, isFalse);
    expect(o.captureFailedRequests, isFalse);
    expect(o.reportPackages, isFalse);
    expect(o.maxBreadcrumbs, 50);
    expect(o.beforeSend, isNotNull);
    expect(o.beforeBreadcrumb, isNotNull);
  });

  test('configureSentry keeps SDK release when not defined', () {
    final o = SentryFlutterOptions()..release = 'from-sdk';
    configureSentry(o, const ObservabilityConfig(sentryDsn: 'x'));
    expect(o.release, 'from-sdk');
  });

  test('scrubText replaces coordinates, e-mails, URLs and packages', () {
    expect(
      scrubText(
        'at 48.1486, 17.1077 by a.b@example.com in com.instagram.android',
      ),
      'at <coords> by <email> in <pkg>',
    );
    expect(scrubText('GET https://x.y/z?q=1 failed'), 'GET <url> failed');
    expect(scrubText('StateError: bad state'), 'StateError: bad state');
  });

  test('beforeSend drops user, server, request, device name and timezone', () {
    final event = SentryEvent(
      user: SentryUser(id: 'install-id', ipAddress: '1.2.3.4'),
      serverName: 'host',
      request: SentryRequest(url: 'https://x'),
      message: SentryMessage(
        'near 48.1486, 17.1077',
        template: 'mail a@b.cc',
        params: const ['secret'],
      ),
      exceptions: [
        SentryException(type: 'StateError', value: 'pkg com.whatsapp.app'),
        SentryException(type: 'X', value: null),
      ],
      breadcrumbs: [
        Breadcrumb(message: 'ok', type: sakinaBreadcrumbType),
        Breadcrumb(message: 'tap "Fajr done"', category: 'ui.click'),
      ],
      tags: {'locale_city': 'Bratislava', 'flavor': 'prod'},
      contexts: Contexts(
        device: SentryDevice(name: 'Filip phone', model: 'Pixel'),
        culture: SentryCulture(timezone: 'Europe/Bratislava', locale: 'en'),
      ),
    );
    final out = scrubEvent(event, Hint())!;
    expect(out.user, isNull);
    expect(out.serverName, isNull);
    expect(out.request, isNull);
    expect(out.message!.formatted, 'near <coords>');
    expect(out.message!.template, 'mail <email>');
    expect(out.message!.params, isNull);
    expect(out.exceptions!.first.value, 'pkg <pkg>');
    expect(out.exceptions!.last.value, isNull);
    expect(out.breadcrumbs!.map((b) => b.message), ['ok']);
    expect(out.tags, {'flavor': 'prod'});
    expect(out.contexts.device!.name, isNull);
    expect(out.contexts.device!.model, 'Pixel');
    expect(out.contexts.culture!.timezone, isNull);
  });

  test('beforeSend tolerates an empty event', () {
    expect(scrubEvent(SentryEvent(), Hint()), isNotNull);
  });

  test('beforeBreadcrumb keeps only logger breadcrumbs', () {
    expect(
      filterBreadcrumb(Breadcrumb(type: sakinaBreadcrumbType), Hint()),
      isNotNull,
    );
    expect(
      filterBreadcrumb(Breadcrumb(category: 'navigation'), Hint()),
      isNull,
    );
    expect(filterBreadcrumb(null, Hint()), isNull);
  });

  group('SentryCrashReporter', () {
    LogEntry entry(LogLevel l, String msg, Map<String, Object?> kv) =>
        LogEntry(DateTime.utc(2027), l, 'content', msg, kv);

    test('without DSN start is a no-op', () async {
      final r = SentryCrashReporter(const ObservabilityConfig());
      await r.start();
      expect(r.isRunning, isFalse);
    });

    test('stop(wipe) closes Sentry and deletes the offline cache', () async {
      var wiped = 0;
      final r = SentryCrashReporter(
        const ObservabilityConfig(),
        wipeCache: () async => wiped++,
      );
      await r.stop(wipe: false);
      expect(wiped, 0);
      await r.stop(wipe: true);
      expect(wiped, 1);
      expect(r.isRunning, isFalse);
    });

    test('cache wipe failure is logged, not thrown', () async {
      final ring = RingBufferLog();
      final r = SentryCrashReporter(
        const ObservabilityConfig(),
        wipeCache: () => Future.error(const FileSystemExceptionLike()),
        logger: AppLogger(sinks: [ring], echoToConsole: false),
      );
      await r.stop(wipe: true);
      expect(ring.entries.single.msg, 'cache wipe failed');
    });

    test('breadcrumbs and reports are safe while Sentry is closed', () async {
      final r = SentryCrashReporter(const ObservabilityConfig())
        ..addBreadcrumb(entry(LogLevel.info, 'download ok', {'status': 200}))
        ..addBreadcrumb(entry(LogLevel.warn, 'slow', const {}))
        ..captureEntry(
          entry(LogLevel.error, 'failure', {'code': 'net.http.503'}),
        )
        ..captureEntry(
          entry(LogLevel.fatal, 'db open failed', {'type': 'StateError'}),
        );
      await pumpEventQueue();
      expect(r.isRunning, isFalse);
    });
  });
}

class FileSystemExceptionLike implements Exception {
  const FileSystemExceptionLike();
}
