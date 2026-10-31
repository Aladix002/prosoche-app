import 'package:flutter/material.dart';
import 'package:prosoche/ui/theme/prosoche_colors.dart';
import 'package:prosoche/ui/theme/prosoche_motion.dart';
import 'package:prosoche/ui/theme/prosoche_spacing.dart';
import 'package:prosoche/ui/theme/prosoche_typography.dart';
import 'package:prosoche/ui/tokens/sk_fonts.dart';
import 'package:prosoche/ui/tokens/sk_space.dart';

/// `ThemeData` pre svetlu a tmavu temu (docs/01 2 a 3.1).
///
/// `ColorScheme` sa sklada rucne, nie `fromSeed` (D10), aby sedeli overene
/// kontrasty. Nahrada za `PlaceholderTheme` z S-01.
abstract final class ProsocheTheme {
  static ThemeData light({
    bool highContrast = false,
    bool reduceMotion = false,
    String uiFontFamily = SkFonts.inter,
    double uiHeightFactor = 1,
  }) => build(
    colors: highContrast
        ? ProsocheColors.lightHighContrast
        : ProsocheColors.light,
    brightness: Brightness.light,
    reduceMotion: reduceMotion,
    uiFontFamily: uiFontFamily,
    uiHeightFactor: uiHeightFactor,
  );

  static ThemeData dark({
    bool highContrast = false,
    bool reduceMotion = false,
    String uiFontFamily = SkFonts.inter,
    double uiHeightFactor = 1,
  }) => build(
    colors: highContrast
        ? ProsocheColors.darkHighContrast
        : ProsocheColors.dark,
    brightness: Brightness.dark,
    reduceMotion: reduceMotion,
    uiFontFamily: uiFontFamily,
    uiHeightFactor: uiHeightFactor,
  );

  /// Rucne zlozena `ColorScheme` z tokenov (docs/01 2.1.1, stlpec M3 rola).
  static ColorScheme colorScheme(ProsocheColors c, Brightness brightness) =>
      ColorScheme(
        brightness: brightness,
        primary: c.primary,
        onPrimary: c.onPrimary,
        primaryContainer: c.primaryContainer,
        onPrimaryContainer: c.onPrimaryContainer,
        // Sekundarna rola = tonalne primary (tonal tlacidla, nav indikator).
        secondary: c.primary,
        onSecondary: c.onPrimary,
        secondaryContainer: c.primaryContainer,
        onSecondaryContainer: c.onPrimaryContainer,
        tertiary: c.accentText,
        onTertiary: c.surface,
        error: c.error,
        onError: c.onError,
        errorContainer: c.errorContainer,
        onErrorContainer: c.onErrorContainer,
        surface: c.bg,
        onSurface: c.textPrimary,
        onSurfaceVariant: c.textSecondary,
        surfaceContainerLowest: c.surface,
        surfaceContainerLow: c.surface,
        surfaceContainer: c.surface,
        surfaceContainerHigh: c.surfaceAlt,
        surfaceContainerHighest: c.surfaceAlt,
        surfaceDim: c.bg,
        surfaceBright: c.surface,
        outline: c.outlineStrong,
        outlineVariant: c.outline,
        shadow: const Color(0xFF000000),
        scrim: c.scrim,
        inverseSurface: c.inverseSurface,
        onInverseSurface: c.onInverseSurface,
        inversePrimary: c.inversePrimary,
        surfaceTint: const Color(0x00000000),
      );

