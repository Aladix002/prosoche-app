import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/blocker/blocker_gateway.dart';
import 'package:prosoche/data/blocker/gate_repository.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/blocker/gate_friction.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/quests.dart';
import 'package:prosoche/features/gate/gate_deck.dart';

/// Pravidla brany (docs/02 A4, docs/01 5.3, TECHNICKY_PLAN 9.2).
abstract final class GateRules {
  /// `gate.min_dwell_ms`: dwell karty je `max(card.seen_dwell_ms, 4000)`.
  static const minDwell = Duration(milliseconds: 4000);

  /// Karty sa nenacitali do 3 s = chyba ("Continue to {app}").
  static const loadTimeout = Duration(seconds: 3);

  /// Odpocet emergency po podrzani 1,5 s.
  static const emergencyCountdown = Duration(seconds: 10);

  /// Obrazovka "is open for" bez akcie -> automaticky "Continue".
  static const autoContinue = Duration(seconds: 5);

  /// `blocked_app.unlock_minutes` default, ked appka nie je znama.
  static const defaultUnlockMinutes = 10;

  /// Po tolkych kartach bez obsahu za sebou brana skonci stavom empty.
  static const maxMissingInRow = 5;
}

/// Faza brany (stavy docs/02 A4).
enum GatePhase {
  loading,

  /// "Why are you opening {app}?" pred kartami (G-01).
  intent,

  /// Ranny zamok "Practice first": namiesto kariet Practice (G-01).
  practiceFirst,

  cards,

  /// Emergency odpocet 10 s.
  emergency,

  /// N kariet prejdenych, appka odomknuta.
  unlocked,

  /// Nic na zobrazenie, appka sa otvori.
  empty,

  /// Chyba alebo timeout: "Continue to {app}" (`source=error`).
  error,

  /// Brana sa zavrela (nativ uz prepina na home alebo appku).
  closed,
}

/// Nastavenia brany z `settings` (G-01). Default = vsetko vypnute.
@immutable
class GateOptions {
  const GateOptions({
    this.askIntent = false,
    this.risingFriction = false,
    this.practiceFirst = const PracticeFirstRule(
      enabled: false,
      until: PracticeFirstRule.defaultUntil,
    ),
  });

  /// `gate.ask_intent`
  final bool askIntent;

  /// `gate.rising_friction`
  final bool risingFriction;

  /// `gate.practice_first` a `gate.practice_first.until`
  final PracticeFirstRule practiceFirst;
}

/// Zavislosti brany, v testoch fakes.
@immutable
class GateDeps {
  const GateDeps({
    required this.blocker,
    required this.gates,
    required this.sets,
    required this.clock,
    required this.today,
    required this.log,
    this.dwellMs,
    this.freeReading,
    this.overlayEnabled,
    this.syncQuests,
    this.options,
  });

  final BlockerGateway blocker;
  final GateRepository gates;
  final DailySetRepository sets;
  final Clock clock;

  /// `localDate` pri otvoreni brany (z neho `activeSetDate`, docs/02 0.1).
  final LocalDate Function() today;
  final AppLogger log;

  /// `card.seen_dwell_ms`; null = default feedu.
  final Future<int?> Function()? dwellMs;

  /// Karty volneho citania po konci sady (B11); null = ziadne.
  final Future<List<CardId>> Function()? freeReading;

  /// Remote kill-switch `blocker_overlay` (docs/06 A.7); null = zapnute.
  final bool Function()? overlayEnabled;

  /// Prepocet auto questov po volnom citani (READ quest).
  final Future<void> Function(LocalDate date)? syncQuests;

  /// Nastavenia G-01 (zamer, odpor, ranny zamok); null = vypnute.
  final Future<GateOptions> Function()? options;
}

/// Stav a logika jednej brany pre appku [ref]. Obrazovka len vykresluje.
///
/// Brana nikdy neuvazni: kazda chyba vedie do [GatePhase.error] s
/// "Continue to {app}" a ked zlyha aj nativ, `closeGate(openTarget: true)`
/// prepusti pouzivatela s kratkym prechodom (GateActivity).
class GateController extends ChangeNotifier {
  GateController({
    required this.ref,
    required this.deps,
    this.onClosed,
    this.onPractice,
  });

  static const _tag = 'gate';

