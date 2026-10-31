import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/quests/quests.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/cards/card_parts.dart';
import 'package:sakina/features/cards/card_providers.dart';
import 'package:sakina/features/cards/card_share.dart';
import 'package:sakina/features/cards/hadith_explanations_pack.dart';
import 'package:sakina/features/cards/types/ayah_card.dart';
import 'package:sakina/features/cards/types/day_cards.dart';
import 'package:sakina/features/cards/types/text_cards.dart';
import 'package:sakina/features/quran/quran_routes.dart';
import 'package:sakina/features/settings/problem_report_sheet.dart';
import 'package:sakina/ui/i18n/i18n.dart';
import 'package:sakina/ui/ui.dart';

/// Karta podla `card_id` (docs/02 B): nacita obsah, vyberie typ karty,
/// prida akcie (ulozit, zdielat, moznosti) a gesta (double tap, long
/// press, B0.3). Zapis `seen` riesi volajuci (feed, brana).
class CardView extends ConsumerWidget {
  const CardView({
    required this.cardId,
    required this.date,
    this.surface = CardSurface.feed,
    this.pos,
    this.total,
    this.cardsCount,
    this.onSkip,
    super.key,
  });

  final CardId cardId;

  /// Den, ku ktoremu sa zapisuju akcie (`activeSetDate`).
  final LocalDate date;
  final CardSurface surface;

  /// Pozicia v sade a N (screen reader "Card 5 of 12").
  final int? pos;
  final int? total;

  /// N pre uvodnu kartu.
  final int? cardsCount;

  /// "Skip this card" pri chybe obsahu (feed ju zapise ako `skipped`).
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final content = ref.watch(cardContentProvider(cardId));
    final failed = content.hasError && !content.isLoading;
    final missing = content is AsyncData<CardContent?> && content.value == null;
    if (failed || missing) {
      return SkCardSurface(
        error: SkErrorState(
          title: l10n.feedCardErrorTitle,
          onRetry: content.hasError
              ? () => ref.invalidate(cardContentProvider(cardId))
              : null,
          secondaryLabel: onSkip == null ? null : l10n.feedSkipCard,
          onSecondary: onSkip,
        ),
      );
    }
    final value = content.value;
    if (value == null) return const SkCardSurface(loading: true);
    return _TypedCard(
      content: value,
      date: date,
      surface: surface,
      pos: pos,
      total: total,
      cardsCount: cardsCount,
    );
  }
}

class _TypedCard extends ConsumerWidget {
  const _TypedCard({
    required this.content,
    required this.date,
    required this.surface,
    this.pos,
    this.total,
    this.cardsCount,
  });

  final CardContent content;
  final LocalDate date;
  final CardSurface surface;
  final int? pos;
  final int? total;
  final int? cardsCount;

  CardId get id => content.id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final type = id.type;
    final saved =
        type.canSave && (ref.watch(isSavedProvider(id)).value ?? false);
    final source = switch (content) {
      AyahContent(:final ayah) when ayah.translation != null =>
        ref
            .watch(
              translationSourceProvider((
                ayah.translation!.lang,
                ayah.translation!.sourceId,
              )),
            )
            .value,
      _ => null,
    };
    // Atribucia zdroja hadisu s verziou (docs/09, HadeethEnc).
    final contentSource = switch (content) {
      HadithContent(:final sourceId) =>
        ref.watch(cardSourceProvider(sourceId)).value,
      _ => null,
    };
    final sourceLine = contentSource == null
        ? null
        : sourceAttributionLine(context, contentSource);
    final ops = _CardOps(
      ref: ref,
      context: context,
      content: content,
      date: date,
      surface: surface,
      pos: pos,
      share: shareDataFor(
        context,
        content,
        // Zdielanie je re-publish: QuranEnc vyzaduje zdroj a verziu (docs/09).
        translationSource: source?.attribution,
        sourceLine: sourceLine,
      ),
      source: source,
    );
    final actions = CardActions(
      saved: saved,
      onToggleSave: type.canSave ? () => ops.toggleSave(saved: saved) : null,
      onShare: type.canShare ? ops.shareImage : null,
      onMore: type.canShare || type.canSave ? ops.openOptions : null,
    );
    final label = _semanticLabel(context);

