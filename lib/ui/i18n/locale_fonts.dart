import 'package:flutter/material.dart';
import 'package:prosoche/ui/tokens/sk_fonts.dart';

/// Nazvy rodin fontov z `assets/fonts/` (dodava U-01, docs/01 2.3,
/// PLAN_VYVOJA U-01). Aliasy na [SkFonts], aby sedeli s `family:`
/// v pubspec.yaml (overuje test/ui/i18n/locale_fonts_test.dart).
abstract final class ProsocheFontFamilies {
  static const String inter = SkFonts.inter;
  static const String literata = SkFonts.literata;
}

/// Font a riadkovanie UI pre jeden jazyk.
@immutable
final class LocaleFontSpec {
  const LocaleFontSpec({
    required this.family,
    required this.fallback,
    this.lineHeightScale = 1,
    this.minLineHeight = 0,
  });

  final String family;

  /// Fallback pre znaky mimo [family].
  final List<String> fallback;

  /// Nasobok `height` z typovej skaly (Inter 24/16 = 1.5).
  final double lineHeightScale;

  /// Minimalna `height`; pisma s vysokymi tvarmi by sa pri malej
  /// `height` orezali.
  final double minLineHeight;

  /// Vyska riadku pre styl s povodnou [height] (null = metriky fontu).
  double? scaleHeight(double? height) {
    if (height == null) return minLineHeight > 0 ? minLineHeight : null;
    final scaled = height * lineHeightScale;
    return scaled < minLineHeight ? minLineHeight : scaled;
  }
}

/// Vyber fontu UI podla jazyka (PLAN_VYVOJA U-02). v1 ma len latinku (EN);
/// dalsie pisma sa pridaju s dalsimi jazykmi.
abstract final class LocaleFonts {
  static const latin = LocaleFontSpec(
    family: ProsocheFontFamilies.inter,
    fallback: SkFonts.uiFallback,
  );

  static LocaleFontSpec forLocale(Locale locale) =>
      forLanguage(locale.languageCode);

  static LocaleFontSpec forLanguage(String languageCode) => latin;
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
