import 'package:flutter_test/flutter_test.dart' hide Timeout;
import 'package:sakina/core/result.dart';

void main() {
  group('Result', () {
    test('fold and valueOrNull on Ok', () {
      const r = Ok<int>(2);
      expect(r.fold((v) => v * 2, (_) => -1), 4);
      expect(r.valueOrNull, 2);
      expect(r.isOk, isTrue);
    });

    test('fold and valueOrNull on Err', () {
      const Result<int> r = Err(Offline());
      expect(r.fold((v) => v, (f) => f.code), 'net.offline');
      expect(r.valueOrNull, isNull);
      expect(r.isOk, isFalse);
    });

    test('then2 chains Ok and short-circuits Err', () async {
      Future<Result<int>> ok(int v) async => Ok(v);
      Future<Result<int>> fail() async => const Err(StorageFull());

      expect(await ok(1).then2((v) => ok(v + 1)), const Ok(2));
      var called = false;
      final r = await fail().then2((v) async {
        called = true;
        return Ok(v);
      });
      expect(r, const Err<int>(StorageFull()));
      expect(called, isFalse);
    });
  });

  group('AppFailure', () {
    test('codes are stable and contain no user data', () {
      expect(const HttpStatus(503).code, 'net.http.503');
      expect(
        const SecurityFailure.rollback().code,
        'security.version_rollback',
      );
      expect(const DbCorrupted('user').code, 'data.db_corrupted.user');
      expect(
        const PermissionDenied('overlay').code,
        'platform.permission_denied.overlay',
      );
    });

    test('retryable and reportable flags', () {
      expect(const HttpStatus(429).retryable, isTrue);
      expect(const HttpStatus(404).retryable, isFalse);
      expect(const Offline().retryable, isTrue);
      expect(const SecurityFailure.badSignature().reportable, isTrue);
      expect(const ContentIntegrityFailed('sha256').reportable, isTrue);
      expect(const LocationRequired().reportable, isFalse);
    });

    test('exhaustive switch over top-level families', () {
      String family(AppFailure f) => switch (f) {
        DomainFailure() => 'domain',
        DataFailure() => 'data',
        NetworkFailure() => 'network',
        PlatformFailure() => 'platform',
      };
      expect(family(const SecurityFailure.unknownKey()), 'data');
      expect(family(const Timeout()), 'network');
    });
  });
}
