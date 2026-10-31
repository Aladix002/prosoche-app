// Hodnoty z docs/DESIGN.md 2 (D-01). Menit len spolu s docs/DESIGN.md,
// docs/tools/contrast.py a test/ui/theme/contrast_test.dart.
import 'package:flutter/material.dart';

/// Farebne tokeny Prosoche "kamen, atrament, okra, terakota"
/// (docs/DESIGN.md 2). Pristup: `context.sk.colors`.
///
/// Obsahuje celu paletu vratane tokenov, ktore su aj v `ColorScheme`.
/// Widgety nikdy nepouzivaju hex ani `Colors.*` priamo.
@immutable
class ProsocheColors extends ThemeExtension<ProsocheColors> {
  const ProsocheColors({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.lead,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.accentText,
    required this.goldDeco,
    required this.outline,
    required this.outlineStrong,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.success,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.inversePrimary,
    required this.scrim,
    required this.focusRing,
  });

  static const light = ProsocheColors(
    bg: Color(0xFFF2EFE9),
    surface: Color(0xFFFBFAF7),
    surfaceAlt: Color(0xFFE7E2D8),
    textPrimary: Color(0xFF1B2230),
    textSecondary: Color(0xFF485061),
    textTertiary: Color(0xFF5C6270),
    textDisabled: Color(0xFFA2A5AB),
    lead: Color(0xFF141A26),
    primary: Color(0xFF1F3A5F),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDAE2EE),
    onPrimaryContainer: Color(0xFF0F2440),
    accentText: Color(0xFF97482B),
    goldDeco: Color(0xFFB3843A),
    outline: Color(0xFFD6D0C4),
    outlineStrong: Color(0xFF7A7D85),
    error: Color(0xFFA3242F),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF6DCDA),
    onErrorContainer: Color(0xFF5A1418),
    success: Color(0xFF3B6844),
    warning: Color(0xFF80570E),
    warningContainer: Color(0xFFF2E5C6),
    onWarningContainer: Color(0xFF45300A),
    inverseSurface: Color(0xFF232A36),
    onInverseSurface: Color(0xFFF0EDE7),
    inversePrimary: Color(0xFFA9C0E2),
    scrim: Color(0x66000000),
    focusRing: Color(0xFF1F3A5F),
  );

  static const dark = ProsocheColors(
    bg: Color(0xFF0E131A),
    surface: Color(0xFF161C25),
    surfaceAlt: Color(0xFF1F2631),
    textPrimary: Color(0xFFECE7DF),
    textSecondary: Color(0xFFB9BDC5),
    textTertiary: Color(0xFF9198A3),
    textDisabled: Color(0xFF525966),
    lead: Color(0xFFF3EFE8),
    primary: Color(0xFFA9C0E2),
    onPrimary: Color(0xFF0E1A2C),
    primaryContainer: Color(0xFF26364F),
    onPrimaryContainer: Color(0xFFD9E3F3),
    accentText: Color(0xFFE59E80),
    goldDeco: Color(0xFFC6A05C),
    outline: Color(0xFF2A3240),
    outlineStrong: Color(0xFF6F7785),
    error: Color(0xFFF2A3A8),
    onError: Color(0xFF3D0B10),
    errorContainer: Color(0xFF4B1A1F),
    onErrorContainer: Color(0xFFF6DCDA),
    success: Color(0xFF9CC9A2),
    warning: Color(0xFFE3C27A),
    warningContainer: Color(0xFF3A2D10),
    onWarningContainer: Color(0xFFF2E5C6),
    inverseSurface: Color(0xFFECE7DF),
    onInverseSurface: Color(0xFF1B2230),
    inversePrimary: Color(0xFF1F3A5F),
    scrim: Color(0x99000000),
    focusRing: Color(0xFFA9C0E2),
  );

  /// Pozadie obrazoviek (`surface` v M3).
  final Color bg;

  /// Karty, sheety.
  final Color surface;

  /// Vnorene plochy, chipy, track.
  final Color surfaceAlt;

  /// Hlavny text.
  final Color textPrimary;

  /// Popisy, metadata.
  final Color textSecondary;

  /// Pomocny text, neaktivne stavy.
  final Color textTertiary;

  /// Disabled (WCAG vynimka).
  final Color textDisabled;

  /// Text filozofa (citat, uryvok, citacka).
  final Color lead;

  /// Primarne akcie, aktivne stavy.
  final Color primary;

  /// Text na `primary`.
  final Color onPrimary;

  /// Vybrany tab, highlight.
  final Color primaryContainer;

  /// Text na `primaryContainer`.
  final Color onPrimaryContainer;

  /// Terakota: typ karty, eyebrow, datum (jediny teply text).
  final Color accentText;

  /// Okra: iba dekor (motiv), nikdy text ani informacia.
  final Color goldDeco;

  /// Dekorativne oddelovace.
  final Color outline;

  /// Hranice inputov, neaktivny progres.
  final Color outlineStrong;

  /// Chyby (karminova, vzdy s ikonou a textom).
  final Color error;

  /// Text na `error`.
  final Color onError;

  /// Chybovy banner.
  final Color errorContainer;

  /// Text na `errorContainer`.
  final Color onErrorContainer;

  /// Splneny quest, ulozene.
  final Color success;

  /// Upozornenie.
  final Color warning;

  /// Banner chybajuceho povolenia.
  final Color warningContainer;

  /// Text na `warningContainer`.
  final Color onWarningContainer;

  /// Snackbar.
  final Color inverseSurface;

  /// Text na `inverseSurface`.
  final Color onInverseSurface;

  /// Akcia v snackbare.
  final Color inversePrimary;

  /// Pod dialogom (40 % / 60 %).
  final Color scrim;

  /// Focus indikator 2 dp.
  final Color focusRing;

  /// Varianty pre `MediaQuery.highContrastOf` (docs/01 8.5):
  /// `textSecondary := textPrimary`, `outlineStrong` o stupen vyraznejsi.
  static final ProsocheColors lightHighContrast = light.copyWith(
    textSecondary: light.textPrimary,
    outlineStrong: const Color(0xFF5A5E66),
  );

  static final ProsocheColors darkHighContrast = dark.copyWith(
    textSecondary: dark.textPrimary,
    outlineStrong: const Color(0xFF9198A3),
  );

  /// Farby, ktore su len dekor a nikdy nenesu text ani informaciu.
  static const decorativeOnly = {'goldDeco', 'outline'};

  /// Vsetky tokeny podla mena (pre kontrastny test a galeriu).
  Map<String, Color> asMap() => {
    'bg': bg,
    'surface': surface,
    'surfaceAlt': surfaceAlt,
    'textPrimary': textPrimary,
    'textSecondary': textSecondary,
    'textTertiary': textTertiary,
    'textDisabled': textDisabled,
    'lead': lead,
    'primary': primary,
    'onPrimary': onPrimary,
    'primaryContainer': primaryContainer,
    'onPrimaryContainer': onPrimaryContainer,
    'accentText': accentText,
    'goldDeco': goldDeco,
    'outline': outline,
    'outlineStrong': outlineStrong,
    'error': error,
    'onError': onError,
    'errorContainer': errorContainer,
    'onErrorContainer': onErrorContainer,
    'success': success,
    'warning': warning,
    'warningContainer': warningContainer,
    'onWarningContainer': onWarningContainer,
    'inverseSurface': inverseSurface,
    'onInverseSurface': onInverseSurface,
    'inversePrimary': inversePrimary,
    'scrim': scrim,
    'focusRing': focusRing,
  };

  @override
  bool operator ==(Object other) =>
      other is ProsocheColors &&
      other.bg == bg &&
      other.surface == surface &&
      other.surfaceAlt == surfaceAlt &&
      other.textPrimary == textPrimary &&
      other.textSecondary == textSecondary &&
      other.textTertiary == textTertiary &&
      other.textDisabled == textDisabled &&
      other.lead == lead &&
      other.primary == primary &&
      other.onPrimary == onPrimary &&
      other.primaryContainer == primaryContainer &&
      other.onPrimaryContainer == onPrimaryContainer &&
      other.accentText == accentText &&
      other.goldDeco == goldDeco &&
      other.outline == outline &&
      other.outlineStrong == outlineStrong &&
      other.error == error &&
      other.onError == onError &&
      other.errorContainer == errorContainer &&
      other.onErrorContainer == onErrorContainer &&
      other.success == success &&
      other.warning == warning &&
      other.warningContainer == warningContainer &&
      other.onWarningContainer == onWarningContainer &&
      other.inverseSurface == inverseSurface &&
      other.onInverseSurface == onInverseSurface &&
      other.inversePrimary == inversePrimary &&
      other.scrim == scrim &&
      other.focusRing == focusRing;

  @override
  int get hashCode => Object.hashAll([
    bg,
    surface,
    surfaceAlt,
    textPrimary,
    textSecondary,
    textTertiary,
    textDisabled,
    lead,
    primary,
    onPrimary,
    primaryContainer,
    onPrimaryContainer,
    accentText,
    goldDeco,
    outline,
    outlineStrong,
    error,
    onError,
    errorContainer,
    onErrorContainer,
    success,
    warning,
    warningContainer,
    onWarningContainer,
    inverseSurface,
    onInverseSurface,
    inversePrimary,
    scrim,
    focusRing,
  ]);

  @override
  ProsocheColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? lead,
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? accentText,
    Color? goldDeco,
    Color? outline,
    Color? outlineStrong,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? success,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? inverseSurface,
    Color? onInverseSurface,
    Color? inversePrimary,
    Color? scrim,
    Color? focusRing,
  }) => ProsocheColors(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    surfaceAlt: surfaceAlt ?? this.surfaceAlt,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary: textTertiary ?? this.textTertiary,
    textDisabled: textDisabled ?? this.textDisabled,
    lead: lead ?? this.lead,
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    primaryContainer: primaryContainer ?? this.primaryContainer,
    onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
    accentText: accentText ?? this.accentText,
    goldDeco: goldDeco ?? this.goldDeco,
    outline: outline ?? this.outline,
    outlineStrong: outlineStrong ?? this.outlineStrong,
    error: error ?? this.error,
    onError: onError ?? this.onError,
    errorContainer: errorContainer ?? this.errorContainer,
    onErrorContainer: onErrorContainer ?? this.onErrorContainer,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    inverseSurface: inverseSurface ?? this.inverseSurface,
    onInverseSurface: onInverseSurface ?? this.onInverseSurface,
    inversePrimary: inversePrimary ?? this.inversePrimary,
    scrim: scrim ?? this.scrim,
    focusRing: focusRing ?? this.focusRing,
  );

  @override
  ProsocheColors lerp(
    covariant ThemeExtension<ProsocheColors>? other,
    double t,
  ) {
    if (other is! ProsocheColors) return this;
    return ProsocheColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      lead: Color.lerp(lead, other.lead, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryContainer: Color.lerp(
        primaryContainer,
        other.primaryContainer,
        t,
      )!,
      onPrimaryContainer: Color.lerp(
        onPrimaryContainer,
        other.onPrimaryContainer,
        t,
      )!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      goldDeco: Color.lerp(goldDeco, other.goldDeco, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineStrong: Color.lerp(outlineStrong, other.outlineStrong, t)!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      onErrorContainer: Color.lerp(
        onErrorContainer,
        other.onErrorContainer,
        t,
      )!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      inverseSurface: Color.lerp(inverseSurface, other.inverseSurface, t)!,
      onInverseSurface: Color.lerp(
        onInverseSurface,
        other.onInverseSurface,
        t,
      )!,
      inversePrimary: Color.lerp(inversePrimary, other.inversePrimary, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
    );
  }
}
