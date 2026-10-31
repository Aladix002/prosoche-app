/// Spacing scale, zaklad 4 dp (docs/01 2.4).
abstract final class SkSpace {
  static const double space0 = 0;
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;

  /// Gutter obrazovky na telefone, padding karty v liste.
  static const double space16 = 16;

  /// Padding feed karty, medzi sekciami.
  static const double space24 = 24;

  /// Medzi hlavnym blokom a textom karty.
  static const double space32 = 32;
  static const double space48 = 48;
  static const double space64 = 64;

  /// Min. velkost dotykoveho ciela (docs/01 8.4).
  static const double minTouchTarget = 48;

  /// Max. sirka obsahu na tabletoch a foldoch.
  static const double maxContentWidth = 640;

  /// Bocny okraj podla sirky okna: 16 dp pod 600 dp, inak 24 dp.
  static double gutterFor(double width) => width < 600 ? space16 : space24;
}

/// Radiusy (docs/DESIGN.md 4): mensie nez v Murse, kamen nie papier.
abstract final class SkRadius {
  /// Segment progres baru, tag.
  static const double xs = 2;

  /// Chip, input, snackbar.
  static const double sm = 4;

  /// Tlacidla, list karta, quest.
  static const double md = 8;

  /// Feed karta, dialog.
  static const double lg = 12;

  /// Bottom sheet (horne rohy).
  static const double xl = 16;

  /// Pill.
  static const double full = 999;
}
