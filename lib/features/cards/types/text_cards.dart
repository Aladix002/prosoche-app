import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/features/cards/card_parts.dart';
import 'package:prosoche/features/cards/card_providers.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

/// UI je arabske: arabsky original zbierky a stupna (BF-02).
bool _arabicUi(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ar';

/// Hodnota `hadith.collection` pre hadis v Bukhari aj Muslim (HadeethEnc):
/// "muttafaq alayh" po arabsky.
const String hadithMuttafaqAlayh =
    // prosoche-lint: ignore prosoche_arabic_text_outside_sk_arabic_text
    '\u0645\u062A\u0641\u0642 \u0639\u0644\u064A\u0647';

/// Retazec obsahuje arabske pismo (blok U+0600-U+06FF).
bool _hasArabicScript(String s) =>
    s.runes.any((r) => r >= 0x0600 && r <= 0x06FF);

/// Zbierka hadisu v jazyku UI (BF-02). `hadith.collection` je arabsky
/// takhrij z HadeethEnc ("muttafaq alayh", "rawahu Muslim"); mimo AR UI
/// sa zobrazi lokalizovany stitok (ARB) alebo takhrij z prekladu
/// (`hadith_text.attribution`, doslovne), arabcina len ked preklad nie je.
String hadithCollection(BuildContext context, HadithContent h) {
  final collection = h.collection.trim();
  if (_arabicUi(context)) return collection;
  if (collection == hadithMuttafaqAlayh) {
    return context.l10n.cardHadithAgreedUpon;
  }
  if (!_hasArabicScript(collection)) return collection;
  final localized = h.attribution?.trim();
  return localized == null || localized.isEmpty ? collection : localized;
}

/// Referencia hadisu "{zbierka} {cislo}" (docs/02 B0.4).
String hadithReference(BuildContext context, HadithContent h) {
  final collection = hadithCollection(context, h);
  return h.number == null
      ? collection
      : context.l10n.cardHadithReference(collection, h.number!);
}

/// Riadok atribucie zdroja (docs/09: HadeethEnc vyzaduje nazov
/// "HadeethEnc.com" a cislo verzie): `source.attribution` z content.db,
/// doplnene o verziu, ak ju atribucia neobsahuje.
String sourceAttributionLine(BuildContext context, CardSourceInfo s) {
  final l10n = context.l10n;
  final attribution = s.attribution.trim().isEmpty ? s.name : s.attribution;
  return attribution.contains(s.version)
      ? l10n.cardSourceLine(attribution)
      : l10n.cardSourceLineVersion(attribution, s.version);
}

/// Stupen hadisu (BF-02): v AR UI arabsky original `hadith.grade_ar`
/// (doslovne), inak lokalizovany stitok podla enumu `hadith.grade` (ARB).
String hadithGrade(BuildContext context, HadithContent h) {
  final ar = h.gradeAr?.trim();
  if (_arabicUi(context) && ar != null && ar.isNotEmpty) return ar;
  return switch (h.grade) {
    'sahih' || 'hasan' || 'daif' => context.l10n.cardHadithGradeLabel(h.grade),
    _ => h.grade,
  };
}

/// B5 hadis: zbierka, cislo a stupen su vzdy viditelne (plan 17.11).
/// Vysvetlivka len ked je dostupna ([onExplanation] != null); inak, ked
/// balik nie je stiahnuty, "Download explanations" ([onDownloadExplanations],
/// pocas stahovania [downloadingExplanations]). Po zlyhani stahovania
/// ([explanationsFailed]) inline hlaska a "Retry" (BF-02).
class HadithCard extends StatelessWidget {
  const HadithCard({
    required this.content,
    this.actions = CardActions.none,
    this.onExplanation,
    this.onDownloadExplanations,
    this.downloadingExplanations = false,
    this.explanationsFailed = false,
    this.sourceLine,
    this.semanticLabel,
    super.key,
  });

  final HadithContent content;

  /// Atribucia zdroja ([sourceAttributionLine]); null = este sa nacitava
  /// alebo zdroj chyba.
  final String? sourceLine;
  final CardActions actions;
  final VoidCallback? onExplanation;
  final VoidCallback? onDownloadExplanations;
  final bool downloadingExplanations;

  /// Posledne stiahnutie balika vysvetliviek zlyhalo; [onDownloadExplanations]
  /// je potom "Retry".
  final bool explanationsFailed;
  final String? semanticLabel;

  Widget? _footer(BuildContext context) {
    final l10n = context.l10n;
    final Widget button;
    if (onExplanation != null) {
      button = SkButton.tertiary(
        label: l10n.cardHadithExplanation,
        onPressed: onExplanation,
      );
    } else if (explanationsFailed &&
        onDownloadExplanations != null &&
        !downloadingExplanations) {
      final sk = context.sk;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.cardHadithExplanationsFailed,
              style: sk.text.bodySmall!.copyWith(
                color: sk.colors.textSecondary,
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SkButton.tertiary(
              label: l10n.cardHadithExplanationsRetry,
              icon: Icons.refresh,
              onPressed: onDownloadExplanations,
            ),
          ),
        ],
      );
    } else if (onDownloadExplanations != null || downloadingExplanations) {
      button = SkButton.tertiary(
        label: l10n.cardHadithDownloadExplanations,
        icon: Icons.download_outlined,
        loading: downloadingExplanations,
        onPressed: downloadingExplanations ? null : onDownloadExplanations,
      );
    } else {
      return null;
    }
    return Align(alignment: AlignmentDirectional.centerStart, child: button);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final h = content;
    final title = h.title;
    final reference = hadithReference(context, h);
    return SkCardSurface(
      semanticLabel: semanticLabel,
      // Referencia zhodna s atribuciou dole by bola dvakrat.
      eyebrow: l10n.cardTypeHadith,
      eyebrowDetail: reference == h.attribution?.trim() ? null : reference,
      headerActions: actions.build(context),
      arabic: SkArabicText.text(h.textAr),
      translation: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null && title.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: SkSpace.space8),
              child: Text(title, style: context.sk.text.titleMedium),
            ),
          CardTranslation(text: h.text, lang: h.lang, arabicOnly: h.arabicOnly),
          CardMeta(l10n.cardHadithGrade(hadithGrade(context, h))),
          if (sourceLine case final line?) CardSourceNote(line),
        ],
      ),
      attribution: h.attribution,
      footer: _footer(context),
    );
  }
}

