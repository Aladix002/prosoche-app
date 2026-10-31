import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/streak/streak.dart';
import 'package:sakina/ui/i18n/i18n.dart';
import 'package:sakina/ui/ui.dart';

/// Gregoriansky mesiac `(rok, mesiac)` osobneho kalendara.
typedef JourneyMonth = (int, int);

/// Posun mesiaca o [delta].
JourneyMonth shiftJourneyMonth(JourneyMonth m, int delta) {
  final index = m.$1 * 12 + (m.$2 - 1) + delta;
  return (index ~/ 12, index % 12 + 1);
}

/// Pocet mesiacov od [from] po [to] (zaporny, ak je [to] skor).
int journeyMonthsBetween(JourneyMonth from, JourneyMonth to) =>
    (to.$1 * 12 + to.$2) - (from.$1 * 12 + from.$2);

/// Znacka dna v kalendari (docs/01 3.2 `SkCalendarDayCell`). Tvar aj
/// farba, nikdy cervena (docs/01 1.4).
enum JourneyDayMark {
  /// Splneny den (sada alebo aspon 1 quest).
  done,

  /// Vynechany den pokryty grace dnom.
  grace,

  /// Nesplneny den, neutralne.
  missed,

  /// Ospravedlneny den (navrh D8, docs/03 6.5).
  excused,

  /// Bez zaznamu (pred prvym dnom, dnesok zatial nesplneny).
  none,

  /// Buduci den, neda sa otvorit.
  future;

  /// Hodnota pre `journeyDayState` (ARB select).
  String wire({required bool today}) => this == none && today ? 'today' : name;
}

/// Znacka dna [date]. `day_log` ma len uzavrete dni, dnesok sa berie
/// zo `StreakSummary.todayDone`. [simple] (`simple_mode`) ukaze len
/// splnene dni (A8.1).
JourneyDayMark journeyDayMark({
  required LocalDate date,
  required LocalDate today,
  required bool todayDone,
  required bool simple,
  DayLogEntry? entry,
}) {
  if (date.isAfter(today)) return JourneyDayMark.future;
  if (date == today && todayDone) return JourneyDayMark.done;
  final status = entry?.status;
  if (status == null) return JourneyDayMark.none;
  if (status == DayStatus.done) return JourneyDayMark.done;
  if (simple) return JourneyDayMark.none;
  return switch (status) {
    DayStatus.done => JourneyDayMark.done,
    DayStatus.grace => JourneyDayMark.grace,
    DayStatus.missed => JourneyDayMark.missed,
    DayStatus.excused => JourneyDayMark.excused,
  };
}

/// Mesacny kalendar dni (A8.1): hlavicka s listovanim, dni v tyzdni,
/// bunky so znackou a legenda textom.
class JourneyCalendar extends StatelessWidget {
  const JourneyCalendar({
    required this.month,
    required this.today,
    required this.entries,
    required this.todayDone,
    required this.simple,
    required this.onPrevious,
    required this.onNext,
    required this.onOpenDay,
    super.key,
  });

