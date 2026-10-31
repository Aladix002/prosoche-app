import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/features/cards/translator_notes.dart';
import 'package:sakina/features/quran/quran_format.dart';
import 'package:sakina/ui/i18n/i18n.dart';
import 'package:sakina/ui/ui.dart';

/// Vers v citatelovi (docs/02 A5.2): arabsky text (bajtovo
/// `ayah.text_uthmani`) s koncovym znakom, preklad vyznamu, referencia,
/// sajda a akcie. Nic sa neoreze ani neprekryje (docs/01 1.3).
class AyahTile extends ConsumerStatefulWidget {
  const AyahTile({
    required this.ayah,
    required this.surahName,
    required this.contentLang,
    required this.showTranslation,
    required this.onActions,
    this.onToggleSaved,
    super.key,
  });

  final AyahView ayah;
  final String surahName;

  /// Jazyk obsahu; `ar` = Koran bez prekladu.
  final String contentLang;
  final bool showTranslation;
  final VoidCallback onActions;
  final ValueChanged<bool>? onToggleSaved;

  @override
  ConsumerState<AyahTile> createState() => _AyahTileState();
}

class _AyahTileState extends ConsumerState<AyahTile> {
  bool _notes = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final ayah = widget.ayah;
    final translation = ayah.translation;
    final saved =
        ref.watch(isSavedProvider(AyahCardId(ayah.id))).value ?? false;
    final caption = sk.text.bodySmall!.copyWith(color: sk.colors.textSecondary);

    return Semantics(
      container: true,
      label: context.ayahSemantics(widget.surahName, ayah.id),
      child: InkWell(
        onLongPress: widget.onActions,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            SkSpace.space16,
            SkSpace.space8,
            SkSpace.space16,
            SkSpace.space8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SkArabicText.quran(
                [
                  SkArabicSegment(ayah.textUthmani),
                  SkArabicSegment(verseEndMarker(ayah.number)),
                ],
                // TODO(D-02): `text_simple` pre screen reader (docs/01 8.2);
                // AyahView ho zatial nema, cita sa Uthmani.
                textSimple: ayah.textUthmani,
                style: SkQuranStyle.reader,
                textAlign: TextAlign.start,
              ),
              if (widget.showTranslation && widget.contentLang != 'ar')
                if (translation != null)
                  _Translation(
                    translation: translation,
                    showNotes: _notes,
                    onToggleNotes: () => setState(() => _notes = !_notes),
                  )
                else
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      top: SkSpace.space4,
                    ),
                    child: Text(l10n.quranTranslationMissing, style: caption),
                  ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.ayahReference(widget.surahName, ayah.id),
                      style: caption,
                    ),
                  ),
                  if (ayah.sajda != null)
                    Tooltip(
                      message: l10n.quranSajda,
                      child: Semantics(
                        label: l10n.quranSajda,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.all(
                            SkSpace.space12,
                          ),
                          child: Icon(
                            Icons.south,
                            size: 20,
                            color: sk.colors.accentText,
                          ),
                        ),
                      ),
                    ),
                  SkIconButton(
                    icon: Icons.bookmark_border,
                    selectedIcon: Icons.bookmark,
                    selected: saved,
                    tooltip: saved ? l10n.quranRemoveSaved : l10n.quranSave,
                    onPressed: widget.onToggleSaved == null
                        ? null
                        : () => widget.onToggleSaved!(!saved),
                  ),
                  SkIconButton(
                    icon: Icons.more_horiz,
                    tooltip: l10n.quranVerseActions,
                    onPressed: widget.onActions,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Translation extends StatelessWidget {
  const _Translation({
    required this.translation,
    required this.showNotes,
    required this.onToggleNotes,
  });

  final TranslationText translation;
  final bool showNotes;
  final VoidCallback onToggleNotes;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final lang = translation.lang;
    final style = translationStyle(sk.type.translationReader, lang);
    final footnotes = translation.footnotes;
    // Znacky `[n]` ako horny index s tapom na poznamku, rovnako ako karta
    // (BF-01, BF-02). Text prekladu sa nemeni (docs/09 2.2).
    final span = translationWithNotes(
      context,
      text: translation.text,
      footnotes: footnotes,
      lang: lang,
      style: style,
    );
    final notes = parseTranslatorNotes(footnotes);
    // Rozbalovacka len ked niektora poznamka nema znacku v texte (inak by
    // boli poznamky dvakrat); poznamky sa nemazu (QuranEnc).
    final unreferenced =
        footnotes != null &&
        footnotes.trim().isNotEmpty &&
        (span == null ||
            referencedTranslatorNotes(translation.text, notes).length <
                notes.length);
    final caption = sk.text.bodySmall!.copyWith(color: sk.colors.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (translation.isFallback)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Semantics(
              label: l10n.quranTranslationFallbackLabel,
              child: ExcludeSemantics(
                child: SkTag(label: l10n.quranTranslationFallbackTag),
              ),
            ),
          ),
        // Preklad v smere a fonte svojho jazyka (docs/04 5.2 bod 2).
        Directionality(
          textDirection: textDirectionForLanguage(lang),
          child: span == null
              ? Text(
                  translation.text,
                  style: style,
                  locale: Locale(lang),
                  textAlign: TextAlign.start,
                )
              : Text.rich(
                  span,
                  style: style,
                  locale: Locale(lang),
                  textAlign: TextAlign.start,
                ),
        ),
        // Poznamky prekladatela sa nemazu (docs/09 2.2, QuranEnc).
        if (unreferenced) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: onToggleNotes,
              child: Text(
                showNotes ? l10n.quranFootnotesHide : l10n.quranFootnotesShow,
              ),
            ),
          ),
          if (showNotes)
            Directionality(
              textDirection: textDirectionForLanguage(lang),
              child: Text(
                footnotes,
                style: translationStyle(caption, lang),
                locale: Locale(lang),
              ),
            ),
        ],
      ],
    );
  }
}

/// Styl prekladu: Literata pre latinku, inak font jazyka (Nastaliq, Bengali)
/// s jeho riadkovanim (docs/01 2.3.1).
TextStyle translationStyle(TextStyle base, String lang) => switch (lang) {
  'ur' || 'bn' || 'ar' => applyLocaleFont(base, Locale(lang)),
  _ => base,
};
