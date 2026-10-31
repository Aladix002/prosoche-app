import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/logging/app_logger.dart';
import 'package:sakina/data/observability/crash_reporter.dart';

import 'fakes.dart';

LogEntry _e(LogLevel l, String tag, [String msg = 'm']) =>
    LogEntry(DateTime.utc(2027), l, tag, msg, const {});

void main() {
  late FakeCrashReporter reporter;
  late CrashLogSink sink;

  setUp(() async {
    reporter = FakeCrashReporter();
    sink = CrashLogSink();
    await reporter.start();
  });

  test('detached sink forwards nothing', () {
    sink.add(_e(LogLevel.error, 'db'));
    expect(reporter.crumbs, isEmpty);
  });

  test('stopped reporter receives nothing', () async {
    sink.attach(reporter);
    await reporter.stop(wipe: true);
    sink.add(_e(LogLevel.error, 'db'));
    expect(reporter.crumbs, isEmpty);
  });

  test('info+ become breadcrumbs, debug is local only', () {
    sink
      ..attach(reporter)
      ..add(_e(LogLevel.debug, 'db'))
      ..add(_e(LogLevel.info, 'db'))
      ..add(_e(LogLevel.warn, 'db'));
    expect(reporter.crumbs.map((e) => e.level), [LogLevel.info, LogLevel.warn]);
    expect(reporter.captured, isEmpty);
  });

  test('errors are captured except those Sentry integrations catch', () {
    sink
      ..attach(reporter)
      ..add(_e(LogLevel.error, 'onboarding'))
      ..add(_e(LogLevel.fatal, 'db'))
      ..add(_e(LogLevel.error, 'flutter'))
      ..add(_e(LogLevel.error, 'platform'));
    expect(reporter.captured.map((e) => e.tag), ['onboarding', 'db']);
    expect(reporter.crumbs, hasLength(4));
  });

  test('NoopCrashReporter does nothing', () async {
    const noop = NoopCrashReporter();
    await noop.start();
    expect(noop.isRunning, isFalse);
    noop
      ..addBreadcrumb(_e(LogLevel.info, 'x'))
      ..captureEntry(_e(LogLevel.error, 'x'));
    await noop.stop(wipe: true);
  });
}
