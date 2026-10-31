import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/ui/gallery/gallery_catalog.dart';
import 'package:sakina/ui/gallery/gallery_samples.dart';
import 'package:sakina/ui/ui.dart';

import '../helpers/pump_sk.dart';

RichText _richText(WidgetTester tester) => tester.widget<RichText>(
  find.descendant(
    of: find.byType(SkArabicText),
    matching: find.byType(RichText),
  ),
);

/// `Text.rich` obali span do DefaultTextStyle spanu; vrati nase segmenty.
List<TextSpan> _segments(RichText rt) =>
    ((rt.text as TextSpan).children!.single as TextSpan).children!
        .cast<TextSpan>();

TextStyle _firstSpanStyle(RichText rt) => _segments(rt).first.style!;

const _quran = SkArabicText.quran([
  SkArabicSegment(GallerySamples.sentence),
], textSimple: GallerySamples.sentenceSimple);

void main() {
  testWidgets('renders RTL, ar locale, no maxLines/overflow', (tester) async {
    await tester.pumpSk(_quran);
    final rt = _richText(tester);
    expect(rt.textDirection, TextDirection.rtl);
    expect(rt.locale, const Locale('ar'));
    expect(rt.maxLines, isNull);
    expect(rt.softWrap, isTrue);
    expect(rt.overflow, TextOverflow.visible);
    expect(rt.textAlign, TextAlign.center);
    final style = _firstSpanStyle(rt);
    expect(style.fontFamily, SkFonts.amiriQuran);
    expect(style.fontWeight, FontWeight.w400);
    expect(style.letterSpacing, 0);
    expect(style.wordSpacing, 0);
    expect(style.color, SakinaColors.light.arabic);
    expect(
      tester
          .widget<Directionality>(
            find
                .ancestor(
                  of: find.byType(RichText),
                  matching: find.byType(Directionality),
                )
                .first,
          )
          .textDirection,
      TextDirection.rtl,
    );
  });

  testWidgets('screen reader reads text_simple with ar locale (D11)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpSk(_quran);
    final node = tester.getSemantics(find.byType(SkArabicText));
    expect(node.label, GallerySamples.sentenceSimple);
    expect(node.label, isNot(contains('۝')));
    final attrs = node.attributedLabel.attributes;
    expect(attrs, hasLength(1));
    final attr = attrs.single as LocaleStringAttribute;
    expect(attr.locale, const Locale('ar'));
    expect(attr.range, TextRange(start: 0, end: node.label.length));
    handle.dispose();
  });

  testWidgets('semanticsOverride replaces label without ar locale', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpSk(
      const SkArabicText.quran(
        [SkArabicSegment(GallerySamples.words)],
        textSimple: GallerySamples.wordsSimple,
        semanticsOverride: 'Arabic verse',
      ),
    );
    final node = tester.getSemantics(find.byType(SkArabicText));
    expect(node.label, 'Arabic verse');
    expect(node.attributedLabel.attributes, isEmpty);
    handle.dispose();
  });

  testWidgets('text() uses Noto Naskh and semanticsText', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpSk(
      SkArabicText.text(
        GallerySamples.words,
        semanticsText: GallerySamples.wordsSimple,
        style: SkArabicTextStyle.lemma,
      ),
    );
    final style = _firstSpanStyle(_richText(tester));
    expect(style.fontFamily, SkFonts.notoNaskhArabic);
    expect(style.fontSize, 48);
    expect(
      tester.getSemantics(find.byType(SkArabicText)).label,
      GallerySamples.wordsSimple,
    );
    final w = tester.widget<SkArabicText>(find.byType(SkArabicText));
    expect(w.isQuran, isFalse);
    expect(w.semanticsText, GallerySamples.wordsSimple);
    handle.dispose();
  });

  testWidgets('Quran is not clamped, other Arabic is (D12)', (tester) async {
    await tester.pumpSk(
      Column(children: [_quran, SkArabicText.text(GallerySamples.words)]),
      textScale: 3,
    );
    final texts = tester
        .widgetList<RichText>(
          find.descendant(
            of: find.byType(SkArabicText),
            matching: find.byType(RichText),
          ),
        )
        .toList();
    expect(texts[0].textScaler.scale(10), 30);
    expect(texts[1].textScaler.scale(10), 20);
  });

  testWidgets('tajwid colors segments, selected word gets background', (
    tester,
  ) async {
    await tester.pumpSk(
      const SkArabicText.quran(
        GallerySamples.segments,
        textSimple: GallerySamples.sentenceSimple,
        tajwid: true,
        selectedSegment: 0,
      ),
    );
    final spans = _segments(_richText(tester));
    expect(
      spans.first.style!.backgroundColor,
      SakinaColors.light.primaryContainer,
    );
    expect(spans.elementAt(1).style!.color, TajwidColors.light.ghunna);
    expect(spans.elementAt(3).style!.color, TajwidColors.light.qalqala);
    expect(spans.first.style!.color, SakinaColors.light.arabic);
  });

  testWidgets('tajwid off ignores rules', (tester) async {
    await tester.pumpSk(
      const SkArabicText.quran(
        GallerySamples.segments,
        textSimple: GallerySamples.sentenceSimple,
      ),
    );
    final spans = _segments(_richText(tester));
    expect(
      spans.every((s) => s.style!.color == SakinaColors.light.arabic),
      isTrue,
    );
  });

  test('every tajwid rule maps to its token', () {
    const t = TajwidColors.light;
    expect(
      SkTajwidRule.values.map((r) => r.colorIn(t)).toList(),
      t.asMap().values.toList(),
    );
  });

  testWidgets('highlight uses tonal background, border with tajwid', (
    tester,
  ) async {
    for (final tajwid in [false, true]) {
      await tester.pumpSk(
        SkArabicText.quran(
          GallerySamples.segments,
          textSimple: GallerySamples.sentenceSimple,
          tajwid: tajwid,
          highlight: true,
        ),
      );
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(SkArabicText),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final deco = box.decoration as BoxDecoration;
      if (tajwid) {
        expect(deco.color, isNull);
        expect(deco.border, isA<BorderDirectional>());
      } else {
        expect(deco.color, SakinaColors.light.primaryContainer);
      }
    }
  });

  testWidgets('user arabic scale enlarges text', (tester) async {
    await tester.pumpSk(
      const ArabicScaleOverride(scale: SkArabicScale.xl, child: _quran),
    );
    expect(
      _firstSpanStyle(_richText(tester)).fontSize,
      closeTo(30 * 1.45, 1e-9),
    );
  });

  testWidgets('integrity failure shows error and hides text', (tester) async {
    await tester.pumpSk(
      const SkArabicText.quran(
        [SkArabicSegment(GallerySamples.words)],
        textSimple: GallerySamples.wordsSimple,
        integrityFailed: true,
      ),
    );
    expect(find.byType(SkErrorState), findsOneWidget);
    expect(
      find.text(SkUiStrings.fallbackEn.contentUnavailableTitle),
      findsOneWidget,
    );
    expect(find.textContaining('كتاب'), findsNothing);
  });

  testWidgets('overflow in bounded height throws instead of clipping', (
    tester,
  ) async {
    await tester.pumpSk(
      const SizedBox(
        width: 200,
        height: 40,
        child: SkArabicText.quran([
          SkArabicSegment(GallerySamples.long),
        ], textSimple: GallerySamples.longSimple),
      ),
      scroll: false,
    );
    final error = tester.takeException();
    expect(error, isA<FlutterError>());
    expect('$error', contains('SkArabicText'));
  });

  testWidgets('fits in bounded height without error', (tester) async {
    await tester.pumpSk(
      const SizedBox(
        width: 300,
        height: 400,
        child: SkArabicText.quran([
          SkArabicSegment(GallerySamples.words),
        ], textSimple: GallerySamples.wordsSimple),
      ),
      scroll: false,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('justify is rejected', (tester) async {
    await tester.pumpSk(
      const SkArabicText.quran(
        [SkArabicSegment(GallerySamples.words)],
        textSimple: GallerySamples.wordsSimple,
        textAlign: TextAlign.justify,
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('dark theme uses dark arabic color', (tester) async {
    await tester.pumpSk(_quran, theme: SakinaTheme.dark());
    expect(_firstSpanStyle(_richText(tester)).color, SakinaColors.dark.arabic);
  });
}
