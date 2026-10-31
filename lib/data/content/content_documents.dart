import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/content/sem_ver.dart';

/// Strukturalne kontroly zrkadlia `prosoche-content/pipeline/sign.py`
/// (`validate_manifest`, kontrakt content.db v1 kap. 8). Parsuju sa az bajty
/// s overenym podpisom. Manifest v1 nema `packs`; `remote_config.json`
/// a `revocations.json` prosoche-content v1 nepublikuje ([RemoteConfig]
/// ostava ako tvar pre buduci kill-switch).

final _sha256Re = RegExp(r'^[0-9a-f]{64}$');
final _tsRe = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$');
final _cardIdRe = RegExp(r'^[a-z][a-z_]*:[A-Za-z0-9_.:-]+$');
final _kidRe = RegExp(r'^[a-z0-9][a-z0-9-]{1,63}$');

/// Chyba tvaru dokumentu, mapuje sa na [ContentIntegrityFailed].
class _Invalid implements Exception {
  const _Invalid();
}

Result<T> _parse<T>(
  Uint8List bytes,
  String check,
  T Function(Map<String, Object?> json) build,
) {
  try {
    final json = jsonDecode(utf8.decode(bytes));
    if (json is! Map<String, Object?>) throw const _Invalid();
    return Ok(build(json));
  } on FormatException {
    return Err(ContentIntegrityFailed(check));
  } on _Invalid {
    return Err(ContentIntegrityFailed(check));
  }
}

String _string(Object? v) => v is String ? v : throw const _Invalid();

int _posInt(Object? v) => v is int && v > 0 ? v : throw const _Invalid();

int _nonNegInt(Object? v) => v is int && v >= 0 ? v : throw const _Invalid();

String _match(Object? v, RegExp re) =>
    v is String && re.hasMatch(v) ? v : throw const _Invalid();

SemVer _semver(Object? v) =>
    v is String && !v.contains('+') && SemVer.tryParse(v) != null
    ? SemVer.parse(v)
    : throw const _Invalid();

DateTime _ts(Object? v) => DateTime.parse(_match(v, _tsRe));

Uri _https(Object? v) {
  final uri = v is String ? Uri.tryParse(v) : null;
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    throw const _Invalid();
  }
  return uri;
}

/// `db` v manifeste.
@immutable
class DbArchiveInfo {
  const DbArchiveInfo({
    required this.url,
    required this.fallbackUrl,
    required this.sha256,
    required this.size,
    required this.gzSha256,
    required this.gzSize,
  });

  /// Kontroly `db` (prosoche-content `validate_manifest`): gzip, https URL,
  /// sha256, kladne velkosti.
  factory DbArchiveInfo._fromJson(Object? v) {
    if (v is! Map<String, Object?>) throw const _Invalid();
    if (v['compression'] != 'gzip') throw const _Invalid();
    return DbArchiveInfo(
      url: _https(v['url']),
      fallbackUrl: _https(v['fallback_url']),
      sha256: _match(v['sha256'], _sha256Re),
      size: _posInt(v['size']),
      gzSha256: _match(v['gz_sha256'], _sha256Re),
      gzSize: _posInt(v['gz_size']),
    );
  }

  final Uri url;
  final Uri fallbackUrl;

  /// Rozbalena db.
  final String sha256;
  final int size;

  /// Stahovany `*.db.gz`.
  final String gzSha256;
  final int gzSize;
}

/// `manifest.json` (kontrakt content.db v1 kap. 8, prosoche-content
/// `build_manifest`).
@immutable
class ContentManifest {
  const ContentManifest({
    required this.contentVersion,
    required this.schemaVersion,
    required this.minAppVersion,
    required this.createdAt,
    required this.db,
    required this.disabledIds,
    required this.sectionsSha256,
    required this.devContent,
  });

  static const schema = 1;

  /// [Err] s `ContentIntegrityFailed('manifest')` pri zlom tvare.
  static Result<ContentManifest> parse(Uint8List bytes) =>
      _parse(bytes, 'manifest', (m) {
        if (m['schema'] != schema) throw const _Invalid();
        _match(m['kid'], _kidRe);
        final ids = m['disabled_ids'];
        if (ids is! List<Object?>) throw const _Invalid();
        final sources = m['sources'];
        if (sources is! List<Object?> || sources.isEmpty) {
          throw const _Invalid();
        }
        final schemaVersion = m['schema_version'];
        if (schemaVersion is! int) throw const _Invalid();
        final dev = m['dev_content'];
        if (dev is! bool) throw const _Invalid();
        return ContentManifest(
          contentVersion: _posInt(m['content_version']),
          schemaVersion: schemaVersion,
          minAppVersion: _semver(m['min_app_version']),
          createdAt: _ts(m['created_at']),
          db: DbArchiveInfo._fromJson(m['db']),
          disabledIds: {for (final id in ids) _match(id, _cardIdRe)},
          sectionsSha256: _match(m['sections_sha256'], _sha256Re),
          devContent: dev,
        );
      });

