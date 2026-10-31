import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/ui/theme/prosoche_typography.dart';

// Providery obrazoviek Koranu (A5). Data idu len cez D-02 repozitare.

/// Sura podla cisla (hlavicka readera, bismillah).
final FutureProviderFamily<SurahInfo?, int> quranSurahProvider =
    FutureProvider.family<SurahInfo?, int>((ref, id) async {
      final lang = await ref.watch(contentLanguageProvider.future);
      return await ref.watch(quranRepositoryProvider).surah(id, lang);
    }, name: 'quranSurahProvider');

/// Prvy vers kazdeho juz (zalozka Juz, A5.1).
final FutureProvider<List<JuzStart>> juzStartsProvider =
    FutureProvider<List<JuzStart>>(
      (ref) => ref.watch(quranRepositoryProvider).juzStarts(),
      name: 'juzStartsProvider',
    );

/// Zdroje prekladu pre jazyk (vyber prekladu, atribucia).
final FutureProviderFamily<List<TranslationSource>, String>
translationSourcesProvider =
    FutureProvider.family<List<TranslationSource>, String>(
      (ref, lang) =>
          ref.watch(quranRepositoryProvider).translationSources(lang),
      name: 'translationSourcesProvider',
    );

/// Zvoleny zdroj prekladu jazyka obsahu (`translation.{lang}`).
final FutureProvider<TranslationSource?> selectedTranslationProvider =
    FutureProvider<TranslationSource?>((ref) async {
      final lang = await ref.watch(contentLanguageProvider.future);
      ref.watch(settingProvider(SettingsKeys.translation(lang)));
      return await ref.watch(quranRepositoryProvider).selectedTranslation(lang);
    }, name: 'selectedTranslationProvider');

/// Vyhladavanie (A5.4). Kluc = orezany dotaz (min 2 znaky riesi repozitar).
final FutureProviderFamily<QuranSearchResult, String> quranSearchProvider =
    FutureProvider.autoDispose.family<QuranSearchResult, String>((
      ref,
      query,
    ) async {
      final lang = await ref.watch(contentLanguageProvider.future);
      return await ref.watch(quranRepositoryProvider).search(query, lang: lang);
    }, name: 'quranSearchProvider');

/// `display.arabic_scale` ako krok [SkArabicScale] (najblizsi faktor).
final ProviderListenable<SkArabicScale> readerArabicScaleProvider =
    settingProvider(SettingsKeys.displayArabicScale)
        .select((v) => arabicScaleOf((v.value as double?) ?? 1));

/// `display.translation` (default zapnute).
final ProviderListenable<bool> readerShowTranslationProvider = settingProvider(
  SettingsKeys.displayTranslation,
).select((v) => (v.value as bool?) ?? true);

/// `reader.last_ayah_id` (posledny otvoreny vers v browse mode).
final ProviderListenable<AyahId?> readerLastAyahProvider =
    settingProvider(SettingsKeys.readerLastAyahId).select(
      (v) => switch (v.value) {
        final int id => AyahId.tryFromValue(id),
        _ => null,
      },
    );

/// Najblizsi krok velkosti arabciny k ulozenemu faktoru.
SkArabicScale arabicScaleOf(double factor) {
  var best = SkArabicScale.m;
  for (final s in SkArabicScale.values) {
    if ((s.factor - factor).abs() < (best.factor - factor).abs()) best = s;
  }
  return best;
}
