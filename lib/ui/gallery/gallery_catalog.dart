import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:sakina/ui/components/sk_arabic_text.dart';
import 'package:sakina/ui/components/sk_banners.dart';
import 'package:sakina/ui/components/sk_button.dart';
import 'package:sakina/ui/components/sk_card_surface.dart';
import 'package:sakina/ui/components/sk_chips.dart';
import 'package:sakina/ui/components/sk_daily_progress.dart';
import 'package:sakina/ui/components/sk_dialogs.dart';
import 'package:sakina/ui/components/sk_nav_bar.dart';
import 'package:sakina/ui/components/sk_prayer_row.dart';
import 'package:sakina/ui/components/sk_quest_item.dart';
import 'package:sakina/ui/components/sk_states.dart';
import 'package:sakina/ui/gallery/gallery_samples.dart';
import 'package:sakina/ui/theme/sakina_typography.dart';
import 'package:sakina/ui/theme/sk_context.dart';
import 'package:sakina/ui/tokens/sk_space.dart';

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
    arabicText,
    cardSurface,
    dailyProgress,
    questItem,
    prayerRow,
    chips,
    buttons,
    navBar,
    dialogs,
    banners,
    states,
  ];

  static final arabicText = GalleryComponent('SkArabicText', [
    GalleryEntry(
      'quran card',
      (_) => const SkArabicText.quran([
        SkArabicSegment(GallerySamples.sentence),
      ], textSimple: GallerySamples.sentenceSimple),
    ),
    GalleryEntry(
      'quran tajwid',
      (_) => const SkArabicText.quran(
        GallerySamples.segments,
        textSimple: GallerySamples.sentenceSimple,
        tajwid: true,
      ),
    ),
    GalleryEntry(
      'highlight',
      (_) => const SkArabicText.quran(
        [SkArabicSegment(GallerySamples.sentence)],
        textSimple: GallerySamples.sentenceSimple,
        highlight: true,
      ),
    ),
    GalleryEntry(
      'highlight + tajwid',
      (_) => const SkArabicText.quran(
        GallerySamples.segments,
        textSimple: GallerySamples.sentenceSimple,
        tajwid: true,
        highlight: true,
      ),
    ),
    GalleryEntry(
      'selected word',
      (_) => const SkArabicText.quran(
        GallerySamples.wordSegments,
        textSimple: GallerySamples.wordSegmentsSimple,
        style: SkQuranStyle.word,
        selectedSegment: 2,
      ),
    ),
    GalleryEntry(
      'reader, long, start',
      (_) => const SkArabicText.quran(
        [SkArabicSegment(GallerySamples.long)],
        textSimple: GallerySamples.longSimple,
        style: SkQuranStyle.reader,
        textAlign: TextAlign.start,
      ),
    ),
    GalleryEntry(
      'bismillah token',
      (_) => const SkArabicText.quran(
        [SkArabicSegment(GallerySamples.words)],
        textSimple: GallerySamples.wordsSimple,
        style: SkQuranStyle.bismillah,
      ),
    ),
    GalleryEntry(
      'XL scale',
      (_) => const ArabicScaleOverride(
        scale: SkArabicScale.xl,
        child: SkArabicText.quran([
          SkArabicSegment(GallerySamples.words),
        ], textSimple: GallerySamples.wordsSimple),
      ),
    ),
    GalleryEntry(
      'text body',
      (_) => SkArabicText.text(
        GallerySamples.long,
        semanticsText: GallerySamples.longSimple,
      ),
    ),
    GalleryEntry(
      'text lemma',
      (_) => SkArabicText.text(
        GallerySamples.lemma,
        style: SkArabicTextStyle.lemma,
      ),
    ),
    GalleryEntry(
      'text name',
      (_) => SkArabicText.text(
        GallerySamples.lemma,
        style: SkArabicTextStyle.name,
      ),
    ),
    GalleryEntry(
      'integrity failed',
      (_) => const SkArabicText.quran(
        [SkArabicSegment(GallerySamples.words)],
        textSimple: GallerySamples.wordsSimple,
        integrityFailed: true,
      ),
    ),
  ]);

  static Widget _arabicCard({bool tajwid = false}) => SkArabicText.quran(
    tajwid
        ? GallerySamples.segments
        : const [SkArabicSegment(GallerySamples.sentence)],
    textSimple: GallerySamples.sentenceSimple,
    tajwid: tajwid,
  );

  static final cardSurface = GalleryComponent('SkCardSurface', [
    GalleryEntry(
      'full',
      (_) => SkCardSurface(
        eyebrow: 'SAMPLE 1:12',
        headerActions: const [
          SkIconButton(
            icon: Icons.bookmark_border,
            tooltip: 'Save',
            onPressed: _noop,
          ),
        ],
        arabic: _arabicCard(),
        translation: const Text(GallerySamples.translation),
        attribution: GallerySamples.attribution,
        semanticLabel: 'Card 5 of 12',
      ),
    ),
    GalleryEntry(
      'saved + footer',
      (_) => SkCardSurface(
        eyebrow: 'SAMPLE 1:12',
        headerActions: const [
          SkIconButton(
            icon: Icons.bookmark_border,
            selectedIcon: Icons.bookmark,
            selected: true,
            tooltip: 'Saved',
            onPressed: _noop,
          ),
        ],
        arabic: _arabicCard(tajwid: true),
        translation: const Text(GallerySamples.translation),
        footer: const SkButton.secondary(label: 'Next card', onPressed: _noop),
      ),
    ),
    GalleryEntry(
      'gate',
      (_) => SkCardSurface(
        variant: SkCardVariant.gate,
        eyebrow: 'SAMPLE 1:12',
        arabic: _arabicCard(),
        translation: const Text(GallerySamples.translation),
      ),
    ),
    GalleryEntry(
      'compact',
      (_) => const SkCardSurface(
        variant: SkCardVariant.compact,
        eyebrow: 'SAMPLE 1:12',
        translation: Text('[PLACEHOLDER] Welcome to the library…'),
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
        title: 'Read 10 verses',
        slot: SkQuestSlot.read,
        state: SkQuestState.inProgress,
        progress: 6,
        target: 10,
        onTap: _noop,
      ),
    ),
    GalleryEntry(
      'learn done',
      (_) => const SkQuestItem(
        title: 'Learn 1 new word',
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
      'event override',
      (_) => const SkQuestItem(
        title: '[PLACEHOLDER event quest]',
        slot: SkQuestSlot.act,
        eventLabel: 'Jumu’ah',
        onAction: _noop,
      ),
    ),
  ]);

  static final prayerRow = GalleryComponent('SkPrayerRow', [
    GalleryEntry(
      'passed on time',
      (_) => const SkPrayerRow(
        name: 'Dhuhr',
        time: '11:58',
        state: SkPrayerRowState.passed,
        status: SkPrayerStatus.onTime,
      ),
    ),
    GalleryEntry(
      'next',
      (_) => SkPrayerRow(
        name: 'Asr',
        time: '14:21',
        state: SkPrayerRowState.next,
        relative: 'in 1 h 12 min',
        onTrackerTap: _noop,
        customActions: {
          const CustomSemanticsAction(label: 'Mark on time'): _noop,
        },
      ),
    ),
    GalleryEntry(
      'current',
      (_) => const SkPrayerRow(
        name: 'Maghrib',
        time: '16:43',
        state: SkPrayerRowState.current,
      ),
    ),
    GalleryEntry(
      'late',
      (_) => const SkPrayerRow(
        name: 'Fajr',
        time: '05:12',
        state: SkPrayerRowState.passed,
        status: SkPrayerStatus.late,
      ),
    ),
    GalleryEntry(
      'missed',
      (_) => const SkPrayerRow(
        name: 'Fajr',
        time: '05:12',
        state: SkPrayerRowState.passed,
        status: SkPrayerStatus.missed,
      ),
    ),
    GalleryEntry(
      'qada',
      (_) => const SkPrayerRow(
        name: 'Fajr',
        time: '05:12',
        state: SkPrayerRowState.passed,
        status: SkPrayerStatus.qada,
      ),
    ),
    GalleryEntry(
      'estimated, notif off, adjusted',
      (_) => const SkPrayerRow(
        name: 'Isha',
        time: '18:15',
        estimated: true,
        notificationOff: true,
        adjustedLabel: '+2 min',
      ),
    ),
  ]);

  static final chips = GalleryComponent('SkNextPrayerChip + SkHijriHeader', [
    GalleryEntry(
      'next prayer',
      (_) => const SkNextPrayerChip(label: 'Asr in 1 h 12 min', onTap: _noop),
    ),
    GalleryEntry(
      'next prayer now',
      (_) => const SkNextPrayerChip(
        label: 'Asr now',
        state: SkNextPrayerState.now,
      ),
    ),
    GalleryEntry(
      'next prayer unavailable',
      (_) => const SkNextPrayerChip(
        label: 'Set location for prayer times',
        state: SkNextPrayerState.unavailable,
        onTap: _noop,
      ),
    ),
    GalleryEntry(
      'hijri',
      (_) => const SkHijriHeader(
        date: '14 Jumada al-Ula 1448 · Friday',
        onTap: _noop,
      ),
    ),
    GalleryEntry(
      'hijri event + offset',
      (_) => const SkHijriHeader(
        date: '14 Jumada al-Ula 1448 · Friday',
        eventLabel: 'Jumu’ah',
        offsetLabel: '+1 day',
        onTap: _noop,
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
        label: 'Choose city',
        icon: Icons.location_city,
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
            'Quran',
            'Prayer',
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
        title: 'Change city?',
        body: 'Prayer times will be recalculated.',
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
        title: 'Estimated times',
        closeLabel: 'Close',
        actions: [SkButton.secondary(label: 'Got it', onPressed: _noop)],
        child: Text('[PLACEHOLDER] How high latitude times are estimated.'),
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
      (_) => const SkOfflineNote(message: 'Audio needs internet'),
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

/// Prepise pouzivatelsku velkost arabciny v podstrome (galeria, testy).
class ArabicScaleOverride extends StatelessWidget {
  const ArabicScaleOverride({
    required this.scale,
    required this.child,
    super.key,
  });

  final SkArabicScale scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = context.sk.type.copyWith(arabicScale: scale);
    return Theme(
      data: theme.copyWith(extensions: [...theme.extensions.values, type]),
      child: child,
    );
  }
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
