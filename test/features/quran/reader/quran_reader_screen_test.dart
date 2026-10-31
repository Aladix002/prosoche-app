import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/quests.dart'
    show CardAction, CardContext;
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/quran/quran_format.dart';
import 'package:prosoche/features/quran/widgets/ayah_tile.dart';
import 'package:prosoche/ui/ui.dart';

import '../../../fakes/fake_repositories.dart';
import '../../../helpers/golden/golden.dart';
import '../quran_test_helpers.dart';

/// A5.2 citatel: stavy, bajtovy text, bismillah, lenivy zoznam, dwell,
/// khatm/browse, preklad a fallback, akcie, a11y, text scale 2.0.
void main() {
  setUpAll(loadProsocheFonts);

  Finder tileOf(AyahId id) => find.byKey(ValueKey(id.value));

  testWidgets('shows text_uthmani byte for byte with the verse end marker', (
    tester,
  ) async {
    await tester.pumpQuran('/quran/read/1');
    final texts = displayedQuranTexts(tester);
    // Ziadne bismillah nad 1 (je to vers 1:1).
    expect(texts.first, '[PLACEHOLDER uthmani 1:1]');
    for (final (i, t) in texts.indexed) {
      expect(t.codeUnits, '[PLACEHOLDER uthmani 1:${i + 1}]'.codeUnits);
    }
    final segments = quranSegments(tester, within: tileOf(AyahId(1, 1)));
    expect(segments.single, ['[PLACEHOLDER uthmani 1:1]', verseEndMarker(1)]);
    // NBSP + U+06DD + arabsko-indicke cislice.
    expect(verseEndMarker(255).codeUnits, [0xA0, 0x6DD, 0x662, 0x665, 0x665]);
  });

  testWidgets('bismillah from content.db above surah 2, not above 9', (
    tester,
  ) async {
    await tester.pumpQuran('/quran/read/2');
    expect(displayedQuranTexts(tester).first, '[PLACEHOLDER bismillah]');
    await tester.pumpQuran('/quran/read/9');
    expect(displayedQuranTexts(tester).first, '[PLACEHOLDER uthmani 9:1]');
  });

  testWidgets('opens at the verse lazily (2:255 on top, 2:1 not built)', (
    tester,
  ) async {
    await tester.pumpQuran('/quran/read/2?ayah=2255&mode=browse');
    expect(tileOf(AyahId(2, 255)), findsOneWidget);
    expect(tileOf(AyahId(2, 1)), findsNothing);
    expect(
      find.byType(AyahTile).evaluate().length,
      lessThan(20),
      reason: 'zoznam musi byt lenivy',
    );
    final top = tester.getTopLeft(tileOf(AyahId(2, 255))).dy;
    expect(top, lessThan(200));
    // Scroll hore odhali predchadzajuce versy.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(tileOf(AyahId(2, 254)), findsOneWidget);
  });

  testWidgets('invalid ayah opens the surah at the start with E-LINK-1', (
    tester,
  ) async {
    await tester.pumpQuran('/quran/read/2?ayah=3001');
    expect(find.text('That verse could not be found.'), findsOneWidget);
    expect(tileOf(AyahId(2, 1)), findsOneWidget);
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.text('That verse could not be found.'), findsNothing);
  });

  testWidgets('non numeric ayah is also not found', (tester) async {
    await tester.pumpQuran('/quran/read/1?ayah=x');
    expect(find.text('That verse could not be found.'), findsOneWidget);
  });

  testWidgets('juz and page of the top verse in the header', (tester) async {
    await tester.pumpQuran('/quran/read/2?ayah=2150');
    expect(find.text('Juz 2 · Page 31'), findsOneWidget);
  });

  group('reading (dwell 2.5 s at 60 %)', () {
    testWidgets('browse: verses are read after 2.5 s, not before', (
      tester,
    ) async {
      final fakes = quranFakes();
      await tester.pumpQuran(
        '/quran/read/36?ayah=36001',
        fakes: fakes,
        settle: false,
      );
      await tester.pump();
      await tester.pump();
      expect(displayedQuranTexts(tester), isNotEmpty);
      await tester.pump(const Duration(milliseconds: 2400));
      expect(fakes.quran.read, isEmpty);
      await tester.pump(const Duration(milliseconds: 200));
      expect(fakes.quran.read, isNotEmpty);
      expect(fakes.quran.read.first, (AyahId(36, 1), ReaderMode.browse));
      // Browse neposuva khatm poziciu.
      expect(fakes.quran.position, isNull);
    });

    testWidgets('khatm: position moves verse by verse in order', (
      tester,
    ) async {
      final fakes = quranFakes();
      fakes.quran.position = AyahId(2, 142);
      await tester.pumpQuran(
        '/quran/read/2?ayah=2143&mode=khatm',
        fakes: fakes,
      );
      await tester.pump(const Duration(seconds: 3));
      final read = [for (final r in fakes.quran.read) r.$1];
      expect(read.first, AyahId(2, 143));
      expect(read, orderedEquals([...read]..sort()));
      expect(fakes.quran.position, read.last);
      expect(fakes.quran.position!.value, greaterThanOrEqualTo(2144));
    });

    testWidgets('khatm: does not move past an unread verse', (tester) async {
      final fakes = quranFakes();
      fakes.quran.position = AyahId(2, 141);
      // 2:142 nie je na obrazovke, 2:143+ su: pozicia sa nepohne.
      await tester.pumpQuran(
        '/quran/read/2?ayah=2143&mode=khatm',
        fakes: fakes,
      );
      await tester.pump(const Duration(seconds: 3));
      expect(fakes.quran.position, AyahId(2, 141));
    });

    testWidgets('only while the app is in the foreground', (tester) async {
      final fakes = quranFakes();
      await tester.pumpQuran('/quran/read/1', fakes: fakes);
      await tester.pump(const Duration(seconds: 1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 3));
      expect(fakes.quran.read, isEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 3));
      expect(fakes.quran.read, isNotEmpty);
    });

    testWidgets('scrolling stops the timer of verses that left the screen', (
      tester,
    ) async {
      final fakes = quranFakes();
      await tester.pumpQuran('/quran/read/2', fakes: fakes);
      await tester.pump(const Duration(seconds: 1));
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, -6000),
        3000,
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      final read = [for (final r in fakes.quran.read) r.$1.ayah];
      expect(read, isNot(contains(1)));
      expect(read, isNotEmpty);
    });

    testWidgets('khatm complete after 114:6 shows the completion dialog', (
      tester,
    ) async {
      final fakes = quranFakes();
      fakes.quran.position = AyahId(114, 5);
      final router = await tester.pumpQuran(
        '/quran/read/114?ayah=114006&mode=khatm',
        fakes: fakes,
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('You completed the Quran'), findsOneWidget);
      await tester.tap(find.text('Start again from Placeholder 1'));
      await tester.pumpAndSettle();
      expect(router.state.uri.toString(), '/quran/read/1?ayah=1001&mode=khatm');
    });
  });

  group('translation', () {
    testWidgets('EN: translation with attribution and version', (tester) async {
      await tester.pumpQuran('/quran/read/1');
      expect(find.text('[PLACEHOLDER translation 1:1]'), findsOneWidget);
      expect(
        find.text('Translation of meaning: Fake translation'),
        findsOneWidget,
      );
      expect(
        find.text('Version 1 · [PLACEHOLDER attribution]'),
        findsOneWidget,
      );
      expect(find.text('EN'), findsNothing);
    });

    testWidgets('AR: Quran without translation', (tester) async {
      await tester.pumpQuran('/quran/read/1', locale: const Locale('ar'));
      expect(find.textContaining('[PLACEHOLDER translation'), findsNothing);
      expect(find.textContaining('Fake translation'), findsNothing);
      expect(displayedQuranTexts(tester), isNotEmpty);
    });

    testWidgets('BN: English fallback with EN tag', (tester) async {
      await tester.pumpQuran('/quran/read/1', locale: const Locale('bn'));
      expect(find.text('[PLACEHOLDER translation 1:1]'), findsOneWidget);
      expect(find.text('EN'), findsWidgets);
    });

    testWidgets('missing translation note (B0.6)', (tester) async {
      final quran = TestQuranRepository(noTranslation: {AyahId(1, 1)});
      await tester.pumpQuran('/quran/read/1', fakes: quranFakes(quran: quran));
      expect(
        find.text('Translation not available in your language'),
        findsOneWidget,
      );
    });

    testWidgets('translation can be turned off in the Aa sheet', (
      tester,
    ) async {
      final fakes = quranFakes();
      await tester.pumpQuran('/quran/read/1', fakes: fakes);
      await tester.tap(find.byTooltip('Text settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show translation'));
      await tester.pumpAndSettle();
      expect(await fakes.settings.get(SettingsKeys.displayTranslation), false);
      await tester.tap(find.text('XL'));
      await tester.pumpAndSettle();
      expect(await fakes.settings.get(SettingsKeys.displayArabicScale), 1.45);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('[PLACEHOLDER translation 1:1]'), findsNothing);
      final style = quranTextStyle(tester, tileOf(AyahId(1, 1)));
      expect(style.fontSize, closeTo(28 * 1.45, 0.01));
    });

    testWidgets('translator notes are kept and can be expanded', (
      tester,
    ) async {
      final quran = TestQuranRepository(
        footnotes: {AyahId(1, 2): '[PLACEHOLDER footnote]'},
      );
      await tester.pumpQuran('/quran/read/1', fakes: quranFakes(quran: quran));
      expect(find.text('[PLACEHOLDER footnote]'), findsNothing);
      await tester.ensureVisible(find.text("Translator's notes"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Translator's notes"));
      await tester.pumpAndSettle();
      expect(find.text('[PLACEHOLDER footnote]'), findsOneWidget);
      await tester.tap(find.text('Hide notes'));
      await tester.pumpAndSettle();
      expect(find.text('[PLACEHOLDER footnote]'), findsNothing);
    });
  });

  group('actions', () {
    testWidgets('save and remove from saved (context reader)', (tester) async {
      final fakes = quranFakes();
      await tester.pumpQuran('/quran/read/1', fakes: fakes);
      await tester.tap(find.byTooltip('Save').first);
      await tester.pumpAndSettle();
      expect(fakes.actions.logged.last, (
        AyahCardId(AyahId(1, 1)),
        CardAction.saved,
        CardContext.reader,
      ));
      expect(find.byTooltip('Remove from saved'), findsOneWidget);
      await tester.tap(find.byTooltip('Remove from saved'));
      await tester.pumpAndSettle();
      expect(fakes.actions.logged.last.$2, CardAction.unsaved);
    });

    testWidgets('long press: copy verse with reference and attribution', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpQuran('/quran/read/1');
      await tester.longPress(tileOf(AyahId(1, 2)));
      await tester.pumpAndSettle();
      expect(find.text('Verse actions'), findsOneWidget);
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(
        copied,
        '[PLACEHOLDER uthmani 1:2]\n\n[PLACEHOLDER translation 1:2]\n\n'
        '- Placeholder 1 1:2 (Fake translation)\nvia Prosoche',
      );
      // Potvrdenie je banner nad zoznamom, nie snackbar nad textom.
      expect(find.text('Verse copied'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Verse copied'), findsNothing);
    });

    testWidgets('save from the actions sheet', (tester) async {
      final fakes = quranFakes();
      await tester.pumpQuran('/quran/read/1', fakes: fakes);
      await tester.tap(find.byTooltip('Verse actions').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();
      expect(fakes.actions.logged.single.$2, CardAction.saved);
    });

    testWidgets('sajda verse has an icon with tooltip', (tester) async {
      final quran = TestQuranRepository(sajda: {AyahId(1, 1)});
      await tester.pumpQuran('/quran/read/1', fakes: quranFakes(quran: quran));
      expect(find.byTooltip('Prostration verse'), findsOneWidget);
    });

    testWidgets('next surah at the end', (tester) async {
      final router = await tester.pumpQuran('/quran/read/1?mode=khatm');
      await tester.scrollUntilVisible(
        find.text('Next: Placeholder 2'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Next: Placeholder 2'));
      await tester.pumpAndSettle();
      expect(router.state.uri.toString(), '/quran/read/2?mode=khatm');
    });

    testWidgets('last surah ends with back to surahs', (tester) async {
      await tester.pumpQuran(
        '/quran/read/114',
        fakes: quranFakes(quran: TestQuranRepository(surahCount: 114)),
        size: const Size(360, 2000),
      );
      expect(find.text('Back to surahs'), findsOneWidget);
    });
  });

  group('states', () {
    testWidgets('loading: skeleton after 300 ms', (tester) async {
      final quran = TestQuranRepository()..hold = Completer<void>();
      await tester.pumpQuran(
        '/quran/read/1',
        fakes: quranFakes(quran: quran),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(SkSkeleton), findsOneWidget);
      quran.hold!.complete();
      await tester.pumpAndSettle();
      expect(displayedQuranTexts(tester), isNotEmpty);
    });

    testWidgets('error: text is not shown (E-CONTENT-1) and retry works', (
      tester,
    ) async {
      final quran = TestQuranRepository()..error = StateError('integrity');
      await tester.pumpQuran('/quran/read/1', fakes: quranFakes(quran: quran));
      expect(find.textContaining('This text can'), findsOneWidget);
      expect(displayedQuranTexts(tester), isEmpty);
      quran.error = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(displayedQuranTexts(tester), isNotEmpty);
    });
  });

  testWidgets('semantics: verse reference read in words', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpQuran('/quran/read/1');
    expect(
      find.bySemanticsLabel(RegExp('^Surah Placeholder 1, verse 2')),
      findsOneWidget,
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  for (final locale in fullGoldenLocales) {
    testWidgets('${locale.languageCode}: textScale 2.0 and XL, no clipping', (
      tester,
    ) async {
      final fakes = FakeRepositories(
        quran: TestQuranRepository(
          footnotes: {AyahId(2, 255): '[PLACEHOLDER footnote]'},
        ),
      );
      await fakes.settings.set(SettingsKeys.displayArabicScale, 1.45);
      await tester.pumpQuran(
        '/quran/read/2?ayah=2255',
        fakes: fakes,
        locale: locale,
        textScale: 2,
      );
      expectNoTextClipping(tester);
      // Arabcina Koranu sa neclampuje (D12): XL x 2.0.
      final style = tester
          .widget<RichText>(
            find
                .descendant(
                  of: tileOf(AyahId(2, 255)),
                  matching: find.byType(RichText),
                )
                .first,
          )
          .textScaler;
      expect(style.scale(10), 20);
    });
  }
}
