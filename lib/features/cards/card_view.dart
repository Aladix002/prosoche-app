import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/quests.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/cards/card_parts.dart';
import 'package:prosoche/features/cards/card_share.dart';
import 'package:prosoche/features/cards/types/day_cards.dart';
import 'package:prosoche/features/cards/types/text_cards.dart';
import 'package:prosoche/features/library/library_routes.dart';
import 'package:prosoche/features/practice/practice_routes.dart';
import 'package:prosoche/features/practice/widgets/journal_prompt_sheet.dart';
import 'package:prosoche/features/settings/problem_report_sheet.dart';
import 'package:prosoche/ui/ui.dart';

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
    final ops = _CardOps(
      ref: ref,
      context: context,
      content: content,
      date: date,
      surface: surface,
      pos: pos,
      share: shareDataFor(context, content),
    );
    final actions = CardActions(
      saved: saved,
      onToggleSave: type.canSave ? () => ops.toggleSave(saved: saved) : null,
      onShare: type.canShare ? ops.shareImage : null,
      onMore: type.canShare || type.canSave ? ops.openOptions : null,
    );
    final label = _semanticLabel(context);
    final links = surface.showReadInContext;
    final inContext = links && content.sectionKey != null
        ? ops.readInContext
        : null;

    final card = switch (content) {
      final IntroContent c => _IntroCardView(
        content: c,
        date: date,
        cardsCount: cardsCount ?? total ?? 0,
        semanticLabel: label,
      ),
      final QuoteContent c => QuoteCard(
        content: c,
        actions: actions,
        onReadInContext: inContext,
        semanticLabel: label,
      ),
      final PracticeContent c => PracticeCard(
        content: c,
        actions: actions,
        onOpen: links ? ops.openPractice : null,
        onReadInContext: inContext,
        semanticLabel: label,
      ),
      final PromptContent c => PromptCard(
        content: c,
        actions: actions,
        onReflect: links ? ops.reflect : null,
        onReadInContext: inContext,
        semanticLabel: label,
      ),
      final ConceptContent c => ConceptCard(
        content: c,
        actions: actions,
        onReadInContext: inContext,
        semanticLabel: label,
      ),
      final AuthorContent c => AuthorCard(
        content: c,
        actions: actions,
        onReadWork: links && c.firstWorkId != null ? ops.readWork : null,
        semanticLabel: label,
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
      QuoteContent(:final author) => l10n.cardQuoteA11y(author),
      IntroContent() => null,
      final c => cardTypeLabel(context, c).toLowerCase(),
    };
    final p = pos;
    final n = total;
    if (p == null || n == null) return what;
    final position = l10n.feedCardPosition(p, n);
    return what == null ? position : '$position, $what';
  }
}

/// Obsah na zdielanie a kopirovanie (docs/02 B0.7): cely text, referencia
/// a prekladatel; null = typ sa nezdiela (0.2). Nikdy nie "Project
/// Gutenberg" (kontrakt kap. 5): atribucia je len prekladatel a rok.
CardShareData? shareDataFor(BuildContext context, CardContent content) =>
    switch (content) {
      final QuoteContent q => CardShareData(
        text: q.text,
        textLang: 'en',
        reference: q.reference,
        attribution: q.author,
        source: q.translation == null
            ? null
            : translatedBy(context, q.translation!),
      ),
      final PracticeContent p => CardShareData(
        text: p.text,
        textLang: 'en',
        reference: p.title,
        attribution: p.reference,
      ),
      final PromptContent p => CardShareData(
        text: p.text,
        textLang: 'en',
        reference: cardTypeLabel(context, p),
        attribution: p.reference,
      ),
      final ConceptContent c => CardShareData(
        text: c.text,
        textLang: 'en',
        reference: c.subtitle == null ? c.title : '${c.title} (${c.subtitle})',
        attribution: c.reference,
      ),
      final AuthorContent a => CardShareData(
        text: a.text,
        textLang: 'en',
        reference: a.lifespan == null ? a.name : '${a.name}, ${a.lifespan}',
      ),
      IntroContent() => null,
    };

/// Riadok `card:` reportu problemu: `card_id` a referencia (dielo
/// a sekcia), bez textu karty.
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
  });

  final WidgetRef ref;
  final BuildContext context;
  final CardContent content;
  final LocalDate date;
  final CardSurface surface;
  final int? pos;
  final CardShareData? share;

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
        ],
      ),
    );
  }

  /// "Read in context": citacka Library na zdrojovej sekcii karty
  /// (citat zvyrazneny).
  Future<void> readInContext() async {
    final key = content.sectionKey;
    if (key == null) return;
    unawaited(_log(CardAction.sourceOpened));
    await openReader(
      context,
      workId: workIdOfSection(key),
      section: key,
      highlight: switch (content) {
        QuoteContent(:final text) => text,
        _ => null,
      },
    );
  }

  /// Uvod k autorovi: prve dielo autora v Library.
  Future<void> readWork() async {
    final c = content;
    if (c is! AuthorContent || c.firstWorkId == null) return;
    await openReader(context, workId: c.firstWorkId!);
  }

  /// Cvicenie v Practice (postup, "I did this").
  Future<void> openPractice() =>
      context.push(PracticeRoutes.exercise(content.id.key));

  /// Otazka: odpoved do lokalneho dennika (`answered`).
  Future<void> reflect() async {
    final c = content;
    if (c is! PromptContent) return;
    final saved = await showJournalPromptSheet(
      context,
      date: date,
      promptId: c.id.format(),
      prompt: c.text,
    );
    if (saved) await _log(CardAction.answered);
  }

  /// "Report a problem" (D-04): pouzivatel posle `.txt` report sam cez
  /// share sheet. Report nesie len referenciu karty (`card_id`, dielo
  /// a sekcia), ziadny text karty.
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
    final intention = ref.watch(settingOf(SettingsKeys.intentionText)).value;
    return IntroCard(
      content: content,
      cardsCount: cardsCount,
      questSlots: [
        for (final q in quests)
          if (q.status != QuestStatus.skipped) q.slot,
      ],
      intention: intention,
      semanticLabel: semanticLabel,
    );
  }
}
