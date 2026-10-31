import 'package:flutter/widgets.dart';

/// Jazyky UI v MVP (TECHNICKY_PLAN 1, PLAN_VYVOJA U-02). Poradie = poradie
/// vo vybere jazyka; `en` je sablona a fallback pre chybajuce kluce.
abstract final class SakinaLocales {
  static const en = Locale('en');
  static const ar = Locale('ar');
  static const id = Locale('id');
  static const ur = Locale('ur');
  static const bn = Locale('bn');
  static const tr = Locale('tr');

  static const List<Locale> all = [en, ar, id, ur, bn, tr];

  /// Jazyky pisane sprava dolava.
  static const Set<String> rtlLanguages = {'ar', 'ur', 'fa', 'he', 'ps'};

  static bool isRtl(Locale locale) =>
      rtlLanguages.contains(locale.languageCode);

  /// Ci je jazyk v MVP podporovany (podla `languageCode`).
  static bool isSupported(Locale locale) =>
      all.any((l) => l.languageCode == locale.languageCode);

  /// Vyber jazyka UI: ulozena volba (`ui.locale`, napr. `ar`), inak prvy
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

/// Smer textu pre jazyk obsahu (nie UI). Preklad versa sa zobrazuje
/// v smere svojho jazyka bez ohladu na UI (docs/04 5.2 bod 2).
TextDirection textDirectionForLanguage(String languageCode) =>
    SakinaLocales.rtlLanguages.contains(languageCode)
    ? TextDirection.rtl
    : TextDirection.ltr;

/// Smer textu pre [locale].
TextDirection textDirectionForLocale(Locale locale) =>
    textDirectionForLanguage(locale.languageCode);
