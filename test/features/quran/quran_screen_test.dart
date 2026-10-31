import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/quran/quran_screen.dart';
import 'package:sakina/features/quran/reader/quran_reader_screen.dart';
import 'package:sakina/features/quran/search/quran_search_screen.dart';
import 'package:sakina/ui/i18n/i18n.dart';
import 'package:sakina/ui/ui.dart';

import '../../fakes/fake_repositories.dart';
import '../../helpers/golden/golden.dart';
import 'quran_test_helpers.dart';

/// A5.1 zoznam sur: stavy loading, data, error (empty nenastava), Continue,
/// progres, Juz, navigacia, semantics a text scale 2.0.
void main() {
  setUpAll(loadSakinaFonts);

  QuranReaderScreen reader(WidgetTester tester) =>
      tester.widget<QuranReaderScreen>(find.byType(QuranReaderScreen));

  testWidgets('data: surahs with meaning, place and verse count', (
    tester,
  ) async {
    await tester.pumpQuran('/quran');
    expect(find.byType(QuranScreen), findsOneWidget);
    expect(find.text('Placeholder 1'), findsWidgets);
    expect(find.text('[PLACEHOLDER meaning 2]'), findsOneWidget);
    expect(find.text('Meccan · 7 verses'), findsOneWidget);
    expect(find.text('Medinan · 286 verses'), findsOneWidget);
    // Bez precitanych versov ziadny progres bar.
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('tap on a surah opens the reader in browse mode', (tester) async {
    final router = await tester.pumpQuran('/quran');
    await tester.tap(find.text('Placeholder 2').last);
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), '/quran/read/2?mode=browse');
    expect(reader(tester).mode.name, 'browse');
  });

  testWidgets('continue banner: next verse after reading position (khatm)', (
    tester,
  ) async {
    final fakes = quranFakes();
    fakes.quran.position = AyahId(2, 143);
    final router = await tester.pumpQuran('/quran', fakes: fakes);
    final label = find.textContaining('Continue: ');
    expect(label, findsOneWidget);
    expect(
      Bidi.strip(tester.widget<Text>(label).data!),
      'Continue: Placeholder 2 2:144',
    );
    await tester.tap(label);
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), '/quran/read/2?ayah=2144&mode=khatm');
  });

  testWidgets('continue banner starts at 1:1 and hides equal last opened', (
    tester,
  ) async {
    await tester.pumpQuran('/quran');
    expect(find.textContaining('Start reading: '), findsOneWidget);
    expect(find.textContaining('Last opened'), findsNothing);
  });

  testWidgets('last opened (browse) is a second line', (tester) async {
    final fakes = quranFakes();
    await fakes.settings.set(SettingsKeys.readerLastAyahId, 2012);
    final router = await tester.pumpQuran('/quran', fakes: fakes);
    final last = find.textContaining('Last opened: ');
    expect(Bidi.strip(tester.widget<Text>(last).data!), endsWith('2:12'));
    await tester.tap(last);
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), '/quran/read/2?ayah=2012&mode=browse');
  });

  testWidgets('progress of a surah only when > 0', (tester) async {
    final quran = TestQuranRepository()..readCounts = {2: 143};
    await tester.pumpQuran('/quran', fakes: quranFakes(quran: quran));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('50 %'), findsOneWidget);
    // Zmena pocitadla sa prejavi hned (stream).
    quran.counts.add({1: 7, 2: 143});
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    expect(find.text('100 %'), findsOneWidget);
  });

  testWidgets('juz tab lists juz starts', (tester) async {
    final router = await tester.pumpQuran('/quran');
    await tester.tap(find.text('Juz'));
    await tester.pumpAndSettle();
    expect(find.text('Juz 1'), findsOneWidget);
    expect(find.text('Juz 2'), findsOneWidget);
    await tester.tap(find.text('Juz 2'));
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), '/quran/read/2?ayah=2142&mode=browse');
  });

  testWidgets('search button opens search', (tester) async {
    await tester.pumpQuran('/quran');
    await tester.tap(find.byTooltip('Search the Quran'));
    await tester.pumpAndSettle();
    expect(find.byType(QuranSearchScreen), findsOneWidget);
  });

  testWidgets('loading: nothing for 300 ms, then skeleton', (tester) async {
    final quran = TestQuranRepository()..hold = Completer<void>();
    await tester.pumpQuran(
      '/quran',
      fakes: quranFakes(quran: quran),
      settle: false,
    );
    expect(find.byType(SkSkeleton), findsNothing);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(SkSkeleton), findsOneWidget);
    quran.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(SkSkeleton), findsNothing);
    expect(find.text('Placeholder 1'), findsWidgets);
  });

  testWidgets('error: E-CONTENT-1 with retry', (tester) async {
    final quran = TestQuranRepository()..error = StateError('integrity');
    await tester.pumpQuran('/quran', fakes: quranFakes(quran: quran));
    expect(find.textContaining('This text can'), findsOneWidget);
    quran.error = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Placeholder 2'), findsWidgets);
  });

  testWidgets('empty list is shown as content error (cannot happen)', (
    tester,
  ) async {
    await tester.pumpQuran(
      '/quran',
      fakes: quranFakes(quran: TestQuranRepository(surahCount: 0)),
    );
    expect(find.textContaining('This text can'), findsOneWidget);
  });

  testWidgets('semantics: surah row is one button with full label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpQuran('/quran');
    expect(
      find.bySemanticsLabel(
        RegExp(r'^Surah 2, Placeholder 2, .*Medinan · 286 verses$'),
      ),
      findsOneWidget,
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  for (final locale in fullGoldenLocales) {
    testWidgets('${locale.languageCode}: textScale 2.0 without clipping', (
      tester,
    ) async {
      final quran = TestQuranRepository(surahCount: 3)..readCounts = {2: 10};
      final fakes = FakeRepositories(quran: quran);
      fakes.quran.position = AyahId(2, 9);
      await tester.pumpQuran(
        '/quran',
        fakes: fakes,
        locale: locale,
        textScale: 2,
      );
      expectNoTextClipping(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
