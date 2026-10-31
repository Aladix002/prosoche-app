/// Rodiny fontov pribalenych v `assets/fonts/` (docs/DESIGN.md 3.1).
///
/// Ziadne runtime stahovanie (offline a sukromie). Nazvy sa musia zhodovat
/// s `family:` v pubspec.yaml.
abstract final class SkFonts {
  /// UI latinka (tlacidla, labely, metadata, cisla).
  static const inter = 'Inter';

  /// Text filozofov: citat, uryvok, citacka, pojmy (aj grectina).
  static const serif = 'EB Garamond';

  /// Display a headline (nadpisy obrazoviek, zaver dna, autor). Od 24 sp.
  static const display = 'Cormorant Garamond';

  /// Stary nazov z forku (Mursa): citaci serif je teraz [serif].
  static const String literata = serif;

  /// Fallback pre UI text (prazdny: vsetky jazyky v1 su latinka).
  static const List<String> uiFallback = [];

  /// Fallback serifu (znaky mimo subsetu EB Garamond).
  static const List<String> serifFallback = [inter];

  /// Adresare v `assets/fonts/` s `OFL.txt` (pre `LicenseRegistry`).
  static const Map<String, String> licenseDirs = {
    'Inter': 'inter',
    'EB Garamond': 'eb_garamond',
    'Cormorant Garamond': 'cormorant_garamond',
  };
}
