// Ukazkove arabske texty su data pre SkArabicText (vsetky pouzitia
// v gallery_catalog.dart ich vykresluju cez SkArabicText, overuje
// test/ui/arabic_text_usage_test.dart). Literaly tu nie su vo vnutri
// konstruktora SkArabicText, preto file-level vynimka D13 lintu.
// prosoche-lint: ignore-file prosoche_arabic_text_outside_sk_arabic_text
import 'package:prosoche/ui/components/sk_arabic_text.dart';

/// Neutralny arabsky ukazkovy text pre galeriu a goldeny. Ziadny
/// nabozensky obsah (PLAN 5.5 bod 1): bezne slova ("pekna kniha",
/// "vitajte v kniznici", "pero").
///
/// Jediny subor v `lib/` s arabskymi literalmi mimo l10n (allowlist v
/// `test/ui/arabic_text_usage_test.dart`).
abstract final class GallerySamples {
  /// "Pekna kniha" s diakritikou.
  static const words = 'كِتَابٌ جَمِيلٌ';

  /// Bez diakritiky (ako `text_simple` pre screen reader).
  static const wordsSimple = 'كتاب جميل';

  /// "Vitajte v kniznici" s diakritikou a ornamentom cisla.
  static const sentence = 'مَرْحَبًا بِكُمْ فِي الْمَكْتَبَةِ ۝١٢';

  static const sentenceSimple = 'مرحبا بكم في المكتبة';

  /// "Pero" - jedno slovo pre lemma a meno.
  static const lemma = 'قَلَمٌ';

  /// Segmenty s ukazkovym (nie skutocnym) tajwid ofarbenim.
  static const segments = [
    SkArabicSegment('مَرْ'),
    SkArabicSegment('حَ', rule: SkTajwidRule.ghunna),
    SkArabicSegment('بًا '),
    SkArabicSegment('بِكُمْ', rule: SkTajwidRule.qalqala),
    SkArabicSegment(' فِي ', rule: SkTajwidRule.madd2),
    SkArabicSegment('الْ', rule: SkTajwidRule.silent),
    SkArabicSegment('مَكْتَبَةِ ۝١٢'),
  ];

  /// "Vitajte" po slovach (word-by-word vyber).
  static const wordSegments = [
    SkArabicSegment('مَرْحَبًا'),
    SkArabicSegment(' '),
    SkArabicSegment('بِكُمْ'),
  ];

  static const wordSegmentsSimple = 'مرحبا بكم';

  /// Dlhsi text na overenie zalamovania (3x veta).
  static const long =
      'مَرْحَبًا بِكُمْ فِي الْمَكْتَبَةِ، كِتَابٌ جَمِيلٌ وَقَلَمٌ جَدِيدٌ، '
      'مَرْحَبًا بِكُمْ فِي الْمَكْتَبَةِ، كِتَابٌ جَمِيلٌ وَقَلَمٌ جَدِيدٌ، '
      'مَرْحَبًا بِكُمْ فِي الْمَكْتَبَةِ ۝١٢';

  static const longSimple =
      'مرحبا بكم في المكتبة، كتاب جميل وقلم جديد، '
      'مرحبا بكم في المكتبة، كتاب جميل وقلم جديد، مرحبا بكم في المكتبة';

  /// Placeholder preklad (nie preklad vyznamu).
  static const translation =
      '[PLACEHOLDER translation] Welcome to the library. This sentence only '
      'shows how a translation wraps under the Arabic block.';

  static const attribution = '[PLACEHOLDER] Translation: sample source';
}
