/// Rodiny fontov pribalenych v `assets/fonts/` (docs/01 2.3.1, PLAN U-01).
///
/// Ziadne runtime stahovanie (offline a sukromie). Novu serifovu typografiu
/// (PLAN.md kap. 4) dodá D-01.
abstract final class SkFonts {
  /// UI latinka.
  static const inter = 'Inter';

  /// Citanie dlhsich textov (citaty, uryvky).
  static const literata = 'Literata';

  /// Fallback pre UI text (prazdny: vsetky jazyky v1 su latinka).
  static const List<String> uiFallback = [];

  /// Adresare v `assets/fonts/` s `OFL.txt` (pre `LicenseRegistry`).
  static const Map<String, String> licenseDirs = {
    'Inter': 'inter',
    'Literata': 'literata',
  };
}
