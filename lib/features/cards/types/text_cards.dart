import 'package:flutter/material.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/features/cards/card_parts.dart';
import 'package:prosoche/features/cards/card_providers.dart';
import 'package:prosoche/ui/ui.dart';

// Karty obsahu content.db v1 (kontrakt kap. 6). Texty filozofov su doslovne
// z content.db, appka ich nemeni. Skladaju sa z existujucich `Sk*`
// komponentov (SkCardSurface); po zluceni s D-01 sa daju preskinovat na
// SkQuoteCard / SkConceptHeader / SkAuthorHeader / SkPracticeSteps
// (docs/DESIGN.md 6.2, mapa typov tam).

/// Riadok atribucie zdroja (docs/09): `source.attribution` z content.db,
/// doplnene o verziu, ak ju atribucia neobsahuje.
String sourceAttributionLine(BuildContext context, CardSourceInfo s) {
  final l10n = context.l10n;
  final attribution = s.attribution.trim().isEmpty ? s.name : s.attribution;
  return attribution.contains(s.version)
      ? l10n.cardSourceLine(attribution)
      : l10n.cardSourceLineVersion(attribution, s.version);
}

/// "Translated by George Long (1862)".
String translatedBy(BuildContext context, Translation t) {
  final l10n = context.l10n;
  final year = t.year;
  return year == null
      ? l10n.cardTranslatedBy(t.translator)
      : l10n.cardTranslatedByYear(t.translator, year);
}

/// Eyebrow typu karty ("QUOTE", "PASSAGE", ...), verzalkami.
String cardTypeLabel(BuildContext context, CardContent content) {
  final l10n = context.l10n;
  return switch (content) {
    QuoteContent(isPassage: true) => l10n.cardTypePassage,
    QuoteContent() => l10n.cardTypeQuote,
    PracticeContent() => l10n.cardTypePractice,
    PromptContent() => l10n.cardTypePrompt,
    ConceptContent() => l10n.cardTypeConcept,
    AuthorContent() => l10n.cardTypeAuthor,
    IntroContent() => '',
  }.toUpperCase();
}

/// Odkaz pod textom karty ("Read in context", "Open practice").
class CardLink extends StatelessWidget {
  const CardLink({
    required this.label,
    required this.onPressed,
    this.icon = Icons.menu_book_outlined,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: TextButton.styleFrom(
        minimumSize: const Size(SkSpace.minTouchTarget, SkSpace.minTouchTarget),
      ),
    ),
  );
}

/// Citat alebo uryvok: text doslovne z content.db, referencia
/// ("Meditations 2.1"), autor a prekladatel ("Translated by George Long")
/// cez `SkQuoteCard` (D-01).
class QuoteCard extends StatelessWidget {
  const QuoteCard({
    required this.content,
    this.actions = CardActions.none,
    this.onReadInContext,
    this.semanticLabel,
    super.key,
  });

  final QuoteContent content;
  final CardActions actions;

  /// "Read in context" (Library na zdrojovej sekcii); null = bez odkazu.
  final VoidCallback? onReadInContext;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = content;
    final t = q.translation;
    return SkQuoteCard(
      semanticLabel: semanticLabel,
      eyebrow: cardTypeLabel(context, q),
      text: q.text,
      work: q.work,
      locus: q.ref,
      author: q.author.isEmpty ? null : q.author,
      translator: t?.translator,
      year: t?.year,
      style: q.isPassage ? SkQuoteStyle.passage : SkQuoteStyle.quote,
      headerActions: actions.build(context),
      footer: onReadInContext == null
          ? null
          : CardLink(
              label: l10n.cardReadInContext,
              onPressed: onReadInContext!,
            ),
    );
  }
}

/// Cvicenie: nadpis, popis a postup po odstavcoch (vlastny text).
class PracticeCard extends StatelessWidget {
  const PracticeCard({
    required this.content,
    this.actions = CardActions.none,
    this.onOpen,
    this.onReadInContext,
    this.semanticLabel,
    super.key,
  });

  final PracticeContent content;
  final CardActions actions;

  /// "Open in Practice".
  final VoidCallback? onOpen;
  final VoidCallback? onReadInContext;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = content;
    return SkCardSurface(
      semanticLabel: semanticLabel,
      eyebrow: cardTypeLabel(context, p),
      eyebrowDetail: p.title,
      headerActions: actions.build(context),
      lead: p.subtitle == null ? null : _Subtitle(p.subtitle!),
      translation: SkPracticeSteps(steps: p.steps),
      attribution: p.reference == null
          ? null
          : l10n.cardRelatedReference(p.reference!),
      footer: _links(context, onOpen, onReadInContext),
    );
  }
}

/// Otazka na zamyslenie.
class PromptCard extends StatelessWidget {
  const PromptCard({
    required this.content,
    this.actions = CardActions.none,
    this.onReflect,
    this.onReadInContext,
    this.semanticLabel,
    super.key,
  });

