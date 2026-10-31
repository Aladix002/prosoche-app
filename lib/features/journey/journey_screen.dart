import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/journey/intention_dialog.dart';
import 'package:prosoche/features/journey/journey_calendar.dart';
import 'package:prosoche/features/journey/journey_providers.dart';
import 'package:prosoche/features/journey/journey_routes.dart';
import 'package:prosoche/features/shell/settings_button.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

/// Moja cesta (docs/02 A8.1): umysel, kalendar dni, streak a grace days
/// (skryte v `simple_mode`), ulozene karty. Vsetko je
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
          const JourneyIntention(),
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
    final formats = ProsocheFormats(Localizations.localeOf(context));
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

class _SavedButton extends ConsumerWidget {
  const _SavedButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(savedCardsProvider(null)).value?.length ?? 0;
    final formats = ProsocheFormats(Localizations.localeOf(context));
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
