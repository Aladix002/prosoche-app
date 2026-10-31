import 'package:flutter/material.dart';
import 'package:prosoche/ui/components/sk_card_surface.dart';
import 'package:prosoche/ui/foundation/sk_ui_strings.dart';
import 'package:prosoche/ui/motif/sk_greek_motif.dart';
import 'package:prosoche/ui/theme/sk_context.dart';
import 'package:prosoche/ui/tokens/sk_space.dart';

/// Styl textu filozofa (docs/DESIGN.md 3.3).
enum SkQuoteStyle {
  /// Kratky citat (EB Garamond 22/32).
  quote,

  /// Dlhsi uryvok, cvicenie, vysvetlenie (19/29).
  passage,

  /// Otazka na zamyslenie (italic 22/32).
  prompt,
}

/// Text filozofa alebo karty. Nikdy neoreze (bez `maxLines`, bez
/// `overflow`), zarovnany na zaciatok riadku, bez pridanych uvodzoviek
/// (docs/DESIGN.md 3.4).
class SkQuoteText extends StatelessWidget {
  const SkQuoteText(
    this.text, {
    this.style = SkQuoteStyle.quote,
    this.color,
    super.key,
  });

  final String text;
  final SkQuoteStyle style;

  /// Default `lead`.
  final Color? color;

  /// TextStyle pre [style] v aktualnej teme.
  static TextStyle styleOf(BuildContext context, SkQuoteStyle style) {
    final t = context.sk.type;
    return switch (style) {
      SkQuoteStyle.quote => t.quote,
      SkQuoteStyle.passage => t.passage,
      SkQuoteStyle.prompt => t.prompt,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = styleOf(context, style);
    return Text(
      text,
      style: color == null ? s : s.copyWith(color: color),
      textAlign: TextAlign.start,
      softWrap: true,
    );
  }
}

/// Rozlozenie referencie.
enum SkReferenceLayout {
  /// Pod textom: autor (italic), prekladatel a rok (Inter, textTertiary).
  /// Referencia diela je v hlavicke karty.
  footer,

  /// Vsetko pod textom: dielo + locus, autor, prekladatel (zdielany
  /// obrazok, compact karta).
  full,

  /// Jeden riadok "Meditations 2.1 · Marcus Aurelius" (zoznamy).
  inline,
}

/// Referencia diela a atribucia (docs/DESIGN.md 3.5). Referencia sa nikdy
/// neskracuje.
class SkReference extends StatelessWidget {
  const SkReference({
    required this.work,
    this.locus,
    this.author,
    this.translator,
    this.year,
    this.layout = SkReferenceLayout.footer,
    super.key,
  });

  /// Napr. "Meditations".
  final String work;

  /// Napr. "2.1", "5", "1.1.7".
  final String? locus;

  /// Napr. "Marcus Aurelius".
  final String? author;

  /// Napr. "George Long".
  final String? translator;

  /// Rok prekladu, napr. 1862.
  final int? year;
  final SkReferenceLayout layout;

  /// "Meditations 2.1".
  static String format(String work, String? locus) =>
      locus == null || locus.isEmpty ? work : '$work $locus';

  /// Pre screen reader: "Meditations, 2.1" (cislo sa necita ako desatinne).
  static String semanticsFor(String work, String? locus) {
    if (locus == null || locus.isEmpty) return work;
    final parts = locus.split('.');
    return '$work, ${parts.join(' ')}';
  }

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final c = sk.colors;
    final strings = SkUiStrings.of(context);
    final translatorLine = translator == null
        ? null
        : strings.translatedBy(translator!, year);
    final ref = format(work, locus);
    switch (layout) {
      case SkReferenceLayout.inline:
        final line = [ref, ?author].join(' · ');
        return Semantics(
          label: [semanticsFor(work, locus), ?author].join(', '),
          excludeSemantics: true,
          child: Text(line, style: sk.type.attribution),
        );
      case SkReferenceLayout.footer:
      case SkReferenceLayout.full:
        final full = layout == SkReferenceLayout.full;
        return MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (full)
                Semantics(
                  label: semanticsFor(work, locus),
                  excludeSemantics: true,
                  child: Text(ref, style: sk.type.reference),
                ),
              if (author != null) Text(author!, style: sk.type.attribution),
              if (translatorLine != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    top: SkSpace.space2,
                  ),
                  child: Text(
                    translatorLine,
                    style: sk.text.bodySmall!.copyWith(color: c.textTertiary),
                  ),
                ),
            ],
          ),
        );
    }
  }
}

