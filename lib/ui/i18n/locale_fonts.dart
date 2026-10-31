import 'package:flutter/material.dart';
import 'package:prosoche/ui/tokens/sk_fonts.dart';

/// Nazvy rodin fontov z `assets/fonts/` (dodava U-01, docs/01 2.3,
/// PLAN_VYVOJA U-01). Aliasy na [SkFonts], aby sedeli s `family:`
/// v pubspec.yaml (overuje test/ui/i18n/locale_fonts_test.dart).
abstract final class ProsocheFontFamilies {
  static const String inter = SkFonts.inter;
  static const String literata = SkFonts.literata;
  static const String notoNaskhArabic = SkFonts.notoNaskhArabic;
  static const String notoNastaliqUrdu = SkFonts.notoNastaliqUrdu;
  static const String notoSansBengali = SkFonts.notoSansBengali;
}

/// Font a riadkovanie UI pre jeden jazyk. Koranovy text sem nepatri
/// (Amiri Quran, len cez `SkArabicText`).
@immutable
final class LocaleFontSpec {
  const LocaleFontSpec({
    required this.family,
    required this.fallback,
    this.lineHeightScale = 1,
    this.minLineHeight = 0,
  });

  final String family;

  /// Fallback pre znaky mimo [family] (latinka v arabskom UI, `ﷺ`, ...).
  final List<String> fallback;

  /// Nasobok `height` z typovej skaly (Inter 24/16 = 1.5).
  final double lineHeightScale;

  /// Minimalna `height`; pisma s vysokymi tvarmi (Nastaliq) by sa pri
  /// male `height` orezali.
  final double minLineHeight;

  /// Vyska riadku pre styl s povodnou [height] (null = metriky fontu).
  double? scaleHeight(double? height) {
    if (height == null) return minLineHeight > 0 ? minLineHeight : null;
    final scaled = height * lineHeightScale;
    return scaled < minLineHeight ? minLineHeight : scaled;
  }
}

/// Vyber fontu UI podla jazyka (PLAN_VYVOJA U-02). Hodnoty riadkovania su
/// vychodiskove, overia ich goldeny s realnymi fontami (Q-03).
abstract final class LocaleFonts {
  static const latin = LocaleFontSpec(
    family: ProsocheFontFamilies.inter,
    fallback: [ProsocheFontFamilies.notoNaskhArabic],
  );

  static const arabic = LocaleFontSpec(
    family: ProsocheFontFamilies.notoNaskhArabic,
    fallback: [ProsocheFontFamilies.inter],
    lineHeightScale: 1.15,
    minLineHeight: 1.6,
  );

  /// Nastaliq ma velky vertikalny rozsah (sikme spojenia), preto vyrazne
  /// vacsia vyska riadku.
  static const urdu = LocaleFontSpec(
    family: ProsocheFontFamilies.notoNastaliqUrdu,
    fallback: [
      ProsocheFontFamilies.notoNaskhArabic,
      ProsocheFontFamilies.inter,
    ],
    lineHeightScale: 1.5,
    minLineHeight: 2.2,
  );

  static const bengali = LocaleFontSpec(
    family: ProsocheFontFamilies.notoSansBengali,
    fallback: [
      ProsocheFontFamilies.inter,
      ProsocheFontFamilies.notoNaskhArabic,
    ],
    lineHeightScale: 1.15,
    minLineHeight: 1.6,
  );

  static LocaleFontSpec forLocale(Locale locale) =>
      forLanguage(locale.languageCode);

  static LocaleFontSpec forLanguage(String languageCode) =>
      switch (languageCode) {
        'ar' => arabic,
        'ur' => urdu,
        'bn' => bengali,
        _ => latin,
      };
}

/// Aplikuje font jazyka na [style]: rodina, fallback a riadkovanie
/// s rovnomernym rozlozenim (diakritika sa neoreze hore ani dole).
TextStyle applyLocaleFont(TextStyle style, Locale locale) {
  final spec = LocaleFonts.forLocale(locale);
  return style.copyWith(
    fontFamily: spec.family,
    fontFamilyFallback: spec.fallback,
    height: spec.scaleHeight(style.height),
    leadingDistribution: TextLeadingDistribution.even,
  );
}

/// Aplikuje font jazyka na vsetky styly [theme] (pre `ThemeData.textTheme`
/// v `MaterialApp.builder` alebo v teme z U-01).
TextTheme applyLocaleFontToTextTheme(TextTheme theme, Locale locale) {
  TextStyle? f(TextStyle? s) => s == null ? null : applyLocaleFont(s, locale);
  return theme.copyWith(
    displayLarge: f(theme.displayLarge),
    displayMedium: f(theme.displayMedium),
    displaySmall: f(theme.displaySmall),
    headlineLarge: f(theme.headlineLarge),
    headlineMedium: f(theme.headlineMedium),
    headlineSmall: f(theme.headlineSmall),
    titleLarge: f(theme.titleLarge),
    titleMedium: f(theme.titleMedium),
    titleSmall: f(theme.titleSmall),
    bodyLarge: f(theme.bodyLarge),
    bodyMedium: f(theme.bodyMedium),
    bodySmall: f(theme.bodySmall),
    labelLarge: f(theme.labelLarge),
    labelMedium: f(theme.labelMedium),
    labelSmall: f(theme.labelSmall),
  );
}
