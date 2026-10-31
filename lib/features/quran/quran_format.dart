import 'package:flutter/widgets.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/ui/i18n/i18n.dart';

/// Formaty pre obrazovky Koranu v jazyku UI (cislice, bidi izolacia).
extension QuranFormatX on BuildContext {
  ProsocheFormats get quranFormats =>
      ProsocheFormats(Localizations.localeOf(this));

  /// Cislo v cisliciach UI.
  String quranNumber(int n) => quranFormats.number(n);

  /// `Al-Baqarah 2:255` s izolovanym nazvom a referenciou (docs/02 B0.4).
  String ayahReference(String surahName, AyahId id) =>
      '${Bidi.isolate(surahName)} ${quranFormats.ayahRef(id.surah, id.ayah)}';

  /// Referencia pre screen reader slovami (docs/01 8.2).
  String ayahSemantics(String surahName, AyahId id) =>
      l10n.quranAyahSemantics(surahName, quranNumber(id.ayah));

  /// `Meccan` / `Medinan`.
  String revelationLabel(SurahInfo surah) => surah.revelationPlace == 'medinan'
      ? l10n.quranRevelationMedinan
      : l10n.quranRevelationMeccan;
}

/// Koncovy znak versa `U+06DD` s arabsko-indickymi cislicami, oddeleny
/// NBSP, aby sa neodtrhol od posledneho slova (docs/01 1.3 bod 7). Je to
/// samostatny segment; text versa ostava bajtovo `ayah.text_uthmani`.
/// Vykresluje sa len ako segment `SkArabicText.quran`.
String verseEndMarker(int number) =>
    // prosoche-lint: ignore prosoche_arabic_text_outside_sk_arabic_text
    '\u00A0\u06DD${localizeDigits('$number', DigitStyle.arabicIndic)}';

/// Atribucia prekladu zo zdroja (docs/09 2.2: vydavatel, QuranEnc.com,
/// cislo verzie). Retazec `source.attribution` sa zobrazi doslovne a raz;
/// verzia sa prida len ak v nom este nie je (BF-02: RC0 ju ukazal dvakrat).
String translationAttribution(BuildContext context, TranslationSource s) {
  final attribution = s.attribution.trim();
  final version = s.version.trim();
  if (version.isEmpty || attribution.contains(version)) {
    return attribution.isEmpty ? s.name : attribution;
  }
  return context.l10n.quranTranslationVersion(
    version,
    attribution.isEmpty ? s.name : attribution,
  );
}
