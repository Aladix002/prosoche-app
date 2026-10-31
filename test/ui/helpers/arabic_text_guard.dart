import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/ui/components/sk_arabic_text.dart';

/// Arabske pismo (arabic, supplement, extended-A, presentation forms).
/// `ﷺ` (U+FDFA) je povoleny v UI copy (docs/01 1.3) a nepocita sa.
final arabicScript = RegExp(
  '[؀-ۿݐ-ݿࢠ-ࣿﭐ-ﷹﷻ-﷿'
  'ﹰ-﻿]',
);

bool containsArabic(String text) => arabicScript.hasMatch(text);

/// Vrati texty vsetkych vykreslenych `RichText`, ktore obsahuju arabske
/// pismo a nie su vnutri `SkArabicText` (D13).
///
/// Pouzitie vo widget testoch obrazoviek s LTR locale:
/// `expect(bareArabicTexts(tester), isEmpty);`. Pre UI v AR/UR (U-02) sa
/// kontrola nepouziva - tam je arabske pismo beznym UI textom.
List<String> bareArabicTexts(WidgetTester tester) => [
  for (final element in find.byType(RichText).evaluate())
    if (containsArabic((element.widget as RichText).text.toPlainText()) &&
        find
            .ancestor(
              of: find.byElementPredicate((e) => e == element),
              matching: find.byType(SkArabicText),
            )
            .evaluate()
            .isEmpty)
      (element.widget as RichText).text.toPlainText(),
];
