import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/content/sem_ver.dart';

/// Strukturalne kontroly zrkadlia `prosoche-content/pipeline/manifest.py`
/// (`validate_manifest`, `validate_remote_config`, `validate_revocations`).
/// Parsuju sa az bajty s overenym podpisom.

final _sha256Re = RegExp(r'^[0-9a-f]{64}$');
final _tsRe = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$');
final _cardIdRe = RegExp(r'^[a-z][a-z_]*:[A-Za-z0-9_.:-]+$');
final _kidRe = RegExp(r'^[a-z0-9][a-z0-9-]{1,63}$');
final _packIdRe = RegExp(r'^[a-z][a-z0-9_]{0,63}$');

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

/// `db` alebo balik z `packs` v manifeste.
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

  /// Spolocne kontroly pre `db` a kazdy balik (prosoche-content
  /// `_artifact_errors`): gzip, https URL, sha256, kladne velkosti.
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

/// Volitelny obsahovy balik z `packs` v manifeste (C-06). `ContentPackService`
/// ho ignoruje; stahovanie balikov zatial nie je (F-01 rozhodne o pouziti).
@immutable
class ContentPackInfo {
  const ContentPackInfo({
    required this.id,
    required this.archive,
    required this.schemaVersion,
    required this.optional,
  });

  final String id;
  final DbArchiveInfo archive;

  /// `PRAGMA user_version` balika.
  final int schemaVersion;
  final bool optional;
}

/// `manifest.json` (docs/06 B.2, prosoche-content `build_manifest`).
@immutable
class ContentManifest {
  const ContentManifest({
    required this.contentVersion,
    required this.schemaVersion,
    required this.minAppVersion,
    required this.createdAt,
    required this.db,
    required this.disabledIds,
    this.packs = const {},
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
        return ContentManifest(
          contentVersion: _posInt(m['content_version']),
          schemaVersion: schemaVersion,
          minAppVersion: _semver(m['min_app_version']),
          createdAt: _ts(m['created_at']),
          db: DbArchiveInfo._fromJson(m['db']),
          disabledIds: {for (final id in ids) _match(id, _cardIdRe)},
          // Chybajuce pole = ziadne baliky (format C-05).
          packs: m.containsKey('packs') ? _packs(m['packs']) : const {},
        );
      });

  /// `packs` podla prosoche-content `_packs_errors`.
  static Map<String, ContentPackInfo> _packs(Object? v) {
    if (v is! List<Object?>) throw const _Invalid();
    final out = <String, ContentPackInfo>{};
    for (final p in v) {
      if (p is! Map<String, Object?>) throw const _Invalid();
      final id = _match(p['id'], _packIdRe);
      if (out.containsKey(id)) throw const _Invalid();
      final optional = p['optional'];
      if (optional is! bool) throw const _Invalid();
      out[id] = ContentPackInfo(
        id: id,
        archive: DbArchiveInfo._fromJson(p),
        schemaVersion: _posInt(p['schema_version']),
        optional: optional,
      );
    }
    return out;
  }

  final int contentVersion;
  final int schemaVersion;
  final SemVer minAppVersion;
  final DateTime createdAt;
  final DbArchiveInfo db;
  final Set<String> disabledIds;

  /// Volitelne baliky podla `id` (prazdne, ak manifest `packs` nema).
  final Map<String, ContentPackInfo> packs;
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

/// `revocations.json` (docs/06 B.2), podpisany len root klucom.
@immutable
class Revocations {
  const Revocations({required this.seq, required this.revoked});

  static const schema = 1;

  /// [rootKids]: root kluc sa suborom nerevokuje (len novou binarkou).
  static Result<Revocations> parse(
    Uint8List bytes, {
    Iterable<String> rootKids = const [],
  }) => _parse(bytes, 'revocations', (m) {
    if (m['schema'] != schema) throw const _Invalid();
    _ts(m['issued_at']);
    final rev = m['revoked'];
    if (rev is! List<Object?>) throw const _Invalid();
    final kids = {for (final k in rev) _match(k, _kidRe)};
    if (kids.any(rootKids.contains)) throw const _Invalid();
    return Revocations(seq: _nonNegInt(m['seq']), revoked: kids);
  });

  final int seq;
  final Set<String> revoked;
}