/// Hotova karta citatu, uryvku alebo otazky na [SkCardSurface]
/// (docs/DESIGN.md 6.2). Eyebrow je typ karty ("QUOTE"), referencia diela
/// je v hlavicke, autor a prekladatel pod textom.
class SkQuoteCard extends StatelessWidget {
  const SkQuoteCard({
    required this.eyebrow,
    required this.text,
    this.work,
    this.locus,
    this.author,
    this.translator,
    this.year,
    this.style = SkQuoteStyle.quote,
    this.variant = SkCardVariant.full,
    this.headerActions = const [],
    this.footer,
    this.semanticLabel,
    this.onTap,
    super.key,
  });

  /// Typ karty, uz lokalizovany ("Quote"); zobrazi sa verzalkami.
  final String eyebrow;
  final String text;

  /// Dielo; null = vlastny text (napr. otazka v stave draft) bez referencie.
  final String? work;
  final String? locus;
  final String? author;
  final String? translator;
  final int? year;
  final SkQuoteStyle style;
  final SkCardVariant variant;

  /// Ulozit, zdielat (48 x 48).
  final List<Widget> headerActions;

  /// Akcia pod textom.
  final Widget? footer;

  /// Napr. "Card 5 of 12, quote".
  final String? semanticLabel;

  /// Len compact (detail).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final compact = variant == SkCardVariant.compact;
    final w = work;
    final hasAttribution = author != null || translator != null;
    return SkCardSurface(
      variant: variant,
      eyebrow: eyebrow.toUpperCase(),
      eyebrowDetail: w == null ? null : SkReference.format(w, locus),
      headerActions: headerActions,
      translation: compact
          ? Text(text, maxLines: 3, overflow: TextOverflow.ellipsis)
          : SkQuoteText(text, style: style),
      footer: (!compact && hasAttribution) || footer != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!compact && hasAttribution)
                  SkReference(
                    work: w ?? '',
                    locus: locus,
                    author: author,
                    translator: translator,
                    year: year,
                  ),
                if (footer != null) ...[
                  if (!compact && hasAttribution)
                    const SizedBox(height: SkSpace.space24),
                  footer!,
                ],
              ],
            )
          : null,
      semanticLabel: semanticLabel,
      onTap: onTap,
    );
  }
}

/// Pojem: grecke slovo, prepis a vyznam (concept karta). Screen reader
/// cita prepis a vyznam, nie grecke znaky.
class SkConceptHeader extends StatelessWidget {
  const SkConceptHeader({
    required this.term,
    required this.gloss,
    this.greek,
    super.key,
  });

  /// Prepis latinkou, napr. "prosoche".
  final String term;

  /// Napr. "attention".
  final String gloss;

  /// Napr. "προσοχή".
  final String? greek;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final c = sk.colors;
    return Semantics(
      label: '$term, $gloss',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(greek ?? term, style: sk.type.term),
          const SizedBox(height: SkSpace.space4),
          Text(
            [if (greek != null) term, gloss].join(' · '),
            style: sk.type.attribution.copyWith(
              fontSize: 17,
              height: 24 / 17,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: SkSpace.space16),
          const SkCornice(width: 72),
        ],
      ),
    );
  }
}

/// Autor bez portretu: stlp ako znak, meno (Cormorant), roky a rola.
class SkAuthorHeader extends StatelessWidget {
  const SkAuthorHeader({required this.name, this.dates, this.role, super.key});

  final String name;

  /// Napr. "c. 50 – c. 135".
  final String? dates;

  /// Napr. "Teacher, former slave".
  final String? role;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final c = sk.colors;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: sk.text.headlineMedium),
        if (dates != null)
          Text(
            dates!,
            style: sk.text.bodyMedium!.copyWith(color: c.textSecondary),
          ),
        if (role != null) ...[
          const SizedBox(height: SkSpace.space4),
          Text(role!, style: sk.type.attribution),
        ],
      ],
    );
    return MergeSemantics(
      child: sk.largeText
          ? text
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SkColumn(height: 72),
                const SizedBox(width: SkSpace.space16),
                Expanded(child: text),
              ],
            ),
    );
  }
}

/// Kroky cvicenia ako cislovany zoznam (practice karta).
class SkPracticeSteps extends StatelessWidget {
  const SkPracticeSteps({required this.steps, this.duration, super.key});

  final List<String> steps;

  /// Napr. "2 min" (uz lokalizovane).
  final String? duration;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final c = sk.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (duration != null) ...[
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: c.textSecondary),
              const SizedBox(width: SkSpace.space4),
              Flexible(
                child: Text(
                  duration!,
                  style: sk.text.bodySmall!.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: SkSpace.space12),
        ],
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: SkSpace.space12),
            child: MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${i + 1}.',
                      style: sk.type.passage.copyWith(color: c.accentText),
                    ),
                  ),
                  Expanded(child: Text(steps[i], style: sk.type.passage)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
