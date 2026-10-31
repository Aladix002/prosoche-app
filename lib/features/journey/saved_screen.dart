import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/quests.dart' show CardContext;
import 'package:prosoche/features/cards/translator_notes.dart'
    show translationWithNotes;
import 'package:prosoche/features/journey/card_pager.dart';
import 'package:prosoche/features/journey/journey_providers.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

/// Filtre ulozenych kariet (A8.3); null = All.
const List<CardType?> savedFilters = [
  null,
  CardType.ayah,
  CardType.hadith,
  CardType.dua,
  CardType.name,
  CardType.reflection,
];

/// Typ z `?type=` (docs/02 C2); neplatny = bez filtra.
CardType? parseSavedType(String? raw) {
  final t = raw == null ? null : CardType.fromWire(raw);
  return t != null && t.canSave ? t : null;
}

/// Ulozene karty (docs/02 A8.3): najnovsie prve, filtre, nahlad 1-2
/// riadky (arabcina sa v nahlade neukazuje, docs/01 3.2 `compact`), tap
/// otvori kartu, swipe na riadku ju odoberie s Undo.
class SavedCardsScreen extends ConsumerStatefulWidget {
  const SavedCardsScreen({this.initialType, super.key});

  final CardType? initialType;

  @override
  ConsumerState<SavedCardsScreen> createState() => _SavedCardsScreenState();
}

class _SavedCardsScreenState extends ConsumerState<SavedCardsScreen> {
  late CardType? _type = widget.initialType;

  /// Odobrate karty, kym ich stream neodstrani (Dismissible musi zmiznut
  /// zo stromu hned).
  final _hidden = <CardId>{};

  Future<void> _remove(CardId id) async {
    final l10n = context.l10n;
    final actions = ref.read(cardActionsRepositoryProvider);
    final date = ref.read(localDateProvider);
    setState(() => _hidden.add(id));
    await actions.unsave(date, id, context: CardContext.saved);
    if (!mounted) return;
    showSkSnackbar(
      context,
      message: l10n.journeySavedRemoved,
      actionLabel: l10n.journeyUndo,
      onAction: () => unawaited(() async {
        await actions.save(date, id, context: CardContext.saved);
        if (mounted) setState(() => _hidden.remove(id));
      }()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final saved = ref.watch(savedCardsProvider(_type));
    final gutter = SkSpace.gutterFor(MediaQuery.sizeOf(context).width);
    final cards = [
      for (final c in saved.value ?? const <SavedCard>[])
        if (!_hidden.contains(c.cardId)) c,
    ];
    final Widget content;
    if (saved.hasError && !saved.isLoading) {
      content = SkErrorState(
        title: l10n.journeyErrorTitle,
        body: l10n.journeyErrorBody,
        onRetry: () => ref.invalidate(savedCardsProvider(_type)),
      );
    } else if (!saved.hasValue) {
      content = const SkLoadingView(skeleton: SkSkeleton.list(lines: 4));
    } else if (cards.isEmpty) {
      content = SkEmptyState(
        title: l10n.journeySavedEmptyTitle,
        body: l10n.journeySavedEmptyBody,
        icon: Icons.bookmark_border,
      );
    } else {
      final today = ref.watch(localDateProvider);
      content = Column(
        children: [
          for (final (i, c) in cards.indexed)
            _SavedTile(
              key: ValueKey('saved:${c.cardId}'),
              card: c.cardId,
              onOpen: () => unawaited(
                openJourneyCards(
                  context,
                  cards: [for (final s in cards) s.cardId],
                  date: today,
                  initialIndex: i,
                ),
              ),
              onRemove: () => unawaited(_remove(c.cardId)),
            ),
        ],
      );
    }
    return Scaffold(
      appBar: skAppBar(context, title: l10n.journeySavedTitle),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: SkSpace.space32),
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              gutter,
              SkSpace.space8,
              gutter,
              SkSpace.space8,
            ),
            child: Wrap(
              spacing: SkSpace.space8,
              runSpacing: SkSpace.space8,
              children: [
                for (final t in savedFilters)
                  ChoiceChip(
                    key: ValueKey('saved-filter:${t?.wire ?? 'all'}'),
                    label: Text(l10n.journeySavedFilter(t?.wire ?? 'all')),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
          ),
          content,
        ],
      ),
    );
  }
}

/// Ikona typu karty v zozname.
IconData savedTypeIcon(CardType type) => switch (type) {
  CardType.ayah => Icons.menu_book_outlined,
  CardType.hadith => Icons.format_quote_outlined,
  CardType.dua => Icons.volunteer_activism_outlined,
  CardType.name => Icons.auto_awesome_outlined,
  CardType.reflection => Icons.lightbulb_outline,
  _ => Icons.bookmark_outline,
};

/// Titulok a nahlad ulozenej karty; texty su doslovne z content.db,
/// arabcina sa nepouziva.
(String, String?) savedPreview(BuildContext context, CardContent? content) {
  final l10n = context.l10n;
  final formats = ProsocheFormats(Localizations.localeOf(context));
  String type(CardType t) => l10n.journeyCardType(t.wire);
  return switch (content) {
    AyahContent(:final ayah, :final surah) => (
      l10n.cardAyahReference(
        surah.nameTranslit,
        formats.ayahRef(ayah.id.surah, ayah.id.ayah),
      ),
      ayah.translation?.text,
    ),
    HadithContent(:final title, :final text) => (
      type(CardType.hadith),
      title ?? text,
    ),
    DuaContent(:final title, :final text, :final translit) => (
      title ?? type(CardType.dua),
      text ?? translit,
    ),
    NameContent(:final translit, :final meaning) => (
      translit ?? type(CardType.name),
      meaning,
    ),
    ReflectionContent(:final question, :final text) => (
      type(CardType.reflection),
      question ?? text,
    ),
    _ => (type(content?.id.type ?? CardType.ayah), null),
  };
}

/// Nahlad versa so znackami poznamok prekladatela ako horny index bez tapu
/// (rovnaky renderer ako karta, BF-02); text prekladu sa nemeni. Null =
/// obycajny text.
InlineSpan? savedPreviewSpan(BuildContext context, CardContent? content) {
  if (content is! AyahContent) return null;
  final t = content.ayah.translation;
  if (t == null) return null;
  return translationWithNotes(
    context,
    text: t.text,
    footnotes: t.footnotes,
    lang: t.lang,
    interactive: false,
  );
}

class _SavedTile extends ConsumerWidget {
  const _SavedTile({
    required this.card,
    required this.onOpen,
    required this.onRemove,
    super.key,
  });

  final CardId card;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final content = ref.watch(cardContentProvider(card));
    final (title, preview) = content.hasValue
        ? savedPreview(context, content.value)
        : (l10n.journeyCardType(card.type.wire), null);
    return Dismissible(
      key: ValueKey('dismiss:$card'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: ColoredBox(
        color: sk.colors.surfaceAlt,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: SkSpace.space24,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(l10n.journeySavedRemove, style: sk.text.labelLarge),
              ),
              const SizedBox(width: SkSpace.space8),
              const Icon(Icons.delete_outline),
            ],
          ),
        ),
      ),
      child: Semantics(
        customSemanticsActions: {
          CustomSemanticsAction(label: l10n.journeySavedRemove): onRemove,
        },
        child: ListTile(
          leading: ExcludeSemantics(child: Icon(savedTypeIcon(card.type))),
          title: Text(title),
          subtitle: preview == null
              ? null
              : Text.rich(
                  savedPreviewSpan(context, content.value) ??
                      TextSpan(text: preview),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
          onTap: onOpen,
        ),
      ),
    );
  }
}