    final card = switch (content) {
      final IntroContent c => _IntroCardView(
        content: c,
        date: date,
        cardsCount: cardsCount ?? total ?? 0,
        semanticLabel: label,
      ),
      final AyahContent c => AyahCard(
        content: c,
        translationSource: source?.name,
        actions: actions,
        semanticLabel: label,
        onReadInContext: surface.showReadInContext
            ? () => context.push(
                QuranRoutes.read(
                  c.ayah.id.surah,
                  ayahId: c.ayah.id.value,
                  mode: 'browse',
                ),
              )
            : null,
      ),
      final HadithContent c => _HadithCardView(
        content: c,
        actions: actions,
        sourceLine: sourceLine,
        semanticLabel: label,
      ),
      final DuaContent c => DuaCard(
        content: c,
        actions: actions,
        semanticLabel: label,
      ),
      final NameContent c => NameCard(
        content: c,
        actions: actions,
        semanticLabel: label,
        onOpenAyah: c.refAyah == null || !surface.showReadInContext
            ? null
            : () => context.push(
                QuranRoutes.read(
                  c.refAyah!.surah,
                  ayahId: c.refAyah!.value,
                  mode: 'browse',
                ),
              ),
      ),
      final ReflectionContent c => ReflectionCard(
        content: c,
        actions: actions,
        semanticLabel: label,
      ),
      final EventContent c => _EventCardView(
        content: c,
        surface: surface,
        semanticLabel: label,
      ),
      final KhatmContent c => KhatmCard(
        content: c,
        semanticLabel: label,
        onStartAgain: surface.showReadInContext
            ? () => context.push(
                QuranRoutes.read(1, ayahId: AyahId.first.value, mode: 'khatm'),
              )
            : null,
      ),
    };

    return GestureDetector(
      onLongPress: type.canShare || type.canSave ? ops.openOptions : null,
      child: CardDoubleTap(
        onDoubleTap: type.canSave ? () => ops.toggleSave(saved: saved) : null,
        child: Semantics(
          customSemanticsActions: {
            if (type.canShare || type.canSave)
              CustomSemanticsAction(label: l10n.cardMore): ops.openOptions,
          },
          child: card,
        ),
      ),
    );
  }

  String? _semanticLabel(BuildContext context) {
    final l10n = context.l10n;
    final what = switch (content) {
      AyahContent(:final ayah, :final surah) => l10n.cardAyahA11y(
        surah.nameTranslit,
        localizeDigits('${ayah.number}', context.formats.digits),
      ),
      HadithContent() => l10n.cardTypeHadith,
      DuaContent() => l10n.cardTypeDua,
      NameContent() => l10n.cardTypeName,
      ReflectionContent() => l10n.cardTypeReflection,
      EventContent(:final text) => text?.title ?? l10n.cardTypeEvent,
      IntroContent() || KhatmContent() => null,
    };
    final p = pos;
    final n = total;
    if (p == null || n == null) return what;
    final position = l10n.feedCardPosition(p, n);
    return what == null ? position : '$position, $what';
  }
}

/// Obsah na zdielanie a kopirovanie (docs/02 B0.7); null = typ sa
/// nezdiela (0.2).
CardShareData? shareDataFor(
  BuildContext context,
  CardContent content, {
  String? translationSource,
  String? sourceLine,
}) {
  final l10n = context.l10n;
  return switch (content) {
    AyahContent(:final ayah, :final surah) => CardShareData(
      arabic: ayah.textUthmani,
      arabicIsQuran: true,
      translation: ayah.translation?.text,
      translationLang: ayah.translation?.lang,
      reference: context.ayahReference(surah.nameTranslit, ayah.id),
      attribution: ayah.translation == null || translationSource == null
          ? null
          : l10n.cardTranslationLabel(translationSource),
    ),
    final HadithContent h => CardShareData(
      arabic: h.textAr,
      translation: h.text,
      translationLang: h.lang,
      // Hadis vzdy so zbierkou, cislom a stupnom (plan 17.11).
      reference:
          '${hadithReference(context, h)} · '
          '${l10n.cardHadithGrade(hadithGrade(context, h))}',
      attribution: h.attribution,
      source: sourceLine,
    ),
    final DuaContent d => CardShareData(
      arabic: d.textAr,
      translation: d.text,
      translationLang: d.lang,
      reference: d.sourceRef,
    ),
    final NameContent n => CardShareData(
      arabic: n.textAr,
      translation: [?n.translit, ?n.meaning].join(' · '),
      translationLang: n.lang,
      reference: l10n.cardNameIndex(
        localizeDigits(
          '${(n.id as NameCardId).nameId}',
          context.formats.digits,
        ),
      ),
    ),
    final ReflectionContent r => CardShareData(
      translation: [r.text, ?r.question].join('\n\n'),
      translationLang: r.lang,
      reference: l10n.cardReflectionAttribution,
    ),
    IntroContent() || EventContent() || KhatmContent() => null,
  };
}

