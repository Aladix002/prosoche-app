import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/core/logging/logger_provider.dart';
import 'package:prosoche/data/blocker/blocker_gateway.dart';
import 'package:prosoche/data/blocker/blocker_gateway_provider.dart';
import 'package:prosoche/data/blocker/gate_repository.dart';
import 'package:prosoche/data/content/content_providers.dart';
import 'package:prosoche/data/content/remote_config_policy.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/cards/cards.dart';
import 'package:prosoche/features/gate/gate_controller.dart';
import 'package:prosoche/features/gate/gate_deck.dart';
import 'package:prosoche/features/gate/gate_views.dart';
import 'package:prosoche/ui/ui.dart';

/// Remote kill-switch `blocker_overlay` (docs/06 A.7). Chyba configu =
/// zapnute (defaulty z kodu).
final Provider<bool> gateOverlayEnabledProvider = Provider<bool>((ref) {
  try {
    return ref
        .watch(remoteConfigPolicyProvider)
        .isFeatureEnabled(RemoteFeature.blockerOverlay);
  } on Object {
    return true;
  }
}, name: 'gateOverlayEnabledProvider');

/// Aktualna modlitba a jej zaciatok pre prayer lock; null bez polohy.
typedef GatePrayerNow = ({Prayer prayer, DateTime start});

/// Zisti aktualnu modlitbu (pri kazdom otvoreni brany znova).
final Provider<Future<GatePrayerNow?> Function()> gateCurrentPrayerProvider =
    Provider<Future<GatePrayerNow?> Function()>((ref) {
      final clock = ref.watch(appClockProvider);
      return () async {
        final config = await ref.read(prayerConfigProvider.future);
        if (config == null) return null;
        final m = config.schedule.current(clock.now());
        return (prayer: m.prayer, start: m.time as DateTime);
      };
    }, name: 'gateCurrentPrayerProvider');

/// Zavislosti [GateController] z providerov appky (aj engine `gateMain`).
final Provider<GateDeps> gateDepsProvider = Provider<GateDeps>(
  (ref) => GateDeps(
    blocker: ref.watch(blockerGatewayProvider),
    gates: ref.watch(gateRepositoryProvider),
    sets: ref.watch(dailySetRepositoryProvider),
    clock: ref.watch(appClockProvider),
    today: () => ref.read(localDateProvider),
    log: ref.watch(appLoggerProvider),
    dwellMs: () =>
        ref.read(settingsRepositoryProvider).get(SettingsKeys.cardSeenDwellMs),
    prayerLockMinutes: () => ref
        .read(settingsRepositoryProvider)
        .get(SettingsKeys.blockerPrayerLockMinutes),
    currentPrayer: ref.watch(gateCurrentPrayerProvider),
    overlayEnabled: () => ref.read(gateOverlayEnabledProvider),
    syncQuests: (date) => ref.read(questRepositoryProvider).syncAuto(date),
  ),
  name: 'gateDepsProvider',
);

/// Brana pred blokovanou appkou (docs/02 A4, docs/01 5.3).
///
/// N kariet z dnesnej sady (po jej dokonceni volne citanie), dwell
/// `max(card.seen_dwell_ms, 4 s)` s odpoctom, po N kartach `unlockFor` a
/// obrazovka "is open for", emergency 1,5 s + 10 s odpocet (5 min). Chyba
/// = "Continue to {app}" (`source=error`), brana nikdy neuvazni.
///
/// Back nesmie vratit pouzivatela do blokovanej appky: pri targetSdk 36 sa
/// `onBackPressed` nevola, preto [PopScope] -> home screen.
class GateScreen extends ConsumerStatefulWidget {
  const GateScreen({
    required this.app,
    this.source = 'monitor',
    this.onClosed,
    super.key,
  });

  /// Package name blokovanej appky. Nikdy ho nelogovat.
  final String app;

  /// `monitor` | `notif` | `test` | `error`
  final String source;

  /// Brana sa zavrela (nativ uz prepina aktivitu).
  final VoidCallback? onClosed;

