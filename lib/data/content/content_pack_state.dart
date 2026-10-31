import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

/// Odkial je aktivna content.db.
enum ContentDbOrigin { bundled, downloaded }

/// Perzistentny stav obsahu (`<content dir>/state.json`).
///
/// Starsie kluce (`revoked_kids`, `remote_config*` z Mursy) sa pri citani
/// ignoruju a pri dalsom zapise zmiznu.
@immutable
class ContentPackState {
  const ContentPackState({
    this.installedVersion,
    this.origin,
    this.disabledIds = const {},
    this.disabledIdsVersion = 0,
    this.rejectedVersion,
  });

  factory ContentPackState.fromJson(Map<String, Object?> j) {
    Set<String> strings(Object? v) =>
        v is List<Object?> ? {for (final s in v.whereType<String>()) s} : {};
    int? int_(Object? v) => v is int ? v : null;
    final origin = j['origin'];
    return ContentPackState(
      installedVersion: int_(j['installed_version']),
      origin: ContentDbOrigin.values.where((o) => o.name == origin).firstOrNull,
      disabledIds: strings(j['disabled_ids']),
      disabledIdsVersion: int_(j['disabled_ids_version']) ?? 0,
      rejectedVersion: int_(j['rejected_version']),
    );
  }

  /// `content_version` aktivnej db (`meta.content_version`, 0 ak nie je
  /// cislo, napr. vyvojovy build).
  final int? installedVersion;
  final ContentDbOrigin? origin;

  /// `disabled_ids` z posledneho platneho manifestu (docs/03 7.4).
  final Set<String> disabledIds;

  /// `content_version` manifestu, z ktoreho su [disabledIds].
  final int disabledIdsVersion;

  /// `content_version`, ktorej db opakovane nesedela so sha256; preskakuje
  /// sa do dalsej verzie manifestu (docs/06 C.6).
  final int? rejectedVersion;

  ContentPackState copyWith({
    int? installedVersion,
    ContentDbOrigin? origin,
    Set<String>? disabledIds,
    int? disabledIdsVersion,
    int? rejectedVersion,
  }) => ContentPackState(
    installedVersion: installedVersion ?? this.installedVersion,
    origin: origin ?? this.origin,
    disabledIds: disabledIds ?? this.disabledIds,
    disabledIdsVersion: disabledIdsVersion ?? this.disabledIdsVersion,
    rejectedVersion: rejectedVersion ?? this.rejectedVersion,
  );

  Map<String, Object?> toJson() => {
    'installed_version': installedVersion,
    'origin': origin?.name,
    'disabled_ids': disabledIds.toList()..sort(),
    'disabled_ids_version': disabledIdsVersion,
    'rejected_version': rejectedVersion,
  };
}

/// Ulozisko [ContentPackState] v JSON subore s atomickym zapisom.
class ContentPackStateStore {
  ContentPackStateStore(this.file);

  final File file;

  /// Poskodeny alebo chybajuci subor = prazdny stav (zapecene kluce
  /// a podpisy ostavaju v platnosti).
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
