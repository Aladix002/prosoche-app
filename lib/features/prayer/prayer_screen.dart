import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:prosoche/domain/prayer/prayer_schedule.dart';
import 'package:prosoche/features/calendar/calendar_routes.dart';
import 'package:prosoche/features/prayer/prayer_paths.dart';
import 'package:prosoche/features/prayer/prayer_providers.dart';
import 'package:prosoche/features/prayer/prayer_status_sheet.dart';
import 'package:prosoche/features/prayer/prayer_texts.dart';
import 'package:prosoche/features/prayer/prayer_view.dart';
import 'package:prosoche/features/shell/day_phase.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

/// Casy modlitieb a tracker (docs/02 A7.1). Route `/prayer`.
class PrayerScreen extends ConsumerStatefulWidget {
  const PrayerScreen({super.key});

  /// Dozadu max 30 dni (oznacenie qada spatne), dopredu max dnes.
  static const maxDaysBack = 30;

  @override
  ConsumerState<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends ConsumerState<PrayerScreen> {
  /// Zvoleny den; null = den trackera (po polnoci do fajr vcerajsok).
  LocalDate? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final config = ref.watch(prayerConfigProvider);
    final trackerDate = ref.watch(prayerTrackerDateProvider);
    final Widget body;
    if (config.hasError) {
      body = SkErrorState(
        title: l10n.prayerErrorTitle,
        body: l10n.prayerErrorBody,
        onRetry: () => ref.invalidate(prayerConfigProvider),
        secondaryLabel: l10n.prayerSettingsTooltip,
        onSecondary: () => unawaited(context.push(PrayerPaths.settings)),
      );
    } else if (!config.hasValue || !trackerDate.hasValue) {
      body = const Center(
        child: SkLoadingView(skeleton: SkSkeleton.list(lines: 6)),
      );
    } else {
      body = _PrayerDayView(
        config: config.requireValue,
        trackerDate: trackerDate.requireValue,
        date: _selected ?? trackerDate.requireValue,
        onDate: (d) => setState(() => _selected = d),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabPrayer),
        actions: [
          SkIconButton(
            icon: Icons.calendar_month_outlined,
            tooltip: l10n.prayerCalendarTooltip,
            onPressed: () => unawaited(context.push(CalendarRoutes.root)),
          ),
          SkIconButton(
            icon: Icons.explore_outlined,
            tooltip: l10n.prayerQiblaTooltip,
            onPressed: () => unawaited(context.push(PrayerPaths.qibla)),
          ),
          SkIconButton(
            icon: Icons.tune,
            tooltip: l10n.prayerSettingsTooltip,
            onPressed: () => unawaited(context.push(PrayerPaths.settings)),
          ),
        ],
      ),
      body: body,
    );
  }
}

class _PrayerDayView extends ConsumerWidget {
  const _PrayerDayView({
    required this.config,
    required this.trackerDate,
    required this.date,
    required this.onDate,
  });

  final PrayerConfig? config;
  final LocalDate trackerDate;
  final LocalDate date;
  final ValueChanged<LocalDate> onDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final today = ref.watch(localDateProvider);
    final now =
        ref.watch(minuteTickProvider).value ?? ref.read(appClockProvider).now();
    final log = ref.watch(prayerLogProvider(date)).value ?? const {};
    final schedule = config?.schedule;
    final rows = buildPrayerRows(
      date: date,
      now: now,
      log: log,
      schedule: schedule,
      estimated: ref.watch(estimatedPrayersProvider(date)).value ?? const {},
      notificationsOff:
          ref.watch(prayerNotificationsOffProvider).value ?? const {},
    );
    final health =
        ref.watch(prayerReminderHealthProvider).value ??
        PrayerReminderHealth.ok;
    final tzMismatch = ref.watch(prayerTimeZoneMismatchProvider).value ?? false;
    final earliest = today.addDays(-PrayerScreen.maxDaysBack);
    final last = trackerDate.isAfter(today) ? trackerDate : today;
    final estimated = rows.where((r) => r.estimated).toList();
    final gutter = SkSpace.gutterFor(MediaQuery.sizeOf(context).width);

