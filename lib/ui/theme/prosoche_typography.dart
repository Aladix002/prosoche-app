import 'package:flutter/material.dart';
import 'package:prosoche/ui/tokens/sk_fonts.dart';

/// Typograficke tokeny mimo `TextTheme` (docs/01 2.3.2 a 2.3.3).
/// Pristup: `context.sk.type`.
@immutable
class ProsocheTypography extends ThemeExtension<ProsocheTypography> {
  const ProsocheTypography({
    required this.translation,
    required this.translationReader,
    required this.reflection,
  });

  /// Tokeny pre danu farbu textu.
  factory ProsocheTypography.forColor(Color text) => ProsocheTypography(
    translation: _literata(18, 28, text),
    translationReader: _literata(17, 27, text),
    reflection: _literata(19, 30, text),
  );

  static TextStyle _literata(double size, double lineHeight, Color color) =>
      TextStyle(
        fontFamily: SkFonts.literata,
        fontFamilyFallback: SkFonts.uiFallback,
        fontSize: size,
        height: lineHeight / size,
        fontWeight: FontWeight.w400,
        color: color,
      );

  /// Text citatu na karte (Literata 18/28).
  final TextStyle translation;

  /// Text v citatelovi (Literata 17/27).
  final TextStyle translationReader;

  /// Zamyslenie (Literata 19/30).
  final TextStyle reflection;

  /// Tabularne cislice (casy, pocitadla).
  static TextStyle tabular(TextStyle style) =>
      style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  @override
  ProsocheTypography copyWith({
    TextStyle? translation,
    TextStyle? translationReader,
    TextStyle? reflection,
  }) => ProsocheTypography(
    translation: translation ?? this.translation,
    translationReader: translationReader ?? this.translationReader,
    reflection: reflection ?? this.reflection,
  );

  @override
  ProsocheTypography lerp(
    covariant ThemeExtension<ProsocheTypography>? other,
    double t,
  ) {
    if (other is! ProsocheTypography) return this;
    return ProsocheTypography(
      translation: TextStyle.lerp(translation, other.translation, t)!,
      translationReader: TextStyle.lerp(
        translationReader,
        other.translationReader,
        t,
      )!,
      reflection: TextStyle.lerp(reflection, other.reflection, t)!,
    );
  }
}

/// UI typova skala (docs/01 2.3.2) namapovana na M3 `TextTheme`.
abstract final class SkTextTheme {
  /// [fontFamily] a [heightFactor] meni vyber fontu podla jazyka
  /// (`lib/ui/i18n/`, U-02).
  static TextTheme build({
    required Color primary,
    required Color secondary,
    String fontFamily = SkFonts.inter,
    List<String> fontFamilyFallback = SkFonts.uiFallback,
    double heightFactor = 1,
  }) {
    TextStyle s(double size, double line, FontWeight w, Color c) => TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontSize: size,
      height: line / size * heightFactor,
      fontWeight: w,
      color: c,
      letterSpacing: 0,
    );
    const w4 = FontWeight.w400;
    const w5 = FontWeight.w500;
    const w6 = FontWeight.w600;
    return TextTheme(
      displayLarge: s(45, 52, w4, primary),
      displayMedium: s(40, 48, w4, primary),
      displaySmall: s(34, 40, w6, primary),
      headlineLarge: s(30, 36, w6, primary),
      headlineMedium: s(28, 34, w6, primary),
      headlineSmall: s(26, 32, w6, primary),
      titleLarge: s(20, 28, w6, primary),
      titleMedium: s(17, 24, w5, primary),
      titleSmall: s(15, 22, w5, primary),
      bodyLarge: s(16, 24, w4, primary),
      bodyMedium: s(14, 20, w4, secondary),
      bodySmall: s(12, 16, w4, secondary),
      labelLarge: s(14, 20, w5, primary),
      labelMedium: s(13, 18, w5, primary),
      labelSmall: s(12, 16, w5, secondary),
    );
  }
}
