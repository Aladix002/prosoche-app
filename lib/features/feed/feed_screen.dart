import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/core/logging/logger_provider.dart';
import 'package:prosoche/core/router/routes.dart';
import 'package:prosoche/data/observability/observability_providers.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/feed.dart';
import 'package:prosoche/domain/quests/quests.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/cards/cards.dart';
import 'package:prosoche/features/feed/feed_rules.dart';
import 'package:prosoche/ui/ui.dart';

/// Fullscreen denna sada (docs/02 A3): vertikalny `PageView`, karta je
/// `seen` po dwell (0.4), dalej sa da az po precitani, sada konci kartou
/// "Dnes si hotovy" (B10). Feed konci, nic dalsie sa nenacita (docs/01 1.2).
///
/// `activeSetDate` sa urci raz pri vstupe a pocas session sa nemeni (0.1).
/// Back vedie vzdy na Dnes (docs/01 4.4), aj po deep linku.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen>
    with WidgetsBindingObserver {
  LocalDate? _date;
  _FeedSession? _session;
  bool _foreground = true;
  bool _newDayAsked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    final session = _session;
    if (!foreground) {
      // Dwell plati len v popredi a pri navrate zacina odznova (0.4).
      session?.cancelDwell();
      return;
    }
    ref.read(localDateProvider.notifier).refresh();
    session?.reactivate?.call();
    unawaited(_maybeAskNewDay());
  }

  /// Novy den pocas otvoreneho feedu (docs/02 A3 okrajove pripady).
  Future<void> _maybeAskNewDay() async {
    final date = _date;
    final session = _session;
    if (date == null || session == null || _newDayAsked) return;
    final today = ref.read(localDateProvider);
    final state = ref.read(dailySetProvider(date)).value;
    if (!today.isAfter(date) || state == null || state.isCompleted) return;
    _newDayAsked = true;
    final l10n = context.l10n;
    final startToday = await showSkConfirmDialog(
      context,
      title: l10n.feedNewDayTitle,
      body: l10n.feedNewDayBody,
      confirmLabel: l10n.feedNewDayToday,
      cancelLabel: l10n.feedNewDayContinue,
    );
    if (!startToday || !mounted) return;
    setState(() {
      _session?.dispose();
      _session = null;
      _date = today;
    });
  }

  /// Pod feedom moze chybat routa (deep link): vtedy rovno na Dnes.
  bool get _canPop =>
      GoRouter.maybeOf(context)?.canPop() ?? Navigator.of(context).canPop();

  void _close() {
    final router = GoRouter.maybeOf(context);
    if (_canPop) {
      router != null ? router.pop() : Navigator.of(context).pop();
    } else {
      router?.go(AppRoutes.today);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final activeDate = ref.watch(activeSetDateProvider);
    // Datum sady sa zafixuje pri prvej hodnote (docs/02 0.1).
    final date = _date ??= activeDate.value;
    final set = date == null ? null : ref.watch(dailySetProvider(date));
    final failed =
        (activeDate.hasError && !activeDate.isLoading && date == null) ||
        (set != null && set.hasError && !set.isLoading && !set.hasValue);
    final value = set?.value;

    Widget body;
    if (failed) {
      body = Center(
        child: SkErrorState(
          title: l10n.feedErrorTitle,
          body: l10n.feedErrorBody,
          onRetry: () {
            ref.invalidate(activeSetDateProvider);
            if (date != null) ref.invalidate(dailySetProvider(date));
          },
          secondaryLabel: l10n.feedBackToToday,
          onSecondary: _close,
        ),
      );
    } else if (value == null || date == null) {
      body = const Padding(
        padding: EdgeInsetsDirectional.all(SkSpace.space16),
        child: SkLoadingView(),
      );
    } else {
      final session = _session ??= _FeedSession(
        state: value,
        onChanged: () {
          if (mounted) setState(() {});
        },
      );
      body = _FeedBody(
        date: date,
        state: value,
        session: session,
        onClose: _close,
        dwellMs:
            ref.watch(settingOf(SettingsKeys.cardSeenDwellMs)).value ??
            FeedRules.defaultDwellMs,
      );
    }

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) GoRouter.maybeOf(context)?.go(AppRoutes.today);
      },
      child: Scaffold(
        body: SafeArea(
          child: value == null || date == null
              ? Column(
                  children: [
                    _TopBar(onClose: _close),
                    Expanded(child: body),
                  ],
                )
              : body,
        ),
      ),
    );
  }
}