    final children = <Widget>[
      // D-05: hlavicka s atmosferou podla casti dna (ako Dnes).
      SkAtmospherePanel(
        phase: watchDayPhase(ref),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: SkSpace.space8,
          vertical: SkSpace.space8,
        ),
        child: Column(
          children: [
            if (config case final c?)
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: SkSpace.space8,
                ),
                child: _LocationLine(city: c.location.city ?? c.location.tz),
              ),
            _DateNavigator(
              date: date,
              onPrevious: date.isAfter(earliest)
                  ? () => onDate(date.addDays(-1))
                  : null,
              onNext: date.isBefore(last)
                  ? () => onDate(date.addDays(1))
                  : null,
            ),
          ],
        ),
      ),
      if (date == trackerDate && trackerDate.isBefore(today))
        SkInlineBanner(message: l10n.prayerIshaContinues),
      if (tzMismatch)
        SkInlineBanner(
          variant: SkBannerVariant.warning,
          title: l10n.prayerTimeZoneTitle,
          message: l10n.prayerTimeZoneBody,
          actionLabel: l10n.prayerChooseCity,
          onAction: () => unawaited(context.push(PrayerPaths.citySearch)),
        ),
      if (schedule != null && !health.notificationsEnabled)
        SkInlineBanner(
          variant: SkBannerVariant.warning,
          title: l10n.prayerRemindersOffTitle,
          message: l10n.prayerRemindersOffBody,
          actionLabel: l10n.prayerRemindersTurnOn,
          onAction: () => unawaited(context.push(PrayerPaths.notifications)),
        ),
      if (config == null) ...[
        const _NoLocation(),
        Text(l10n.prayerNoTimesHint, style: context.sk.text.bodyMedium),
      ],
      for (final row in rows)
        if (row.prayer.isSalah)
          _PrayerRow(date: date, row: row, schedule: schedule)
        else
          _SunriseRow(row: row),
      if (estimated.isNotEmpty)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            icon: const Icon(Icons.info_outline),
            label: Text('* ${l10n.prayerEstimatedInfo}'),
            onPressed: () => unawaited(
              _showEstimated(context, estimated.first.prayer, config!),
            ),
          ),
        ),
      if (config case final c?) _InfoLine(config: c),
      if (schedule != null && !health.exactAlarms)
        SkInlineBanner(
          message: l10n.prayerExactInfo,
          actionLabel: l10n.prayerExactAllow,
          onAction: () => unawaited(context.push(PrayerPaths.notifications)),
        ),
    ];
    // Explicitny padding vypne automaticky SafeArea padding ListView, preto
    // sa spodny systemovy inset pricita rucne (edge-to-edge). V shelli ho
    // uz odobral Scaffold so SkNavBar (0), mimo shellu by posledny riadok
    // (metoda vypoctu) ostal pod navigacnou listou systemu (P-01).
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(
        gutter,
        SkSpace.space8,
        gutter,
        SkSpace.space24 + bottomInset,
      ),
      children: [
        for (final (i, w) in children.indexed) ...[
          if (i > 0) const SizedBox(height: SkSpace.space8),
          w,
        ],
      ],
    );
  }

  Future<void> _showEstimated(
    BuildContext context,
    Prayer prayer,
    PrayerConfig config,
  ) {
    final l10n = context.l10n;
    return showSkInfoSheet<void>(
      context,
      title: l10n.prayerEstimatedTitle,
      closeLabel: MaterialLocalizations.of(context).closeButtonTooltip,
      actions: [
        SkButton.secondary(
          label: l10n.prayerChangeRule,
          onPressed: () {
            Navigator.of(context).pop();
            unawaited(context.push(PrayerPaths.settings));
          },
        ),
      ],
      child: Text(
        l10n.prayerEstimatedBody(
          context.prayerName(prayer),
          context.highLatName(config.settings.highLatRule),
        ),
      ),
    );
  }
}