  final int contentVersion;
  final int schemaVersion;
  final SemVer minAppVersion;
  final DateTime createdAt;
  final DbArchiveInfo db;
  final Set<String> disabledIds;

  /// `meta.sections_sha256` db z manifestu (kontrola po rozbaleni).
  final String sectionsSha256;

  /// Db obsahuje karty `status = draft`; prod flavor taky obsah neprijme.
  final bool devContent;
}

/// Prepinac funkcie v remote configu.
@immutable
class FeatureSwitch {
  const FeatureSwitch({required this.enabled, this.maxVersion});

  final bool enabled;

  /// Ak nie je `null`, [enabled] plati len pre verzie appky <= [maxVersion];
  /// novsie verzie maju funkciu zapnutu (oprava uz je v nich).
  final SemVer? maxVersion;
}

/// Oznam v remote configu (`notice`).
@immutable
class RemoteNotice {
  const RemoteNotice({
    required this.id,
    required this.severity,
    required this.text,
    required this.showOnVersions,
  });

  final String id;
  final String severity;

  /// Jazyk -> text.
  final Map<String, String> text;

  /// Prazdne = vsetky verzie.
  final Set<SemVer> showOnVersions;
}

/// `remote_config.json` (docs/06 A.7).
@immutable
class RemoteConfig {
  const RemoteConfig({
    required this.seq,
    required this.issuedAt,
    required this.expiresAt,
    required this.minSupportedVersion,
    required this.features,
    required this.brokenVersions,
    this.recommendedVersion,
    this.notice,
  });

  static const schema = 1;

  /// [Err] s `ContentIntegrityFailed('remote_config')` pri zlom tvare
  /// alebo ak config obsahuje URL (kill-switch nesmie nic stahovat).
  static Result<RemoteConfig> parse(Uint8List bytes) =>
      _parse(bytes, 'remote_config', (m) {
        if (m['schema'] != schema) throw const _Invalid();
        if (_strings(m).any((s) => s.contains('://'))) throw const _Invalid();
        final issued = _ts(m['issued_at']);
        final expires = _ts(m['expires_at']);
        if (!expires.isAfter(issued)) throw const _Invalid();
        final feats = m['features'];
        if (feats is! Map<String, Object?>) throw const _Invalid();
        final broken = m['broken_versions'] ?? const <Object?>[];
        if (broken is! List<Object?>) throw const _Invalid();
        final rv = m['recommended_version'];
        return RemoteConfig(
          seq: _nonNegInt(m['seq']),
          issuedAt: issued,
          expiresAt: expires,
          minSupportedVersion: _semver(m['min_supported_version']),
          recommendedVersion: rv == null ? null : _semver(rv),
          features: {for (final e in feats.entries) e.key: _feature(e.value)},
          brokenVersions: {for (final v in broken) _semver(v)},
          notice: _notice(m['notice']),
        );
      });

  final int seq;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final SemVer minSupportedVersion;
  final SemVer? recommendedVersion;
  final Map<String, FeatureSwitch> features;
  final Set<SemVer> brokenVersions;
  final RemoteNotice? notice;

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  static FeatureSwitch _feature(Object? v) {
    if (v is! Map<String, Object?>) throw const _Invalid();
    final enabled = v['enabled'];
    if (enabled is! bool) throw const _Invalid();
    final max = v['max_version'];
    return FeatureSwitch(
      enabled: enabled,
      maxVersion: max == null ? null : _semver(max),
    );
  }

  static RemoteNotice? _notice(Object? v) {
    if (v == null) return null;
    if (v is! Map<String, Object?>) throw const _Invalid();
    final text = v['text'];
    final show = v['show_on_versions'] ?? const <Object?>[];
    if (text is! Map<String, Object?> || show is! List<Object?>) {
      throw const _Invalid();
    }
    final id = v['id'];
    final severity = v['severity'];
    if (id is! String || severity is! String) throw const _Invalid();
    return RemoteNotice(
      id: id,
      severity: severity,
      text: {for (final e in text.entries) e.key: _string(e.value)},
      showOnVersions: {for (final s in show) _semver(s)},
    );
  }

  static Iterable<String> _strings(Object? o) sync* {
    if (o is String) {
      yield o;
    } else if (o is Map<String, Object?>) {
      for (final e in o.entries) {
        yield e.key;
        yield* _strings(e.value);
      }
    } else if (o is List<Object?>) {
      for (final v in o) {
        yield* _strings(v);
      }
    }
  }
}
