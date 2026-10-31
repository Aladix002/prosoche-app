import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stav balika vysvetliviek hadisov `hadith_extra.db` z pohladu karty
/// hadisu (BF-01, docs/02 B5 "Explanation").
enum HadithExplanationsPackStatus {
  /// Stahovanie nie je k dispozicii (default kym D-05 nenapoji
  /// `HadithExtraPackService`): karta ukaze "Explanation" len ked
  /// vysvetlivka existuje.
  notAvailable,

  /// Balik nie je stiahnuty: karta ponukne "Download explanations".
  notDownloaded,

  /// Balik sa stahuje: tlacidlo so spinnerom, disabled.
  downloading,

  /// Balik je stiahnuty a overeny.
  ready,

  /// Posledne stiahnutie zlyhalo: karta ponukne stiahnutie znova.
  failed,
}

/// Rozhranie pre stahovanie balika vysvetliviek z karty hadisu. Implementaciu
/// doda D-05 (`HadithExtraPackService` v `lib/data/content`) cez override
/// [hadithExplanationsPackProvider] v `lib/app` (integracia).
abstract interface class HadithExplanationsPack {
  /// Aktualny stav a jeho zmeny (prva hodnota hned).
  Stream<HadithExplanationsPackStatus> watchStatus();

  /// Stiahne a overi balik; skonci po `ready` alebo `failed`.
  Future<void> download();
}

/// Default bez D-05: stahovanie nie je k dispozicii.
class UnavailableHadithExplanationsPack implements HadithExplanationsPack {
  const UnavailableHadithExplanationsPack();

  @override
  Stream<HadithExplanationsPackStatus> watchStatus() =>
      Stream.value(HadithExplanationsPackStatus.notAvailable);

  @override
  Future<void> download() async {}
}

/// Bod napojenia D-05 (override v `lib/app`).
final Provider<HadithExplanationsPack> hadithExplanationsPackProvider =
    Provider<HadithExplanationsPack>(
      (ref) => const UnavailableHadithExplanationsPack(),
      name: 'hadithExplanationsPackProvider',
    );

/// Stav balika vysvetliviek pre kartu hadisu.
final StreamProvider<HadithExplanationsPackStatus>
hadithExplanationsPackStatusProvider =
    StreamProvider<HadithExplanationsPackStatus>(
      (ref) => ref.watch(hadithExplanationsPackProvider).watchStatus(),
      name: 'hadithExplanationsPackStatusProvider',
    );
