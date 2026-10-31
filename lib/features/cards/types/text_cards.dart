import 'package:flutter/material.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/features/cards/card_parts.dart';
import 'package:prosoche/features/cards/card_providers.dart';
import 'package:prosoche/ui/ui.dart';

/// Riadok atribucie zdroja (docs/09): `source.attribution` z content.db,
/// doplnene o verziu, ak ju atribucia neobsahuje.
String sourceAttributionLine(BuildContext context, CardSourceInfo s) {
  final l10n = context.l10n;
  final attribution = s.attribution.trim().isEmpty ? s.name : s.attribution;
  return attribution.contains(s.version)
      ? l10n.cardSourceLine(attribution)
      : l10n.cardSourceLineVersion(attribution, s.version);
}

/// Kratky citat: text doslovne z content.db, autor a dielo s referenciou
/// (napr. "Meditations 2.1"). Dalsie typy kariet (uryvok, cvicenie,
/// otazka, pojem, autor) doplni F-01.
class QuoteCard extends StatelessWidget {
  const QuoteCard({
    required this.content,
    this.actions = CardActions.none,
    this.sourceLine,
    this.semanticLabel,
    super.key,
  });

  final QuoteContent content;
  final CardActions actions;

  /// Atribucia zdroja (`source.attribution`), ak je v content.db.
  final String? sourceLine;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = content;
    return SkCardSurface(
      semanticLabel: semanticLabel,
      eyebrow: l10n.cardTypeQuote,
      eyebrowDetail: q.reference,
      headerActions: actions.build(context),
      // D-01: citat v EB Garamond 22/32 (`SkQuoteText`), autor pod nim,
      // zdroj ako posledny riadok (docs/DESIGN.md 3.4, 3.5).
      translation: SkQuoteText(q.text),
      attribution: l10n.cardQuoteAttribution(q.author, q.reference),
      footer: sourceLine == null ? null : CardSourceNote(sourceLine!),
    );
  }
}
