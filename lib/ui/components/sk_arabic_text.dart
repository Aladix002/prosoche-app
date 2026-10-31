import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:prosoche/ui/components/sk_states.dart';
import 'package:prosoche/ui/foundation/sk_text_scaling.dart';
import 'package:prosoche/ui/foundation/sk_ui_strings.dart';
import 'package:prosoche/ui/theme/prosoche_typography.dart';
import 'package:prosoche/ui/theme/sk_context.dart';
import 'package:prosoche/ui/theme/tajwid_colors.dart';
import 'package:prosoche/ui/tokens/sk_space.dart';

/// Tajwid pravidlo segmentu (docs/01 2.2).
enum SkTajwidRule {
  madd6,
  madd45,
  madd246,
  madd2,
  ghunna,
  qalqala,
  tafkhim,
  silent;

  Color colorIn(TajwidColors t) => switch (this) {
    madd6 => t.madd6,
    madd45 => t.madd45,
    madd246 => t.madd246,
    madd2 => t.madd2,
    ghunna => t.ghunna,
    qalqala => t.qalqala,
    tafkhim => t.tafkhim,
    silent => t.silent,
  };
}

/// Segment koranoveho textu. Segment je cely grafem alebo slovo, nikdy
/// samostatna diakritika (docs/01 2.2) - zodpovednost volajuceho.
@immutable
class SkArabicSegment {
  const SkArabicSegment(this.text, {this.rule});

  final String text;
  final SkTajwidRule? rule;
}

/// Token pre `SkArabicText.quran`.
enum SkQuranStyle { card, reader, word, bismillah }

/// Token pre `SkArabicText.text` (arabcina mimo Koranu).
enum SkArabicTextStyle { body, lemma, name }

/// Jediny sposob, ako vykreslit arabsky text (docs/01 1.3, 2.3.3, 3.2, D13).
///
/// Vynucuje: RTL, `locale: ar`, vahu 400, ziadny `maxLines`/overflow,
/// letter/word spacing ani dekoraciu, rovnomerny leading s vyskou aj na
/// prvom a poslednom riadku, vertikalny padding `space16`. Screen reader
/// cita `textSimple` (imlaei) s `ar` locale, nie Uthmani (D11).
///
/// V debug builde, ak rodic obmedzi vysku a text sa nezmesti, nahlasi
/// `FlutterError` (nikdy ticho neoreze).
class SkArabicText extends StatelessWidget {
  /// Text Koranu (Amiri Quran). [textSimple] = `text_simple` z content.db.
  const SkArabicText.quran(
    List<SkArabicSegment> segments, {
    required String textSimple,
    SkQuranStyle style = SkQuranStyle.card,
    this.tajwid = false,
    this.highlight = false,
    this.selectedSegment,
    this.integrityFailed = false,
    this.textAlign = TextAlign.center,
    this.semanticsOverride,
    super.key,
  }) : _segments = segments,
       _semanticsText = textSimple,
       _quranStyle = style,
       _textStyle = null;

  /// Arabcina mimo Koranu (Noto Naskh Arabic): hadis, dua, slovicka, mena.
  /// [semanticsText] default = [text].
  SkArabicText.text(
    String text, {
    SkArabicTextStyle style = SkArabicTextStyle.body,
    String? semanticsText,
    this.textAlign = TextAlign.center,
    this.semanticsOverride,
    super.key,
  }) : _segments = [SkArabicSegment(text)],
       _semanticsText = semanticsText ?? text,
       _quranStyle = null,
       _textStyle = style,
       tajwid = false,
       highlight = false,
       selectedSegment = null,
       integrityFailed = false;

  final List<SkArabicSegment> _segments;
  final String _semanticsText;
  final SkQuranStyle? _quranStyle;
  final SkArabicTextStyle? _textStyle;

  /// Ofarbit segmenty podla tajwidu (len na `surface`/`bg`).
  final bool tajwid;

  /// Aktualny vers pri recitacii: tonalne pozadie, s tajwidom okraj.
  final bool highlight;

  /// Vybrate slovo (word-by-word).
  final int? selectedSegment;

  /// Kontrola integrity zlyhala: text sa nezobrazi (docs/01 1.3 bod 10).
  final bool integrityFailed;

  /// Center na karte; `start` v citatelovi. Nikdy justify.
  final TextAlign textAlign;

  /// Ked pouzivatel vypol citanie arabciny screen readerom: label v jazyku
  /// UI (napr. "Arabic verse") bez `ar` locale (docs/01 8.2).
  final String? semanticsOverride;

  bool get isQuran => _quranStyle != null;

