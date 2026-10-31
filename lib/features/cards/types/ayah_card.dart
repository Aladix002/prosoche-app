import 'package:flutter/material.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/features/cards/card_parts.dart';
import 'package:prosoche/features/cards/translator_notes.dart';
import 'package:prosoche/ui/ui.dart';

/// B2 vers (a B11 volne citanie): Uthmani text, referencia, preklad
/// vyznamu so zdrojom; znacky `[n]` poznamok prekladatela su tapnutelne.
/// Bismillah sa nepridava (karta ukazuje len text versa, docs/02 B2).
class AyahCard extends StatelessWidget {
  const AyahCard({
    required this.content,
    this.translationSource,
    this.actions = CardActions.none,
    this.onReadInContext,
    this.freeReading = false,
    this.semanticLabel,
    super.key,
  });

  final AyahContent content;

  /// Nazov zdroja prekladu (`source.name`); null = este nenacitany.
  final String? translationSource;
  final CardActions actions;

  /// "Read in context" (nie v brane).
  final VoidCallback? onReadInContext;

  /// B11: hlavicka "FREE READING".
  final bool freeReading;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ayah = content.ayah;
    final translation = ayah.translation;
    final reference = context.ayahReference(
      content.surah.nameTranslit,
      ayah.id,
    );
    return SkCardSurface(
      semanticLabel: semanticLabel,
      eyebrow: freeReading ? l10n.cardTypeFreeReading : l10n.cardTypeVerse,
      eyebrowDetail: reference,
      headerActions: actions.build(context),
      arabic: SkArabicText.quran(
        [SkArabicSegment(ayahTextWithEnd(ayah.textUthmani, ayah.number))],
        // TODO(D-02): `text_simple` pre screen reader, AyahView ho nema.
        textSimple: ayah.textUthmani,
      ),
      translation: CardTranslation(
        text: translation?.text,
        lang: translation?.lang,
        isFallback: translation?.isFallback ?? false,
        arabicOnly: content.arabicOnly,
        // Znacky poznamok prekladatela QuranEnc ako horny index (BF-01).
        textSpan: translation == null
            ? null
            : translationWithNotes(
                context,
                text: translation.text,
                footnotes: translation.footnotes,
                lang: translation.lang,
              ),
      ),
      attribution: translation == null || translationSource == null
          ? null
          : l10n.cardTranslationLabel(translationSource!),
      footer: onReadInContext == null
          ? null
          : Align(
              alignment: AlignmentDirectional.centerStart,
              child: SkButton.tertiary(
                label: l10n.cardReadInContext,
                icon: Icons.menu_book_outlined,
                onPressed: onReadInContext,
              ),
            ),
    );
  }
}
