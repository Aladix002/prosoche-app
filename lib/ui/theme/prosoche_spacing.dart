import 'package:flutter/material.dart';
import 'package:prosoche/ui/tokens/sk_space.dart';

/// Spacing v teme (docs/01 3.1). Konstanty su v [SkSpace]; extension je len
/// kvoli guttru na tabletoch. Pristup: `context.sk.space`.
@immutable
class ProsocheSpacing extends ThemeExtension<ProsocheSpacing> {
  const ProsocheSpacing({
    this.gutterPhone = SkSpace.space16,
    this.gutterTablet = SkSpace.space24,
    this.maxContentWidth = SkSpace.maxContentWidth,
  });

  final double gutterPhone;
  final double gutterTablet;
  final double maxContentWidth;

  /// Bocny okraj pre sirku okna [width].
  double gutter(double width) => width < 600 ? gutterPhone : gutterTablet;

  @override
  ProsocheSpacing copyWith({
    double? gutterPhone,
    double? gutterTablet,
    double? maxContentWidth,
  }) => ProsocheSpacing(
    gutterPhone: gutterPhone ?? this.gutterPhone,
    gutterTablet: gutterTablet ?? this.gutterTablet,
    maxContentWidth: maxContentWidth ?? this.maxContentWidth,
  );

  @override
  ProsocheSpacing lerp(
    covariant ThemeExtension<ProsocheSpacing>? other,
    double t,
  ) => other is ProsocheSpacing && t >= 0.5 ? other : this;
}
