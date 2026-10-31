import 'package:meta/meta.dart';
import 'package:prosoche/core/result.dart';

/// Stav balika `hadith_extra.db` (D-05) pre UI: karta hadisu
/// ("Download explanations") a nastavenia.
@immutable
sealed class HadithExtraPackStatus {
  const HadithExtraPackStatus();

  /// Ci ma UI ponuknut stiahnutie (prve, znova po aktualizacii obsahu
  /// alebo po chybe).
  bool get canDownload => false;

  /// Ci su vysvetlivky dostupne (repozitar vracia data).
  bool get isReady => false;
}

/// Aktivna content.db balik neohlasuje (`meta.hadith_extra_sha256`
/// chyba): tlacidlo sa neukazuje.
final class HadithExtraUnavailable extends HadithExtraPackStatus {
  const HadithExtraUnavailable();

  @override
  bool operator ==(Object other) => other is HadithExtraUnavailable;

  @override
  int get hashCode => (HadithExtraUnavailable).hashCode;
}

/// Balik este nie je stiahnuty.
final class HadithExtraNotDownloaded extends HadithExtraPackStatus {
  const HadithExtraNotDownloaded();

  @override
  bool get canDownload => true;

  @override
  bool operator ==(Object other) => other is HadithExtraNotDownloaded;

  @override
  int get hashCode => (HadithExtraNotDownloaded).hashCode;
}

/// Stahovanie a overovanie bezi.
final class HadithExtraDownloading extends HadithExtraPackStatus {
  const HadithExtraDownloading({this.receivedBytes = 0, this.totalBytes});

  /// Stiahnute bajty `hadith_extra.db.gz` (aktualny pokus).
  final int receivedBytes;

  /// `gz_size` z manifestu; `null`, kym sa manifest nenacita.
  final int? totalBytes;

  /// 0.0-1.0, `null` = neurcity priebeh (manifest, overovanie).
  double? get progress {
    final total = totalBytes;
    if (total == null || total <= 0) return null;
    return (receivedBytes / total).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      other is HadithExtraDownloading &&
      other.receivedBytes == receivedBytes &&
      other.totalBytes == totalBytes;

  @override
  int get hashCode => Object.hash(receivedBytes, totalBytes);
}

/// Balik je overeny, sedi s aktivnou content.db a da sa citat.
final class HadithExtraReady extends HadithExtraPackStatus {
  const HadithExtraReady({required this.sizeBytes});

  /// Velkost rozbalenej `hadith_extra.db` (napr. pre nastavenia).
  final int sizeBytes;

  @override
  bool get isReady => true;

  @override
  bool operator ==(Object other) =>
      other is HadithExtraReady && other.sizeBytes == sizeBytes;

  @override
  int get hashCode => sizeBytes.hashCode;
}

/// Na disku je balik k inej (starsej) content.db: vysvetlivky su
/// nedostupne, kym sa nestiahne novy.
final class HadithExtraStale extends HadithExtraPackStatus {
  const HadithExtraStale();

  @override
  bool get canDownload => true;

  @override
  bool operator ==(Object other) => other is HadithExtraStale;

  @override
  int get hashCode => (HadithExtraStale).hashCode;
}

/// Posledne stiahnutie zlyhalo; content.db aj predchadzajuci subor
/// balika ostali nedotknute. UI mapuje [failure] `code` na
/// `error_<code>` a ponukne opakovanie.
final class HadithExtraFailed extends HadithExtraPackStatus {
  const HadithExtraFailed(this.failure);

  final AppFailure failure;

  @override
  bool get canDownload => true;

  @override
  bool operator ==(Object other) =>
      other is HadithExtraFailed && other.failure.code == failure.code;

  @override
  int get hashCode => failure.code.hashCode;
}
