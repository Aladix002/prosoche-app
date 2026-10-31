import 'package:flutter/material.dart';
import 'package:prosoche/ui/theme/prosoche_colors.dart';
import 'package:prosoche/ui/theme/prosoche_motion.dart';
import 'package:prosoche/ui/theme/prosoche_spacing.dart';
import 'package:prosoche/ui/theme/prosoche_typography.dart';

/// Pristup k tokenom: `context.sk.colors`, `.type`, `.space`,
/// `.motion` (docs/01 3.1).
extension SkContextX on BuildContext {
  SkTokens get sk => SkTokens._(this);
}

/// Pohlad na ThemeExtensions Prosoche. Ak tema extension nema (napr. test
/// s holou `ThemeData`), vrati svetle/standardne hodnoty.
@immutable
class SkTokens {
  const SkTokens._(this._context);

  final BuildContext _context;

  ThemeData get _theme => Theme.of(_context);

  bool get _isDark => _theme.brightness == Brightness.dark;

  ProsocheColors get colors =>
      _theme.extension<ProsocheColors>() ??
      (_isDark ? ProsocheColors.dark : ProsocheColors.light);

  ProsocheTypography get type =>
      _theme.extension<ProsocheTypography>() ?? ProsocheTypography.of(colors);

  ProsocheSpacing get space =>
      _theme.extension<ProsocheSpacing>() ?? const ProsocheSpacing();

  /// Motion tokeny uz prepocitane podla systemoveho reduce motion
  /// (`MediaQuery.disableAnimationsOf`) aj in-app prepinaca (tema).
  ProsocheMotion get motion {
    final fromTheme =
        _theme.extension<ProsocheMotion>() ?? ProsocheMotion.standard;
    final system = MediaQuery.maybeDisableAnimationsOf(_context) ?? false;
    return system ? ProsocheMotion.reducedMotion : fromTheme;
  }

  /// Velky text: riadky s textom sa prepinaju na stlpec (docs/01 8.3).
  /// Prah 1.3 (nie 1.5), lebo pri 1.5 sa uz riadky na 360 dp lamu.
  bool get largeText =>
      MediaQuery.textScalerOf(_context).scale(10) >= largeTextScale * 10;

  static const largeTextScale = 1.3;

  /// Text styly UI skaly (M3 `TextTheme`).
  TextTheme get text => _theme.textTheme;
}
