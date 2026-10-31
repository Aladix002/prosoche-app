import 'package:meta/meta.dart';
import 'package:prosoche/data/content/content_documents.dart';
import 'package:prosoche/data/content/sem_ver.dart';

/// Nazvy funkcii v `remote_config.json` `features` (docs/06 A.7).
abstract final class RemoteFeature {
  static const blockerOverlay = 'blocker_overlay';
  static const contentAutoUpdate = 'content_auto_update';
  static const audioStream = 'audio_stream';
  static const posthog = 'posthog';
}

/// Kill-switch pre beziacu verziu appky (docs/06 A.7, A.8).
///
/// [config] je posledny overeny a neexpirovany config, alebo `null`
/// (offline, expirovany, nikdy nestiahnuty): vtedy platia defaulty z kodu,
/// vsetko zapnute a ziadna vynutena aktualizacia.
@immutable
class RemoteConfigPolicy {
  const RemoteConfigPolicy(this.config, this.appVersion);

  final RemoteConfig? config;
  final SemVer appVersion;

  /// Neznama funkcia alebo chybajuci config = zapnute.
  bool isFeatureEnabled(String feature) {
    final f = config?.features[feature];
    if (f == null || f.enabled) return true;
    final max = f.maxVersion;
    return max != null && appVersion > max;
  }

  /// Blokujuca obrazovka "Aktualizuj" (A.8): verzia <
  /// `min_supported_version` alebo v `broken_versions`.
  bool get updateRequired {
    final c = config;
    if (c == null) return false;
    return appVersion < c.minSupportedVersion ||
        c.brokenVersions.contains(appVersion);
  }

  /// `recommended_version` > aktualna verzia.
  bool get updateRecommended {
    final r = config?.recommendedVersion;
    return r != null && appVersion < r;
  }

  /// Oznam pre tuto verziu (prazdne `show_on_versions` = vsetky).
  RemoteNotice? get notice {
    final n = config?.notice;
    if (n == null) return null;
    if (n.showOnVersions.isEmpty || n.showOnVersions.contains(appVersion)) {
      return n;
    }
    return null;
  }
}
