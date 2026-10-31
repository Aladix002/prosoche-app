import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/bootstrap.dart';
import 'package:sakina/core/logging/app_logger.dart';

void main() {
  late RingBufferLog ring;
  late AppLogger logger;

  setUp(() {
    ring = RingBufferLog();
    logger = AppLogger(sinks: [ring], echoToConsole: false);
  });

  test('framework errors are presented and logged by type only', () {
    final originalPresent = FlutterError.presentError;
    addTearDown(() => FlutterError.presentError = originalPresent);
    var presented = 0;
    FlutterError.presentError = (_) => presented++;

    flutterErrorHandler(logger)(
      FlutterErrorDetails(exception: StateError('private detail')),
    );

    expect(presented, 1);
    final e = ring.entries.single;
    expect((e.tag, e.level), ('flutter', LogLevel.error));
    expect(e.kv, {'type': 'StateError'});
  });

  test('platform errors are logged and marked handled', () {
    final handled = platformErrorHandler(logger)(
      ArgumentError('async'),
      StackTrace.empty,
    );
    expect(handled, isTrue);
    expect(ring.entries.single.tag, 'platform');
    expect(ring.entries.single.kv, {'type': 'ArgumentError'});
  });

  test('installGlobalErrorHandlers sets FlutterError.onError', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final original = FlutterError.onError;
    final originalPlatform = PlatformDispatcher.instance.onError;
    addTearDown(() {
      FlutterError.onError = original;
      PlatformDispatcher.instance.onError = originalPlatform;
    });
    installGlobalErrorHandlers(logger);
    expect(FlutterError.onError, isNot(same(original)));
  });
}
