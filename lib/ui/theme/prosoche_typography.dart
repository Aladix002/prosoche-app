import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:prosoche/ui/tokens/sk_fonts.dart';

/// Pouzivatelska velkost arabciny, nezavisla od systemoveho textScale
/// (docs/01 2.3.3).
enum SkArabicScale {
  s(0.85),
  m(1),
  l(1.2),
  xl(1.45);

  SkArabicScale(this.factor);

  final double factor;
}

/// Arabsky typograficky token (docs/01 2.3.3). Vykresluje ho len
/// `SkArabicText`.
@immutable
class SkArabicStyle {
  const SkArabicStyle({
    required this.fontFamily,
    required this.fontSize,
    required this.height,
    required this.minFontSize,
  });

  final String fontFamily;

  /// Velkost pri `SkArabicScale.m`.
  final double fontSize;

  /// Line-height (`TextStyle.height`).
  final double height;

  /// Pod tuto velkost sa nikdy nejde (pred systemovym textScale).
  final double minFontSize;

  bool get isQuran => fontFamily == SkFonts.amiriQuran;

  /// Token x pouzivatelsky faktor, nikdy pod [minFontSize].
  double sizeFor(SkArabicScale scale) =>
      math.max(fontSize * scale.factor, minFontSize);

  /// TextStyle podla pravidiel 1.3 a 2.3.3: vaha 400, bez kurzivy,
  /// letter/word spacingu a dekoracie, `locale: ar`, rovnomerny leading.
  TextStyle toTextStyle({
    required Color color,
    SkArabicScale scale = SkArabicScale.m,
  }) => TextStyle(
    inherit: false,
    fontFamily: fontFamily,
    fontSize: sizeFor(scale),
    height: height,
    leadingDistribution: TextLeadingDistribution.even,
    locale: const Locale('ar'),
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.normal,
    letterSpacing: 0,
    wordSpacing: 0,
    decoration: TextDecoration.none,
    color: color,
    textBaseline: TextBaseline.alphabetic,
  );

  SkArabicStyle lerp(SkArabicStyle other, double t) => SkArabicStyle(
    fontFamily: t < 0.5 ? fontFamily : other.fontFamily,
    fontSize: lerpDouble(fontSize, other.fontSize, t)!,
    height: lerpDouble(height, other.height, t)!,
    minFontSize: lerpDouble(minFontSize, other.minFontSize, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is SkArabicStyle &&
      other.fontFamily == fontFamily &&
      other.fontSize == fontSize &&
      other.height == height &&
      other.minFontSize == minFontSize;

  @override
  int get hashCode => Object.hash(fontFamily, fontSize, height, minFontSize);
}

/// Typograficke tokeny mimo `TextTheme` (docs/01 2.3.2 a 2.3.3).
/// Pristup: `context.sk.type`.
@immutable
class ProsocheTypography extends ThemeExtension<ProsocheTypography> {
  const ProsocheTypography({
    required this.translation,
    required this.translationReader,
    required this.reflection,
    this.quranCard = const SkArabicStyle(
      fontFamily: SkFonts.amiriQuran,
      fontSize: 30,
      height: 2,
      minFontSize: 24,
    ),
    this.quranReader = const SkArabicStyle(
      fontFamily: SkFonts.amiriQuran,
      fontSize: 28,
      height: 2.1,
      minFontSize: 22,
    ),
    this.quranWord = const SkArabicStyle(
      fontFamily: SkFonts.amiriQuran,
      fontSize: 40,
      height: 1.8,
      minFontSize: 32,
    ),
    this.bismillah = const SkArabicStyle(
      fontFamily: SkFonts.amiriQuran,
      fontSize: 26,
      height: 2,
      minFontSize: 22,
    ),
    this.arabicBody = const SkArabicStyle(
      fontFamily: SkFonts.notoNaskhArabic,
      fontSize: 24,
      height: 1.8,
      minFontSize: 20,
    ),
    this.arabicLemma = const SkArabicStyle(
      fontFamily: SkFonts.notoNaskhArabic,
      fontSize: 48,
      height: 1.6,
      minFontSize: 36,
    ),
    this.arabicName = const SkArabicStyle(
      fontFamily: SkFonts.notoNaskhArabic,
      fontSize: 44,
      height: 1.6,
      minFontSize: 32,
    ),
    this.arabicScale = SkArabicScale.m,
  });

  /// Tokeny pre danu farbu textu prekladu.
  factory ProsocheTypography.forColor(
    Color text, {
    SkArabicScale arabicScale = SkArabicScale.m,
  }) => ProsocheTypography(
    translation: _literata(18, 28, text),
    translationReader: _literata(17, 27, text),
    reflection: _literata(19, 30, text),
    arabicScale: arabicScale,
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

  /// Faktor `quranInline` voci okolitemu textu.
  static const quranInlineFactor = 1.25;

  /// Preklad versa na karte (Literata 18/28).
  final TextStyle translation;

  /// Preklad v citatelovi (Literata 17/27).
  final TextStyle translationReader;

  /// Zamyslenie (Literata 19/30).
  final TextStyle reflection;

  final SkArabicStyle quranCard;
  final SkArabicStyle quranReader;
  final SkArabicStyle quranWord;
  final SkArabicStyle bismillah;
  final SkArabicStyle arabicBody;
  final SkArabicStyle arabicLemma;
  final SkArabicStyle arabicName;

  /// Pouzivatelske nastavenie velkosti arabciny.
  final SkArabicScale arabicScale;

  /// Kratka koranova fraza v latinskom texte velkosti [surroundingSize].
  SkArabicStyle quranInline(double surroundingSize) => SkArabicStyle(
    fontFamily: SkFonts.amiriQuran,
    fontSize: surroundingSize * quranInlineFactor,
    height: 1.9,
    minFontSize: 0,
  );

  /// Tabularne cislice (casy modlitieb).
  static TextStyle tabular(TextStyle style) =>
      style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  @override
  ProsocheTypography copyWith({
    TextStyle? translation,
    TextStyle? translationReader,
    TextStyle? reflection,
    SkArabicScale? arabicScale,
  }) => ProsocheTypography(
    translation: translation ?? this.translation,
    translationReader: translationReader ?? this.translationReader,
    reflection: reflection ?? this.reflection,
    quranCard: quranCard,
    quranReader: quranReader,
    quranWord: quranWord,
    bismillah: bismillah,
    arabicBody: arabicBody,
    arabicLemma: arabicLemma,
    arabicName: arabicName,
    arabicScale: arabicScale ?? this.arabicScale,
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
      quranCard: quranCard.lerp(other.quranCard, t),
      quranReader: quranReader.lerp(other.quranReader, t),
      quranWord: quranWord.lerp(other.quranWord, t),
      bismillah: bismillah.lerp(other.bismillah, t),
      arabicBody: arabicBody.lerp(other.arabicBody, t),
      arabicLemma: arabicLemma.lerp(other.arabicLemma, t),
      arabicName: arabicName.lerp(other.arabicName, t),
      arabicScale: t < 0.5 ? arabicScale : other.arabicScale,
    );
  }
}

/// UI typova skala (docs/01 2.3.2) namapovana na M3 `TextTheme`.
abstract final class SkTextTheme {
  /// [fontFamily] a [heightFactor] meni vyber fontu podla jazyka
  /// (`lib/ui/i18n/`, U-02), napr. Nastaliq ma vacsiu vysku riadku.
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
