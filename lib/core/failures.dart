/// Taxonomia ocakavanych chyb (docs/06 C.2).
///
/// [code] je stabilny identifikator do logov a Sentry. Nikdy neobsahuje
/// data pouzivatela. UI ho mapuje na l10n kluc `error_<code>`.
sealed class AppFailure {
  const AppFailure();

  String get code;
  bool get retryable => false;

  /// Ci ide do Sentry ako handled event.
  bool get reportable => false;

  @override
  String toString() => 'AppFailure($code)';
}

// --- domain: porusene biznis pravidla, validacia ---
sealed class DomainFailure extends AppFailure {
  const DomainFailure();
}

final class InvalidImportFile extends DomainFailure {
  const InvalidImportFile(this.reason);

  /// 'schema', 'too_large', 'version'
  final String reason;

  @override
  String get code => 'domain.import_invalid.$reason';
}

final class LocationRequired extends DomainFailure {
  const LocationRequired();

  @override
  String get code => 'domain.location_required';
}

// --- data: DB, subory, integrita obsahu ---
sealed class DataFailure extends AppFailure {
  const DataFailure();
}

final class DbCorrupted extends DataFailure {
  const DbCorrupted(this.db);

  /// 'user' | 'content'
  final String db;

  @override
  String get code => 'data.db_corrupted.$db';

  @override
  bool get reportable => true;
}

final class MigrationFailed extends DataFailure {
  const MigrationFailed(this.from, this.to);
  final int from;
  final int to;

  @override
  String get code => 'data.migration_failed';

  @override
  bool get reportable => true;
}

final class ContentIntegrityFailed extends DataFailure {
  const ContentIntegrityFailed(this.check);

  /// 'ayah_count' | 'uthmani_hash' | 'sha256' | 'dev_content' (placeholder
  /// obsah v release, `meta.dev_content`, D-01)
  final String check;

  @override
  String get code => 'data.content_integrity.$check';

  @override
  bool get reportable => true;
}

final class StorageFull extends DataFailure {
  const StorageFull();

  @override
  String get code => 'data.storage_full';
}

// --- security: podpisy obsahu ---
sealed class SecurityFailure extends DataFailure {
  const SecurityFailure();

  const factory SecurityFailure.badSignature() = _Sec._bad;
  const factory SecurityFailure.unknownKey() = _Sec._unknownKey;
  const factory SecurityFailure.revokedKey() = _Sec._revoked;
  const factory SecurityFailure.wrongKeyRole() = _Sec._role;
  const factory SecurityFailure.malformedSignature() = _Sec._malformed;
  const factory SecurityFailure.unknownAlgorithm() = _Sec._alg;
  const factory SecurityFailure.rollback() = _Sec._rollback;

  @override
  bool get reportable => true;
}

final class _Sec extends SecurityFailure {
  const _Sec._bad() : code = 'security.bad_signature';
  const _Sec._unknownKey() : code = 'security.unknown_key';
  const _Sec._revoked() : code = 'security.revoked_key';
  const _Sec._role() : code = 'security.wrong_key_role';
  const _Sec._malformed() : code = 'security.malformed_signature';
  const _Sec._alg() : code = 'security.unknown_alg';
  const _Sec._rollback() : code = 'security.version_rollback';

  @override
  final String code;
}

// --- network ---
sealed class NetworkFailure extends AppFailure {
  const NetworkFailure();
}

final class Offline extends NetworkFailure {
  const Offline();

  @override
  String get code => 'net.offline';

  @override
  bool get retryable => true;
}

final class Timeout extends NetworkFailure {
  const Timeout();

  @override
  String get code => 'net.timeout';

  @override
  bool get retryable => true;
}

final class HttpStatus extends NetworkFailure {
  const HttpStatus(this.status);
  final int status;

  @override
  String get code => 'net.http.$status';

  @override
  bool get retryable => status == 408 || status == 429 || status >= 500;
}

// --- platform: povolenia, nativny kod, OS obmedzenia ---
sealed class PlatformFailure extends AppFailure {
  const PlatformFailure();
}

final class PermissionDenied extends PlatformFailure {
  const PermissionDenied(this.permission, {this.permanently = false});

  /// 'usage_stats' | 'overlay' | 'notifications' | 'exact_alarm' | 'location'
  final String permission;
  final bool permanently;

  @override
  String get code => 'platform.permission_denied.$permission';
}

final class NativeFailure extends PlatformFailure {
  const NativeFailure(this.nativeCode, this.channel);

  /// Kod z Pigeon `FlutterError`.
  final String nativeCode;
  final String channel;

  @override
  String get code => 'platform.native.$channel.$nativeCode';

  @override
  bool get reportable => true;
}

final class UnsupportedOnPlatform extends PlatformFailure {
  const UnsupportedOnPlatform(this.feature);
  final String feature;

  @override
  String get code => 'platform.unsupported.$feature';
}
