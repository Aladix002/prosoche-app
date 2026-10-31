import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/ui/gallery/sk_gallery_screen.dart';
import 'package:sakina/ui/ui.dart';

import 'helpers/arabic_text_guard.dart';
import 'helpers/pump_sk.dart';

/// D13: arabsky text sa vykresluje iba cez `SkArabicText`.
///
/// 1. Staticky: arabske literaly v `lib/` len v allowliste (ukazkove texty
///    galerie a l10n). Obsah (Koran, hadis, dua) ide z content.db do
///    `SkArabicText`, nie z literalov.
/// 2. Runtime: helper [bareArabicTexts] najde arabsky `RichText` mimo
///    `SkArabicText` (pouzitelny aj vo feature testoch).
///
/// Custom lint `packages/sakina_lints` (U-02) to doplni v analyzeri.

/// Cesty v `lib/`, kde su arabske literaly povolene.
const _allowed = [
  'lib/ui/gallery/gallery_samples.dart',
  // Preklady UI (AR, UR) - generovane z ARB.
  'lib/core/l10n/generated/',
  'lib/l10n/',
  // U-02: cislice, nazvy jazykov.
  'lib/ui/i18n/',
];

List<String> arabicLiteralViolations(String path, String source) {
  if (_allowed.any(path.startsWith)) return const [];
  return [
    for (final (i, line) in source.split('\n').indexed)
      if (containsArabic(line)) '$path:${i + 1}',
  ];
}

void main() {
  group('static scan', () {
    test('detects arabic outside allowlist', () {
      expect(arabicLiteralViolations('lib/features/x.dart', "Text('كتاب')"), [
        'lib/features/x.dart:1',
      ]);
      expect(
        arabicLiteralViolations('lib/ui/gallery/gallery_samples.dart', 'كتاب'),
        isEmpty,
      );
      // ﷺ v UI copy je povoleny.
      expect(arabicLiteralViolations('lib/x.dart', "'Muhammad ﷺ'"), isEmpty);
    });

    test('lib/ has no arabic literals outside allowlist', () {
      final violations = [
        for (final f in Directory('lib').listSync(recursive: true))
          if (f is File && f.path.endsWith('.dart'))
            ...arabicLiteralViolations(
              f.path.replaceAll(r'\', '/'),
              f.readAsStringSync(),
            ),
      ];
      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });

  group('runtime guard', () {
    testWidgets('flags bare Text with arabic', (tester) async {
      await tester.pumpSk(
        Column(
          children: [
            const Text('كتاب'),
            const Text('Latin only ﷺ'),
            SkArabicText.text('قلم'),
          ],
        ),
      );
      expect(bareArabicTexts(tester), ['كتاب']);
    });

    testWidgets('gallery renders arabic only via SkArabicText', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SkGalleryScreen()));
      // Prescrolluje celu galeriu.
      final list = find.byType(Scrollable).first;
      var seen = 0;
      for (var i = 0; i < 60; i++) {
        expect(bareArabicTexts(tester), isEmpty);
        seen += find.byType(SkArabicText).evaluate().length;
        await tester.drag(list, const Offset(0, -500));
        await tester.pump();
      }
      expect(seen, greaterThan(0));
    });
  });
}
