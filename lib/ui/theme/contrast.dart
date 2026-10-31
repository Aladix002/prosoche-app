import 'dart:math' as math;
import 'dart:ui' show Color;

/// WCAG 2.1 kontrast (docs/01 2.1.3).
abstract final class SkContrast {
  /// Text >= 4.5:1.
  static const text = 4.5;

  /// Velky text a UI komponenty >= 3:1.
  static const nonText = 3.0;

  static double _channel(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

  /// Relativna luminancia (linearizovane sRGB, alfa sa ignoruje).
  static double luminance(Color c) =>
      0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

  /// Pomer kontrastu (L1 + 0.05) / (L2 + 0.05), L1 >= L2.
  static double ratio(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }
}
