import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/failures.dart';
import 'package:sakina/core/logging/app_logger.dart';

void main() {
  final fixed = Clock.fixed(DateTime.utc(2027, 1, 20, 18, 3, 11));
  late RingBufferLog ring;
  late AppLogger log;

  setUp(() {
    ring = RingBufferLog(capacity: 3);
    log = AppLogger(sinks: [ring], clock: fixed, echoToConsole: false);
  });

  test('drops keys outside the allowlist', () {
    log.info('content', 'download failed', {
      'code': 'net.http.503',
      'attempt': 2,
      'city': 'Sarajevo',
      'app': 'com.example',
    });
    final e = ring.entries.single;
    expect(e.kv, {'code': 'net.http.503', 'attempt': 2});
    expect(
      e.toJsonLine(),
      '{"t":"2027-01-20T18:03:11.000Z","l":"info","tag":"content",'
      '"msg":"download failed","kv":{"code":"net.http.503","attempt":2}}',
    );
  });

  test('respects minLevel', () {
    log
      ..debug('db', 'noise')
      ..trace('db', 'noise');
    expect(ring.entries, isEmpty);
  });

  test('error logs only exception type, not its message', () {
    log.error('db', 'open failed', error: StateError('secret path /x'));
    final e = ring.entries.single;
    expect(e.level, LogLevel.error);
    expect(e.kv, {'type': 'StateError'});
    expect(e.toJsonLine(), isNot(contains('secret')));
  });

  test('failure level depends on reportable', () {
    log
      ..failure('net', const Offline())
      ..failure('content', const SecurityFailure.badSignature());
    expect(ring.entries.map((e) => e.level), [LogLevel.warn, LogLevel.error]);
    expect(ring.entries.last.kv, {'code': 'security.bad_signature'});
  });

  test('ring buffer keeps only the newest entries', () {
    for (var i = 0; i < 5; i++) {
      log.info('ui', 'tick', {'attempt': i});
    }
    expect(ring.entries.map((e) => e.kv['attempt']), [2, 3, 4]);
  });
}