/// Riadok `card:` reportu problemu: `card_id` a referencia (zbierka
/// a cislo, sura a vers), bez textu karty.
String cardReportSubject(CardContent content, {String? reference}) =>
    reference == null
    ? 'card: ${content.id}'
    : 'card: ${content.id} | $reference';

/// Akcie nad kartou: ulozenie, zdielanie, kopirovanie, zdroj, nahlasenie.
class _CardOps {
  _CardOps({
    required this.ref,
    required this.context,
    required this.content,
    required this.date,
    required this.surface,
    required this.share,
    this.pos,
    this.source,
  });

  final WidgetRef ref;
  final BuildContext context;
  final CardContent content;
  final LocalDate date;
  final CardSurface surface;
  final int? pos;
  final CardShareData? share;
  final TranslationSource? source;

  CardId get id => content.id;
  CardActionsRepository get _repo => ref.read(cardActionsRepositoryProvider);

  Future<void> _log(CardAction action) =>
      _repo.log(date, id, action, context: surface.context, pos: pos);

  Future<void> toggleSave({required bool saved}) async {
    final l10n = context.l10n;
    unawaited(HapticFeedback.lightImpact());
    if (saved) {
      await _repo.unsave(date, id, context: surface.context);
    } else {
      await _repo.save(date, id, context: surface.context);
    }
    if (!context.mounted) return;
    showSkSnackbar(
      context,
      message: saved ? l10n.cardRemoved : l10n.cardSaved,
      actionLabel: SkUiStrings.of(context).undo,
      onAction: () => unawaited(
        saved
            ? _repo.save(date, id, context: surface.context)
            : _repo.unsave(date, id, context: surface.context),
      ),
    );
  }

  String? get _text =>
      share == null ? null : buildShareText(share!, via: _via(context));

  static String _via(BuildContext context) =>
      context.l10n.cardShareVia(context.l10n.appTitle);

  Future<void> shareText() async {
    final text = _text;
    if (text == null) return;
    await ref.read(cardSharerProvider).shareText(text);
    await _log(CardAction.shared);
  }

  Future<void> shareImage() async {
    final data = share;
    final text = _text;
    if (data == null || text == null) return;
    final l10n = context.l10n;
    final png = await ref.read(cardImageRendererProvider)(
      context,
      CardShareImage(data: data, appName: l10n.appTitle),
    );
    if (!context.mounted) return;
    if (png == null) {
      // Dlhy text sa neoreze, ponukne sa zdielanie textom (B0.7).
      showSkSnackbar(
        context,
        message: l10n.cardTooLongForImage,
        actionLabel: l10n.cardSheetShareText,
        onAction: () => unawaited(shareText()),
      );
      return;
    }
    await ref.read(cardSharerProvider).shareImage(png, text: text);
    await _log(CardAction.shared);
  }

  Future<void> copy() async {
    final text = _text;
    if (text == null) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      showSkSnackbar(context, message: context.l10n.cardCopied);
    }
  }

  Future<void> openSource() async {
    final l10n = context.l10n;
    final data = share;
    unawaited(_log(CardAction.sourceOpened));
    await showSkInfoSheet<void>(
      context,
      title: l10n.cardSourceTitle,
      closeLabel: SkUiStrings.of(context).cancel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (data != null) Text(data.reference),
          if (data?.attribution case final a?) CardMeta(a),
          if (data?.source case final s?) CardMeta(s),
          if (source case final s?) ...[
            if (s.attribution.isNotEmpty) CardMeta(s.attribution),
            if (s.license.isNotEmpty)
              CardMeta(l10n.cardSourceLicense(s.license)),
          ],
        ],
      ),
    );
  }

  /// "Report a problem" (D-04): pouzivatel posle `.txt` report sam cez
  /// share sheet. Report nesie len referenciu karty (`card_id`, zbierka
  /// a cislo / sura a vers), ziadny text karty.
  Future<void> report() async {
    final shared = await showProblemReportSheet(
      context,
      subject: cardReportSubject(content, reference: share?.reference),
    );
    if (shared) await _log(CardAction.reported);
  }

  Future<void> openOptions() async {
    final l10n = context.l10n;
    final canShare = id.type.canShare && share != null;
    final picked = await showModalBottomSheet<Future<void> Function()>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canShare) ...[
              _OptionTile(Icons.copy, l10n.cardSheetCopy, copy),
              _OptionTile(
                Icons.image_outlined,
                l10n.cardSheetShareImage,
                shareImage,
              ),
              _OptionTile(Icons.notes, l10n.cardSheetShareText, shareText),
            ],
            _OptionTile(Icons.info_outline, l10n.cardSheetSource, openSource),
            _OptionTile(Icons.flag_outlined, l10n.cardSheetReport, report),
          ],
        ),
      ),
    );
    if (picked != null) await picked();
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile(this.icon, this.label, this.action);

  final IconData icon;
  final String label;
  final Future<void> Function() action;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    minTileHeight: SkSpace.minTouchTarget,
    onTap: () => Navigator.of(context).pop(action),
  );
}

