// BF-01: opravy z prveho behu na emulatore (hadis bez EN fallbacku,
// poznamky prekladatela vo verse, bidi hijri datumu, "Download
// explanations").
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/calendar/calendar.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/features/cards/cards.dart';
import 'package:sakina/ui/i18n/i18n.dart';
import 'package:sakina/ui/ui.dart';

import '../../helpers/golden/golden.dart';
import '../today/f02_harness.dart';

/// Preklad 1:1 v tvare QuranEnc (Saheeh Intl.): prefix `(1)` a znacky.
const _text =
    '(1) In the name of [PLACEHOLDER],[2] the [PLACEHOLDER], the '
    '[PLACEHOLDER].[3]';
const _notes = '[2]- [PLACEHOLDER note two]\n[3]- [PLACEHOLDER note three]';

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
      // Navigator pre sheet s poznamkou.
      child: Navigator(
        key: UniqueKey(),
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => Scaffold(body: SingleChildScrollView(child: card)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AyahContent _ayah({String text = _text, String? notes = _notes}) => AyahContent(
  AyahCardId(AyahId(1, 1)),
  surah: const SurahInfo(
    id: 1,
    nameAr: '[PLACEHOLDER]',
    nameTranslit: 'Placeholder',
    nameMeaning: '[PLACEHOLDER]',
    revelationPlace: 'meccan',
    ayahCount: 7,
    bismillahPre: false,
  ),
  ayah: AyahView(
    id: AyahId(1, 1),
    textUthmani: '[PLACEHOLDER uthmani 1:1]',
    juz: 1,
    page: 1,
    translation: TranslationText(
      text: text,
      footnotes: notes,
      sourceId: 'fake',
      lang: 'en',
    ),
  ),
);

HadithContent _hadith({String? lang, String? text, bool arabicOnly = false}) =>
    HadithContent(
      HadithCardId(13),
      textAr: '[PLACEHOLDER hadith ar]',
      grade: 'sahih',
      collection: '[PLACEHOLDER collection]',
      number: '1',
      sourceId: 'fake',
      lang: lang,
      text: text,
      arabicOnly: arabicOnly,
    );

/// Balik vysvetliviek s ovladanym stavom (D-05 zatial nie je).
class _Pack implements HadithExplanationsPack {
  _Pack(HadithExplanationsPackStatus initial) : _status = initial;

  HadithExplanationsPackStatus _status;
  final _changes = StreamController<HadithExplanationsPackStatus>.broadcast();
  final finish = Completer<void>();
  int downloads = 0;

  void set(HadithExplanationsPackStatus s) {
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
    set(HadithExplanationsPackStatus.downloading);
    await finish.future;
    set(HadithExplanationsPackStatus.ready);
  }
}

/// Vysvetlivka az po stiahnuti balika.
class _AfterDownload implements HadithExtraRepository {
  bool downloaded = false;

  @override
  Future<HadithExtra?> explanation(int hadithId, String lang) async =>
      downloaded
      ? HadithExtra(
          hadithId: hadithId,
          lang: lang,
          explanation: '[PLACEHOLDER explanation]',
        )
      : null;
}

void main() {
  setUpAll(loadSakinaFonts);

  group('translator notes (QuranEnc)', () {
    test('parses "[n]- text", "[n] text" and continuation lines', () {
      expect(parseTranslatorNotes('[2]- a\n[3] b\nmore\n\n[10]-c'), {
        2: 'a',
        3: 'b\nmore',
        10: 'c',
      });
      expect(parseTranslatorNotes(null), isEmpty);
      expect(parseTranslatorNotes('  '), isEmpty);
    });

    test('split keeps the translation text byte for byte', () {
      final notes = parseTranslatorNotes(_notes);
      final parts = splitTranslation(_text, notes);
      expect(parts.map((p) => p.text).join(), _text);
      expect([for (final p in parts) ?p.note], [2, 3]);
      // `(1)` je sucast textu, nie znacka; `[PLACEHOLDER]` tiez nie.
      expect(parts.first.text, startsWith('(1) In the name of'));
      expect(parts.first.note, isNull);
    });

    test('a marker without a note stays plain text', () {
      final parts = splitTranslation('a[4] b[2]', {2: 'x'});
      expect(parts, [(text: 'a[4] b', note: null), (text: '[2]', note: 2)]);
    });

    testWidgets('verse card: markers are tappable and open the note', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpCard(tester, AyahCard(content: _ayah()));
      expect(find.byType(TranslatorNoteMarker), findsNWidgets(2));
      // Znacka je doslovne `[2]`, len styl je iny (horny index).
      expect(find.text('[2]'), findsOneWidget);
      expect(find.bySemanticsLabel("Translator's note 2"), findsOneWidget);

      await tester.tap(find.text('[3]'));
      await tester.pumpAndSettle();
      expect(find.text("Translator's note"), findsOneWidget);
      expect(find.text('[PLACEHOLDER note three]'), findsOneWidget);
      expect(find.text('[PLACEHOLDER note two]'), findsNothing);
      handle.dispose();
    });

    testWidgets('verse card without notes renders plain text', (tester) async {
      await _pumpCard(
        tester,
        AyahCard(content: _ayah(text: 'Plain [2] text', notes: null)),
      );
      expect(find.byType(TranslatorNoteMarker), findsNothing);
      expect(find.text('Plain [2] text'), findsOneWidget);
    });
  });

  group('religious text never falls back to EN (docs/03 7.3)', () {
    testWidgets('AR: hadith shows only the Arabic original, no note', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        HadithCard(content: _hadith(arabicOnly: true)),
        locale: const Locale('ar'),
      );
      expect(find.byType(CardTranslation), findsOneWidget);
      expect(find.byType(SkTag), findsNothing);
      expect(
        find.text('Translation not yet available in your language'),
        findsNothing,
      );
      // Zbierka, cislo a stupen ostavaju (plan 17.11).
      expect(find.textContaining('[PLACEHOLDER collection]'), findsOneWidget);
    });

    testWidgets('BN: hadith without translation shows the note, no EN', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        HadithCard(content: _hadith()),
        locale: const Locale('bn'),
      );
      expect(
        find.text('Translation not yet available in your language'),
        findsOneWidget,
      );
      expect(find.byType(SkTag), findsNothing);
    });

    testWidgets('BN: dua and name without translation show the note', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        DuaCard(
          content: DuaContent(
            DuaCardId(1),
            textAr: '[PLACEHOLDER dua ar]',
            sourceRef: 'example:1',
            repeatCount: 1,
          ),
        ),
        locale: const Locale('bn'),
      );
      expect(
        find.text('Translation not yet available in your language'),
        findsOneWidget,
      );
      await _pumpCard(
        tester,
        NameCard(
          content: NameContent(
            NameCardId(1),
            textAr: '[PLACEHOLDER name ar]',
            arabicOnly: true,
          ),
        ),
        locale: const Locale('ar'),
      );
      expect(
        find.text('Translation not yet available in your language'),
        findsNothing,
      );
    });

    testWidgets('verse EN fallback keeps the EN tag (docs/02 B0.6)', (
      tester,
    ) async {
      final c = _ayah();
      await _pumpCard(
        tester,
        AyahCard(
          content: AyahContent(
            c.id as AyahCardId,
            surah: c.surah,
            ayah: AyahView(
              id: c.ayah.id,
              textUthmani: c.ayah.textUthmani,
              juz: 1,
              page: 1,
              translation: const TranslationText(
                text: '[PLACEHOLDER en]',
                sourceId: 'fake',
                lang: 'en',
                isFallback: true,
              ),
            ),
          ),
        ),
        locale: const Locale('bn'),
      );
      expect(find.byType(SkTag), findsOneWidget);
    });

    testWidgets('CardView in Arabic: hadith without translation or note', (
      tester,
    ) async {
      await pumpF02(
        tester,
        location: '/host',
        locale: const Locale('ar'),
        host: CardView(cardId: HadithCardId(13), date: f02Today),
      );
      await tester.pumpAndSettle();
      expect(find.text('[PLACEHOLDER hadith ar]'), findsOneWidget);
      expect(find.text('[PLACEHOLDER hadith]'), findsNothing);
      expect(
        find.text('Translation not yet available in your language'),
        findsNothing,
      );
    });
  });

  group('hadith explanations pack (D-05 interface)', () {
    Future<void> host(
      WidgetTester tester, {
      HadithExplanationsPack? pack,
      HadithExtraRepository? extra,
    }) async {
      await pumpF02(
        tester,
        location: '/host',
        host: CardView(cardId: HadithCardId(13), date: f02Today),
        overrides: [
          if (pack != null)
            hadithExplanationsPackProvider.overrideWithValue(pack),
          if (extra != null)
            hadithExtraRepositoryProvider.overrideWithValue(extra),
        ],
      );
      await tester.pumpAndSettle();
    }

    testWidgets('default (no D-05): no download button', (tester) async {
      await host(tester);
      expect(find.text('Download explanations'), findsNothing);
      expect(find.text('Explanation'), findsNothing);
    });

    testWidgets('not downloaded: download, spinner, then Explanation', (
      tester,
    ) async {
      final pack = _Pack(HadithExplanationsPackStatus.notDownloaded);
      final extra = _AfterDownload();
      await host(tester, pack: pack, extra: extra);
      expect(find.text('Explanation'), findsNothing);
      await tester.tap(find.text('Download explanations'));
      await tester.pump();
      await tester.pump();
      expect(pack.downloads, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      extra.downloaded = true;
      pack.finish.complete();
      await tester.pumpAndSettle();
      expect(find.text('Download explanations'), findsNothing);
      await tester.tap(find.text('Explanation'));
      await tester.pumpAndSettle();
      expect(find.text('[PLACEHOLDER explanation]'), findsOneWidget);
    });

    testWidgets('failed download offers the download again', (tester) async {
      await host(tester, pack: _Pack(HadithExplanationsPackStatus.failed));
      // BF-02: inline hlaska a Retry namiesto "Download explanations".
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('ready without an explanation: no button', (tester) async {
      await host(tester, pack: _Pack(HadithExplanationsPackStatus.ready));
      expect(find.text('Download explanations'), findsNothing);
      expect(find.text('Explanation'), findsNothing);
    });

    testWidgets('no translation: no explanation offered', (tester) async {
      await pumpF02(
        tester,
        location: '/host',
        locale: const Locale('ar'),
        host: CardView(cardId: HadithCardId(13), date: f02Today),
        overrides: [
          hadithExplanationsPackProvider.overrideWithValue(
            _Pack(HadithExplanationsPackStatus.notDownloaded),
          ),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('Download explanations'), findsNothing);
    });
  });

  group('bidi (RTL)', () {
    final hijri = IslamicCalendar().hijriOf(LocalDate(2026, 10, 29));

    for (final locale in [const Locale('ar'), const Locale('ur')]) {
      testWidgets('${locale.languageCode}: hijri date keeps day-month-year', (
        tester,
      ) async {
        late String label;
        await _pumpCard(
          tester,
          Builder(
            builder: (context) {
              label = context.hijriLabel(hijri);
              return Text(label);
            },
          ),
          locale: locale,
        );
        expect(label, startsWith(Bidi.fsi));
        expect(label, endsWith(Bidi.pdi));
        final day = localizeDigits(
          '${hijri.day}',
          SakinaFormats(locale).digits,
        );
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(label),
        );
        final plain = Bidi.strip(label);
        // Latinkovy nazov mesiaca (EN fallback UI textu): den je vizualne
        // pred mesiacom aj v RTL odstavci, rok za nim.
        final dayX = paragraph
            .getOffsetForCaret(const TextPosition(offset: 1), Rect.zero)
            .dx;
        final yearAt = label.lastIndexOf(plain.split(' ').last);
        final yearX = paragraph
            .getOffsetForCaret(TextPosition(offset: yearAt), Rect.zero)
            .dx;
        expect(plain, startsWith(day));
        expect(dayX, lessThan(yearX));
      });
    }

    testWidgets('verse reference isolates the surah name', (tester) async {
      late String ref;
      await _pumpCard(
        tester,
        Builder(
          builder: (context) {
            ref = context.ayahReference('Al-Faatiha', AyahId(1, 1));
            return Text(ref);
          },
        ),
        locale: const Locale('ar'),
      );
      expect(ref, contains(Bidi.isolate('Al-Faatiha')));
    });
  });
}
