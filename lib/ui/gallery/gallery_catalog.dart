import 'package:flutter/material.dart';
import 'package:prosoche/ui/components/sk_banners.dart';
import 'package:prosoche/ui/components/sk_button.dart';
import 'package:prosoche/ui/components/sk_card_surface.dart';
import 'package:prosoche/ui/components/sk_daily_progress.dart';
import 'package:prosoche/ui/components/sk_dialogs.dart';
import 'package:prosoche/ui/components/sk_nav_bar.dart';
import 'package:prosoche/ui/components/sk_practice.dart';
import 'package:prosoche/ui/components/sk_quest_item.dart';
import 'package:prosoche/ui/components/sk_quote.dart';
import 'package:prosoche/ui/components/sk_reader.dart';
import 'package:prosoche/ui/components/sk_states.dart';
import 'package:prosoche/ui/gallery/gallery_samples.dart';
import 'package:prosoche/ui/motif/sk_greek_motif.dart';
import 'package:prosoche/ui/theme/sk_context.dart';
import 'package:prosoche/ui/tokens/sk_space.dart';

/// Jeden stav komponentu v galerii a goldenoch.
@immutable
class GalleryEntry {
  const GalleryEntry(this.name, this.builder);

  final String name;
  final WidgetBuilder builder;
}

/// Komponent so vsetkymi stavmi.
@immutable
class GalleryComponent {
  const GalleryComponent(this.name, this.entries);

  final String name;
  final List<GalleryEntry> entries;
}

void _noop() {}

/// Katalog vsetkych komponentov a ich stavov. Pouziva ho galeria aj golden
/// testy (`test/ui/goldens/`). Texty su dev-only EN placeholdery.
abstract final class GalleryCatalog {
  static final List<GalleryComponent> components = [
    cardSurface,
    dailyProgress,
    questItem,
    buttons,
    navBar,
    dialogs,
    banners,
    states,
    quoteCards,
    cardHeaders,
    reader,
    practice,
    motif,
  ];

  // D-01: komponenty pre karty, Library a Practice (docs/DESIGN.md 6.2).

  static final quoteCards = GalleryComponent('SkQuoteCard', [
    GalleryEntry(
      'quote',
      (context) => const SkQuoteCard(
        eyebrow: 'Quote',
        text: GallerySamples.quote,
        work: 'Meditations',
        locus: '4.3',
        author: 'Marcus Aurelius',
        translator: 'George Long',
        year: 1862,
        headerActions: [
          SkIconButton(
            icon: Icons.bookmark_border,
            tooltip: 'Save',
            onPressed: _noop,
          ),
        ],
        semanticLabel: 'Card 2 of 12, quote',
      ),
    ),
    GalleryEntry(
      'passage',
      (context) => const SkQuoteCard(
        eyebrow: 'Passage',
        text: GallerySamples.passage,
        work: 'Meditations',
        locus: '2.1',
        author: 'Marcus Aurelius',
        translator: 'George Long',
        year: 1862,
        style: SkQuoteStyle.passage,
      ),
    ),
    GalleryEntry(
      'prompt (draft, bez referencie)',
      (context) => const SkQuoteCard(
        eyebrow: 'Reflect',
        text: GallerySamples.prompt,
        style: SkQuoteStyle.prompt,
        footer: SkButton.secondary(label: 'Reflect tonight', onPressed: _noop),
      ),
    ),
    GalleryEntry(
      'compact',
      (context) => const SkQuoteCard(
        eyebrow: 'Quote',
        text: GallerySamples.passage,
        work: 'Meditations',
        locus: '2.1',
        variant: SkCardVariant.compact,
        onTap: _noop,
      ),
    ),
  ]);

  static final cardHeaders = GalleryComponent('Card headers', [
    GalleryEntry(
      'concept',
      (context) => const SkConceptHeader(
        term: 'prosoche',
        greek: 'προσοχή',
        gloss: 'attention',
      ),
    ),
    GalleryEntry(
      'author',
      (context) => const SkAuthorHeader(
        name: 'Epictetus',
        dates: 'c. 50 – c. 135',
        role: 'Teacher, born a slave',
      ),
    ),
    GalleryEntry(
      'practice steps',
      (context) => const SkPracticeSteps(
        duration: '2 min',
        steps: [
          'Name one difficulty you expect today.',
          'Decide how you want to meet it.',
        ],
      ),
    ),
    GalleryEntry(
      'reference',
      (context) => const SkReference(
        work: 'Meditations',
        locus: '2.1',
        author: 'Marcus Aurelius',
        translator: 'George Long',
        year: 1862,
        layout: SkReferenceLayout.full,
      ),
    ),
  ]);

