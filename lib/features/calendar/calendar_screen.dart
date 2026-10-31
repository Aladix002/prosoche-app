import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/calendar/calendar.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/features/calendar/calendar_providers.dart';
import 'package:prosoche/features/calendar/hijri_offset.dart';
import 'package:prosoche/features/prayer/prayer_texts.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

/// Hijri mesiac `(rok, mesiac)`.
typedef HijriMonthKey = (int, int);

/// Posun hijri mesiaca o [delta] mesiacov.
HijriMonthKey shiftHijriMonth(HijriMonthKey ym, int delta) {
  final index = ym.$1 * 12 + (ym.$2 - 1) + delta;
  return (index ~/ 12, index % 12 + 1);
}

int _monthIndex(HijriMonthKey ym) => ym.$1 * 12 + ym.$2 - 1;

/// Hijri kalendar s eventmi (docs/02 A9). Route `/calendar`.
///
/// [initialMonth] z `?hm=1448-05` alebo `?month=2026-10`; null = mesiac
/// dneska. Listovanie +-12 mesiacov od dneska.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({this.initialMonth, this.initialGregorian, super.key});

  final HijriMonthKey? initialMonth;

  /// Gregoriansky mesiac: zobrazi sa hijri mesiac jeho prveho dna.
  final (int, int)? initialGregorian;

  static const maxMonths = 12;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  HijriMonthKey? _shown;

  HijriMonthKey _clamp(HijriMonthKey ym, HijriMonthKey today) {
    final d = _monthIndex(ym) - _monthIndex(today);
    if (d.abs() <= CalendarScreen.maxMonths) return ym;
    return today;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = ref.watch(localDateProvider);
    final hijriToday = ref.watch(hijriDateProvider(today));
    final Widget body;
    if (hijriToday.hasError) {
      body = _CalendarError(onRetry: () => ref.invalidate(hijriDateProvider));
    } else if (!hijriToday.hasValue) {
      body = const Center(child: SkLoadingView());
    } else {
      final h = hijriToday.requireValue;
      final current = (h.year, h.month);
      final initial = widget.initialMonth ?? _fromGregorian(current);
      final shown = _clamp(_shown ?? initial, current);
      final offset = _monthIndex(shown) - _monthIndex(current);
      body = _MonthView(
        month: shown,
        today: today,
        onPrevious: offset > -CalendarScreen.maxMonths
            ? () => setState(() => _shown = shiftHijriMonth(shown, -1))
            : null,
        onNext: offset < CalendarScreen.maxMonths
            ? () => setState(() => _shown = shiftHijriMonth(shown, 1))
            : null,
      );
    }
    return Scaffold(
      appBar: skAppBar(context, title: l10n.calendarTitle),
      body: body,
    );
  }

  HijriMonthKey _fromGregorian(HijriMonthKey fallback) {
    final g = widget.initialGregorian;
    if (g == null) return fallback;
    try {
      final h = IslamicCalendar().hijriOf(LocalDate(g.$1, g.$2, 1));
      return (h.year, h.month);
    } on Object {
      return fallback;
    }
  }
}

class _CalendarError extends StatelessWidget {
  const _CalendarError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SkErrorState(
    title: context.l10n.calendarErrorTitle,
    body: context.l10n.calendarErrorBody,
    onRetry: onRetry,
  );
}

class _MonthView extends ConsumerWidget {
  const _MonthView({
    required this.month,
    required this.today,
    required this.onPrevious,
    required this.onNext,
  });

  final HijriMonthKey month;
  final LocalDate today;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final data = ref.watch(hijriMonthProvider(month));
    final offset = ref.watch(hijriOffsetProvider).value ?? 0;
    final gutter = SkSpace.gutterFor(MediaQuery.sizeOf(context).width);

    final header = Row(
      children: [
        SkIconButton(
          icon: Icons.chevron_left,
          tooltip: l10n.calendarPreviousMonth,
          onPressed: onPrevious,
        ),
        Expanded(
          child: Column(
            children: [
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  context.hijriMonthLabel(month.$1, month.$2),
                  textAlign: TextAlign.center,
                  style: sk.text.titleLarge,
                ),
              ),
              if (data.value case final m?)
                Text(
                  _gregorianRange(context, m),
                  textAlign: TextAlign.center,
                  style: sk.text.bodyMedium!.copyWith(
                    color: sk.colors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        SkIconButton(
          icon: Icons.chevron_right,
          tooltip: l10n.calendarNextMonth,
          onPressed: onNext,
        ),
      ],
    );

    final List<Widget> content;
    if (data.hasError) {
      content = [
        _CalendarError(
          onRetry: () => ref.invalidate(hijriMonthProvider(month)),
        ),
      ];
    } else if (!data.hasValue) {
      content = [const SkLoadingView(skeleton: SkSkeleton.list(lines: 5))];
    } else {
      final m = data.requireValue;
      content = [
        _MonthGrid(month: m, today: today),
        const SizedBox(height: SkSpace.space24),
        if (m.eventIds.isEmpty)
          _EmptyMonth(month: month)
        else
          _EventList(month: m),
      ];
    }

    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(
        gutter,
        SkSpace.space8,
        gutter,
        SkSpace.space24,
      ),
      children: [
        header,
        const SizedBox(height: SkSpace.space8),
        ...content,
        const SizedBox(height: SkSpace.space16),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: SkSpace.space8,
          children: [
            Text(
              l10n.calendarOffsetLine(context.hijriOffsetLabel(offset)),
              style: sk.text.bodyMedium,
            ),
            TextButton(
              onPressed: () => unawaited(showHijriOffsetSheet(context)),
              child: Text(l10n.calendarOffsetChange),
            ),
          ],
        ),
      ],
    );
  }

