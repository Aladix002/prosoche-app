import 'package:flutter/material.dart';
import 'package:sakina/ui/theme/sakina_colors.dart';
import 'package:sakina/ui/theme/sakina_motion.dart';
import 'package:sakina/ui/theme/sakina_spacing.dart';
import 'package:sakina/ui/theme/sakina_typography.dart';
import 'package:sakina/ui/theme/tajwid_colors.dart';

/// Pristup k tokenom: `context.sk.colors`, `.tajwid`, `.type`, `.space`,
/// `.motion` (docs/01 3.1).
extension SkContextX on BuildContext {
  SkTokens get sk => SkTokens._(this);
}

/// Pohlad na ThemeExtensions Sakina. Ak tema extension nema (napr. test
/// s holou `ThemeData`), vrati svetle/standardne hodnoty.
@immutable
class SkTokens {
  const SkTokens._(this._context);

  final BuildContext _context;

  ThemeData get _theme => Theme.of(_context);

  bool get _isDark => _theme.brightness == Brightness.dark;

  SakinaColors get colors =>
      _theme.extension<SakinaColors>() ??
      (_isDark ? SakinaColors.dark : SakinaColors.light);

  TajwidColors get tajwid =>
      _theme.extension<TajwidColors>() ??
      (_isDark ? TajwidColors.dark : TajwidColors.light);

  SakinaTypography get type =>
      _theme.extension<SakinaTypography>() ??
      SakinaTypography.forColor(colors.textPrimary);

  SakinaSpacing get space =>
      _theme.extension<SakinaSpacing>() ?? const SakinaSpacing();

  /// Motion tokeny uz prepocitane podla systemoveho reduce motion
  /// (`MediaQuery.disableAnimationsOf`) aj in-app prepinaca (tema).
  SakinaMotion get motion {
    final fromTheme = _theme.extension<SakinaMotion>() ?? SakinaMotion.standard;
    final system = MediaQuery.maybeDisableAnimationsOf(_context) ?? false;
    return system ? SakinaMotion.reducedMotion : fromTheme;
  }

  /// Velky text: riadky s textom sa prepinaju na stlpec (docs/01 8.3).
  /// Prah 1.3 (nie 1.5), lebo pri 1.5 sa uz riadky na 360 dp lamu.
  bool get largeText =>
      MediaQuery.textScalerOf(_context).scale(10) >= largeTextScale * 10;

  static const largeTextScale = 1.3;

  /// Text styly UI skaly (M3 `TextTheme`).
  TextTheme get text => _theme.textTheme;
}
