// BF-02: opravy citacky z behu RC0 (znacky poznamok prekladatela ako
// horny index, atribucia prekladu s verziou raz).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/features/cards/translator_notes.dart';
import 'package:sakina/features/quran/quran_format.dart';

import '../../../helpers/golden/golden.dart';
import '../quran_test_helpers.dart';

/// Preklad v tvare QuranEnc (Saheeh Intl.): prefix `(1)` a znacky `[n]`.
const _text = '(1) [PLACEHOLDER] one,[7] [PLACEHOLDER] two.[8]';
const _notes = '[7]- [PLACEHOLDER note seven]\n[8]- [PLACEHOLDER note eight]';

/// Zdroj ako v content.db: atribucia uz obsahuje cislo verzie.
const _quranEnc = TranslationSource(
  id: 'fake-en',
  lang: 'en',
  name: 'Fake translation',
  version: '1.1.2',
  attribution: '[PLACEHOLDER] publisher, via QuranEnc.com, version 1.1.2',
  license: 'test-only',
);

void main() {
  setUpAll(loadSakinaFonts);

  Finder tileOf(AyahId id) => find.byKey(ValueKey(id.value));

  /// Plny text odstavca prekladu versa (TextSpan + WidgetSpan znacky).
  String paragraphText(WidgetTester tester, AyahId id) {
    final p = tester
        .renderObjectList<RenderParagraph>(
          find.descendant(of: tileOf(id), matching: find.byType(RichText)),
        )
        .firstWhere((p) => p.text.toPlainText().contains('[PLACEHOLDER] one'));
    final buffer = StringBuffer();
    p.text.visitChildren((span) {
      if (span is TextSpan && span.text != null) buffer.write(span.text);
      return true;
    });
    return buffer.toString();
  }

  group('translator notes in the reader', () {
    testWidgets('markers are superscript buttons, text is unchanged', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final quran = TestQuranRepository(
        translations: {AyahId(1, 1): _text},
        footnotes: {AyahId(1, 1): _notes},
      );
      await tester.pumpQuran('/quran/read/1', fakes: quranFakes(quran: quran));

      final markers = find.descendant(
        of: tileOf(AyahId(1, 1)),
        matching: find.byType(TranslatorNoteMarker),
      );
      expect(markers, findsNWidgets(2));
      expect(find.bySemanticsLabel("Translator's note 7"), findsOneWidget);
      // Bez znaciek je text versa doslovne zvysok prekladu; spolu so
      // znackami je to presne povodny retazec (splitTranslation).
      final plain = paragraphText(tester, AyahId(1, 1));
      expect(plain, '(1) [PLACEHOLDER] one, [PLACEHOLDER] two.');
      final marker = tester.widget<TranslatorNoteMarker>(markers.first);
      expect(marker.marker, '[7]');
      // Znacka je mensia nez text prekladu (horny index).
      final markerSize = tester.getSize(
        find.descendant(of: markers.first, matching: find.text('[7]')),
      );
      expect(markerSize.height, lessThan(20));

      // Poznamky nie su dvakrat: ziadna rozbalovacka.
      expect(find.text("Translator's notes"), findsNothing);

      await tester.tap(
        find.descendant(of: markers.last, matching: find.text('[8]')),
      );
      await tester.pumpAndSettle();
      expect(find.text("Translator's note"), findsOneWidget);
      expect(find.text('[PLACEHOLDER note eight]'), findsOneWidget);
      expect(find.text('[PLACEHOLDER note seven]'), findsNothing);
      handle.dispose();
    });

    testWidgets('notes without markers in the text stay in the expander', (
      tester,
    ) async {
      final quran = TestQuranRepository(
        translations: {AyahId(1, 1): '(1) [PLACEHOLDER] one,[7]'},
        footnotes: {AyahId(1, 1): _notes},
      );
      await tester.pumpQuran('/quran/read/1', fakes: quranFakes(quran: quran));
      expect(find.byType(TranslatorNoteMarker), findsOneWidget);
      // [8] nema znacku: poznamky sa nemazu (QuranEnc), ostava rozbalovacka.
      expect(find.text("Translator's notes"), findsOneWidget);
    });

    test('referenced notes', () {
      final notes = parseTranslatorNotes(_notes);
      expect(referencedTranslatorNotes(_text, notes), {7, 8});
      expect(referencedTranslatorNotes('a[7] b[9]', notes), {7});
    });
  });

  group('translation attribution', () {
    testWidgets('version is shown once when the attribution has it', (
      tester,
    ) async {
      final quran = TestQuranRepository(sources: const [_quranEnc]);
      await tester.pumpQuran('/quran/read/1', fakes: quranFakes(quran: quran));
      expect(
        find.text('[PLACEHOLDER] publisher, via QuranEnc.com, version 1.1.2'),
        findsOneWidget,
      );
      expect(find.textContaining('Version 1.1.2'), findsNothing);
      // Atribucia v Aa sheete tiez raz.
      await tester.tap(find.byTooltip('Text settings'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Version 1.1.2'), findsNothing);
    });

    testWidgets('version is added when the attribution lacks it', (
      tester,
    ) async {
      await tester.pumpQuran('/quran/read/1');
      expect(
        find.text('Version 1 · [PLACEHOLDER attribution]'),
        findsOneWidget,
      );
    });

    testWidgets('empty attribution falls back to the name', (tester) async {
      late String a;
      late String b;
      await tester.pumpWidget(
        LocalizedTestApp(
          locale: const Locale('en'),
          child: Builder(
            builder: (context) {
              a = translationAttribution(
                context,
                const TranslationSource(
                  id: 'x',
                  lang: 'en',
                  name: 'Name',
                  version: '2',
                  attribution: ' ',
                  license: '-',
                ),
              );
              b = translationAttribution(
                context,
                const TranslationSource(
                  id: 'x',
                  lang: 'en',
                  name: 'Name',
                  version: '',
                  attribution: 'Attr',
                  license: '-',
                ),
              );
              return const SizedBox();
            },
          ),
        ),
      );
      expect(a, 'Version 2 · Name');
      expect(b, 'Attr');
    });
  });
}