  static String _gregorianRange(BuildContext context, CalendarMonth m) {
    final tag = Localizations.localeOf(context).toLanguageTag();
    final first = m.days.first.date.toLocalDateTime();
    final last = m.days.last.date.toLocalDateTime();
    final String raw;
    if (first.year == last.year && first.month == last.month) {
      raw = DateFormat.yMMMM(tag).format(first);
    } else if (first.year == last.year) {
      raw =
          '${DateFormat.MMM(tag).format(first)} – '
          '${DateFormat.yMMM(tag).format(last)}';
    } else {
      raw =
          '${DateFormat.yMMM(tag).format(first)} – '
          '${DateFormat.yMMM(tag).format(last)}';
    }
    return localizeDigits(raw, context.formats.digits);
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.today});

  final CalendarMonth month;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final sk = context.sk;
    final first = material.firstDayOfWeekIndex;
    final weekdays = [
      for (var i = 0; i < 7; i++) material.narrowWeekdays[(first + i) % 7],
    ];
    // DateTime.weekday: po=1..ne=7; MaterialLocalizations: ne=0.
    final leading = (month.days.first.date.weekday % 7 - first) % 7;
    final cells = <Widget>[
      for (final w in weekdays)
        ExcludeSemantics(
          child: Center(
            child: Text(
              w,
              style: sk.text.labelMedium!.copyWith(
                color: sk.colors.textSecondary,
              ),
            ),
          ),
        ),
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (final d in month.days) _DayCell(day: d, today: d.date == today),
    ];
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      final row = cells.sublist(i, i + 7 > cells.length ? cells.length : i + 7);
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final c in row) Expanded(child: c),
            for (var k = row.length; k < 7; k++)
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      );
    }
    return Column(children: rows);
  }
}

class _DayCell extends ConsumerWidget {
  const _DayCell({required this.day, required this.today});

  final CalendarDay day;
  final bool today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final c = sk.colors;
    final hasEvents = day.eventIds.isNotEmpty;
    final formats = context.formats;
    final label = [
      context.hijriDateLabel(day.hijri),
      formats.weekdayDate(day.date.toLocalDateTime()),
      if (today) l10n.calendarToday,
      if (hasEvents) l10n.calendarHasEvents,
    ].join(', ');
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(SkRadius.sm),
        onTap: () => unawaited(_showDay(context)),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          margin: const EdgeInsetsDirectional.all(SkSpace.space2),
          decoration: BoxDecoration(
            color: today ? c.primaryContainer : null,
            border: today ? Border.all(color: c.primary, width: 2) : null,
            borderRadius: BorderRadius.circular(SkRadius.sm),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formats.number(day.hijri.day),
                style: sk.text.titleMedium!.copyWith(
                  color: today ? c.onPrimaryContainer : c.textPrimary,
                ),
              ),
              Text(
                formats.number(day.date.day),
                style: sk.text.labelSmall!.copyWith(
                  color: today ? c.onPrimaryContainer : c.textSecondary,
                ),
              ),
              // Bodka eventu: tvar, nie len farba (docs/01 8.5).
              SizedBox.square(
                dimension: 8,
                child: hasEvents
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.accentText,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDay(BuildContext context) => showSkInfoSheet<void>(
    context,
    title: context.hijriDateLabel(day.hijri),
    closeLabel: MaterialLocalizations.of(context).closeButtonTooltip,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.formats.weekdayDate(day.date.toLocalDateTime()),
          style: context.sk.text.bodyMedium,
        ),
        const SizedBox(height: SkSpace.space16),
        if (day.eventIds.isEmpty)
          Text(context.l10n.calendarDayEmpty)
        else
          for (final id in day.eventIds) _EventText(eventId: id, full: true),
      ],
    ),
  );
}

/// Titulok (a v sheete dna aj popis) eventu z `islamic_event_text`.
class _EventText extends ConsumerWidget {
  const _EventText({required this.eventId, this.full = false, this.trailing});

  final String eventId;
  final bool full;
  final String? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(calendarEventTextProvider(eventId)).value;
    if (text == null) return const SizedBox.shrink();
    final sk = context.sk;
    final fallback = text.lang != Localizations.localeOf(context).languageCode;
    final body = text.body;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: SkSpace.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: SkSpace.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(text.title, style: sk.text.titleMedium),
              if (fallback) SkTag(label: context.l10n.calendarEnglishTag),
            ],
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: sk.text.bodyMedium!.copyWith(
                color: sk.colors.textSecondary,
              ),
            ),
          if (full && body != null) ...[
            const SizedBox(height: SkSpace.space4),
            Text(body, style: sk.text.bodyLarge),
          ],
        ],
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({required this.month});

  final CalendarMonth month;

  @override
  Widget build(BuildContext context) {
    final formats = context.formats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            context.l10n.calendarEventsTitle,
            style: context.sk.text.titleSmall,
          ),
        ),
        const SizedBox(height: SkSpace.space8),
        for (final id in month.eventIds)
          _EventText(
            eventId: id,
            trailing: [
              for (final d in month.days)
                if (d.eventIds.contains(id)) formats.number(d.hijri.day),
            ].join(', '),
          ),
      ],
    );
  }
}

class _EmptyMonth extends ConsumerWidget {
  const _EmptyMonth({required this.month});

  final HijriMonthKey month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final next = ref.watch(nextCalendarEventProvider(month)).value;
    final title = next == null
        ? null
        : ref.watch(calendarEventTextProvider(next.eventId)).value?.title;
    return SkEmptyState(
      title: l10n.calendarEmptyTitle,
      body: next == null || title == null
          ? null
          : l10n.calendarEmptyNext(
              title,
              context.formats.date(next.date.toLocalDateTime()),
            ),
    );
  }
}
