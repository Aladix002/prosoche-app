/// Pravidlo obsahu notifikacii (plan 8.2, docs/01 D8): ziadny vers, meno
/// Allaha ani hadis, ani v nesukromnom rezime.
///
/// Texty su len z ARB (UI texty), takze vers ani hadis sa do nich nedostane.
/// Kontrola chyti meno Allaha v ARB preklade alebo v nazve eventu.
abstract final class NotificationContentPolicy {
  static final _forbidden = [
    RegExp('allah', caseSensitive: false),
    // Arabsky zapis vratane tvarov s diakritikou a ligatury.
    // Escape v regexe (nie v retazci), aby v zdrojaku nebol arabsky text.
    RegExp(r'\u0627?\u0644\u0644[\u064B-\u065F\u0670]*\u0647'),
    RegExp(r'\uFDF2'),
  ];

  /// Text smie byt v notifikacii.
  static bool allows(String? text) =>
      text == null || !_forbidden.any((re) => re.hasMatch(text));
}