  static ThemeData build({
    required ProsocheColors colors,
    required Brightness brightness,
    bool reduceMotion = false,
    String uiFontFamily = SkFonts.inter,
    double uiHeightFactor = 1,
  }) {
    final c = colors;
    final scheme = colorScheme(c, brightness);
    final text = SkTextTheme.build(
      primary: c.textPrimary,
      secondary: c.textSecondary,
      fontFamily: uiFontFamily,
      heightFactor: uiHeightFactor,
    );
    final isDark = brightness == Brightness.dark;
    // e3: svetla = surface + tien, tmava = surfaceAlt bez tiena (2.6).
    final floating = isDark ? c.surfaceAlt : c.surface;
    const transparent = Color(0x00000000);
    RoundedRectangleBorder rounded(double r) =>
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));
    final buttonShape = WidgetStatePropertyAll<OutlinedBorder>(
      rounded(SkRadius.md),
    );
    const minButton = WidgetStatePropertyAll(
      Size(SkSpace.minTouchTarget, SkSpace.minTouchTarget),
    );
    final focusSide = WidgetStateProperty.resolveWith<BorderSide?>(
      (s) => s.contains(WidgetState.focused)
          ? BorderSide(color: c.focusRing, width: 2)
          : null,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: text,
      fontFamily: uiFontFamily,
      fontFamilyFallback: SkFonts.uiFallback,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      dividerColor: c.outline,
      disabledColor: c.textDisabled,
      focusColor: c.focusRing.withValues(alpha: 0.12),
      splashFactory: InkRipple.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: [
        c,
        ProsocheTypography.of(c),
        const ProsocheSpacing(),
        if (reduceMotion)
          ProsocheMotion.reducedMotion
        else
          ProsocheMotion.standard,
      ],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SkFadePageTransitionsBuilder(),
          TargetPlatform.iOS: SkFadePageTransitionsBuilder(),
          TargetPlatform.linux: SkFadePageTransitionsBuilder(),
          TargetPlatform.macOS: SkFadePageTransitionsBuilder(),
          TargetPlatform.windows: SkFadePageTransitionsBuilder(),
          TargetPlatform.fuchsia: SkFadePageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.textPrimary,
        surfaceTintColor: transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        surfaceTintColor: transparent,
        margin: EdgeInsets.zero,
        shape: rounded(SkRadius.md),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: c.surface,
        surfaceTintColor: transparent,
        elevation: 0,
        indicatorColor: c.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelSmall!.copyWith(
            color: s.contains(WidgetState.selected)
                ? c.textPrimary
                : c.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected)
                ? c.onPrimaryContainer
                : c.textSecondary,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: minButton,
          shape: buttonShape,
          side: focusSide,
          textStyle: WidgetStatePropertyAll(text.labelLarge),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: minButton,
          shape: buttonShape,
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          side: WidgetStateProperty.resolveWith(
            (s) => BorderSide(
              color: s.contains(WidgetState.focused)
                  ? c.focusRing
                  : s.contains(WidgetState.disabled)
                  ? c.textDisabled
                  : c.outlineStrong,
              width: s.contains(WidgetState.focused) ? 2 : 1,
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: minButton,
          shape: buttonShape,
          side: focusSide,
          textStyle: WidgetStatePropertyAll(text.labelLarge),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(minimumSize: minButton, side: focusSide),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.inverseSurface,
        contentTextStyle: text.bodyMedium!.copyWith(color: c.onInverseSurface),
        actionTextColor: c.inversePrimary,
        elevation: isDark ? 0 : 2,
        shape: rounded(SkRadius.sm),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: floating,
        surfaceTintColor: transparent,
        elevation: isDark ? 0 : 4,
        shadowColor: const Color(0x1F1F2A2E),
        shape: rounded(SkRadius.lg),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: floating,
        modalBackgroundColor: floating,
        surfaceTintColor: transparent,
        elevation: isDark ? 0 : 4,
        modalElevation: isDark ? 0 : 4,
        shadowColor: const Color(0x1F1F2A2E),
        showDragHandle: true,
        dragHandleColor: c.outlineStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(SkRadius.xl),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.outline, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceAlt,
        selectedColor: c.primaryContainer,
        labelStyle: text.labelSmall!.copyWith(color: c.textPrimary),
        side: BorderSide.none,
        shape: rounded(SkRadius.sm),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: SkSpace.space12,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SkRadius.sm),
          borderSide: BorderSide(color: c.outlineStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SkRadius.sm),
          borderSide: BorderSide(color: c.outlineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SkRadius.sm),
          borderSide: BorderSide(color: c.focusRing, width: 2),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.outlineStrong,
        circularTrackColor: c.surfaceAlt,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
        minVerticalPadding: SkSpace.space12,
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: SkSpace.space16,
        ),
      ),
    );
  }
}

/// Fade-through prechod obrazoviek (docs/01 2.8): neutralny voci RTL,
/// bez horizontalneho slide.
class SkFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const SkFadePageTransitionsBuilder();

  @override
  Duration get transitionDuration => ProsocheMotion.standard.long.duration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    final curve = ProsocheMotion.standard.long.curve;
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: curve),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0).animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: const Interval(0, 0.35),
          ),
        ),
        child: child,
      ),
    );
  }
}
