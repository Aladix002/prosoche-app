// BF-02: opravy kariet z behu RC0 (stupen a zbierka hadisu v jazyku UI,
// zlyhane stiahnutie vysvetliviek s Retry).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/features/cards/cards.dart';
import 'package:sakina/ui/gallery/gallery_samples.dart';
import 'package:sakina/ui/ui.dart';

import '../../helpers/golden/golden.dart';
import '../today/f02_harness.dart';

Future<void> _pumpCard(
  WidgetTester tester,
  Widget card, {
  Locale locale = const Locale('en'),
}) async {
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    LocalizedTestApp(
      locale: locale,
      theme: (b) => SakinaTheme.light(),
      child: Scaffold(body: SingleChildScrollView(child: card)),
    ),
  );
  await tester.pumpAndSettle();
}

/// Hadis v tvare HadeethEnc: `collection` je arabsky takhrij, `grade_ar`
/// arabsky original stupna, preklad ma vlastny takhrij v `attribution`.
HadithContent _hadith({
  String collection = hadithMuttafaqAlayh,
  String grade = 'sahih',
  String? lang = 'en',
  String? attribution = '[PLACEHOLDER takhrij en]',
}) => HadithContent(
  HadithCardId(13),
  textAr: '[PLACEHOLDER hadith ar]',
  grade: grade,
  gradeAr: '[PLACEHOLDER grade ar]',
  collection: collection,
  sourceId: 'fake',
  lang: lang,
  text: lang == null ? null : '[PLACEHOLDER hadith]',
  attribution: lang == null ? null : attribution,
  gradeLabel: lang == null ? null : '[PLACEHOLDER grade label]',
  arabicOnly: lang == null,
);

/// Balik vysvetliviek s ovladanym stavom.
class _Pack implements HadithExplanationsPack {
  _Pack(this._status);

  HadithExplanationsPackStatus _status;
  final _changes = StreamController<HadithExplanationsPackStatus>.broadcast();
  final finish = Completer<void>();
  int downloads = 0;

  void _set(HadithExplanationsPackStatus s) {
    _status = s;
    _changes.add(s);
  }

  @override
  Stream<HadithExplanationsPackStatus> watchStatus() async* {
    yield _status;
    yield* _changes.stream;
  }

  @override
  Future<void> download() async {
    downloads++;
    _set(HadithExplanationsPackStatus.downloading);
    await finish.future;
    _set(HadithExplanationsPackStatus.failed);
  }
}

void main() {
  setUpAll(loadSakinaFonts);

  group('hadith grade and collection in the UI language', () {
    testWidgets('EN: localized grade from the enum, no Arabic', (tester) async {
      await _pumpCard(tester, HadithCard(content: _hadith()));
      expect(find.text('Grade: Sahih (authentic)'), findsOneWidget);
      expect(find.textContaining(hadithMuttafaqAlayh), findsNothing);
      expect(find.textContaining('[PLACEHOLDER grade ar]'), findsNothing);
      // D-05: typ a referencia su v hlavicke na dvoch riadkoch.
      expect(find.text('HADITH'), findsOneWidget);
      expect(find.text('Agreed upon (Bukhari & Muslim)'), findsOneWidget);
      // Takhrij prekladu (atribucia) ostava doslovne.
      expect(find.text('[PLACEHOLDER takhrij en]'), findsOneWidget);
    });

    testWidgets('EN: hasan', (tester) async {
      await _pumpCard(tester, HadithCard(content: _hadith(grade: 'hasan')));
      expect(find.text('Grade: Hasan (good)'), findsOneWidget);
    });

    testWidgets('EN: other Arabic takhrij uses the translated one once', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        HadithCard(content: _hadith(collection: GallerySamples.lemma)),
      );
      expect(find.textContaining(GallerySamples.lemma), findsNothing);
      // Referencia == atribucia: hlavicka len typ, takhrij raz dole.
      expect(find.text('HADITH'), findsOneWidget);
      expect(find.text('[PLACEHOLDER takhrij en]'), findsOneWidget);
    });

    testWidgets('non-Arabic collection stays as it is', (tester) async {
      late String reference;
      await _pumpCard(
        tester,
        Builder(
          builder: (context) {
            reference = hadithReference(
              context,
              _hadith(collection: 'Sahih al-Bukhari'),
            );
            return const SizedBox();
          },
        ),
      );
      expect(reference, 'Sahih al-Bukhari');
    });

    testWidgets('AR: Arabic original of the grade and collection', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        HadithCard(content: _hadith(lang: null)),
        locale: const Locale('ar'),
      );
      expect(find.textContaining('[PLACEHOLDER grade ar]'), findsOneWidget);
      expect(find.textContaining('Sahih (authentic)'), findsNothing);
      expect(find.textContaining(hadithMuttafaqAlayh), findsOneWidget);
      expect(find.textContaining('Agreed upon'), findsNothing);
    });

    testWidgets('share text uses the same localized reference and grade', (
      tester,
    ) async {
      late CardShareData? data;
      await _pumpCard(
        tester,
        Builder(
          builder: (context) {
            data = shareDataFor(context, _hadith());
            return const SizedBox();
          },
        ),
      );
      expect(
        data!.reference,
        'Agreed upon (Bukhari & Muslim) · Grade: Sahih (authentic)',
      );
    });
  });

  group('explanations download failed', () {
    testWidgets('inline message with Retry', (tester) async {
      var retries = 0;
      final handle = tester.ensureSemantics();
      await _pumpCard(
        tester,
        HadithCard(
          content: _hadith(),
          explanationsFailed: true,
          onDownloadExplanations: () => retries++,
        ),
      );
      expect(
        find.text(
          "Couldn't download explanations. Check your connection and try "
          'again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Download explanations'), findsNothing);
      expect(find.bySemanticsLabel('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
      handle.dispose();
    });

    testWidgets('CardView: Retry downloads again, spinner, then message', (
      tester,
    ) async {
      final pack = _Pack(HadithExplanationsPackStatus.failed);
      await pumpF02(
        tester,
        location: '/host',
        host: CardView(cardId: HadithCardId(13), date: f02Today),
        overrides: [hadithExplanationsPackProvider.overrideWithValue(pack)],
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Retry'));
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();
      expect(pack.downloads, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Retry'), findsNothing);

      pack.finish.complete();
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('not downloaded still offers Download explanations', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        HadithCard(content: _hadith(), onDownloadExplanations: () {}),
      );
      expect(find.text('Download explanations'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });
  });
}
