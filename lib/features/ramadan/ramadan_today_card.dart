import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/flags/feature_flags.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/ramadan/ramadan.dart';
import 'package:sakina/features/ramadan/ramadan_providers.dart';
import 'package:sakina/features/settings/settings_routes.dart';
import 'package:sakina/ui/i18n/i18n.dart';
import 'package:sakina/ui/ui.dart';

/// Karta Ramadanu na obrazovke Dnes (F-08, docs/04 1.3, 1.13 bod 1).
///
/// Bod zapojenia pre F-02: jeden riadok `const RamadanTodayCard()` pod
/// chipom dalsej modlitby. Pri vypnutom `FEATURE_RAMADAN_LIGHT`, mimo
/// sezony a pocas nacitania nezabera miesto (`SizedBox.shrink`).
class RamadanTodayCard extends ConsumerWidget {
  const RamadanTodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(featureFlagsProvider).ramadanLight) {
      return const SizedBox.shrink();
    }
    final async = ref.watch(ramadanStateProvider);
    if (async.hasError && !async.hasValue) {
      return _padded(
        SkInlineBanner(
          variant: SkBannerVariant.error,
          message: context.l10n.errorGeneric,
          actionLabel: SkUiStrings.of(context).tryAgain,
          onAction: () => ref.invalidate(ramadanStateProvider),
        ),
      );
    }
    final state = async.value;
    final season = state?.season;
    if (state == null || season == null) return const SizedBox.shrink();
    final actions = ref.read(ramadanActionsProvider);
    final child = switch (state.phase) {
      RamadanPhase.inactive => const SizedBox.shrink(),
      RamadanPhase.upcoming || RamadanPhase.confirmed => RamadanInfoView(
        startDate: season.startDate,
        confirmed: state.phase == RamadanPhase.confirmed,
      ),
      RamadanPhase.awaitingConfirmation => RamadanQuestionView(
        question: context.l10n.ramadanStartQuestion,
        answers: [
          (
            context.l10n.ramadanStartTomorrow,
            () => actions.confirmStart(season, 1),
          ),
          (
            context.l10n.ramadanStartDayAfter,
            () => actions.confirmStart(season, 2),
          ),
          (
            context.l10n.ramadanUseCalculation,
            () => actions.confirmStart(season, null),
          ),
        ],
      ),
      RamadanPhase.active || RamadanPhase.ending || RamadanPhase.eid => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.phase != RamadanPhase.eid)
            RamadanCountdownView(
              night: state.night,
              isNight: state.isNight,
              countdown: state.countdown,
              onSetLocation: () =>
                  unawaited(context.push('${SettingsRoutes.prayer}/location')),
            ),
          if (state.phase == RamadanPhase.ending) ...[
            const SizedBox(height: SkSpace.space8),
            RamadanQuestionView(
              question: context.l10n.ramadanEndQuestion,
              answers: [
                (
                  context.l10n.ramadanAnswerYes,
                  () => actions.confirmEnd(season, eidTomorrow: true),
                ),
                (
                  context.l10n.ramadanAnswerNo,
                  () => actions.confirmEnd(season, eidTomorrow: false),
                ),
                (
                  context.l10n.ramadanUseCalculation,
                  () => actions.confirmEnd(season, eidTomorrow: null),
                ),
              ],
            ),
          ],
          if (state.trackerDay case final day?) ...[
            const SizedBox(height: SkSpace.space8),
            _FastLog(day: day, dayNumber: season.dayOf(day)!),
          ],
        ],
      ),
    };
    if (child is SizedBox) return child;
    return _padded(child);
  }

  static Widget _padded(Widget child) => Padding(
    padding: const EdgeInsetsDirectional.only(top: SkSpace.space16),
    child: child,
  );
}

class _FastLog extends ConsumerWidget {
  const _FastLog({required this.day, required this.dayNumber});

  final LocalDate day;
  final int dayNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(fastEntryProvider(day));
    return FastLogView(
      dayNumber: dayNumber,
      selected: entry.value,
      onSelected: entry.hasValue
          ? (e) => unawaited(ref.read(ramadanActionsProvider).setFast(day, e))
          : null,
    );
  }
}

SakinaFormats _formats(BuildContext context) =>
    SakinaFormats(Localizations.localeOf(context));

/// "in 2 h 14 min" / "in 12 min" (cislice podla jazyka UI).
String ramadanDurationLabel(BuildContext context, Duration d) {
  final l10n = context.l10n;
  final minutes = (d.inSeconds / 60).ceil().clamp(0, 1 << 20);
  final text = minutes >= 60
      ? l10n.ramadanInHoursMinutes(minutes ~/ 60, minutes % 60)
      : l10n.ramadanInMinutes(minutes);
  return localizeDigits(text, _formats(context).digits);
}

class _CardBox extends StatelessWidget {
  const _CardBox({required this.child, this.emphasis = false});