  static final reader = GalleryComponent('SkReaderText', [
    GalleryEntry(
      'heading + paragraphs',
      (context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkReadingProgress(value: 0.4, label: 'Reading position'),
          SkReaderHeading(title: 'Book II', subtitle: 'Among the Quadi'),
          SkReaderText(text: GallerySamples.passage, sectionNumber: '1'),
          SkReaderText(
            text: GallerySamples.quote,
            sectionNumber: '2',
            highlighted: true,
          ),
        ],
      ),
    ),
    GalleryEntry(
      'size XL',
      (context) => const SkReaderText(
        text: GallerySamples.quote,
        sectionNumber: '3',
        size: SkReaderSize.xl,
      ),
    ),
  ]);

  static final practice = GalleryComponent('SkPracticeHeader', [
    GalleryEntry(
      'morning',
      (context) => const SkPracticeHeader(
        time: SkPracticeTime.morning,
        eyebrow: 'Morning',
        title: 'Morning preparation',
        subtitle: 'Marcus Aurelius, Meditations 2.1',
      ),
    ),
    GalleryEntry(
      'evening',
      (context) => const SkPracticeHeader(
        time: SkPracticeTime.evening,
        eyebrow: 'Evening',
        title: 'Evening review',
        subtitle: 'Seneca, On Anger 3.36',
      ),
    ),
    GalleryEntry('journal field', (context) => const _JournalSample()),
  ]);

  static final motif = GalleryComponent('Motif', [
    GalleryEntry(
      'meander + cornice',
      (context) => const Column(
        children: [
          SkMeanderBand(),
          SizedBox(height: SkSpace.space16),
          SkCornice(),
        ],
      ),
    ),
    GalleryEntry(
      'arch, column, portal',
      (context) => const Wrap(
        spacing: SkSpace.space24,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [SkArch(size: 64), SkColumn(), SkPortalMark()],
      ),
    ),
  ]);

  static Widget _lead(BuildContext context) =>
      Text(GallerySamples.lead, style: context.sk.type.reflection);

  static final cardSurface = GalleryComponent('SkCardSurface', [
    GalleryEntry(
      'full',
      (context) => SkCardSurface(
        eyebrow: 'SAMPLE 2.1',
        headerActions: const [
          SkIconButton(
            icon: Icons.bookmark_border,
            tooltip: 'Save',
            onPressed: _noop,
          ),
        ],
        lead: _lead(context),
        translation: const Text(GallerySamples.translation),
        attribution: GallerySamples.attribution,
        semanticLabel: 'Card 5 of 12',
      ),
    ),
    GalleryEntry(
      'saved + footer',
      (context) => SkCardSurface(
        eyebrow: 'SAMPLE 2.1',
        headerActions: const [
          SkIconButton(
            icon: Icons.bookmark_border,
            selectedIcon: Icons.bookmark,
            selected: true,
            tooltip: 'Saved',
            onPressed: _noop,
          ),
        ],
        lead: _lead(context),
        translation: const Text(GallerySamples.translation),
        footer: const SkButton.secondary(label: 'Next card', onPressed: _noop),
      ),
    ),
    GalleryEntry(
      'gate',
      (context) => SkCardSurface(
        variant: SkCardVariant.gate,
        eyebrow: 'SAMPLE 2.1',
        lead: _lead(context),
        translation: const Text(GallerySamples.translation),
      ),
    ),
    GalleryEntry(
      'compact',
      (_) => const SkCardSurface(
        variant: SkCardVariant.compact,
        eyebrow: 'SAMPLE 2.1',
        translation: Text('[PLACEHOLDER] The sample line…'),
        onTap: _noop,
      ),
    ),
    GalleryEntry('loading', (_) => const SkCardSurface(loading: true)),
    GalleryEntry(
      'error',
      (_) => const SkCardSurface(
        error: SkErrorState(
          title: 'This card couldn’t load',
          onRetry: _noop,
          secondaryLabel: 'Skip this card',
          onSecondary: _noop,
        ),
      ),
    ),
  ]);

  static final dailyProgress = GalleryComponent('SkDailyProgress', [
    GalleryEntry(
      'not started',
      (_) => const SkDailyProgress(done: 0, total: 12),
    ),
    GalleryEntry(
      'in progress',
      (_) => const SkDailyProgress(done: 5, total: 12),
    ),
    GalleryEntry(
      'completed',
      (_) => const SkDailyProgress(done: 12, total: 12),
    ),
    GalleryEntry(
      'extended',
      (_) => const SkDailyProgress(done: 12, total: 12, extended: true),
    ),
    GalleryEntry(
      'gate',
      (_) => const SkDailyProgress(
        done: 1,
        total: 3,
        variant: SkDailyProgressVariant.gate,
      ),
    ),
    GalleryEntry(
      'today summary',
      (_) => const SkDailyProgress(
        done: 5,
        total: 12,
        variant: SkDailyProgressVariant.todaySummary,
        summaryLabel: '5 of 12 cards',
      ),
    ),
  ]);

  static final questItem = GalleryComponent('SkQuestItem', [
    GalleryEntry(
      'read in progress',
      (_) => const SkQuestItem(
        title: 'Read 5 cards',
        slot: SkQuestSlot.read,
        state: SkQuestState.inProgress,
        progress: 3,
        target: 5,
        onTap: _noop,
      ),
    ),
    GalleryEntry(
      'learn done',
      (_) => const SkQuestItem(
        title: 'Learn one idea',
        slot: SkQuestSlot.learn,
        state: SkQuestState.done,
        progress: 1,
        target: 1,
      ),
    ),
    GalleryEntry(
      'act open',
      (_) => const SkQuestItem(
        title: '[PLACEHOLDER quest act]',
        subtitle: '[PLACEHOLDER source]',
        slot: SkQuestSlot.act,
        onAction: _noop,
      ),
    ),
    GalleryEntry(
      'act skipped',
      (_) => const SkQuestItem(
        title: '[PLACEHOLDER quest act]',
        slot: SkQuestSlot.act,
        state: SkQuestState.skipped,
        onUndo: _noop,
      ),
    ),
    GalleryEntry(
      'with label',
      (_) => const SkQuestItem(
        title: '[PLACEHOLDER quest]',
        slot: SkQuestSlot.act,
        eventLabel: 'Theme',
        onAction: _noop,
      ),
    ),
  ]);

  static final buttons = GalleryComponent('SkButton', [
    GalleryEntry(
      'primary',
      (_) => const SkButton.primary(label: 'Continue', onPressed: _noop),
    ),
    GalleryEntry(
      'secondary',
      (_) => const SkButton.secondary(label: 'I did it', onPressed: _noop),
    ),
    GalleryEntry(
      'tertiary',
      (_) => const SkButton.tertiary(label: 'Not now', onPressed: _noop),
    ),
    GalleryEntry(
      'outlined + icon',
      (_) => const SkButton.outlined(
        label: 'Choose apps',
        icon: Icons.apps,
        onPressed: _noop,
      ),
    ),
    GalleryEntry(
      'destructive',
      (_) => const SkButton.destructive(
        label: 'Delete all data',
        onPressed: _noop,
      ),
    ),
    GalleryEntry(
      'disabled',
      (_) => const SkButton.primary(label: 'Continue', onPressed: null),
    ),
    GalleryEntry(
      'loading',
      (_) => const SkButton.primary(
        label: 'Continue',
        loading: true,
        onPressed: _noop,
      ),
    ),
    GalleryEntry(
      'expanded',
      (_) => const SkButton.primary(
        label: 'Allow notifications',
        expand: true,
        onPressed: _noop,
      ),
    ),
    GalleryEntry(
      'hold to confirm',
      (_) => const SkHoldToConfirmButton(
        label: 'Emergency',
        icon: Icons.lock_open,
        onConfirmed: _noop,
        onAccessibleConfirm: _noop,
      ),
    ),
    GalleryEntry(
      'icon',
      (_) => const Row(
        children: [
          SkIconButton(icon: Icons.share, tooltip: 'Share', onPressed: _noop),
          SkIconButton(
            icon: Icons.bookmark_border,
            selectedIcon: Icons.bookmark,
            selected: true,
            tooltip: 'Saved',
            onPressed: _noop,
          ),
        ],
      ),
    ),
  ]);

  static final navBar = GalleryComponent('SkNavBar', [
    GalleryEntry(
      'today selected',
      (_) => SkNavBar(
        selectedIndex: 0,
        onSelected: (_) {},
        destinations: [
          for (final (i, label) in const [
            'Today',
            'Library',
            'Practice',
            'Journey',
          ].indexed)
            SkNavDestination(
              icon: SkNavBar.tabIcons[i].$1,
              selectedIcon: SkNavBar.tabIcons[i].$2,
              label: label,
            ),
        ],
      ),
    ),
  ]);

  static final dialogs = GalleryComponent('Dialogs + sheets', [
    GalleryEntry(
      'confirm neutral',
      (_) => const SkConfirmDialog(
        title: 'Change cards per day?',
        body: 'This applies from tomorrow.',
        confirmLabel: 'Change',
      ),
    ),
    GalleryEntry(
      'confirm destructive',
      (_) => const SkConfirmDialog(
        title: 'Delete all data?',
        body: 'This removes your progress from this device.',
        confirmLabel: 'Delete',
        variant: SkConfirmVariant.destructive,
      ),
    ),
    GalleryEntry(
      'sheet',
      (_) => const SkSheet(
        title: 'About this card',
        closeLabel: 'Close',
        actions: [SkButton.secondary(label: 'Got it', onPressed: _noop)],
        child: Text('[PLACEHOLDER] Where this text comes from.'),
      ),
    ),
  ]);

  static final banners = GalleryComponent('Banners', [
    GalleryEntry(
      'info',
      (_) => const SkInlineBanner(
        message: 'Notifications are off.',
        actionLabel: 'Turn on',
        onAction: _noop,
        onDismiss: _noop,
      ),
    ),
    GalleryEntry(
      'warning',
      (_) => const SkInlineBanner(
        variant: SkBannerVariant.warning,
        title: 'Gate is paused',
        message: 'Usage access was turned off.',
        actionLabel: 'Fix',
        onAction: _noop,
      ),
    ),
    GalleryEntry(
      'error',
      (_) => const SkInlineBanner(
        variant: SkBannerVariant.error,
        message: 'Something went wrong.',
        actionLabel: 'Try again',
        onAction: _noop,
        onDismiss: _noop,
      ),
    ),
    GalleryEntry(
      'offline note',
      (_) => const SkOfflineNote(message: 'Updates need internet'),
    ),
  ]);

  static final states = GalleryComponent('Screen states', [
    GalleryEntry(
      'empty',
      (_) => const SkEmptyState(
        title: 'Nothing saved yet',
        body: 'Cards you save will appear here.',
        actionLabel: 'Open today',
        onAction: _noop,
      ),
    ),
    GalleryEntry(
      'error',
      (_) => const SkErrorState(
        title: 'Couldn’t load',
        body: 'Please try again.',
        onRetry: _noop,
        secondaryLabel: 'Report a problem',
        onSecondary: _noop,
      ),
    ),
    GalleryEntry('skeleton card', (_) => const SkSkeleton.card()),
    GalleryEntry('skeleton list', (_) => const SkSkeleton.list()),
    GalleryEntry(
      'loading (immediate)',
      (_) => const SkLoadingView(
        showAfter: Duration.zero,
        skeleton: SkSkeleton.list(lines: 2),
      ),
    ),
  ]);
}

/// Spolocny obal pre zobrazenie jedneho stavu (galeria aj goldeny).
class GalleryFrame extends StatelessWidget {
  const GalleryFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.sk.colors.bg,
    child: Padding(
      padding: const EdgeInsets.all(SkSpace.space16),
      child: child,
    ),
  );
}

class _JournalSample extends StatefulWidget {
  const _JournalSample();

  @override
  State<_JournalSample> createState() => _JournalSampleState();
}

class _JournalSampleState extends State<_JournalSample> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SkJournalField(
    controller: _controller,
    label: 'What did I do well today?',
    privacyNote: 'Your journal stays on this device.',
  );
}
