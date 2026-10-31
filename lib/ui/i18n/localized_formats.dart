import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Sada cislic pre zobrazenie cisel, casov a datumov (docs/04 5.2 bod 3).
enum DigitStyle {
  /// 0123456789
  latin('0123456789', '.', ','),

  /// Arabsko-indicke (U+0660..U+0669), arabske oddelovace.
  arabicIndic(
    '\u0660\u0661\u0662\u0663\u0664\u0665\u0666\u0667\u0668\u0669',
    '\u066B',
    '\u066C',
  ),

  /// Rozsirene arabsko-indicke (perzske/urdske tvary, U+06F0..U+06F9).
  extendedArabicIndic(
    '\u06F0\u06F1\u06F2\u06F3\u06F4\u06F5\u06F6\u06F7\u06F8\u06F9',
    '\u066B',
    '\u066C',
  ),

  /// Bengalske (U+09E6..U+09EF).
  bengali(
    '\u09E6\u09E7\u09E8\u09E9\u09EA\u09EB\u09EC\u09ED\u09EE\u09EF',
    '.',
    ',',
  );

  DigitStyle(this.digits, this.decimalSeparator, this.groupSeparator);

  /// Desat cislic 0..9 v poradi.
  final String digits;
  final String decimalSeparator;
  final String groupSeparator;

  /// Vychodiskova sada podla systemoveho [locale] tak, ako ju formatuje
  /// `intl` (CLDR): `ar` a `ar_SA` latinka, `ar_EG` arabsko-indicke,
  /// `bn` bengalske, `ur` latinka. Overene testom (U-02).
  static DigitStyle systemDefault(Locale locale) {
    final sample = NumberFormat('0', _intlLocale(locale)).format(7);
    for (final style in values) {
      if (sample == style.digits[7]) return style;
    }
    return latin;
  }
}

String _intlLocale(Locale locale) {
  final tag = locale.countryCode == null
      ? locale.languageCode
      : '${locale.languageCode}_${locale.countryCode}';
  return Intl.verifiedLocale(
        tag,
        NumberFormat.localeExists,
        onFailure: (_) => 'en',
      ) ??
      'en';
}

final _anyDigit = RegExp('[0-9\u0660-\u0669\u06F0-\u06F9\u09E6-\u09EF]');

int _digitValue(int codeUnit) {
  for (final base in const [0x30, 0x660, 0x6F0, 0x9E6]) {
    if (codeUnit >= base && codeUnit <= base + 9) return codeUnit - base;
  }
  throw ArgumentError.value(codeUnit, 'codeUnit', 'not a digit');
}

/// Prepise vsetky cislice (latinske aj nativne) v [text] do [style].
/// Nemeni ine znaky, takze sa da pouzit aj na hotove retazce z ARB.
String localizeDigits(String text, DigitStyle style) => text.replaceAllMapped(
  _anyDigit,
  (m) => style.digits[_digitValue(m[0]!.codeUnitAt(0))],
);

/// Formaty cisel, casov a datumov pre UI jazyk a zvolenu sadu cislic.
///
/// Pred pouzitim datumov musia byt nacitane symboly `intl`
/// (`GlobalMaterialLocalizations.delegate` to robi v appke,
/// v cistych testoch `initializeDateFormatting()`).
@immutable
final class ProsocheFormats {
  ProsocheFormats(this.locale, {DigitStyle? digits})
    : digits = digits ?? DigitStyle.systemDefault(locale),
      _tag = _intlLocale(locale);

  final Locale locale;
  final DigitStyle digits;
  final String _tag;

  /// Cele alebo desatinne cislo s oddelovacmi tisicov.
  String number(num value) {
    final raw = NumberFormat.decimalPattern(_tag).format(value);
    if (digits == DigitStyle.latin || digits == DigitStyle.bengali) {
      return localizeDigits(raw, digits);
    }
    // Arabske oddelovace len pri arabskych cisliciach.
    final symbols = NumberFormat.decimalPattern(_tag).symbols;
    final out = StringBuffer();
    for (final ch in raw.split('')) {
      out.write(
        ch == symbols.DECIMAL_SEP
            ? digits.decimalSeparator
            : ch == symbols.GROUP_SEP
            ? digits.groupSeparator
            : ch,
      );
    }
    return localizeDigits(out.toString(), digits);
  }

  /// Cas modlitby: 24 h (`HH:mm`) alebo 12 h podla jazyka (`h:mm a`).
  String time(DateTime value, {bool use24h = true}) => localizeDigits(
    (use24h ? DateFormat.Hm(_tag) : DateFormat.jm(_tag)).format(value),
    digits,
  );

  /// Kratky datum, napr. `Mar 7, 2026` / `7 Mar 2026`.
  String date(DateTime value) =>
      localizeDigits(DateFormat.yMMMd(_tag).format(value), digits);

  /// Den v tyzdni a datum, napr. `Saturday, March 7`.
  String weekdayDate(DateTime value) =>
      localizeDigits(DateFormat.MMMMEEEEd(_tag).format(value), digits);

  /// Referencia na vers `2:255` v cisliciach UI, izolovana pre bidi.
  String ayahRef(int surah, int ayah) =>
      '\u2068${localizeDigits('$surah:$ayah', digits)}\u2069';
}