  @override
  ConsumerState<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends ConsumerState<GateScreen> {
  late final GateController _c;
  PageController? _pager;
  GatePhase? _lastPhase;
  Timer? _slowTimer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _c = GateController(
      ref: widget.app,
      deps: ref.read(gateDepsProvider),
      onClosed: widget.onClosed,
    )..addListener(_onChange);
    _slowTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _slow = true);
    });
    unawaited(_c.start());
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _c
      ..removeListener(_onChange)
      ..dispose();
    _pager?.dispose();
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    final phase = _c.phase;
    if (phase == GatePhase.cards && _lastPhase != GatePhase.cards) {
      // PageView sa znova vytvori (po prayer, emergency, keep reading).
      _pager?.dispose();
      _pager = PageController(initialPage: _c.page);
    }
    _lastPhase = phase;
    setState(() {});
  }

  String? get _label => _c.app?.label;

  void _next() {
    final pager = _pager;
    if (pager == null || !pager.hasClients) return;
    final motion = context.sk.motion.medium;
    pager.nextPage(duration: motion.duration, curve: motion.curve);
  }

  Future<void> _emergencyA11y() async {
    final l10n = context.l10n;
    final ok = await showSkConfirmDialog(
      context,
      title: l10n.gateEmergencyDialogFor(_label, emergencyUnlockMinutes),
      confirmLabel: l10n.gateEmergency,
      cancelLabel: l10n.gateEmergencyCancel,
    );
    if (ok && mounted) _c.startEmergency();
  }

  void _onBack() {
    if (_c.phase == GatePhase.emergency) {
      _c.cancelEmergency();
    } else {
      unawaited(_c.goBack());
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _onBack();
    },
    child: Scaffold(body: SafeArea(child: _body(context))),
  );

  Widget _body(BuildContext context) {
    final l10n = context.l10n;
    switch (_c.phase) {
      case GatePhase.loading:
      case GatePhase.closed:
        return GateLoadingView(slow: _slow && _c.phase == GatePhase.loading);
      case GatePhase.prayer:
        final prayer = _c.prayer;
        return GatePrayerView(
          app: _label,
          prayer: prayer == null ? '' : l10n.notifPrayerName(prayer.name),
          onPray: () => unawaited(_c.prayFirst()),
          onShowCards: _c.showCardsAnyway,
        );
      case GatePhase.emergency:
        return GateEmergencyView(
          app: _label,
          secondsLeft: _c.emergencySecondsLeft,
          onCancel: _c.cancelEmergency,
        );
      case GatePhase.unlocked:
        return GateUnlockedView(
          app: _label,
          minutes: _c.unlockMinutes,
          setFinished: _setFinished,
          onContinue: () => unawaited(_c.continueToApp()),
          onClose: () => unawaited(_c.goBack()),
          onKeepReading: _c.keepReading,
        );
      case GatePhase.error:
        return GateErrorView(
          app: _label,
          onContinue: () => unawaited(_c.continueAfterError()),
          onBack: () => unawaited(_c.goBack()),
        );
      case GatePhase.empty:
        return GateEmptyView(
          app: _label,
          onContinue: () => unawaited(_c.continueAfterError()),
        );
      case GatePhase.cards:
        return _cards(context);
    }
  }

  /// Gate karty dokoncili sadu (zobrazi sa namiesto B10, docs/02 A4).
  bool get _setFinished {
    final items = _c.items;
    var lastSet = -1;
    for (var i = 0; i < items.length; i++) {
      if (items[i] is SetGateItem) lastSet = i;
    }
    return lastSet >= 0 &&
        _c.isPassed(lastSet) &&
        items.skip(lastSet + 1).any((i) => i is FreeReadingItem);
  }

  Widget _cards(BuildContext context) {
    final items = _c.items;
    final page = _c.page;
    final current = page < items.length ? items[page] : null;
    final passed = _c.isPassed(page);
    final canNext = passed && page + 1 < _c.reachable;
    final l10n = context.l10n;
    return Column(
      children: [
        GateHeader(
          app: _label,
          done: _c.cardsSeen,
          total: _c.cardsRequired,
          freeReading: current is FreeReadingItem,
          onBack: () => unawaited(_c.goBack()),
          onContinue: _c.unlocked ? () => unawaited(_c.continueToApp()) : null,
          continueLabel: _c.unlocked ? l10n.gateContinueFor(_label) : null,
        ),
        Expanded(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context)
                .copyWith(physics: const ClampingScrollPhysics()),
            child: PageView.builder(
              controller: _pager,
              scrollDirection: Axis.vertical,
              itemCount: _c.reachable,
              onPageChanged: _c.showPage,
              itemBuilder: _page,
            ),
          ),
        ),
        GateFooter(
          secondsLeft: passed ? 0 : _c.dwellSecondsLeft,
          onNext: canNext ? _next : null,
          onEmergency: _c.unlocked ? null : _c.startEmergency,
          onEmergencyA11y: () => unawaited(_emergencyA11y()),
        ),
      ],
    );
  }

  Widget _page(BuildContext context, int i) {
    final items = _c.items;
    if (i >= items.length) return const SizedBox.shrink();
    final item = items[i];
    final date = _c.date!;
    final content = ref.watch(cardContentProvider(item.cardId));
    if (i == _c.page && !_c.isPassed(i)) {
      if (content case AsyncData(value: null)) {
        // Chybajuci obsah: preskocit, nepocita sa (docs/02 A3).
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_c.skipMissing(i));
        });
      } else if (content.value != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _c.contentReady(i);
        });
      }
    }
    final l10n = context.l10n;
    return Semantics(
      customSemanticsActions: {
        if (i == _c.page && _c.isPassed(i) && i + 1 < _c.reachable)
          CustomSemanticsAction(label: l10n.gateNext): _next,
      },
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: SkSpace.space16,
          vertical: SkSpace.space8,
        ),
        child: CardView(
          key: ValueKey(item.cardId),
          cardId: item.cardId,
          date: date,
          surface: CardSurface.gate,
          onSkip: () => unawaited(_c.skipMissing(i)),
        ),
      ),
    );
  }
}