/// Lokalny stav otvorenej sady: aktualna strana, dwell, prave prejdene
/// karty (kym ich nepotvrdi stream z DB) a rezim len na prezeranie.
class _FeedSession {
  _FeedSession({required DailySetState state, required this.onChanged})
    : reviewOnly = state.isCompleted,
      page = state.isCompleted
          ? state.set.cards.length
          : math.min(state.cursor, state.set.cards.length) {
    controller = PageController(initialPage: page);
  }

  final VoidCallback onChanged;

  /// Sada bola dokoncena uz pri otvoreni: len prezeranie, ziadne `seen`
  /// (docs/02 A3).
  final bool reviewOnly;
  late final PageController controller;
  int page;

  final passedLocally = <int>{};
  final skipping = <int>{};
  bool doneLogged = false;

  /// Cas prveho prejdenia karty v tejto session (kym DB nema
  /// `started_at`).
  DateTime? firstPassAt;

  /// Pretekajuce karty a ci su doscrollovane (B0.5).
  final overflow = <int, ({bool overflows, bool atEnd})>{};

  Timer? _dwell;
  final _since = Stopwatch();
  void Function(int index)? _onDwell;

  /// Znova aktivuje aktualnu kartu (navrat do popredia).
  VoidCallback? reactivate;
  Duration Function(int index)? _dwellFor;
  int? _dwellFrom;

  bool hint = false;
  Timer? _hintTimer;

  void bind({
    required void Function(int index) onDwell,
    required Duration Function(int index) dwellFor,
    required VoidCallback reactivate,
  }) {
    this.reactivate = reactivate;
    _onDwell = onDwell;
    _dwellFor = dwellFor;
  }

  void cancelDwell() {
    _dwell?.cancel();
    _dwell = null;
    _since
      ..stop()
      ..reset();
  }

  /// Karta [index] je aktivna: zacne dwell (ak sa ma zapisat `seen`).
  void activate(int index, {bool needsDwell = true}) {
    cancelDwell();
    page = index;
    _dwellFrom = index;
    if (!needsDwell) return;
    _since.start();
    _schedule(index, _dwellFor?.call(index) ?? FeedRules.defaultDwell);
  }

  /// Karta zacala pretekat: dwell sa predlzi (B0.5).
  void extendDwell(int index) {
    if (_dwell == null || _dwellFrom != index) return;
    final total = _dwellFor?.call(index) ?? FeedRules.defaultDwell;
    final left = total - _since.elapsed;
    _dwell?.cancel();
    _schedule(index, left.isNegative ? Duration.zero : left);
  }

  void _schedule(int index, Duration d) {
    _dwell = Timer(d, () {
      _dwell = null;
      if (page == index) _onDwell?.call(index);
    });
  }

  void showHint() {
    hint = true;
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 2), () {
      hint = false;
      onChanged();
    });
    onChanged();
  }

  void dispose() {
    cancelDwell();
    _hintTimer?.cancel();
    controller.dispose();
  }
}

class _FeedBody extends ConsumerStatefulWidget {
  const _FeedBody({
    required this.date,
    required this.state,
    required this.session,
    required this.onClose,
    required this.dwellMs,
  });

  final LocalDate date;
  final DailySetState state;
  final _FeedSession session;
  final VoidCallback onClose;
  final int dwellMs;

  @override
  ConsumerState<_FeedBody> createState() => _FeedBodyState();
}

class _FeedBodyState extends ConsumerState<_FeedBody> {
  _FeedSession get _s => widget.session;
  DailySetState get _state => widget.state;
  List<DailySetCard> get _cards => _state.set.cards;
  int get _donePage => _cards.length;