class _LocationLine extends StatelessWidget {
  const _LocationLine({required this.city});

  final String city;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final l10n = context.l10n;
    return Semantics(
      button: true,
      label: '$city, ${l10n.prayerLocationChange}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(SkRadius.sm),
        onTap: () => unawaited(context.push(PrayerPaths.citySearch)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: SkSpace.minTouchTarget),
          child: Row(
            children: [
              Icon(Icons.place_outlined, size: 20, color: sk.colors.primary),
              const SizedBox(width: SkSpace.space8),
              Flexible(child: Text(city, style: sk.text.titleMedium)),
              const SizedBox(width: SkSpace.space8),
              Text(
                l10n.prayerLocationChange,
                style: sk.text.labelLarge!.copyWith(color: sk.colors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateNavigator extends ConsumerWidget {
  const _DateNavigator({
    required this.date,
    required this.onPrevious,
    required this.onNext,
  });

  final LocalDate date;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final hijri = ref.watch(hijriDateProvider(date)).value;
    return Row(
      children: [
        SkIconButton(
          icon: Icons.chevron_left,
          tooltip: l10n.prayerPreviousDay,
          onPressed: onPrevious,
        ),
        Expanded(
          child: Column(
            children: [
              Semantics(
                header: true,
                child: Text(
                  context.formats.weekdayDate(date.toLocalDateTime()),
                  style: sk.text.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              if (hijri != null)
                InkWell(
                  borderRadius: BorderRadius.circular(SkRadius.sm),
                  onTap: () => unawaited(context.push(CalendarRoutes.root)),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: SkSpace.minTouchTarget,
                    ),
                    child: Center(
                      child: Text(
                        context.hijriDateLabel(hijri),
                        style: sk.text.bodyMedium!.copyWith(
                          color: sk.colors.accentText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SkIconButton(
          icon: Icons.chevron_right,
          tooltip: l10n.prayerNextDay,
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _NoLocation extends ConsumerWidget {
  const _NoLocation();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locator = ref.watch(deviceLocatorProvider);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.sk.colors.surfaceAlt,
        borderRadius: BorderRadius.circular(SkRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkEmptyState(
            title: l10n.prayerLocationTitle,
            body: l10n.prayerLocationBody,
            actionLabel: l10n.prayerChooseCity,
            onAction: () => unawaited(context.push(PrayerPaths.citySearch)),
          ),
          if (locator != null)
            SkButton.tertiary(
              label: l10n.prayerUseMyLocation,
              icon: Icons.my_location,
              onPressed: () => unawaited(context.push(PrayerPaths.citySearch)),
            ),
        ],
      ),
    );
  }
}

class _PrayerRow extends ConsumerWidget {
  const _PrayerRow({
    required this.date,
    required this.row,
    required this.schedule,
  });

  final LocalDate date;
  final PrayerRowModel row;
  final PrayerSchedule? schedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = row.prayer;
    final logged = row.status != null;
    final repo = ref.read(prayerRepositoryProvider);
    final name = context.prayerName(p);

    Future<void> set(PrayerStatus s) => repo.setStatus(date, p, s);
    Future<void> clear() async {
      final previous = row.status;
      await repo.clearStatus(date, p);
      if (!context.mounted || previous == null) return;
      showSkSnackbar(
        context,
        message: l10n.prayerLogCleared(name),
        actionLabel: SkUiStrings.of(context).undo,
        onAction: () => unawaited(set(previous)),
      );
    }

    Future<void> tap() async {
      if (logged) {
        await clear();
        return;
      }
      final now = ref.read(appClockProvider).now();
      final s = PrayerTracker.statusForTap(schedule, date, p, now);
      if (s != null) await set(s);
    }

    Future<void> sheet() async {
      final choice = await showPrayerStatusSheet(
        context,
        prayer: p,
        current: row.status,
        canLog: row.canLog,
      );
      switch (choice) {
        case null:
          return;
        case PrayerStatusChoice(:final status?):
          await set(status);
        case PrayerStatusChoice():
          await clear();
      }
    }

    final adjust = row.adjustMinutes;
    // Screen reader ma namiesto long pressu custom akcie (docs/01 8.1).
    return GestureDetector(
      excludeFromSemantics: true,
      onLongPress: () => unawaited(sheet()),
      child: SkPrayerRow(
        name: name,
        time: row.time == null ? '' : context.formats.time(row.time!),
        state: row.state,
        status: skStatus(row.status),
        relative: row.until == null ? null : context.untilLabel(row.until!),
        estimated: row.estimated,
        notificationOff: row.notificationOff,
        adjustedLabel: adjust == 0
            ? null
            : l10n.prayerAdjustedLabel(context.signedNumber(adjust)),
        onTrackerTap: row.canLog ? () => unawaited(tap()) : null,
        customActions: row.canLog
            ? {
                CustomSemanticsAction(label: l10n.prayerMarkOnTime): () =>
                    unawaited(set(PrayerStatus.onTime)),
                CustomSemanticsAction(label: l10n.prayerMarkLate): () =>
                    unawaited(set(PrayerStatus.late)),
                CustomSemanticsAction(label: l10n.prayerMarkMissed): () =>
                    unawaited(set(PrayerStatus.missed)),
                CustomSemanticsAction(label: l10n.prayerMarkQadaAction): () =>
                    unawaited(set(PrayerStatus.qada)),
                if (logged)
                  CustomSemanticsAction(label: l10n.prayerClearLog): () =>
                      unawaited(clear()),
              }
            : const {},
      ),
    );
  }
}

/// Vychod slnka: len cas, bez trackera (koniec casu fajr).
class _SunriseRow extends StatelessWidget {
  const _SunriseRow({required this.row});

  final PrayerRowModel row;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final next = row.state == SkPrayerRowState.next;
    final color = next ? sk.colors.onPrimaryContainer : sk.colors.textSecondary;
    final name = context.prayerName(row.prayer);
    final time = context.formats.time(row.time!);
    final relative = next ? context.untilLabel(row.until!) : null;
    return MergeSemantics(
      child: Container(
        constraints: const BoxConstraints(minHeight: SkSpace.minTouchTarget),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: SkSpace.space16,
          vertical: SkSpace.space8,
        ),
        decoration: BoxDecoration(
          color: next ? sk.colors.primaryContainer : null,
          borderRadius: BorderRadius.circular(SkRadius.md),
        ),
        child: Wrap(
          spacing: SkSpace.space12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 88),
              child: Text(
                name,
                style: sk.text.bodyLarge!.copyWith(color: color),
              ),
            ),
            Text(
              time,
              style: ProsocheTypography.tabular(
                sk.text.bodyLarge!.copyWith(color: color),
              ),
            ),
            if (relative != null)
              Text(relative, style: sk.text.bodyMedium!.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.config});

  final PrayerConfig config;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = config.settings;
    final adjusted = s.adjust.values.where((m) => m != 0).length;
    final text = l10n.prayerInfoLine(
      context.methodName(s.method),
      context.asrShort(s.asr),
      adjusted == 0
          ? l10n.prayerInfoNoAdjust
          : l10n.prayerInfoAdjusted(adjusted),
    );
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(SkRadius.sm),
        onTap: () => unawaited(context.push(PrayerPaths.settings)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: SkSpace.minTouchTarget),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              localizeDigits(text, context.formats.digits),
              style: context.sk.text.bodyMedium!.copyWith(
                color: context.sk.colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
