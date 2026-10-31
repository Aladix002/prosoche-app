import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/core/router/routes.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/quests.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/cards/cards.dart';
import 'package:prosoche/features/library/widgets/library_widgets.dart';
import 'package:prosoche/features/settings/blocking/blocking_providers.dart';
import 'package:prosoche/features/settings/settings_routes.dart';
import 'package:prosoche/features/shell/day_phase.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

/// Dnes (docs/02 A2): datum, questy dna, vstup do sady, streak a umysel. Ziadny nekonecny obsah ani badge (docs/01 1.2).
///
/// Polnoc prekresli obrazovku cez `localDateProvider` (casovac) a navrat
/// do popredia ho prepocita (zmena zony, dlhe spanie).
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(localDateProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localDate = ref.watch(localDateProvider);
    // Zapisy (questy, sada) idu na `activeSetDate` (docs/02 0.1).
    final setDate = ref.watch(activeSetDateProvider).value ?? localDate;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.all(SkSpace.space16),
          children: [
            _Header(date: localDate),
            const _GatePausedBanner(),
            const SizedBox(height: SkSpace.space24),
            _Quests(date: setDate),
            const SizedBox(height: SkSpace.space24),
            const _SetPanel(child: TodaySetCta()),
            const _KeepReading(),
            const SizedBox(height: SkSpace.space24),
            const _StreakLine(),
            const _IntentionLine(),
            const SizedBox(height: SkSpace.space16),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.date});

  final LocalDate date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    // Hlavicka s atmosferou podla casti dna (svetlo na kameni).
    return SkAtmospherePanel(
      phase: watchDayPhase(ref),
      padding: sk.largeText
          ? const EdgeInsetsDirectional.fromSTEB(
              SkSpace.space16,
              SkSpace.space8,
              SkSpace.space8,
              SkSpace.space16,
            )
          : const EdgeInsetsDirectional.fromSTEB(
              SkSpace.space24,
              SkSpace.space8,
              SkSpace.space8,
              SkSpace.space16,
            ),
      // D-01: datum len raz (eyebrow v terakote), nadpis "Today"
      // (Cormorant) a pod nim rimsa.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    top: SkSpace.space12,
                  ),
                  child: Semantics(
                    header: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.formats
                              .weekdayDate(date.toLocalDateTime())
                              .toUpperCase(),
                          style: sk.type.eyebrow,
                        ),
                        const SizedBox(height: SkSpace.space4),
                        Text(
                          l10n.tabToday,
                          style: sk.largeText
                              ? sk.text.headlineSmall
                              : sk.text.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SkIconButton(
                icon: Icons.settings_outlined,
                tooltip: l10n.todaySettings,
                onPressed: () => context.push(SettingsRoutes.root),
              ),
            ],
          ),
          const SizedBox(height: SkSpace.space12),
          const SkCornice(),
        ],
      ),
    );
  }
}

/// Panel vstupu do sady: tonalna plocha `surface` (D-05).
class _SetPanel extends StatelessWidget {
  const _SetPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.sk.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(SkRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(SkSpace.space16),
        child: child,
      ),
    );
  }
}

/// Brana je zapnuta, ale chyba jej povolenie (I-03): "The gate is paused"
/// s akciou "Fix" na obrazovku povoleni. Len pri `FEATURE_GATE`.
class _GatePausedBanner extends ConsumerWidget {
  const _GatePausedBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!(ref.watch(gateNeedsAttentionProvider).value ?? false)) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: SkSpace.space16),
      child: SkInlineBanner(
        key: const ValueKey('today:gatePaused'),
        variant: SkBannerVariant.warning,
        title: l10n.todayGatePaused,
        message: l10n.todayGatePausedBody,
        actionLabel: l10n.todayGateFix,
        onAction: () =>
            unawaited(context.push('${SettingsPaths.blocking}/permissions')),
      ),
    );
  }
}

/// "1 h 12 min" / "45 min" (cislice podla jazyka UI).
String durationLabel(BuildContext context, Duration d) {
  final l10n = context.l10n;
  final minutes = (d.inSeconds / 60).ceil();
  final text = minutes >= 60
      ? l10n.todayDurationHoursMinutes(minutes ~/ 60, minutes % 60)
      : l10n.todayDurationMinutes(minutes);
  return localizeDigits(text, context.formats.digits);
}

/// Titulok questu: text sablony z content.db, inak genericky z ARB.
String questTitle(BuildContext context, QuestView q) {
  final l10n = context.l10n;
  if (q.title case final t? when t.isNotEmpty) return t;
  final count = q.genericCount ?? 1;
  return switch (q.generic) {
    GenericQuest.readCards => l10n.questGenericReadCards(count),
    GenericQuest.learnIdea => l10n.questGenericLearnIdea,
    GenericQuest.actPractice => l10n.questGenericActPractice,
    null => questSlotLabel(context, q.slot),
  };
}