  SkArabicStyle _token(ProsocheTypography t) =>
      switch (_quranStyle) {
        SkQuranStyle.card => t.quranCard,
        SkQuranStyle.reader => t.quranReader,
        SkQuranStyle.word => t.quranWord,
        SkQuranStyle.bismillah => t.bismillah,
        null => null,
      } ??
      switch (_textStyle!) {
        SkArabicTextStyle.body => t.arabicBody,
        SkArabicTextStyle.lemma => t.arabicLemma,
        SkArabicTextStyle.name => t.arabicName,
      };

  /// Text vrateny pre screen reader (pre testy a integraciu).
  String get semanticsText => _semanticsText;

  @override
  Widget build(BuildContext context) {
    assert(textAlign != TextAlign.justify, 'Justify sa nepouziva (2.3.3).');
    if (integrityFailed) {
      final s = SkUiStrings.of(context);
      return SkErrorState(
        title: s.contentUnavailableTitle,
        body: s.contentUnavailableBody,
      );
    }
    final sk = context.sk;
    final colors = sk.colors;
    final type = sk.type;
    final base = _token(type)
        .toTextStyle(color: colors.arabic, scale: type.arabicScale);
    // Koran sa neclampuje (D12), ostatna arabcina ano.
    final scaler = isQuran
        ? SkTextScaling.unclampedOf(context)
        : MediaQuery.textScalerOf(context);

    final spans = [
      for (final (i, seg) in _segments.indexed)
        TextSpan(
          text: seg.text,
          style: base.copyWith(
            color: tajwid && seg.rule != null
                ? seg.rule!.colorIn(sk.tajwid)
                : null,
            backgroundColor: i == selectedSegment
                ? colors.primaryContainer
                : null,
          ),
        ),
    ];

    final text = Text.rich(
      TextSpan(children: spans, style: base),
      textDirection: TextDirection.rtl,
      textAlign: textAlign,
      textScaler: scaler,
      locale: const Locale('ar'),
      softWrap: true,
      // Nikdy ellipsis/fade/clip (docs/01 1.3).
      overflow: TextOverflow.visible,
      textHeightBehavior: const TextHeightBehavior(
        leadingDistribution: TextLeadingDistribution.even,
      ),
    );

    final label = semanticsOverride ?? _semanticsText;
    Widget block = Semantics(
      container: true,
      textDirection: semanticsOverride == null ? TextDirection.rtl : null,
      selected: highlight,
      attributedLabel: AttributedString(
        label,
        attributes: [
          if (semanticsOverride == null && label.isNotEmpty)
            LocaleStringAttribute(
              range: TextRange(start: 0, end: label.length),
              locale: const Locale('ar'),
            ),
        ],
      ),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: SkSpace.space16,
            horizontal: SkSpace.space8,
          ),
          child: _OverflowGuard(child: text),
        ),
      ),
    );

    if (highlight) {
      block = DecoratedBox(
        decoration: tajwid
            // Tajwid farby len na surface/bg: okraj namiesto pozadia.
            ? BoxDecoration(
                border: BorderDirectional(
                  start: BorderSide(color: colors.primary, width: 3),
                ),
              )
            : BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(SkRadius.sm),
              ),
        child: block,
      );
    }
    return Directionality(textDirection: TextDirection.rtl, child: block);
  }
}

/// V debug builde overi, ze text pri obmedzenej vyske nepretecie.
class _OverflowGuard extends SingleChildRenderObjectWidget {
  const _OverflowGuard({required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderOverflowGuard();
}

class _RenderOverflowGuard extends RenderProxyBox {
  @override
  void performLayout() {
    assert(() {
      final c = constraints;
      if (child != null && c.hasBoundedHeight && c.hasBoundedWidth) {
        final needed = child!.getMaxIntrinsicHeight(c.maxWidth);
        if (needed > c.maxHeight + 0.5) {
          // Nahlasi FlutterError (v testoch `takeException`), layout
          // pokracuje bez orezania.
          final error = FlutterError.fromParts([
            ErrorSummary('SkArabicText sa nezmesti do obmedzenej vysky.'),
            ErrorDescription(
              'Potrebna vyska ${needed.toStringAsFixed(1)}, dostupna '
              '${c.maxHeight.toStringAsFixed(1)}.',
            ),
            ErrorHint(
              'Arabsky text sa nikdy neoreze (docs/01 1.3): obal ho do '
              'scrollujuceho kontajnera alebo rozdel na hranici versa.',
            ),
          ]);
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: StackTrace.current,
              library: 'prosoche ui',
            ),
          );
        }
      }
      return true;
    }(), 'SkArabicText overflow guard');
    super.performLayout();
  }
}
