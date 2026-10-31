import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/domain/streak/streak.dart';
import 'package:prosoche/features/cards/card_parts.dart';
import 'package:prosoche/features/journey/card_pager.dart';
import 'package:prosoche/features/journey/journey_calendar.dart';
import 'package:prosoche/features/journey/journey_providers.dart';
import 'package:prosoche/ui/ui.dart';

/// Detail dna (docs/02 A8.2): datum, stav dna a denna sada (x/N, cas
/// dokoncenia, prehlad kariet bez zapisu `seen`). Len citanie, nic sa
/// negeneruje ani nezapisuje.
class JourneyDayScreen extends ConsumerWidget {
  const JourneyDayScreen({required this.date, super.key});

  final LocalDate date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final log = ref.watch(dayLogProvider((date.year, date.month)));
    final set = ref.watch(journeyDaySetProvider(date));
    final Widget body;
    if ((log.hasError && !log.isLoading) || (set.hasError && !set.isLoading)) {
      body = SkErrorState(
        title: l10n.journeyErrorTitle,
        body: l10n.journeyErrorBody,
        onRetry: () => ref
          ..invalidate(dayLogProvider((date.year, date.month)))
          ..invalidate(journeyDaySetProvider(date)),
      );
    } else if (!log.hasValue || !set.hasValue) {
      body = const Center(child: SkLoadingView());
    } else {
      body = _DayDetail(
        date: date,
        entry: log.requireValue.where((e) => e.date == date).firstOrNull,
        set: set.value,
      );
    }
    return Scaffold(
      appBar: skAppBar(
        context,
        title: context.formats.date(date.toLocalDateTime()),
      ),
      body: body,
    );
  }
}

class _DayDetail extends ConsumerWidget {
  const _DayDetail({required this.date, required this.entry, this.set});

  final LocalDate date;
  final DayLogEntry? entry;
  final DailySetState? set;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final today = ref.watch(localDateProvider);
    final todayDone = ref.watch(streakProvider).value?.todayDone ?? false;
    final simple = ref.watch(settingOf(SettingsKeys.simpleMode)).value != false;
    final mark = journeyDayMark(
      date: date,
      today: today,
      entry: entry,
      todayDone: date == today && todayDone,
      simple: simple,
    );
    final gutter = SkSpace.gutterFor(MediaQuery.sizeOf(context).width);
    final s = set;
    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(
        gutter,
        SkSpace.space16,
        gutter,
        SkSpace.space32,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(
            context.formats.weekdayDate(date.toLocalDateTime()),
            style: sk.text.headlineSmall,
          ),
        ),
        const SizedBox(height: SkSpace.space16),
        if (mark != JourneyDayMark.none || date == today)
          MergeSemantics(
            child: Row(
              children: [
                JourneyDayMarker(mark: mark),
                const SizedBox(width: SkSpace.space8),
                Expanded(
                  child: Text(
                    l10n.journeyDayState(mark.wire(today: date == today)),
                    style: sk.text.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        if (mark == JourneyDayMark.done)
          for (final source in DaySource.values)
            if (entry?.sources.contains(source) ?? false)
              Text(
                l10n.journeyDaySources(source.wire),
                style: sk.text.bodyMedium,
              ),
        const SizedBox(height: SkSpace.space24),
        if (s == null)
          Text(l10n.journeyDayNoSet, style: sk.text.bodyLarge)
        else ...[
          Text(
            l10n.journeyDaySet(
              context.formats.number(s.seenContentCount),
              context.formats.number(s.n),
            ),
            style: sk.text.bodyLarge,
          ),
          if (s.completedAt case final at?)
            Text(
              l10n.journeyDayCompletedAt(context.formats.time(at)),
              style: sk.text.bodyMedium!.copyWith(
                color: sk.colors.textSecondary,
              ),
            ),
          const SizedBox(height: SkSpace.space12),
          SkButton.secondary(
            label: l10n.journeyDayViewCards,
            icon: Icons.style_outlined,
            onPressed: () => unawaited(
              openJourneyCards(
                context,
                cards: [for (final c in s.set.contentCards) c.cardId],
                date: today,
                cardsCount: s.n,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
