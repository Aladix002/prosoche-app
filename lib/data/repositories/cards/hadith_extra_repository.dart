import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:meta/meta.dart';

/// Vysvetlivka hadisu HadeethEnc (balik `hadith_extra.db`, C-06/D-05).
/// content.db v3 ju uz nema (`hadith_text` bez `explanation`, `hints`).
@immutable
final class HadithExtra {
  const HadithExtra({
    required this.hadithId,
    required this.lang,
    this.explanation,
    this.hints,
  });

  final int hadithId;
  final String lang;
  final String? explanation;
  final String? hints;
}

/// Vysvetlivky hadisov na poziadanie (karta hadisu "Explanation", D-05).
abstract interface class HadithExtraRepository {
  /// null = balik nie je stiahnuty alebo vysvetlivka chyba.
  Future<HadithExtra?> explanation(int hadithId, String lang);
}

/// Kym D-05 nedoda balik: ziadne vysvetlivky.
class NoHadithExtraRepository implements HadithExtraRepository {
  const NoHadithExtraRepository();

  @override
  Future<HadithExtra?> explanation(int hadithId, String lang) async => null;
}

/// Override point pre D-05.
final Provider<HadithExtraRepository> hadithExtraRepositoryProvider =
    Provider<HadithExtraRepository>(
      (ref) => const NoHadithExtraRepository(),
      name: 'hadithExtraRepositoryProvider',
    );

/// Vysvetlivka hadisu `(hadithId, lang)`; null = nedostupna.
final FutureProviderFamily<HadithExtra?, (int, String)> hadithExtraProvider =
    FutureProvider.family<HadithExtra?, (int, String)>(
      (ref, key) =>
          ref.watch(hadithExtraRepositoryProvider).explanation(key.$1, key.$2),
      name: 'hadithExtraProvider',
    );
