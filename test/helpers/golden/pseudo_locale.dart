import 'package:flutter/widgets.dart';

/// Pseudo-lokalizacia pre testy (U-02). Nie je to preklad: kazde latinske
/// pismeno sa nahradi pismenom cieloveho pisma, text sa predlzi a obali
/// do `[` `]`, aby sa v testoch a goldenoch overila vyska riadku, sirka
/// a smer bez realnych prekladov (tie robia ludia, K-04).
///
/// Abecedy su zamerne bez alif, lam a ha, aby nahodne sekvencie netvorili
/// zmysluplne slova.
abstract final class PseudoLocale {
  /// Pomer predlzenia (docs/01 8.6: rezerva +40 % pre dlhsie jazyky).
  static const expansion = 0.4;

  static const _arabic =
      'بتثجحخدذرز'
      'سشصضطظعغفق'
      'كمنويب';

  // Urdske tvary: pe, tteh, cheh, ddal, rreh, gaf, bari ye + arabske.
  static const _urdu =
      'پٹچڈڑگےبتج'
      'حخدرزسشصعف'
      'قکمنوی';

  // Bengalske souhlasky a samohlaskove znamienka (tvoria konjunkty
  // a znamienka nad/pod riadkom).
  static const _bengali =
      'কখগঘচছজঝটঠ'
      'ডঢণতথদধনপফ'
      'বভমযরল';
  static const _bengaliSigns = 'িীুূেো';

  // Turecke znaky s diakritikou (vysoke I s bodkou, G s breve ...).
  static const _turkish = 'ğüşıöçĞÜŞİÖÇ';

  /// Pseudo-text pre [locale] z anglickeho [source]. Placeholdery
  /// `{name}` a cislice zostanu zachovane.
  static String localize(String source, Locale locale) {
    final lang = locale.languageCode;
    final out = StringBuffer();
    var inPlaceholder = false;
    var letterIndex = 0;
    for (final rune in source.runes) {
      final ch = String.fromCharCode(rune);
      if (ch == '{') inPlaceholder = true;
      if (inPlaceholder || !_isLatinLetter(rune)) {
        out.write(ch);
      } else {
        out.write(_mapLetter(rune, lang, letterIndex++));
      }
      if (ch == '}') inPlaceholder = false;
    }
    final padLength = (source.length * expansion).ceil();
    final pad = _padding(lang, padLength);
    return '[$out$pad]';
  }

  /// Pseudo-veta danej dlzky (pocet slov) pre [locale].
  static String sentence(Locale locale, {int words = 8}) =>
      localize(List.filled(words, 'lorem').join(' '), locale);

  static bool _isLatinLetter(int rune) =>
      (rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A);

  static String _mapLetter(int rune, String lang, int index) {
    final i = (rune | 0x20) - 0x61;
    return switch (lang) {
      'ar' => _arabic[i % _arabic.length],
      'ur' => _urdu[i % _urdu.length],
      'bn' =>
        _bengali[i % _bengali.length] +
            (index.isOdd ? _bengaliSigns[i % _bengaliSigns.length] : ''),
      'tr' => index % 3 == 0 ? _turkish[i % _turkish.length] : _accent(rune),
      _ => _accent(rune),
    };
  }

  // Latinka s diakritikou pre en/id (siroke a vysoke tvary).
  static String _accent(int rune) {
    const map = {
      'a': 'á', 'e': 'ë', 'i': 'î', 'o': 'ö', 'u': 'ü', //
      'A': 'Å', 'E': 'É', 'I': 'Î', 'O': 'Ø', 'U': 'Û',
    };
    final ch = String.fromCharCode(rune);
    return map[ch] ?? ch;
  }

  static String _padding(String lang, int length) {
    if (length == 0) return '';
    final unit = switch (lang) {
      'ar' => ' منبع',
      'ur' => ' ٹگے',
      'bn' => ' কিতু',
      _ => ' ~~~',
    };
    final b = StringBuffer();
    while (b.length < length) {
      b.write(unit);
    }
    return b.toString();
  }
}
