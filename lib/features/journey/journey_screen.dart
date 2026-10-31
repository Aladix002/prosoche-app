import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/flags/feature_flags.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/feed/feed_rules.dart' show nextReadingAyah;
import 'package:sakina/features/journey/journey_calendar.dart';
import 'package:sakina/features/journey/journey_providers.dart';
import 'package:sakina/features/journey/journey_routes.dart';
import 'package:sakina/features/journey/niyyah_dialog.dart';
import 'package:sakina/features/journey/surah_map.dart';
import 'package:sakina/features/quran/quran_routes.dart';
import 'package:sakina/features/shell/settings_button.dart';
import 'package:sakina/features/words/words_routes.dart';
import 'package:sakina/ui/i18n/i18n.dart';
import 'package:sakina/ui/ui.dart';

/// Moja cesta (docs/02 A8.1): umysel, kalendar dni, streak a grace days
/// (skryte v `simple_mode`), mapa sur, khatm, ulozene karty. Vsetko je
/// sukromne, bez bodov a porovnani (docs/01 1.4).
class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({super.key});

  /// Listovanie do minulosti (mesiace od aktualneho).
  static const maxMonthsBack = 24;

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen> {
  JourneyMonth? _month;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = ref.watch(localDateProvider);
    final current = (today.year, today.month);
    final month = _month ?? current;
    final back = journeyMonthsBetween(month, current);
    final streak = ref.watch(streakProvider);
    final days = ref.watch(dayLogProvider(month));
    // Kym sa `simple_mode` nenacita, cisla sa neukazu (ziadne bliknutie).
    final simple = ref.watch(settingOf(SettingsKeys.simpleMode)).value != false;

    final Widget body;
    if ((streak.hasError && !streak.isLoading) ||
        (days.hasError && !days.isLoading)) {
      body = SkErrorState(
        title: l10n.journeyErrorTitle,
        body: l10n.journeyErrorBody,
        onRetry: () => ref
          ..invalidate(streakProvider)
          ..invalidate(dayLogProvider(month)),
      );
    } else {
      final ready = streak.hasValue && days.hasValue;
      final summary = streak.value;
      final entries = days.value ?? const [];
      final isNew =
          ready &&
          month == current &&
          entries.isEmpty &&
          !summary!.todayDone &&
          summary.longest == 0;
      final gutter = SkSpace.gutterFor(MediaQuery.sizeOf(context).width);
      body = ListView(
        padding: EdgeInsetsDirectional.fromSTEB(
          gutter,
          SkSpace.space8,
          gutter,
          SkSpace.space32,
        ),
        children: [
          const JourneyNiyyah(),
          const SizedBox(height: SkSpace.space16),
          if (!ready)
            const SkLoadingView(skeleton: SkSkeleton.list(lines: 6))
          else ...[
            if (isNew) ...[
              _Intro(
                title: l10n.journeyEmptyTitle,
                body: l10n.journeyEmptyBody,
              ),
              const SizedBox(height: SkSpace.space16),
            ],
            JourneyCalendar(
              month: month,
              today: today,
              entries: entries,
              todayDone: summary!.todayDone,
              simple: simple,
              onPrevious: back < JourneyScreen.maxMonthsBack
                  ? () => setState(() => _month = shiftJourneyMonth(month, -1))
                  : null,
              onNext: back > 0
                  ? () => setState(() => _month = shiftJourneyMonth(month, 1))
                  : null,
              onOpenDay: (d) => context.push(JourneyRoutes.day(d)),
            ),
            if (!simple) ...[
              const SizedBox(height: SkSpace.space16),
              JourneyStreakSummary(summary: summary),
            ],
          ],
          const SizedBox(height: SkSpace.space24),
          const _QuranSection(),
          if (ref.watch(featureFlagsProvider).words)
            ListTile(
              contentPadding: EdgeInsetsDirectional.zero,
              leading: const Icon(Icons.translate),
              title: Text(l10n.journeyWords),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(WordsRoutes.root),
            ),
          const SizedBox(height: SkSpace.space24),
          const _SavedButton(),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Semantics(header: true, child: Text(l10n.journeyTitle)),
        actions: const [ShellSettingsButton()],
      ),
      body: body,
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    // D-05: prvy den bez historie - medailon a uvod v tonalnom paneli.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: sk.colors.surface,
        borderRadius: BorderRadius.circular(SkRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(SkSpace.space16),
        child: Row(
          children: [
            const SkMotifBadge(icon: Icons.route_outlined, size: 48),
            const SizedBox(width: SkSpace.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(title, style: sk.text.titleMedium),
                  ),
                  const SizedBox(height: SkSpace.space4),
                  Text(
                    body,
                    style: sk.text.bodyMedium!.copyWith(
                      color: sk.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "6-day streak · Longest 14", grace days a datum doplnenia. Pri nulovom
/// streaku bez cisla straty (docs/01 5.5). V `simple_mode` sa nezobrazi.
class JourneyStreakSummary extends StatelessWidget {
  const JourneyStreakSummary({required this.summary, super.key});

  final StreakSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final formats = SakinaFormats(Localizations.localeOf(context));
    final refill = summary.state.graceRefillAt;
    final line = [
      if (summary.current > 0)
        localizeDigits(l10n.journeyStreak(summary.current), formats.digits),
      if (summary.longest > 0)
        l10n.journeyLongest(formats.number(summary.longest)),
    ].map(Bidi.isolate).join(' · ');
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (line.isNotEmpty) Text(line, style: sk.text.bodyLarge),
          Text(
            Bidi.isolate(
              localizeDigits(
                l10n.journeyGraceLeft(summary.graceLeft),
                formats.digits,
              ),
            ),
            style: sk.text.bodyMedium,
          ),
          if (refill != null)
            Text(
              l10n.journeyGraceRefill(
                formats.weekdayDate(refill.toLocalDateTime()),
              ),
              style: sk.text.bodyMedium!.copyWith(
                color: sk.colors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Mapa sur, podiel precitaneho, khatm a dalsi vers (A8.1).
class _QuranSection extends ConsumerWidget {
  const _QuranSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final formats = SakinaFormats(Localizations.localeOf(context));
    final counts = ref.watch(readCountsProvider);
    final surahs = ref.watch(surahsProvider).value ?? const [];
    final position = ref.watch(readingPositionProvider);
    final khatms = ref.watch(completedKhatmsProvider).value ?? 0;
    final names = {for (final s in surahs) s.id: s.nameTranslit};
    final map = counts.value;
    final next = nextReadingAyah(position.value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(l10n.journeyQuranTitle, style: sk.text.titleMedium),
              ),
            ),
            if (map != null)
              Text(
                l10n.journeyQuranPercent(formats.number(quranReadPercent(map))),
                style: sk.text.bodyMedium,
              ),
          ],
        ),
        const SizedBox(height: SkSpace.space8),
        if (map == null)
          const SkLoadingView(skeleton: SkSkeleton.list(lines: 2))
        else ...[
          Text(
            map.values.every((v) => v == 0)
                ? l10n.journeyQuranMapEmpty
                : l10n.journeyQuranMapLegend,
            style: sk.text.bodySmall!.copyWith(color: sk.colors.textSecondary),
          ),
          const SizedBox(height: SkSpace.space8),
          SurahMap(
            counts: map,
            names: names,
            onOpen: (s) => context.push(QuranRoutes.read(s, mode: 'browse')),
          ),
        ],
        const SizedBox(height: SkSpace.space8),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: SkSpace.space8,
          children: [
            Text(
              l10n.journeyKhatm(formats.number(khatms)),
              style: sk.text.bodyMedium,
            ),
            if (position.hasValue)
              TextButton(
                onPressed: () => context.push(
                  QuranRoutes.read(
                    next.surah,
                    ayahId: next.value,
                    mode: 'khatm',
                  ),
                ),
                child: Text(
                  l10n.journeyNextVerse(formats.ayahRef(next.surah, next.ayah)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SavedButton extends ConsumerWidget {
  const _SavedButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(savedCardsProvider(null)).value?.length ?? 0;
    final formats = SakinaFormats(Localizations.localeOf(context));
    return SkButton.outlined(
      label: localizeDigits(
        context.l10n.journeySavedButton(count),
        formats.digits,
      ),
      icon: Icons.bookmark_outline,
      expand: true,
      onPressed: () => context.push(JourneyRoutes.saved),
    );
  }
}