  /// Package name. Nikdy nelogovat.
  final String ref;
  final GateDeps deps;

  /// Brana sa zavrela (GateTarget sa vrati do necinneho stavu).
  final VoidCallback? onClosed;

  /// Brana sa zavrela cez "Start morning preparation" (hlavny engine
  /// prejde na Practice); null = [onClosed].
  final VoidCallback? onPractice;

  GatePhase _phase = GatePhase.loading;
  GatePhase get phase => _phase;

  /// Faza pred emergency odpoctom (Cancel sa do nej vrati).
  GatePhase _beforeEmergency = GatePhase.cards;

  GateTarget? _app;
  GateTarget? get app => _app;

  int? _sessionId;
  LocalDate? _date;
  LocalDate? get date => _date;
  late GateDeck _deck;

  final _items = <GateItem>[];
  List<GateItem> get items => List.unmodifiable(_items);

  final _passed = <int>{};
  int _missingInRow = 0;

  /// Aktualna karta (index v [items]).
  int _page = 0;
  int get page => _page;

  int get cardsRequired =>
      math.max(_app?.cardsRequired ?? 0, 1) + _friction.extraCards;

  GateFriction _friction = GateFriction.none;

  /// Rastuci odpor tohto otvorenia (G-01).
  GateFriction get friction => _friction;

  /// Kolkate otvorenie appky dnes; null = pocitadlo vypnute (G-01).
  int? _opensToday;
  int? get opensToday => _opensToday;

  /// Koniec ranneho zamku `HH:mm` vo faze [GatePhase.practiceFirst].
  int _practiceUntil = 0;

  /// Minuta dna, kedy ranny zamok skonci aj bez pripravy.
  int get practiceUntilMinutes => _practiceUntil;
  int get unlockMinutes =>
      _app?.unlockMinutes ?? GateRules.defaultUnlockMinutes;

  /// Prejdene karty (aj po odomknuti pri "Keep reading").
  int get cardsSeen => _passed.length;

  /// Odomknute po N kartach; dalsie karty su "Keep reading".
  bool _unlocked = false;
  bool get unlocked => _unlocked;

  Duration _dwell = GateRules.minDwell;
  Timer? _dwellTimer;
  Timer? _tick;
  int? _awaiting;
  int _dwellLeft = 0;

  /// Sekundy do konca dwellu aktualnej karty (0 = da sa pokracovat).
  int get dwellSecondsLeft => _dwellLeft;

  int _emergencyLeft = 0;
  int get emergencySecondsLeft => _emergencyLeft;
  Timer? _emergencyTimer;

  Timer? _loadTimer;
  Timer? _autoContinue;
  bool _busy = false;
  bool _disposed = false;

  bool isPassed(int index) => _passed.contains(index);

  /// Karty, na ktore sa da prejst (aktualna neprejdena je posledna).
  int get reachable {
    for (var i = 0; i < _items.length; i++) {
      if (!_passed.contains(i)) return i + 1;
    }
    return _items.length;
  }

  // ------------------------------------------------------------- start

  /// Nacita appku, sadu a karty; po [GateRules.loadTimeout] chyba.
  Future<void> start() async {
    _loadTimer = Timer(GateRules.loadTimeout, () {
      if (_phase == GatePhase.loading) {
        deps.log.warn(_tag, 'gate load timeout');
        _setPhase(GatePhase.error);
      }
    });
    try {
      await _load();
    } on Object catch (e, st) {
      deps.log.error(_tag, 'gate load failed', error: e, stack: st);
      if (_phase == GatePhase.loading) _setPhase(GatePhase.error);
    } finally {
      _loadTimer?.cancel();
    }
  }

