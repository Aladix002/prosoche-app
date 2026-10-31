// Generovane z tabuliek docs/01 (U-01). Hodnoty menit len spolu s
// docs/01 a test/ui/theme/contrast_test.dart.
import 'package:flutter/material.dart';

/// Farebne tokeny Prosoche (docs/01 2.1). Pristup: `context.sk.colors`.
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
    bg: Color(0xFFF7F4EC),
    surface: Color(0xFFFFFDF8),
    surfaceAlt: Color(0xFFEFEADF),
    textPrimary: Color(0xFF1F2A2E),
    textSecondary: Color(0xFF4E5A5E),
    textTertiary: Color(0xFF616B68),
    textDisabled: Color(0xFF9AA09C),
    lead: Color(0xFF14201F),
    primary: Color(0xFF1F5E55),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD5E8E2),
    onPrimaryContainer: Color(0xFF0E3530),
    accentText: Color(0xFF7A5C14),
    goldDeco: Color(0xFFB08A2E),
    outline: Color(0xFFD8D2C4),
    outlineStrong: Color(0xFF7E847E),
    error: Color(0xFFA3322A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF8DDD9),
    onErrorContainer: Color(0xFF5C1510),
    success: Color(0xFF2E6B3F),
    warning: Color(0xFF8A5A00),
    warningContainer: Color(0xFFF6E7C4),
    onWarningContainer: Color(0xFF4A3000),
    inverseSurface: Color(0xFF2A3533),
    onInverseSurface: Color(0xFFF1EDE3),
    inversePrimary: Color(0xFF9FD6C9),
    scrim: Color(0x66000000),
    focusRing: Color(0xFF1F5E55),
  );

  static const dark = ProsocheColors(
    bg: Color(0xFF0F1716),
    surface: Color(0xFF172120),
    surfaceAlt: Color(0xFF1F2B2A),
    textPrimary: Color(0xFFE8E4DA),
    textSecondary: Color(0xFFB5BDB8),
    textTertiary: Color(0xFF8E9893),
    textDisabled: Color(0xFF55605C),
    lead: Color(0xFFF1EDE3),
    primary: Color(0xFF7CC4B4),
    onPrimary: Color(0xFF08221E),
    primaryContainer: Color(0xFF1F3F3A),
    onPrimaryContainer: Color(0xFFCDEBE3),
    accentText: Color(0xFFD9B866),
    goldDeco: Color(0xFFB8963E),
    outline: Color(0xFF2E3B39),
    outlineStrong: Color(0xFF6E7A76),
    error: Color(0xFFF2A49C),
    onError: Color(0xFF3A0D09),
    errorContainer: Color(0xFF4A1D19),
    onErrorContainer: Color(0xFFF8DDD9),
    success: Color(0xFF8FCB9B),
    warning: Color(0xFFE8C170),
    warningContainer: Color(0xFF3D2E0C),
    onWarningContainer: Color(0xFFF6E7C4),
    inverseSurface: Color(0xFFE8E4DA),
    onInverseSurface: Color(0xFF1F2A2E),
    inversePrimary: Color(0xFF1F5E55),
    scrim: Color(0x99000000),
    focusRing: Color(0xFF7CC4B4),
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

  /// Hlavny text karty (citat).
  final Color lead;

  /// Primarne akcie, aktivne stavy.
  final Color primary;

  /// Text na `primary`.
  final Color onPrimary;

  /// Vybrany tab, highlight.
  final Color primaryContainer;

  /// Text na `primaryContainer`.
  final Color onPrimaryContainer;

  /// Zlaty akcent v texte.
  final Color accentText;

  /// Iba dekor, nikdy text ani informacia.
  final Color goldDeco;

  /// Dekorativne oddelovace.
  final Color outline;

  /// Hranice inputov, neaktivny progres.
  final Color outlineStrong;

  /// Chyby (nie vynechana modlitba).
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
    outlineStrong: const Color(0xFF5F665F),
  );

  static final ProsocheColors darkHighContrast = dark.copyWith(
    textSecondary: dark.textPrimary,
    outlineStrong: const Color(0xFF8E9893),
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
