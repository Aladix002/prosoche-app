import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/ui/ui.dart';

import '../../helpers/golden/golden_harness.dart';
import '../helpers/pump_sk.dart';

/// D-01: komponenty pre karty, Library a Practice (docs/DESIGN.md 6.2).
void main() {
  setUpAll(loadProsocheFonts);

  test('reference format and semantics', () {
    expect(SkReference.format('Meditations', '2.1'), 'Meditations 2.1');
    expect(SkReference.format('Enchiridion', null), 'Enchiridion');
    expect(
      SkReference.semanticsFor('Discourses', '1.1.7'),
      'Discourses, 1 1 7',
    );
    expect(SkReference.semanticsFor('Enchiridion', ''), 'Enchiridion');
    expect(
      SkUiStrings.fallbackEn.translatedBy('George Long', 1862),
      'tr. George Long, 1862',
    );
    expect(
      SkUiStrings.fallbackEn.translatedBy('George Long', null),
      'tr. George Long',
    );
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('quote card shows everything without clipping x$scale', (
      tester,
    ) async {
      await tester.pumpSk(
        const SizedBox(
          height: 900,
          child: SkQuoteCard(
            eyebrow: 'Quote',
            text: '[PLACEHOLDER quote] A sample quote.',
            work: 'Meditations',
            locus: '2.1',
            author: 'Marcus Aurelius',
            translator: 'George Long',
            year: 1862,
          ),
        ),
        textScale: scale,
      );
      expect(find.text('QUOTE'), findsOneWidget);
      expect(find.text('Meditations 2.1'), findsOneWidget);
      expect(find.text('Marcus Aurelius'), findsOneWidget);
      expect(find.text('tr. George Long, 1862'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('quote text never sets maxLines or overflow', (tester) async {
    await tester.pumpSk(
      const Column(
        children: [
          SkQuoteText('a'),
          SkQuoteText('b', style: SkQuoteStyle.passage),
          SkQuoteText('c', style: SkQuoteStyle.prompt),
        ],
      ),
    );
    for (final t in tester.widgetList<Text>(find.byType(Text))) {
      expect(t.maxLines, isNull);
      expect(t.overflow, isNull);
    }
    final prompt = tester.widget<Text>(find.text('c'));
    expect(prompt.style!.fontStyle, FontStyle.italic);
  });

  testWidgets('concept reads transliteration, not Greek', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpSk(
      const SkConceptHeader(
        term: 'prosoche',
        greek: 'προσοχή',
        gloss: 'attention',
      ),
    );
    expect(find.bySemanticsLabel('prosoche, attention'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('προσοχή')), findsNothing);
    handle.dispose();
  });

  testWidgets('author header drops the column at large text', (tester) async {
    await tester.pumpSk(const SkAuthorHeader(name: 'Epictetus'));
    expect(find.byType(SkColumn), findsOneWidget);
    await tester.pumpSk(const SkAuthorHeader(name: 'Epictetus'), textScale: 2);
    expect(find.byType(SkColumn), findsNothing);
  });

  testWidgets('reader text: section number, highlight and size', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpSk(
      const Column(
        children: [
          SkReaderHeading(title: 'Book II', subtitle: 'Among the Quadi'),
          SkReaderText(
            text: 'Sample.',
            sectionNumber: '1',
            semanticsPrefix: 'Section 1',
            highlighted: true,
            size: SkReaderSize.xl,
          ),
          SkReadingProgress(value: 0.4, label: 'Reading position'),
        ],
      ),
    );
    expect(find.byType(SkCornice), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(SkReadingProgress)),
      matchesSemantics(label: 'Reading position', value: '40 %'),
    );
    expect(SkReaderSize.xl.factor, 1.3);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('practice header and journal field', (tester) async {
    final handle = tester.ensureSemantics();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var changed = '';
    await tester.pumpSk(
      Column(
        children: [
          const SkPracticeHeader(
            time: SkPracticeTime.evening,
            eyebrow: 'Evening',
            title: 'Evening review',
            subtitle: 'Seneca',
          ),
          SkJournalField(
            controller: controller,
            label: 'What did I do well today?',
            privacyNote: 'Your journal stays on this device.',
            onChanged: (v) => changed = v,
          ),
        ],
      ),
    );
    expect(find.text('EVENING'), findsOneWidget);
    expect(find.byType(SkArch), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('What did I do well today')),
      findsWidgets,
    );
    await tester.enterText(find.byType(TextField), 'Kept calm.');
    expect(changed, 'Kept calm.');
    expect(find.text('Your journal stays on this device.'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('screen title is a header with cornice', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpSk(
      const SkScreenTitle(title: 'Library', eyebrow: 'Marcus Aurelius'),
    );
    expect(find.text('MARCUS AURELIUS'), findsOneWidget);
    expect(find.byType(SkCornice), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Library')),
      matchesSemantics(label: 'Library', isHeader: true),
    );
    handle.dispose();
  });
}