  Future<void> _load() async {
    if (!(deps.overlayEnabled?.call() ?? true)) {
      // Kill-switch: brana sa nezobrazi (docs/06 A.7).
      await _close(openTarget: true);
      return;
    }
    final app = await deps.gates.app(ref);
    if (_phase != GatePhase.loading) return;
    if (app == null || !app.enabled) {
      // Stary intent alebo appka uz nie je blokovana: zavriet bez UI.
      await _close(openTarget: true);
      return;
    }
    _app = app;
    _sessionId = await deps.gates.openSession(app.id);
    final options = await deps.options?.call() ?? const GateOptions();
    final today = deps.today();
    final rule = options.practiceFirst;
    if (rule.enabled && app.practiceFirst) {
      final done = await deps.gates.morningPracticeDone(today);
      if (_phase != GatePhase.loading) return;
      if (rule.locks(
        now: deps.clock.now(),
        appSelected: app.practiceFirst,
        morningDone: done,
      )) {
        _practiceUntil = rule.untilMinutes;
        _setPhase(GatePhase.practiceFirst);
        return;
      }
    }
    if (options.risingFriction) {
      final opens = await deps.gates.opensOn(app.id, today);
      _opensToday = math.max(opens, 1);
      _friction = GateFriction.forOpen(opens);
    }
    final date = await deps.sets.activeSetDate(today);
    final state = await deps.sets.ensure(date);
    final extra = await deps.freeReading?.call() ?? const <CardId>[];
    final dwellMs = await deps.dwellMs?.call();
    if (_phase != GatePhase.loading) return;
    _date = date;
    _dwell = _friction.dwell(
      Duration(
        milliseconds: math.max(dwellMs ?? 0, GateRules.minDwell.inMilliseconds),
      ),
    );
    _deck = GateDeck(
      cards: state.set.cards,
      cursor: state.cursor,
      extra: extra,
    );
    final first = _deck.next();
    if (first == null) {
      _setPhase(GatePhase.empty);
      return;
    }
    _items.add(first);
    if (options.askIntent) {
      _setPhase(GatePhase.intent);
      return;
    }
    _setPhase(GatePhase.cards);
    _activate(0);
  }

  // ------------------------------------------------------------ zamer

  /// Odpoved na "Why are you opening {app}?" alebo "Skip" ([intent] null).
  /// Ulozi sa len lokalne k session, potom karty (G-01).
  Future<void> chooseIntent(GateIntent? intent) async {
    if (_phase != GatePhase.intent) return;
    final id = _sessionId;
    _setPhase(GatePhase.cards);
    _activate(_page);
    notifyListeners();
    if (intent != null && id != null) {
      await _guard('intent failed', () => deps.gates.setIntent(id, intent));
    }
  }

  /// "Start morning preparation": brana sa zavrie a otvori sa Practice,
  /// nic sa neodomkne (G-01).
  Future<void> openPractice() async {
    if (_phase != GatePhase.practiceFirst || _busy) return;
    _busy = true;
    await _closeSession(GateResult.dismissed);
    _emergencyTimer?.cancel();
    _setPhase(GatePhase.closed);
    final result = await deps.blocker.openPractice();
    if (result case Err(:final failure)) {
      deps.log.failure(_tag, failure);
      final close = await deps.blocker.closeGate(openTarget: false);
      if (close case Err(:final failure)) deps.log.failure(_tag, failure);
    }
    _busy = false;
    (onPractice ?? onClosed)?.call();
  }

  // ------------------------------------------------------------- karty

  /// Pouzivatel presiel na kartu [index] (swipe alebo "Next").
  void showPage(int index) {
    if (index < 0 || index >= _items.length || index == _page) return;
    _page = index;
    _activate(index);
    notifyListeners();
  }

  void _activate(int index) {
    _cancelDwell();
    final item = _items[index];
    if (_passed.contains(index)) return;
    unawaited(_markAuto(item));
    _dwellLeft = (_dwell.inMilliseconds / 1000).ceil();
    _awaiting = index;
  }

