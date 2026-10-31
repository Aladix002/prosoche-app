import 'package:flutter/widgets.dart';

/// Jazyky UI (PLAN.md: v1 len EN). `en` je sablona a fallback pre
/// chybajuce kluce. Kod pre RTL ostava pre buduce jazyky.
abstract final class ProsocheLocales {
  static const en = Locale('en');

  static const List<Locale> all = [en];

  /// Jazyky pisane sprava dolava.
  static const Set<String> rtlLanguages = {'ar', 'ur', 'fa', 'he', 'ps'};

  static bool isRtl(Locale locale) =>
      rtlLanguages.contains(locale.languageCode);

  /// Ci je jazyk podporovany (podla `languageCode`).
  static bool isSupported(Locale locale) =>
      all.any((l) => l.languageCode == locale.languageCode);

  /// Vyber jazyka UI: ulozena volba (`ui.locale`), inak prvy
  /// podporovany zo systemovych jazykov, inak `en`.
  static Locale resolve({
    String? stored,
    List<Locale> deviceLocales = const [],
  }) {
    if (stored != null) {
      final match = all.where((l) => l.languageCode == stored);
      if (match.isNotEmpty) return match.first;
    }
    for (final device in deviceLocales) {
      if (isSupported(device)) return Locale(device.languageCode);
    }
    return en;
  }
}

/// Smer textu pre jazyk obsahu (nie UI). Text sa zobrazuje v smere
/// svojho jazyka bez ohladu na UI (docs/04 5.2 bod 2).
TextDirection textDirectionForLanguage(String languageCode) =>
    ProsocheLocales.rtlLanguages.contains(languageCode)
    ? TextDirection.rtl
    : TextDirection.ltr;

/// Smer textu pre [locale].
TextDirection textDirectionForLocale(Locale locale) =>
    textDirectionForLanguage(locale.languageCode);