class _Quests extends ConsumerWidget {
  const _Quests({required this.date});

  final LocalDate date;

  SkQuestState _state(QuestView q) => switch (q.status) {
    QuestStatus.done => SkQuestState.done,
    QuestStatus.skipped => SkQuestState.skipped,
    QuestStatus.pending when (q.progress?.current ?? 0) > 0 =>
      SkQuestState.inProgress,
    QuestStatus.pending => SkQuestState.open,
  };

  Future<void> _setAct(
    BuildContext context,
    WidgetRef ref,
    QuestStatus status,
  ) async {
    final repo = ref.read(questRepositoryProvider);
    await repo.setActStatus(date, status);
    if (status != QuestStatus.done || !context.mounted) return;
    // "I did it": jemne cvaknutie (docs/01 2.9).
    unawaited(HapticFeedback.selectionClick());
    showSkSnackbar(
      context,
      message: context.l10n.todayQuestMarked,
      actionLabel: SkUiStrings.of(context).undo,
      onAction: () => unawaited(repo.setActStatus(date, QuestStatus.pending)),
    );
  }

  Future<void> _actMenu(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final skip = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.do_not_disturb_on_outlined),
          title: Text(l10n.todayQuestSkip),
          minTileHeight: SkSpace.minTouchTarget,
          onTap: () => Navigator.of(sheet).pop(true),
        ),
      ),
    );
    if ((skip ?? false) && context.mounted) {
      await _setAct(context, ref, QuestStatus.skipped);
    }
  }

  void _open(BuildContext context, WidgetRef ref) {
    final set = ref.read(dailySetProvider(date)).value;
    if (set?.isCompleted ?? false) {
      // Po dokonceni sady volne citanie v Library (F-01).
      context.go(AppRoutes.library);
    } else {
      unawaited(context.push(AppRoutes.feed));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final quests = ref.watch(questsProvider(date));
    ref.watch(dailySetProvider(date));
    final Widget body;
    if (quests.hasError && !quests.isLoading && !quests.hasValue) {
      body = SkErrorState(
        title: l10n.errorGeneric,
        onRetry: () => ref.invalidate(questsProvider(date)),
      );
    } else if (!quests.hasValue) {
      body = const SkLoadingView(skeleton: SkSkeleton.list());
    } else {
      body = Column(
        children: [
          for (final q in quests.requireValue) ...[
            _questItem(context, ref, q),
            const SizedBox(height: SkSpace.space8),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.todayQuestsTitle, style: sk.text.titleLarge),
        ),
        const SizedBox(height: SkSpace.space12),
        body,
      ],
    );
  }

  Widget _questItem(BuildContext context, WidgetRef ref, QuestView q) {
    final isAct = q.slot == QuestSlot.act;
    final state = _state(q);
    return SkQuestItem(
      key: ValueKey('quest-${q.slot.wire}'),
      title: questTitle(context, q),
      slot: switch (q.slot) {
        QuestSlot.read => SkQuestSlot.read,
        QuestSlot.learn => SkQuestSlot.learn,
        QuestSlot.act => SkQuestSlot.act,
      },
      state: state,
      progress: q.progress?.current ?? 0,
      target: q.progress?.target ?? 0,
      subtitle: q.body,
      // READ/LEARN: kontext (feed alebo reader), ACT: Practice (F-01),
      // splnenie potvrdi pouzivatel.
      onTap: isAct
          ? () => context.go(AppRoutes.practice)
          : () => _open(context, ref),
      onAction: isAct && state == SkQuestState.open
          ? () => unawaited(_setAct(context, ref, QuestStatus.done))
          : null,
      onUndo: isAct
          ? () => unawaited(_setAct(context, ref, QuestStatus.pending))
          : null,
      onLongPress: isAct && state == SkQuestState.open
          ? () => unawaited(_actMenu(context, ref))
          : null,
    );
  }
}

/// Vstup do dennej sady (docs/02 A2 stavy CTA, docs/01 7.6).
///
/// Kym sa sada pripravuje (< 100 ms), tlacidlo uz vedie do feedu (feed ma
/// vlastny loading); po 10 s bez sady chybovy stav E-FEED-1 (docs/01 6).
class TodaySetCta extends ConsumerStatefulWidget {
  const TodaySetCta({super.key});

  static const timeout = Duration(seconds: 10);

  @override
  ConsumerState<TodaySetCta> createState() => _TodaySetCtaState();
}

