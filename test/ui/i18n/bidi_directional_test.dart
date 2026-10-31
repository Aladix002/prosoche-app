import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/ui/i18n/i18n.dart';

void main() {
  group('Bidi', () {
    test('isolates and strips', () {
      expect(Bidi.isolate('2:255'), '\u20682:255\u2069');
      expect(Bidi.isolateLtr('Sakina'), '\u2066Sakina\u2069');
      expect(Bidi.isolateRtl('x'), '\u2067x\u2069');
      expect(
        Bidi.strip(
          Bidi.isolate('a') + Bidi.isolateLtr('b') + Bidi.isolateRtl('c'),
        ),
        'abc',
      );
    });
  });

  group('readingSwipe', () {
    test('LTR: swipe left is forward', () {
      expect(readingSwipe(-200, TextDirection.ltr), ReadingSwipe.forward);
      expect(readingSwipe(200, TextDirection.ltr), ReadingSwipe.backward);
    });

    test('RTL: swipe right is forward', () {
      expect(readingSwipe(200, TextDirection.rtl), ReadingSwipe.forward);
      expect(readingSwipe(-200, TextDirection.rtl), ReadingSwipe.backward);
    });

    test('below threshold is none', () {
      expect(
        readingSwipe(10, TextDirection.rtl, threshold: 50),
        ReadingSwipe.none,
      );
      expect(readingSwipe(0, TextDirection.ltr), ReadingSwipe.none);
    });

    test('startSign', () {
      expect(startSign(TextDirection.ltr), -1);
      expect(startSign(TextDirection.rtl), 1);
    });
  });

  group('DirectionalIcon', () {
    Future<void> pump(
      WidgetTester tester,
      TextDirection direction,
      IconData icon,
    ) => tester.pumpWidget(
      Directionality(
        textDirection: direction,
        child: Center(child: DirectionalIcon(icon, semanticLabel: 'next')),
      ),
    );

    // Transform, ktory pridal DirectionalIcon (nie vnutorny z Icon).
    Finder flip() =>
        find.byWidgetPredicate((w) => w is Transform && w.child is Icon);

    testWidgets('not mirrored in LTR', (tester) async {
      await pump(tester, TextDirection.ltr, Icons.chevron_right);
      expect(flip(), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('mirrored in RTL', (tester) async {
      await pump(tester, TextDirection.rtl, Icons.east);
      expect(flip(), findsOneWidget);
      expect(find.bySemanticsLabel('next'), findsOneWidget);
    });

    testWidgets('icons with matchTextDirection are not flipped twice', (
      tester,
    ) async {
      expect(Icons.arrow_back.matchTextDirection, isTrue);
      await pump(tester, TextDirection.rtl, Icons.arrow_back);
      expect(flip(), findsNothing);
    });
  });
}