  final Widget child;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final c = context.sk.colors;
    return Container(
      decoration: BoxDecoration(
        color: emphasis ? c.primaryContainer : c.surfaceAlt,
        borderRadius: BorderRadius.circular(SkRadius.md),
      ),
      padding: const EdgeInsetsDirectional.all(SkSpace.space16),
      child: child,
    );
  }
}

/// Odpocet suhur/iftar (docs/04 1.3): "Iftar at 17:02 · in 2 h 14 min".
class RamadanCountdownView extends StatelessWidget {
  const RamadanCountdownView({
    required this.night,
    required this.isNight,
    required this.countdown,
    this.onSetLocation,
    super.key,
  });

  /// Cislo islamskeho dna Ramadanu; null = noc pred 1. dnom nie je
  /// (nemalo by nastat v aktivnej faze).
  final int? night;
  final bool isNight;

  /// Null = bez polohy (vyzva na nastavenie).
  final FastingCountdown? countdown;
  final VoidCallback? onSetLocation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final formats = _formats(context);
    final n = night;
    final header = n == null
        ? null
        : localizeDigits(
            isNight ? l10n.ramadanNightLabel(n) : l10n.ramadanDayLabel(n),
            formats.digits,
          );
    final cd = countdown;
    final onColor = sk.colors.onPrimaryContainer;
    return _CardBox(
      emphasis: cd != null,
      child: Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (header != null)
              Text(
                header,
                style: sk.text.labelLarge!.copyWith(
                  color: cd != null ? onColor : sk.colors.textSecondary,
                ),
              ),
            if (cd == null) ...[
              const SizedBox(height: SkSpace.space4),
              Text(l10n.ramadanSetLocation, style: sk.text.bodyMedium),
              if (onSetLocation != null)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: onSetLocation,
                    child: Text(l10n.ramadanSetLocationAction),
                  ),
                ),
            ] else ...[
              const SizedBox(height: SkSpace.space4),
              Text(switch (cd.moment) {
                FastingMoment.suhurEnd => l10n.ramadanSuhurEndsAt(
                  formats.time(cd.at),
                ),
                FastingMoment.iftar => l10n.ramadanIftarAt(formats.time(cd.at)),
              }, style: sk.text.headlineSmall!.copyWith(color: onColor)),
              Text(
                ramadanDurationLabel(context, cd.left),
                style: sk.text.bodyLarge!.copyWith(color: onColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Info pred Ramadanom: ocakavany alebo potvrdeny zaciatok.
class RamadanInfoView extends StatelessWidget {
  const RamadanInfoView({
    required this.startDate,
    required this.confirmed,
    super.key,
  });

  final LocalDate startDate;
  final bool confirmed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final date = _formats(context).date(startDate.toLocalDateTime());
    return _CardBox(
      child: Text(
        confirmed
            ? l10n.ramadanStartsOn(date)
            : l10n.ramadanExpectedStart(date),
        style: context.sk.text.bodyMedium,
      ),
    );
  }
}

/// Otazka so stlacitelnymi odpovedami (zaciatok alebo koniec Ramadanu).
class RamadanQuestionView extends StatelessWidget {
  const RamadanQuestionView({
    required this.question,
    required this.answers,
    super.key,
  });

  final String question;
  final List<(String, Future<void> Function())> answers;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(question, style: sk.text.titleMedium),
          ),
          const SizedBox(height: SkSpace.space12),
          for (final (i, (label, onTap)) in answers.indexed) ...[
            if (i > 0) const SizedBox(height: SkSpace.space8),
            if (i == 0)
              SkButton.primary(
                label: label,
                expand: true,
                onPressed: () => unawaited(onTap()),
              )
            else
              SkButton.secondary(
                label: label,
                expand: true,
                onPressed: () => unawaited(onTap()),
              ),
          ],
        ],
      ),
    );
  }
}

/// Jednoduchy zaznam postu: Fasted / Not today / Excused (bez dovodu,
/// bez hodnotenia a cervenej farby, docs/04 1.1, 1.4).
class FastLogView extends StatelessWidget {
  const FastLogView({
    required this.dayNumber,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final int dayNumber;
  final FastEntry? selected;

  /// Opatovny tap na zvolenu moznost zaznam zmaze (null). Null = nacitava.
  final ValueChanged<FastEntry?>? onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final title = localizeDigits(
      l10n.ramadanFastTitle(dayNumber),
      _formats(context).digits,
    );
    final cb = onSelected;
    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: sk.text.titleSmall),
          ),
          const SizedBox(height: SkSpace.space8),
          Wrap(
            spacing: SkSpace.space8,
            runSpacing: SkSpace.space8,
            children: [
              for (final e in FastEntry.values)
                ChoiceChip(
                  label: Text(switch (e) {
                    FastEntry.fasted => l10n.ramadanFastFasted,
                    FastEntry.notFasted => l10n.ramadanFastNotFasted,
                    FastEntry.excused => l10n.ramadanFastExcused,
                  }),
                  selected: selected == e,
                  onSelected: cb == null ? null : (on) => cb(on ? e : null),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
