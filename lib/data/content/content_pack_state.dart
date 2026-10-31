import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Odkial je aktivna content.db.
enum ContentDbOrigin { bundled, downloaded }

/// Perzistentny stav obsahu (`<content dir>/state.json`).
///
/// Revokovane `kid` sa len pridavaju, nikdy neodoberaju (docs/06 B.2).
/// Remote config sa uklada ako overene surove bajty a parsuje pri citani.
@immutable
class ContentPackState {
  const ContentPackState({
    this.installedVersion,
    this.origin,
    this.revokedKids = const {},
    this.revocationsSeq = -1,
    this.disabledIds = const {},
    this.disabledIdsVersion = 0,
    this.remoteConfigSeq = -1,
    this.remoteConfigRaw,
    this.remoteConfigFetchedAt,
    this.rejectedVersion,
  });

  factory ContentPackState.fromJson(Map<String, Object?> j) {
    Set<String> strings(Object? v) =>
        v is List<Object?> ? {for (final s in v.whereType<String>()) s} : {};
    final raw = j['remote_config'];
    final fetched = j['remote_config_fetched_at'];
    int? int_(Object? v) => v is int ? v : null;
    final origin = j['origin'];
    return ContentPackState(
      installedVersion: int_(j['installed_version']),
      origin: ContentDbOrigin.values.where((o) => o.name == origin).firstOrNull,
      revokedKids: strings(j['revoked_kids']),
      revocationsSeq: int_(j['revocations_seq']) ?? -1,
      disabledIds: strings(j['disabled_ids']),
      disabledIdsVersion: int_(j['disabled_ids_version']) ?? 0,
      remoteConfigSeq: int_(j['remote_config_seq']) ?? -1,
      remoteConfigRaw: raw is String ? base64Decode(raw) : null,
      remoteConfigFetchedAt: fetched is String
          ? DateTime.tryParse(fetched)
          : null,
      rejectedVersion: int_(j['rejected_version']),
    );
  }

  /// `content_version` aktivnej db (`meta.content_version`, 0 ak nie je
  /// cislo, napr. vyvojovy build).
  final int? installedVersion;
  final ContentDbOrigin? origin;
  final Set<String> revokedKids;
  final int revocationsSeq;

  /// `disabled_ids` z posledneho platneho manifestu (docs/03 7.4).
  final Set<String> disabledIds;

  /// `content_version` manifestu, z ktoreho su [disabledIds].
  final int disabledIdsVersion;
  final int remoteConfigSeq;
  final Uint8List? remoteConfigRaw;
  final DateTime? remoteConfigFetchedAt;

  /// `content_version`, ktorej db opakovane nesedela so sha256; preskakuje
  /// sa do dalsej verzie manifestu (docs/06 C.6).
  final int? rejectedVersion;

  ContentPackState copyWith({
    int? installedVersion,
    ContentDbOrigin? origin,
    Set<String>? revokedKids,
    int? revocationsSeq,
    Set<String>? disabledIds,
    int? disabledIdsVersion,
    int? remoteConfigSeq,
    Uint8List? remoteConfigRaw,
    DateTime? remoteConfigFetchedAt,
    int? rejectedVersion,
  }) => ContentPackState(
    installedVersion: installedVersion ?? this.installedVersion,
    origin: origin ?? this.origin,
    revokedKids: revokedKids ?? this.revokedKids,
    revocationsSeq: revocationsSeq ?? this.revocationsSeq,
    disabledIds: disabledIds ?? this.disabledIds,
    disabledIdsVersion: disabledIdsVersion ?? this.disabledIdsVersion,
    remoteConfigSeq: remoteConfigSeq ?? this.remoteConfigSeq,
    remoteConfigRaw: remoteConfigRaw ?? this.remoteConfigRaw,
    remoteConfigFetchedAt: remoteConfigFetchedAt ?? this.remoteConfigFetchedAt,
    rejectedVersion: rejectedVersion ?? this.rejectedVersion,
  );

  Map<String, Object?> toJson() => {
    'installed_version': installedVersion,
    'origin': origin?.name,
    'revoked_kids': revokedKids.toList()..sort(),
    'revocations_seq': revocationsSeq,
    'disabled_ids': disabledIds.toList()..sort(),
    'disabled_ids_version': disabledIdsVersion,
    'remote_config_seq': remoteConfigSeq,
    'remote_config': remoteConfigRaw == null
        ? null
        : base64Encode(remoteConfigRaw!),
    'remote_config_fetched_at': remoteConfigFetchedAt
        ?.toUtc()
        .toIso8601String(),
    'rejected_version': rejectedVersion,
  };
}

/// Ulozisko [ContentPackState] v JSON subore s atomickym zapisom.
class ContentPackStateStore {
  ContentPackStateStore(this.file);

  final File file;

  /// Poskodeny alebo chybajuci subor = prazdny stav (revokacie z neho sa
  /// stratia, ale zapecene kluce a podpisy ostavaju v platnosti).
  Future<ContentPackState> load() async {
    if (!file.existsSync()) return const ContentPackState();
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is Map<String, Object?>) return ContentPackState.fromJson(json);
    } on FormatException {
      // spadne na prazdny stav
    }
    return const ContentPackState();
  }

  Future<void> save(ContentPackState state) async {
    final tmp = File('${file.path}.tmp');
    await tmp.parent.create(recursive: true);
    await tmp.writeAsString(jsonEncode(state.toJson()), flush: true);
    await tmp.rename(file.path);
  }
}
