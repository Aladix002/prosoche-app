/// Unicode izolacia smeru pri mixe arabskeho textu a latinky
/// (docs/04 5.2 bod 5, docs/01 8.6).
abstract final class Bidi {
  /// FIRST STRONG ISOLATE: smer podla prveho silneho znaku.
  static const fsi = '\u2068';

  /// LEFT-TO-RIGHT ISOLATE.
  static const lri = '\u2066';

  /// RIGHT-TO-LEFT ISOLATE.
  static const rli = '\u2067';

  /// POP DIRECTIONAL ISOLATE.
  static const pdi = '\u2069';

  /// Izoluje [text] so smerom podla prveho silneho znaku. Pre referencie
  /// (`Al-Baqarah 2:255`) a mena vlozene do vety v inom smere.
  static String isolate(String text) => '$fsi$text$pdi';

  /// Izoluje [text] ako LTR (latinka, cisla, URL v RTL vete).
  static String isolateLtr(String text) => '$lri$text$pdi';

  /// Izoluje [text] ako RTL (arabske slovo v LTR vete).
  static String isolateRtl(String text) => '$rli$text$pdi';

  /// Odstrani izolacne znaky (napr. pre porovnanie v testoch alebo
  /// pre semantics label).
  static String strip(String text) =>
      text.replaceAll(RegExp('[$lri$rli$fsi$pdi]'), '');
}