  final JourneyMonth month;
  final LocalDate today;
  final List<DayLogEntry> entries;
  final bool todayDone;
  final bool simple;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<LocalDate> onOpenDay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final tag = Localizations.localeOf(context).toLanguageTag();
    final title = localizeDigits(
      DateFormat.yMMMM(tag).format(DateTime(month.$1, month.$2)),
      SakinaFormats(Localizations.localeOf(context)).digits,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                liveRegion: true,
                child: Text(title, style: sk.text.titleMedium),
              ),
            ),
            SkIconButton(
              icon: Icons.chevron_left,
              tooltip: l10n.journeyPreviousMonth,
              onPressed: onPrevious,
            ),
            SkIconButton(
              icon: Icons.chevron_right,
              tooltip: l10n.journeyNextMonth,
              onPressed: onNext,
            ),
          ],
        ),
        const SizedBox(height: SkSpace.space4),
        _grid(context),
        const SizedBox(height: SkSpace.space8),
        JourneyLegend(simple: simple),
      ],
    );
  }

  Widget _grid(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final sk = context.sk;
    final first = material.firstDayOfWeekIndex;
    final byDate = {for (final e in entries) e.date: e};
    final days = DateUtils.getDaysInMonth(month.$1, month.$2);
    final firstDate = LocalDate(month.$1, month.$2, 1);
    // DateTime.weekday: po=1..ne=7; MaterialLocalizations: ne=0.
    final leading = (firstDate.weekday % 7 - first) % 7;
    final cells = <Widget>[
      for (var i = 0; i < 7; i++)
        ExcludeSemantics(
          child: Center(
            child: Text(
              material.narrowWeekdays[(first + i) % 7],
              style: sk.text.labelMedium!.copyWith(
                color: sk.colors.textSecondary,
              ),
            ),
          ),
        ),
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var d = 1; d <= days; d++)
        _DayCell(
          date: LocalDate(month.$1, month.$2, d),
          isToday: LocalDate(month.$1, month.$2, d) == today,
          mark: journeyDayMark(
            date: LocalDate(month.$1, month.$2, d),
            today: today,
            entry: byDate[LocalDate(month.$1, month.$2, d)],
            todayDone: todayDone,
            simple: simple,
          ),
          onTap: onOpenDay,
        ),
    ];
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      final row = cells.sublist(i, math.min(i + 7, cells.length));
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

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isToday,
    required this.mark,
    required this.onTap,
  });

  final LocalDate date;
  final bool isToday;
  final JourneyDayMark mark;
  final ValueChanged<LocalDate> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final c = sk.colors;
    final formats = SakinaFormats(Localizations.localeOf(context));
    final future = mark == JourneyDayMark.future;
    final done = mark == JourneyDayMark.done;
    final label = [
      formats.weekdayDate(date.toLocalDateTime()),
      if (isToday && mark != JourneyDayMark.none) l10n.journeyDayState('today'),
      l10n.journeyDayState(mark.wire(today: isToday)),
    ].join(', ');
    return Semantics(
      container: true,
      button: !future,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(SkRadius.sm),
        onTap: future ? null : () => onTap(date),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: SkSpace.minTouchTarget),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(SkSpace.space2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: done ? c.primaryContainer : null,
                border: isToday ? Border.all(color: c.primary, width: 2) : null,
                borderRadius: BorderRadius.circular(SkRadius.sm),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  vertical: SkSpace.space4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formats.number(date.day),
                      textAlign: TextAlign.center,
                      style: sk.text.bodyMedium!.copyWith(
                        color: future
                            ? c.textDisabled
                            : done
                            ? c.onPrimaryContainer
                            : c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: SkSpace.space2),
                    JourneyDayMarker(mark: mark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Maly symbol stavu dna (12 dp): plny kruh = splneny, polovica = grace,
/// bodka = nesplneny, prazdny kruh = ospravedlneny.
class JourneyDayMarker extends StatelessWidget {
  const JourneyDayMarker({required this.mark, super.key});

  final JourneyDayMark mark;

  static const size = 12.0;

  @override
  Widget build(BuildContext context) {
    final c = context.sk.colors;
    return ExcludeSemantics(
      child: CustomPaint(
        size: const Size.square(size),
        painter: _MarkerPainter(
          mark: mark,
          primary: c.primary,
          neutral: c.textTertiary,
        ),
      ),
    );
  }
}

class _MarkerPainter extends CustomPainter {
  _MarkerPainter({
    required this.mark,
    required this.primary,
    required this.neutral,
  });

  final JourneyDayMark mark;
  final Color primary;
  final Color neutral;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final fill = Paint()..style = PaintingStyle.fill;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    switch (mark) {
      case JourneyDayMark.done:
        canvas.drawCircle(center, r, fill..color = primary);
      case JourneyDayMark.grace:
        canvas
          ..drawCircle(center, r - 0.75, ring..color = primary)
          ..drawArc(
            Rect.fromCircle(center: center, radius: r),
            0,
            math.pi,
            true,
            fill..color = primary,
          );
      case JourneyDayMark.missed:
        canvas.drawCircle(center, r / 3, fill..color = neutral);
      case JourneyDayMark.excused:
        canvas.drawCircle(center, r - 0.75, ring..color = neutral);
      case JourneyDayMark.none:
      case JourneyDayMark.future:
        break;
    }
  }

  @override
  bool shouldRepaint(_MarkerPainter old) =>
      old.mark != mark || old.primary != primary || old.neutral != neutral;
}

/// Legenda kalendara textom (docs/01 8.5: nie len farba).
class JourneyLegend extends StatelessWidget {
  const JourneyLegend({required this.simple, super.key});

  final bool simple;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final items = [
      (JourneyDayMark.done, l10n.journeyLegendDone),
      if (!simple) ...[
        (JourneyDayMark.grace, l10n.journeyLegendGrace),
        (JourneyDayMark.missed, l10n.journeyLegendMissed),
      ],
    ];
    return Wrap(
      spacing: SkSpace.space16,
      runSpacing: SkSpace.space4,
      children: [
        for (final (mark, label) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              JourneyDayMarker(mark: mark),
              const SizedBox(width: SkSpace.space4),
              Flexible(
                child: Text(
                  label,
                  style: sk.text.bodySmall!.copyWith(
                    color: sk.colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