class _TodaySetCtaState extends ConsumerState<TodaySetCta> {
  Timer? _timeout;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _timeout = Timer(TodaySetCta.timeout, () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  void _retry(LocalDate? date) {
    ref.invalidate(activeSetDateProvider);
    if (date != null) ref.invalidate(dailySetProvider(date));
    _timeout?.cancel();
    setState(() => _timedOut = false);
    _timeout = Timer(TodaySetCta.timeout, () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final dateAsync = ref.watch(activeSetDateProvider);
    final date = dateAsync.value;
    final set = date == null ? null : ref.watch(dailySetProvider(date));
    final value = set?.value;
    if (value != null) _timeout?.cancel();
    final failed =
        value == null &&
        (_timedOut ||
            (dateAsync.hasError && !dateAsync.isLoading) ||
            (set != null && set.hasError && !set.isLoading));

    if (failed) {
      return SkErrorState(
        title: l10n.feedErrorTitle,
        body: l10n.feedErrorBody,
        onRetry: () => _retry(date),
      );
    }
    void openFeed() => unawaited(context.push(AppRoutes.feed));
    if (value == null) {
      return SkButton.primary(
        label: l10n.todayCtaBegin,
        onPressed: openFeed,
        expand: true,
      );
    }
    if (value.isCompleted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Icon(Icons.check_circle, color: sk.colors.success),
              ),
              const SizedBox(width: SkSpace.space8),
              Expanded(
                child: Text(l10n.todayCtaComplete, style: sk.text.titleMedium),
              ),
            ],
          ),
          // Ked je pod kartou dlazdica "Keep reading" s poslednou poziciou,
          // druhe tlacidlo s rovnakym textom by bolo duplicitne (I-01).
          if (ref.watch(lastReadingProvider).value == null) ...[
            const SizedBox(height: SkSpace.space12),
            SkButton.secondary(
              label: l10n.todayCtaKeepReading,
              expand: true,
              onPressed: () => context.go(AppRoutes.library),
            ),
          ],
        ],
      );
    }
    if (value.isStarted) {
      return SkButton.primary(
        // Izolacia smeru (BF-01): "x of N" ostane citatelne v RTL UI aj
        // s EN textom tlacidla.
        label: Bidi.isolate(
          l10n.todayCtaContinue(value.seenContentCount, value.n),
        ),
        onPressed: openFeed,
        expand: true,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkButton.primary(
          label: l10n.todayCtaBegin,
          onPressed: openFeed,
          expand: true,
        ),
        const SizedBox(height: SkSpace.space8),
        Text(
          l10n.todayCtaBeginCount(value.n),
          textAlign: TextAlign.center,
          style: sk.text.bodyMedium!.copyWith(color: sk.colors.textSecondary),
        ),
      ],
    );
  }
}

/// "Keep reading" (F-01): naposledy citane dielo a sekcia z Library.
class _KeepReading extends ConsumerWidget {
  const _KeepReading();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(lastReadingProvider).value;
    if (last == null) return const SizedBox.shrink();
    final work = ref
        .watch(libraryAuthorsProvider)
        .value
        ?.expand((a) => a.works)
        .where((w) => w.id == last.workId)
        .firstOrNull;
    if (work == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: SkSpace.space12),
      child: ContinueReadingTile(
        key: const ValueKey('today:keepReading'),
        work: work,
        position: last,
      ),
    );
  }
}

/// "6-day streak · 2 grace days"; skryte pri `simple_mode`.
class _StreakLine extends ConsumerWidget {
  const _StreakLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final simple = ref.watch(settingOf(SettingsKeys.simpleMode));
    final streak = ref.watch(streakProvider).value;
    if (simple.value != false || streak == null || streak.current <= 0) {
      return const SizedBox.shrink();
    }
    final c = context.sk.colors;
    final grace = streak.graceLeft;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: SkSpace.space8,
      runSpacing: SkSpace.space4,
      children: [
        Text(
          // Kazda cast izolovana: cislo na zaciatku (aj EN fallback) sa v RTL
          // inak presunie na koniec ("day streak-1").
          '${Bidi.isolate(l10n.todayStreak(streak.current))} · '
          '${Bidi.isolate(l10n.todayGraceDays(grace))}',
          textAlign: TextAlign.center,
          style: context.sk.text.bodyMedium,
        ),
        // Grace dni ako male kruhy (docs/01 3.2 SkStreakIndicator).
        ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 2; i++)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsetsDirectional.only(end: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < grace ? c.primary : null,
                    border: Border.all(color: c.outlineStrong),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Umysel pouzivatela (`intention.text`); ak nie je, riadok sa nezobrazi.
class _IntentionLine extends ConsumerWidget {
  const _IntentionLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(settingOf(SettingsKeys.intentionText)).value;
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: SkSpace.space16),
      child: Text(
        context.l10n.todayIntention(text),
        textAlign: TextAlign.center,
        // Umysel ako tichy citat (Literata), bez kurzivy.
        style: context.sk.type.reflection.copyWith(
          fontSize: 16,
          height: 1.5,
          color: context.sk.colors.textSecondary,
        ),
      ),
    );
  }
}