  /// Obsah karty [index] je zobrazeny: az teraz bezi dwell (docs/02 0.4).
  void contentReady(int index) {
    if (_awaiting != index || index != _page) return;
    if (_phase != GatePhase.cards) return;
    _awaiting = null;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_dwellLeft > 0) _dwellLeft--;
      notifyListeners();
    });
    _dwellTimer = Timer(_dwell, () => unawaited(_pass(index)));
  }

  void _cancelDwell() {
    _dwellTimer?.cancel();
    _tick?.cancel();
    _dwellTimer = null;
    _tick = null;
    _awaiting = null;
    _dwellLeft = 0;
  }

  Future<void> _markAuto(GateItem item) async {
    final date = _date;
    if (date == null) return;
    for (final c in item.autoSeenBefore) {
      await _guard(
        'auto seen failed',
        () => deps.sets.markSeen(date, c, context: CardContext.gate),
        type: c.cardId.type,
      );
    }
  }

  /// Obsah karty [index] chyba (ID zmizlo z content.db): `skipped` a
  /// namiesto nej dalsia karta, nepocita sa do N (docs/02 A3).
  Future<void> skipMissing(int index) async {
    if (index >= _items.length || _passed.contains(index)) return;
    final date = _date;
    final item = _items[index];
    if (date != null && item is SetGateItem) {
      await _guard(
        'skip failed',
        () => deps.sets.markSkipped(date, item.card, context: CardContext.gate),
        type: item.cardId.type,
      );
    }
    if (_disposed || _phase == GatePhase.closed) return;
    _missingInRow++;
    if (_missingInRow >= GateRules.maxMissingInRow) {
      _cancelDwell();
      _setPhase(GatePhase.empty);
      return;
    }
    final replacement = _deck.next();
    if (replacement == null) {
      _cancelDwell();
      _setPhase(GatePhase.empty);
      return;
    }
    _items[index] = replacement;
    if (index == _page) _activate(index);
    notifyListeners();
  }

  Future<void> _pass(int index) async {
    _cancelDwell();
    if (_passed.contains(index) || _date == null) return;
    _passed.add(index);
    _missingInRow = 0;
    if (index == _items.length - 1) {
      if (_deck.next() case final next?) _items.add(next);
    }
    notifyListeners();
    final date = _date!;
    final item = _items[index];
    switch (item) {
      case SetGateItem(:final card):
        await _guard(
          'card seen failed',
          () => deps.sets.markSeen(date, card, context: CardContext.gate),
          type: card.cardId.type,
        );
      case FreeReadingItem(:final cardId):
        await _guard(
          'free reading failed',
          () => deps.gates.markFreeReading(date, cardId),
          type: cardId.type,
        );
        await _guard(
          'quest sync failed',
          () async => await deps.syncQuests?.call(date),
          type: cardId.type,
        );
    }
    if (!_unlocked && _passed.length >= cardsRequired) await _unlock();
  }

  Future<void> _unlock() async {
    final app = _app;
    if (app == null || _unlocked) return;
    _unlocked = true;
    final result = await deps.blocker.unlockFor(
      ref,
      minutes: app.unlockMinutes,
    );
    if (result case Err(:final failure)) {
      // Continue aj tak prepusti (nativny kratky prechod).
      deps.log.failure(_tag, failure);
    } else {
      await _guard(
        'unlock log failed',
        () => deps.gates.logUnlock(
          app.id,
          source: UnlockSource.cards,
          minutes: app.unlockMinutes,
        ),
      );
    }
    await _closeSession(GateResult.passed);
    if (_phase != GatePhase.cards) return;
    _setPhase(GatePhase.unlocked);
    _autoContinue = Timer(
      GateRules.autoContinue,
      () => unawaited(continueToApp()),
    );
  }

  // ----------------------------------------------------------- akcie

  /// "Keep reading" po odomknuti (odomknutie uz plati).
  void keepReading() {
    if (_phase != GatePhase.unlocked) return;
    _autoContinue?.cancel();
    // Najprv strana, obrazovka podla nej vytvori PageView.
    _page = _items.length - 1;
    _setPhase(GatePhase.cards);
    _activate(_page);
    notifyListeners();
  }

  /// "Continue to {app}" po odomknuti alebo pri "Keep reading".
  Future<void> continueToApp() async {
    if (!_unlocked) return;
    _autoContinue?.cancel();
    await _closeSession(GateResult.passed);
    await _close(openTarget: true);
  }

  /// "Go back", "Not now", Android back, "Close {app} instead": home
  /// screen, nic sa neodomkne (docs/02 A4).
  Future<void> goBack() async {
    if (_phase == GatePhase.closed || _busy) return;
    _autoContinue?.cancel();
    _emergencyTimer?.cancel();
    await _closeSession(
      _unlocked
          ? GateResult.passed
          : _phase == GatePhase.error
          ? GateResult.error
          : GateResult.dismissed,
    );
    await _close(openTarget: false);
  }

  /// "Continue to {app}" v chybe alebo v prazdnom stave: odomkne na
  /// `unlock_minutes` so `source=error` (docs/01 D5).
  Future<void> continueAfterError() async {
    if (_phase != GatePhase.error && _phase != GatePhase.empty) return;
    if (_busy) return;
    _busy = true;
    final minutes = unlockMinutes;
    final result = await deps.blocker.unlockFor(ref, minutes: minutes);
    if (result case Err(:final failure)) {
      deps.log.failure(_tag, failure);
    } else {
      await _guard(
        'unlock log failed',
        () => deps.gates.logUnlock(
          _app?.id,
          source: UnlockSource.error,
          minutes: minutes,
        ),
      );
    }
    await _closeSession(GateResult.error);
    _busy = false;
    await _close(openTarget: true);
  }

  /// Faza, z ktorej ide emergency (karty, otazka zameru, ranny zamok).
  static const Set<GatePhase> _emergencyFrom = {
    GatePhase.cards,
    GatePhase.intent,
    GatePhase.practiceFirst,
  };

  /// Podrzanie 1,5 s (alebo a11y dialog): 10 s odpocet (docs/01 D4).
  /// Emergency je dostupne vzdy, aj pri odpore a rannom zamku (G-01).
  void startEmergency() {
    if (!_emergencyFrom.contains(_phase) || _unlocked) return;
    _beforeEmergency = _phase;
    _cancelDwell();
    _emergencyLeft = GateRules.emergencyCountdown.inSeconds;
    _setPhase(GatePhase.emergency);
    _emergencyTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _emergencyLeft--;
      if (_emergencyLeft <= 0) {
        t.cancel();
        unawaited(_emergencyUnlock());
      } else {
        notifyListeners();
      }
    });
  }

  /// "Cancel" pocas odpoctu: nic sa neodomkne.
  void cancelEmergency() {
    if (_phase != GatePhase.emergency) return;
    _emergencyTimer?.cancel();
    _setPhase(_beforeEmergency);
    if (_phase == GatePhase.cards) _activate(_page);
  }

  Future<void> _emergencyUnlock() async {
    final app = _app;
    final result = await deps.blocker.unlockFor(
      ref,
      minutes: emergencyUnlockMinutes,
    );
    if (result case Err(:final failure)) {
      deps.log.failure(_tag, failure);
    } else {
      await _guard(
        'unlock log failed',
        () => deps.gates.logUnlock(
          app?.id,
          source: UnlockSource.emergency,
          minutes: emergencyUnlockMinutes,
        ),
      );
    }
    await _closeSession(GateResult.emergency);
    await _close(openTarget: true);
  }

  // --------------------------------------------------------- pomocne

  Future<void> _closeSession(GateResult result) async {
    final id = _sessionId;
    if (id == null) return;
    await _guard(
      'session close failed',
      () => deps.gates.closeSession(id, result: result, cardsSeen: cardsSeen),
    );
  }

  Future<void> _close({required bool openTarget}) async {
    if (_phase == GatePhase.closed) return;
    _cancelDwell();
    _emergencyTimer?.cancel();
    _autoContinue?.cancel();
    _loadTimer?.cancel();
    _setPhase(GatePhase.closed);
    final result = await deps.blocker.closeGate(openTarget: openTarget);
    if (result case Err(:final failure)) deps.log.failure(_tag, failure);
    onClosed?.call();
  }

  /// Zapis do DB nesmie zastavit branu; loguje sa len typ karty.
  Future<void> _guard(
    String what,
    Future<Object?> Function() body, {
    CardType? type,
  }) async {
    try {
      await body();
    } on Object catch (e, st) {
      deps.log.error(
        _tag,
        what,
        error: e,
        stack: st,
        kv: {if (type != null) 'type': type.wire},
      );
    }
  }

  void _setPhase(GatePhase phase) {
    if (_disposed || _phase == phase) return;
    _phase = phase;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    // Branu nahradila nova poziadavka (singleTask): session sa uzavrie.
    if (_phase != GatePhase.closed && _sessionId != null) {
      unawaited(
        _closeSession(_unlocked ? GateResult.passed : GateResult.dismissed),
      );
    }
    _disposed = true;
    _cancelDwell();
    _emergencyTimer?.cancel();
    _autoContinue?.cancel();
    _loadTimer?.cancel();
    super.dispose();
  }
}