  final PromptContent content;
  final CardActions actions;

  /// Zapis odpovede do lokalneho dennika.
  final VoidCallback? onReflect;
  final VoidCallback? onReadInContext;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = content;
    return SkCardSurface(
      semanticLabel: semanticLabel,
      eyebrow: cardTypeLabel(context, p),
      eyebrowDetail: p.reference,
      headerActions: actions.build(context),
      translation: SkQuoteText(p.text, style: SkQuoteStyle.prompt),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onReflect != null)
            CardLink(
              label: l10n.cardWriteInJournal,
              icon: Icons.edit_note,
              onPressed: onReflect!,
            ),
          ?_links(context, null, onReadInContext),
        ],
      ),
    );
  }
}

/// `card.subtitle` pojmu ("prosoche - attention") -> (termin, vyznam).
(String, String) conceptTerm(String title, String? subtitle) {
  final s = subtitle;
  if (s == null) return (title.toLowerCase(), '');
  final i = s.indexOf(' - ');
  return i < 0 ? (s, '') : (s.substring(0, i), s.substring(i + 3));
}

/// Pojem: `SkConceptHeader` (termin a vyznam), vysvetlenie.
class ConceptCard extends StatelessWidget {
  const ConceptCard({
    required this.content,
    this.actions = CardActions.none,
    this.onReadInContext,
    this.semanticLabel,
    super.key,
  });

  final ConceptContent content;
  final CardActions actions;
  final VoidCallback? onReadInContext;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = content;
    final (term, gloss) = conceptTerm(c.title, c.subtitle);
    return SkCardSurface(
      semanticLabel: semanticLabel,
      eyebrow: cardTypeLabel(context, c),
      // Nadpis sa neopakuje, ked je rovnaky ako termin (napr. "Amor fati"
      // a "amor fati"), I-01.
      eyebrowDetail: c.title.toLowerCase() == term.toLowerCase()
          ? null
          : c.title,
      headerActions: actions.build(context),
      lead: SkConceptHeader(term: term, gloss: gloss),
      translation: _Paragraphs(
        text: c.text,
        style: SkQuoteText.styleOf(context, SkQuoteStyle.passage),
      ),
      attribution: c.reference == null
          ? null
          : l10n.cardRelatedReference(c.reference!),
      footer: _links(context, null, onReadInContext),
    );
  }
}

/// Uvod k autorovi (bez portretu): `SkAuthorHeader`, text.
class AuthorCard extends StatelessWidget {
  const AuthorCard({
    required this.content,
    this.actions = CardActions.none,
    this.onReadWork,
    this.semanticLabel,
    super.key,
  });

  final AuthorContent content;
  final CardActions actions;

  /// "Read Meditations" (Library).
  final VoidCallback? onReadWork;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final a = content;
    return SkCardSurface(
      semanticLabel: semanticLabel,
      eyebrow: cardTypeLabel(context, a),
      headerActions: actions.build(context),
      lead: SkAuthorHeader(name: a.name, dates: a.lifespan),
      translation: _Paragraphs(
        text: a.text,
        style: SkQuoteText.styleOf(context, SkQuoteStyle.passage),
      ),
      footer: onReadWork == null || a.firstWorkTitle == null
          ? null
          : CardLink(
              label: l10n.cardReadWork(a.firstWorkTitle!),
              onPressed: onReadWork!,
            ),
    );
  }
}

/// Postup cvicenia: odstavce ako cislovane kroky (`SkPracticeSteps`).
class PracticeSteps extends StatelessWidget {
  const PracticeSteps({required this.steps, super.key});

  final List<String> steps;

  @override
  Widget build(BuildContext context) => SkPracticeSteps(steps: steps);
}

class _Subtitle extends StatelessWidget {
  const _Subtitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.sk.text.titleMedium!.copyWith(
      color: context.sk.colors.textSecondary,
    ),
  );
}

/// Odstavce textu (oddelene `\n\n`), nikdy neorezane.
class _Paragraphs extends StatelessWidget {
  const _Paragraphs({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final parts = paragraphs(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, p) in parts.indexed) ...[
          if (i > 0) const SizedBox(height: SkSpace.space12),
          Text(p, style: style),
        ],
      ],
    );
  }
}

Widget? _links(
  BuildContext context,
  VoidCallback? onOpen,
  VoidCallback? onReadInContext,
) {
  final l10n = context.l10n;
  final links = [
    if (onOpen != null)
      CardLink(
        label: l10n.cardOpenPractice,
        icon: Icons.self_improvement,
        onPressed: onOpen,
      ),
    if (onReadInContext != null)
      CardLink(label: l10n.cardReadInContext, onPressed: onReadInContext),
  ];
  if (links.isEmpty) return null;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: links,
  );
}
