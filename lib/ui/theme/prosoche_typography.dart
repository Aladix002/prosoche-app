import 'package:flutter/material.dart';
import 'package:prosoche/ui/theme/prosoche_colors.dart';
import 'package:prosoche/ui/tokens/sk_fonts.dart';

/// Textove tokeny mimo `TextTheme` (docs/DESIGN.md 3.3).
/// Pristup: `context.sk.type`.
@immutable
class ProsocheTypography extends ThemeExtension<ProsocheTypography> {
  const ProsocheTypography({
    required this.quote,
    required this.passage,
    required this.prompt,
    required this.reader,
    required this.term,
    required this.reference,
    required this.attribution,
    required this.eyebrow,
    required this.numeral,
  });

  /// Tokeny pre danu paletu.
  factory ProsocheTypography.of(ProsocheColors c) => ProsocheTypography(
    quote: _serif(22, 32, c.lead),
    passage: _serif(19, 29, c.lead),
    prompt: _serif(22, 32, c.lead, italic: true),
    reader: _serif(19, 30, c.lead),
    term: _serif(34, 42, c.lead, weight: FontWeight.w500),
    reference: _serif(17, 24, c.textPrimary, weight: FontWeight.w500),
    attribution: _serif(15, 22, c.textSecondary, italic: true),
    eyebrow: const TextStyle(
      fontFamily: SkFonts.inter,
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.6,
    ).copyWith(color: c.accentText),
    numeral: TextStyle(
      fontFamily: SkFonts.inter,
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w500,
      color: c.textTertiary,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );

  /// Kompatibilita s kodom z forku: len farba textu.
  factory ProsocheTypography.forColor(Color text) => ProsocheTypography.of(
    ProsocheColors.light.copyWith(lead: text, textPrimary: text),
  );

  static TextStyle _serif(
    double size,
    double lineHeight,
    Color color, {
    bool italic = false,
    FontWeight weight = FontWeight.w400,
  }) => TextStyle(
    fontFamily: SkFonts.serif,
    fontFamilyFallback: SkFonts.serifFallback,
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    letterSpacing: 0,
    color: color,
  );

  /// Kratky citat na karte (EB Garamond 22/32).
  final TextStyle quote;

  /// Dlhsi uryvok, cvicenie, vysvetlenie (EB Garamond 19/29).
  final TextStyle passage;

  /// Otazka na zamyslenie (EB Garamond italic 22/32).
  final TextStyle prompt;

  /// Citacka Library (EB Garamond 19/30, nasobi sa `readerScale`).
  final TextStyle reader;

  /// Pojem: grecke slovo alebo prepis (EB Garamond 500 34/42).
  final TextStyle term;

  /// Referencia "Meditations 2.1" (EB Garamond 500 17/24).
  final TextStyle reference;

  /// Autor "Marcus Aurelius" (EB Garamond italic 15/22, textSecondary).
  final TextStyle attribution;

  /// Typ karty "QUOTE" (Inter 600 12/16, rozostup 1.6, terakota).
  final TextStyle eyebrow;

  /// Cisla sekcii, pocitadla (Inter 500 12/16, tabularne).
  final TextStyle numeral;

  /// Stare nazvy z forku (Mursa): `translation` = [quote].
  TextStyle get translation => quote;

  /// `translationReader` = [reader].
  TextStyle get translationReader => reader;

  /// `reflection` = [prompt].
  TextStyle get reflection => prompt;

  /// Tabularne cislice (casy, pocitadla).
  static TextStyle tabular(TextStyle style) =>
      style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  @override
  ProsocheTypography copyWith({
    TextStyle? quote,
    TextStyle? passage,
    TextStyle? prompt,
    TextStyle? reader,
    TextStyle? term,
    TextStyle? reference,
    TextStyle? attribution,
    TextStyle? eyebrow,
    TextStyle? numeral,
  }) => ProsocheTypography(
    quote: quote ?? this.quote,
    passage: passage ?? this.passage,
    prompt: prompt ?? this.prompt,
    reader: reader ?? this.reader,
    term: term ?? this.term,
    reference: reference ?? this.reference,
    attribution: attribution ?? this.attribution,
    eyebrow: eyebrow ?? this.eyebrow,
    numeral: numeral ?? this.numeral,
  );

  @override
  ProsocheTypography lerp(
    covariant ThemeExtension<ProsocheTypography>? other,
    double t,
  ) {
    if (other is! ProsocheTypography) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return ProsocheTypography(
      quote: l(quote, other.quote),
      passage: l(passage, other.passage),
      prompt: l(prompt, other.prompt),
      reader: l(reader, other.reader),
      term: l(term, other.term),
      reference: l(reference, other.reference),
      attribution: l(attribution, other.attribution),
      eyebrow: l(eyebrow, other.eyebrow),
      numeral: l(numeral, other.numeral),
    );
  }
}

/// UI typova skala (docs/DESIGN.md 3.2) namapovana na M3 `TextTheme`.
/// Display a headline su Cormorant Garamond, zvysok Inter.
abstract final class SkTextTheme {
  /// [fontFamily] a [heightFactor] meni vyber fontu podla jazyka
  /// (`lib/ui/i18n/`). [displayFamily] je pre display/headline.
  static TextTheme build({
    required Color primary,
    required Color secondary,
    String fontFamily = SkFonts.inter,
    String displayFamily = SkFonts.display,
    List<String> fontFamilyFallback = SkFonts.uiFallback,
    double heightFactor = 1,
  }) {
    TextStyle s(
      double size,
      double line,
      FontWeight w,
      Color c, {
      bool display = false,
    }) => TextStyle(
      fontFamily: display ? displayFamily : fontFamily,
      fontFamilyFallback: display
          ? [fontFamily, ...fontFamilyFallback]
          : fontFamilyFallback,
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
      displayLarge: s(52, 58, w5, primary, display: true),
      displayMedium: s(45, 52, w5, primary, display: true),
      displaySmall: s(40, 46, w6, primary, display: true),
      headlineLarge: s(36, 42, w6, primary, display: true),
      headlineMedium: s(34, 40, w6, primary, display: true),
      headlineSmall: s(28, 34, w6, primary, display: true),
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