  @override
  void initState() {
    super.initState();
    _bind();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _activate(_s.page);
    });
  }

  @override
  void didUpdateWidget(_FeedBody old) {
    super.didUpdateWidget(old);
    if (old.session != widget.session) {
      _bind();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _activate(_s.page);
      });
    }
  }

  void _bind() => _s.bind(
    onDwell: _onDwell,
    dwellFor: _dwellFor,
    reactivate: () => _activate(_s.page),
  );

  bool _isPassed(int i) =>
      _s.reviewOnly ||
      i >= _donePage ||
      _cards[i].pos <= _state.cursor ||
      _s.passedLocally.contains(i);

  int get _firstUnpassed {
    for (var i = 0; i < _cards.length; i++) {
      if (!_isPassed(i)) return i;
    }
    return _donePage;
  }

  /// Dalej sa da len po prejdenu kartu (docs/02 0.4); karta done je koniec.
  int get _reachable => _s.reviewOnly ? _cards.length + 1 : _firstUnpassed + 1;

  Duration _dwellFor(int i) {
    final base = Duration(milliseconds: widget.dwellMs);
    final o = _s.overflow[i];
    if (o == null || !o.overflows) return base;
    final content = ref.read(cardContentProvider(_cards[i].cardId)).value;
    return FeedRules.dwellForOverflow(base, translationChars(content));
  }

  void _activate(int i) {
    final needsDwell = i < _donePage && !_isPassed(i);
    _s.activate(i, needsDwell: needsDwell);
    if (i == _donePage) _onDoneShown();
  }

  void _onDoneShown() {
    if (_s.reviewOnly || _s.doneLogged) return;
    _s.doneLogged = true;
    unawaited(ref.read(dailySetRepositoryProvider).markDoneShown(widget.date));
    // Dokoncenie sady: jedna jemna haptika (docs/01 2.9).
    unawaited(HapticFeedback.mediumImpact());
    // duration = dokoncenie - prve `seen` (docs/02 A3).
    final started = _state.startedAt ?? _s.firstPassAt;
    final now = ref.read(appClockProvider).now();
    ref.read(analyticsProvider).track('daily_set_completed', {
      'cards_count': _state.n,
      'duration_s': started == null ? 0 : now.difference(started).inSeconds,
    });
  }

  void _onDwell(int i) {
    if (!mounted || _isPassed(i)) return;
    final content = ref.read(cardContentProvider(_cards[i].cardId));
    if (content.isLoading && !content.hasValue) {
      // Obsah este nie je: dwell sa pocita az od zobrazenia.
      _s.activate(i);
      return;
    }
    if (content.hasError || content.value == null) return;
    unawaited(_pass(i, skipped: false));
  }

  Future<void> _pass(int i, {required bool skipped}) async {
    if (_s.reviewOnly || _s.passedLocally.contains(i)) return;
    // Prvy posun v sade: `daily_set_started` (docs/02 A3).
    if (!_state.isStarted && _s.passedLocally.isEmpty) {
      _s.firstPassAt = ref.read(appClockProvider).now();
      ref.read(analyticsProvider).track('daily_set_started', {
        'cards_count': _state.n,
      });
    }
    setState(() => _s.passedLocally.add(i));
    final repo = ref.read(dailySetRepositoryProvider);
    try {
      if (skipped) {
        await repo.markSkipped(widget.date, _cards[i]);
      } else {
        await repo.markSeen(widget.date, _cards[i]);
      }
    } on Object catch (e, st) {
      // Bez obsahu karty (docs/02 0.6), len typ.
      ref
          .read(appLoggerProvider)
          .error(
            'feed',
            'card pass failed',
            error: e,
            stack: st,
            kv: {'type': _cards[i].cardId.type.wire},
          );
    }
  }

  /// Karta bez obsahu alebo "Skip this card": `skipped` a dalsia karta.
  Future<void> _skip(int i) async {
    if (_s.skipping.contains(i)) return;
    _s.skipping.add(i);
    await _pass(i, skipped: true);
    if (mounted && _s.page == i) _next();
  }

  void _next() {
    if (_s.page >= _donePage) return;
    if (!_isPassed(_s.page)) {
      _s.showHint();
      return;
    }
    _animate(_s.controller.nextPage);
  }

  bool _animating = false;

  /// Jeden prechod naraz (overscroll chodi pocas tahu opakovane).
  void _animate(
    Future<void> Function({required Duration duration, required Curve curve})
    move,
  ) {
    if (_animating) return;
    _animating = true;
    final motion = context.sk.motion.medium;
    unawaited(
      move(
        duration: motion.duration,
        curve: motion.curve,
      ).whenComplete(() => _animating = false),
    );
  }

  void _previous() {
    if (_s.page == 0) return;
    _animate(_s.controller.previousPage);
  }

  /// Rozmery vnutorneho scrollu karty: pretekajuca karta ma dlhsi dwell.
  void _onPageMetrics(int i, ScrollMetrics m) {
    if (m.axis != Axis.vertical) return;
    final overflows = m.maxScrollExtent > 0;
    final atEnd = m.pixels >= m.maxScrollExtent - 1;
    final before = _s.overflow[i];
    _s.overflow[i] = (overflows: overflows, atEnd: atEnd);
    if (overflows && before?.overflows != true) _s.extendDwell(i);
  }

  bool _onPageScroll(int i, ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    _onPageMetrics(i, n.metrics);
    if (n is OverscrollNotification && n.dragDetails != null) {
      // Vnutorny scroll karty je na konci: prechod na dalsiu/predoslu
      // kartu (NestedScroll, docs/02 A3 text scale 200 %).
      if (n.overscroll > 0) _next();
      if (n.overscroll < 0) _previous();
    }
    return true;
  }

  bool _onFeedScroll(ScrollNotification n) {
    if (n.depth == 0 &&
        n is OverscrollNotification &&
        n.dragDetails != null &&
        n.overscroll > 0 &&
        _s.page < _donePage &&
        !_isPassed(_s.page)) {
      _s.showHint();
    }
    return false;
  }

  DoneSummary _doneSummary() {
    final quests = ref.watch(questsProvider(widget.date)).value ?? const [];
    final simple = ref.watch(settingOf(SettingsKeys.simpleMode)).value ?? false;
    final streak = simple ? null : ref.watch(streakProvider).value?.current;
    final act = quests
        .where(
          (q) => q.slot == QuestSlot.act && q.status == QuestStatus.pending,
        )
        .firstOrNull;
    final completedAt = _state.completedAt;
    return DoneSummary(
      cards: _state.n,
      questsDone: quests.where((q) => q.isDone).length,
      questsTotal: quests.length,
      openDeed: act?.title,
      streak: streak,
      countedFor:
          completedAt != null &&
              LocalDate.fromDateTime(completedAt) != widget.date
          ? widget.date
          : null,
    );
  }

  /// "Keep reading": tab Library (citanie celych diel dodá F-01).
  void _keepReading() => context.go(AppRoutes.library);

  Widget _page(BuildContext context, int i) {
    final l10n = context.l10n;
    final Widget child;
    if (i == _donePage) {
      final act = ref
          .watch(questsProvider(widget.date))
          .value
          ?.where(
            (q) => q.slot == QuestSlot.act && q.status == QuestStatus.pending,
          )
          .firstOrNull;
      child = DoneCard(
        summary: _doneSummary(),
        onBack: widget.onClose,
        onKeepReading: _keepReading,
        onDeedDone: act == null
            ? null
            : () => unawaited(
                ref
                    .read(questRepositoryProvider)
                    .setActStatus(widget.date, QuestStatus.done),
              ),
      );
    } else {
      final card = _cards[i];
      final content = ref.watch(cardContentProvider(card.cardId));
      if (content case AsyncData(value: null)
          when !_isPassed(i) && i == _s.page) {
        // Chybajuci obsah (ID zmizlo z content.db): preskocit (A3).
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_skip(i));
        });
      }
      child = NotificationListener<ScrollMetricsNotification>(
        onNotification: (n) {
          _onPageMetrics(i, n.metrics);
          return true;
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) => _onPageScroll(i, n),
          child: CardView(
            cardId: card.cardId,
            date: widget.date,
            pos: card.pos,
            total: _state.n,
            cardsCount: _state.n,
            onSkip: _s.reviewOnly ? null : () => unawaited(_skip(i)),
          ),
        ),
      );
    }
    final canNext = i < _donePage && _isPassed(i);
    Widget page = Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: SkSpace.space16,
        vertical: SkSpace.space8,
      ),
      child: child,
    );
    if (!context.sk.motion.reduced) {
      // D-05: prechod medzi kartami je len jemny fade celej karty podla
      // posunu (docs/01 1.3 bod 5: text sa sam neanimuje ani neskaluje).
      page = AnimatedBuilder(
        animation: _s.controller,
        builder: (context, child) {
          final c = _s.controller;
          var opacity = 1.0;
          if (c.hasClients && c.position.haveDimensions) {
            final d = ((c.page ?? i.toDouble()) - i).abs();
            opacity = (1 - d * 0.7).clamp(0.3, 1.0);
          }
          return Opacity(opacity: opacity, child: child);
        },
        child: page,
      );
    }
    return Semantics(
      customSemanticsActions: {
        if (canNext) CustomSemanticsAction(label: l10n.feedNextCard): _next,
        if (i > 0)
          CustomSemanticsAction(label: l10n.feedPreviousCard): _previous,
      },
      child: page,
    );
  }

  String? _hintText(BuildContext context) {
    final l10n = context.l10n;
    if (_s.hint) return l10n.feedTakeAMoment;
    if (!_s.reviewOnly && _s.page == 0 && _isPassed(0) && _state.cursor <= 1) {
      return l10n.feedSwipeUp;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Lenivy preload aktualnej karty +-2 (docs/02 A3).
    for (var i = _s.page - 2; i <= _s.page + 2; i++) {
      if (i >= 0 && i < _cards.length) {
        ref.watch(cardContentProvider(_cards[i].cardId));
      }
    }
    final n = _state.n;
    final done = _s.reviewOnly
        ? n
        : _state.set.contentCards.where((c) => _isPassed(c.pos - 1)).length;
    final hint = _hintText(context);
    final sk = context.sk;
    return Column(
      children: [
        _TopBar(
          onClose: widget.onClose,
          progress: SkDailyProgress(done: math.min(done, n), total: n),
        ),
        Semantics(
          liveRegion: true,
          child: SizedBox(
            width: double.infinity,
            child: AnimatedOpacity(
              opacity: hint == null ? 0 : 1,
              duration: sk.motion.short.duration,
              child: Text(
                hint ?? '',
                textAlign: TextAlign.center,
                style: sk.text.bodyMedium!.copyWith(
                  color: sk.colors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ScrollConfiguration(
            // Clamping: na konci vnutorneho scrollu pride overscroll, ktory
            // posunie kartu (B0.5).
            behavior: ScrollConfiguration.of(context)
                .copyWith(physics: const ClampingScrollPhysics()),
            child: NotificationListener<ScrollNotification>(
              onNotification: _onFeedScroll,
              child: PageView.builder(
                controller: _s.controller,
                scrollDirection: Axis.vertical,
                itemCount: _reachable,
                // Aj jedna dosiahnutelna karta prijme tah: odpruzi a ukaze
                // hint (docs/02 0.4).
                physics: const AlwaysScrollableScrollPhysics(),
                onPageChanged: _activate,
                itemBuilder: _page,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose, this.progress});

  final VoidCallback onClose;
  final Widget? progress;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(
      start: SkSpace.space4,
      end: SkSpace.space16,
    ),
    child: Row(
      children: [
        SkIconButton(
          icon: Icons.close,
          tooltip: context.l10n.feedClose,
          onPressed: onClose,
        ),
        const SizedBox(width: SkSpace.space8),
        Expanded(child: progress ?? const SizedBox.shrink()),
      ],
    ),
  );
}