/// B6 dua: kategoria, opakovanie, translit (ak je), preklad, zdroj a
/// lokalne pocitadlo opakovani (neuklada sa).
class DuaCard extends StatefulWidget {
  const DuaCard({
    required this.content,
    this.actions = CardActions.none,
    this.semanticLabel,
    super.key,
  });

  final DuaContent content;
  final CardActions actions;
  final String? semanticLabel;

  @override
  State<DuaCard> createState() => _DuaCardState();
}

class _DuaCardState extends State<DuaCard> {
  int _count = 0;

  void _increment() {
    final total = widget.content.repeatCount;
    unawaitedHaptic();
    setState(() => _count = _count >= total ? 0 : _count + 1);
  }

  static void unawaitedHaptic() {
    HapticFeedback.selectionClick().ignore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final d = widget.content;
    final title = d.title;
    final repeat = d.repeatCount > 1;
    return SkCardSurface(
      semanticLabel: widget.semanticLabel,
      eyebrow: l10n.cardTypeDua,
      eyebrowDetail: title == null || title.isEmpty ? null : title,
      headerActions: [
        if (repeat)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: SkSpace.space8,
            ),
            child: SkTag(label: l10n.cardDuaRepeat(d.repeatCount)),
          ),
        ...widget.actions.build(context),
      ],
      arabic: SkArabicText.text(d.textAr),
      translation: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (d.translit case final t? when t.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: SkSpace.space8),
              child: Text(
                t,
                style: sk.text.bodyLarge!.copyWith(
                  color: sk.colors.textSecondary,
                ),
              ),
            ),
          CardTranslation(text: d.text, lang: d.lang, arabicOnly: d.arabicOnly),
          CardMeta(l10n.cardSourceRef(d.sourceRef)),
        ],
      ),
      footer: repeat
          ? Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                hint: l10n.cardDuaCounterHint,
                child: SkButton.outlined(
                  label: l10n.cardDuaCounter(_count, d.repeatCount),
                  onPressed: _increment,
                ),
              ),
            )
          : null,
    );
  }
}

/// B7 meno Allaha: arabsky text, translit, vyznam, kratka poznamka
/// a odkaz na vers (ak je v content.db).
class NameCard extends StatelessWidget {
  const NameCard({
    required this.content,
    this.actions = CardActions.none,
    this.onOpenAyah,
    this.semanticLabel,
    super.key,
  });

  final NameContent content;
  final CardActions actions;
  final VoidCallback? onOpenAyah;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final n = content;
    final nameId = (n.id as NameCardId).nameId;
    final ref = n.refAyah;
    return SkCardSurface(
      semanticLabel: semanticLabel,
      eyebrow: l10n.cardTypeName,
      eyebrowDetail: l10n.cardNameIndex(
        localizeDigits('$nameId', context.formats.digits),
      ),
      headerActions: actions.build(context),
      arabic: SkArabicText.text(n.textAr, style: SkArabicTextStyle.name),
      translation: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (n.translit case final t? when t.isNotEmpty)
            Text(t, textAlign: TextAlign.center, style: sk.text.titleMedium),
          const SizedBox(height: SkSpace.space8),
          CardTranslation(
            text: n.meaning,
            lang: n.lang,
            arabicOnly: n.arabicOnly,
          ),
          if (n.shortNote case final note? when note.isNotEmpty) CardMeta(note),
        ],
      ),
      footer: ref == null
          ? null
          : Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: SkSpace.space8,
              children: [
                Text(
                  l10n.cardNameMentionedIn(
                    context.formats.ayahRef(ref.surah, ref.ayah),
                  ),
                  style: sk.text.bodyMedium,
                ),
                if (onOpenAyah != null)
                  SkButton.tertiary(
                    label: l10n.cardOpen,
                    onPressed: onOpenAyah,
                  ),
              ],
            ),
    );
  }
}

/// B8 zamyslenie (iba recenzovane, otazka je sucast textu alebo
/// samostatne pole).
class ReflectionCard extends StatelessWidget {
  const ReflectionCard({
    required this.content,
    this.actions = CardActions.none,
    this.semanticLabel,
    super.key,
  });

  final ReflectionContent content;
  final CardActions actions;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final r = content;
    return SkCardSurface(
      semanticLabel: semanticLabel,
      eyebrow: l10n.cardTypeReflection,
      headerActions: actions.build(context),
      translation: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CardTranslation(
            text: r.text,
            lang: r.lang,
            style: sk.type.reflection,
          ),
          if (r.question case final q? when q.isNotEmpty) ...[
            const SizedBox(height: SkSpace.space16),
            Directionality(
              textDirection: textDirectionForLanguage(r.lang),
              child: Text(q, style: sk.text.titleMedium),
            ),
          ],
        ],
      ),
      attribution: l10n.cardReflectionAttribution,
    );
  }
}