class _IntroCardView extends ConsumerWidget {
  const _IntroCardView({
    required this.content,
    required this.date,
    required this.cardsCount,
    this.semanticLabel,
  });

  final IntroContent content;
  final LocalDate date;
  final int cardsCount;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests = ref.watch(questsProvider(date)).value ?? const [];
    final niyyah = ref.watch(settingOf(SettingsKeys.niyyahText)).value;
    return IntroCard(
      content: content,
      cardsCount: cardsCount,
      questSlots: [
        for (final q in quests)
          if (q.status != QuestStatus.skipped) q.slot,
      ],
      niyyah: niyyah,
      semanticLabel: semanticLabel,
    );
  }
}

class _HadithCardView extends ConsumerWidget {
  const _HadithCardView({
    required this.content,
    required this.actions,
    this.sourceLine,
    this.semanticLabel,
  });

  final HadithContent content;
  final CardActions actions;
  final String? sourceLine;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = (content.id as HadithCardId).hadithId;
    final lang = content.lang;
    // Vysvetlivka (HadithExtraRepository) len v jazyku prekladu karty;
    // bez prekladu (AR original, chybajuci jazyk) vysvetlivka nie je.
    if (lang == null) {
      return HadithCard(
        content: content,
        actions: actions,
        sourceLine: sourceLine,
        semanticLabel: semanticLabel,
      );
    }
    final status =
        ref.watch(hadithExplanationsPackStatusProvider).value ??
        HadithExplanationsPackStatus.notAvailable;
    final extra = ref.watch(hadithExtraProvider((id, lang))).value;
    final explanation = extra?.explanation;
    final hasExplanation = explanation != null && explanation.isNotEmpty;
    // Balik nie je stiahnuty (D-05): ponuknut stiahnutie (BF-01).
    final canDownload =
        !hasExplanation &&
        (status == HadithExplanationsPackStatus.notDownloaded ||
            status == HadithExplanationsPackStatus.failed);
    return HadithCard(
      content: content,
      actions: actions,
      sourceLine: sourceLine,
      semanticLabel: semanticLabel,
      downloadingExplanations:
          !hasExplanation && status == HadithExplanationsPackStatus.downloading,
      explanationsFailed:
          !hasExplanation && status == HadithExplanationsPackStatus.failed,
      onDownloadExplanations: canDownload
          ? () => unawaited(_download(context))
          : null,
      onExplanation: !hasExplanation
          ? null
          : () => unawaited(
              showSkInfoSheet<void>(
                context,
                title: context.l10n.cardHadithExplanation,
                closeLabel: SkUiStrings.of(context).cancel,
                child: Directionality(
                  textDirection: textDirectionForLanguage(extra!.lang),
                  child: Text(explanation),
                ),
              ),
            ),
    );
  }

  /// Stiahne balik a znova nacita vysvetlivky (cache `null` z doby pred
  /// stiahnutim).
  static Future<void> _download(BuildContext context) async {
    // Kontajner, nie `ref`: karta moze byt pocas stahovania uz zrusena.
    final container = ProviderScope.containerOf(context, listen: false);
    await container.read(hadithExplanationsPackProvider).download();
    container.invalidate(hadithExtraProvider);
  }
}

class _EventCardView extends ConsumerWidget {
  const _EventCardView({
    required this.content,
    required this.surface,
    this.semanticLabel,
  });

  final EventContent content;
  final CardSurface surface;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = content.id as EventCardId;
    final surahId = ref.watch(eventSurahProvider(id)).value;
    final surah = surahId == null
        ? null
        : ref.watch(surahInfoProvider(surahId)).value;
    return EventCard(
      content: content,
      surah: surah,
      semanticLabel: semanticLabel,
      // V brane CTA skryte (docs/02 B9).
      onReadSurah: surah == null || !surface.showReadInContext
          ? null
          : () => context.push(QuranRoutes.read(surah.id, mode: 'browse')),
    );
  }
}
