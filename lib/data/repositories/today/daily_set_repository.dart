import 'dart:async';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show ComparableExpr;
import 'package:meta/meta.dart';
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/data/db/user_db.dart' as db;
import 'package:prosoche/data/repositories/catalog/content_catalog.dart';
import 'package:prosoche/data/repositories/infra/card_events.dart';
import 'package:prosoche/data/repositories/today/quest_repository.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/feed.dart';
import 'package:prosoche/domain/quests/quests.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';

/// Ulozena denna sada a jej progres (docs/02 0.3, D13; A2 CTA, A3).
@immutable
final class DailySetState {
  const DailySetState({
    required this.set,
    required this.cursor,
    this.startedAt,
    this.completedAt,
  });

  final DailySet set;

  /// Najvyssia pozicia `seen`/`answered`/`skipped` bez medzery od 1
  /// (docs/02 0.4). Feed sa otvori na `cursor + 1`.
  final int cursor;

  /// Lokalny cas prveho posunu cursoru.
  final DateTime? startedAt;

  /// Lokalny cas dokoncenia (`daily_set.completed_at`).
  final DateTime? completedAt;

  LocalDate get date => set.date;

  /// N kariet sady.
  int get n => set.n;

  /// Prejdene obsahove karty (CTA "Continue (x/N)").
  int get seenContentCount =>
      set.contentCards.where((c) => c.pos <= cursor).length;

  bool get isStarted => cursor > 0;
  bool get isCompleted => completedAt != null;

  /// Karta, na ktorej sa feed otvori; null = sada je prejdena (karta done).
  DailySetCard? get nextCard =>
      cursor < set.cards.length ? set.cards[cursor] : null;
}

/// Vysledok zapisu `seen` karty v sade.
@immutable
final class SeenResult {
  const SeenResult({
    required this.newlySeen,
    required this.cursor,
    this.completedNow = false,
  });

  /// `seen` sa zapisal prvy raz (docs/02 0.4).
  final bool newlySeen;
  final int cursor;

  /// Tymto zapisom sa sada dokoncila (zobrazit B10).
  final bool completedNow;
}

/// Denna sada: vyber `activeSetDate`, generovanie raz za den, `seen`,
/// cursor a dokoncenie (plan 7.1, docs/02 0.1-0.4, A2, A3, B10).
abstract interface class DailySetRepository {
  /// `activeSetDate` pre `localDate` (docs/02 0.1): pri ceste na zapad
  /// (localDate < najvyssia ulozena sada) je to najvyssia ulozena sada.
  Future<LocalDate> activeSetDate(LocalDate localDate);

  /// Sada dna [date]; ak este nie je, vygeneruje ju (FeedGenerator) a ulozi.
  /// Pre
  /// datum nizsi ako najvyssia ulozena sada sa nikdy negeneruje
  /// ([StateError]). [shorterSet] plati len pri generovani (docs/01 D6).
  Future<DailySetState> ensure(LocalDate date, {bool shorterSet = false});

  /// Ulozena sada alebo null (bez generovania).
  Future<DailySetState?> get(LocalDate date);

  /// Ulozena sada a kazda jej zmena (cursor, dokoncenie).
  Stream<DailySetState?> watch(LocalDate date);

  /// Pocet dni bez sady pred [date] (ponuka "shorter set" od 7).
  Future<int> inactiveDays(LocalDate date);

  /// Karta [card] je videna (dwell splneny). Zapise `card_event{seen}`
  /// najviac raz, posunie cursor, po poslednej karte `completed_at`
  /// a vyhodnoti auto questy.
  Future<SeenResult> markSeen(
    LocalDate date,
    DailySetCard card, {
    CardContext context = CardContext.feed,
  });

  /// Karta odkazuje na chybajuci obsah (A3): `card_event{skipped}`, cursor
  /// ju preskoci.
  Future<SeenResult> markSkipped(
    LocalDate date,
    DailySetCard card, {
    CardContext context = CardContext.feed,
  });

  /// Karta "done" (B10) zobrazena: `seen` raz, `completed_at` ak chyba.
  Future<void> markDoneShown(LocalDate date);
}

/// Odkial sa beru hranice faz dna pre generovanie (null = pevne hodiny).
typedef DayBoundariesSource = Future<DayBoundaries?> Function(LocalDate date);

class DriftDailySetRepository implements DailySetRepository {
  DriftDailySetRepository({
    required db.UserDb userDb,
    required this._catalog,
    required this._quests,
    required this._settings,
    required this._clock,
    required this._installId,
    required this._timeZone,
    this._dayBoundaries,
    this._disabledIds,
    this._logger,
    this._generator = const FeedGenerator(),
  }) : _db = userDb;

  final db.UserDb _db;
  final ContentCatalog _catalog;
  final QuestRepository _quests;
  final SettingsRepository _settings;
  final Clock _clock;
  final Future<String> Function() _installId;
  final Future<String> Function() _timeZone;
  final DayBoundariesSource? _dayBoundaries;
  final Set<CardId> Function()? _disabledIds;
  final AppLogger? _logger;
  final FeedGenerator _generator;

  /// Cooldown obsahu (docs/03 P7).
  static const historyDays = 365;

  final _inFlight = <LocalDate, Future<DailySetState>>{};

  @override
  Future<LocalDate> activeSetDate(LocalDate localDate) async {
    final latest = await _db.dailySetDao.latestDate();
    return latest != null && latest.isAfter(localDate) ? latest : localDate;
  }

  @override
  Future<DailySetState?> get(LocalDate date) async =>
      _state(await _db.dailySetDao.byDate(date));

  @override
  Stream<DailySetState?> watch(LocalDate date) =>
      _db.dailySetDao.watchByDate(date).map(_state);

  DailySetState? _state(db.DailySetRow? row) {
    if (row == null) return null;
    return DailySetState(
      set: DailySet.decode(row.cardsJson, date: row.date),
      cursor: row.cursor,
      startedAt: row.startedAt?.toLocal(),
      completedAt: row.completedAt?.toLocal(),
    );
  }

  @override
  Future<int> inactiveDays(LocalDate date) async {
    final prev = await (_db.select(
      _db.dailySets,
    )..where((t) => t.date.isSmallerThanValue(date.toString()))).get();
    if (prev.isEmpty) return 0;
    final last = prev.map((r) => r.date).reduce((a, b) => a.isAfter(b) ? a : b);
    return date.daysSince(last) - 1;
  }

  @override
  Future<DailySetState> ensure(LocalDate date, {bool shorterSet = false}) =>
      _inFlight[date] ??= _ensure(date, shorterSet).whenComplete(() {
        // Bez navratovej hodnoty: whenComplete by cakal na seba sama.
        unawaited(_inFlight.remove(date));
      });

  Future<DailySetState> _ensure(LocalDate date, bool shorterSet) async {
    final existing = await get(date);
    if (existing != null) return existing;
    final latest = await _db.dailySetDao.latestDate();
    if (latest != null && latest.isAfter(date)) {
      throw StateError('daily set for $date is older than latest $latest');
    }
    final watch = Stopwatch()..start();
    final installId = await _installId();
    final inputs = await _inputs(date, installId, shorterSet);
    final result = _generator.generate(inputs);
    await _db.dailySetDao.insertIfAbsent(
      date: date,
      seed: inputs.seed,
      cardsJson: result.set.encode(),
      generatorVersion: result.set.generatorVersion,
      contentVersion: inputs.contentVersion ?? 'unknown',
      tz: inputs.tz ?? 'UTC',
      phase: db.DayPhase.values.byName(result.set.phase.wire),
    );
    _logger?.info('daily_set', 'generated', {'ms': watch.elapsedMilliseconds});
    return (await get(date))!;
  }

  Future<FeedInputs> _inputs(
    LocalDate date,
    String installId,
    bool shorterSet,
  ) async {
    final cardsCount = await _settings.get(SettingsKeys.feedCardsCount);
    return FeedInputs(
      date: date,
      seed: feedSeed(date, installId),
      generatedAtLocalTime: _clock.now(),
      dayBoundaries: await _dayBoundaries?.call(date),
      prefs: FeedPrefs(cardsCount: cardsCount, shorterSet: shorterSet),
      inactiveDays: await inactiveDays(date),
      pools: await _catalog.feedPools(),
      history: FeedHistory(
        lastShown: await _lastShown(date),
        disabledIds: _disabledIds?.call() ?? const {},
      ),
      contentVersion: await _catalog.contentVersion(),
      tz: await _timeZone(),
    );
  }

  /// Posledne zobrazenie karty z ulozenych sad za [historyDays] dni.
  Future<Map<CardId, LocalDate>> _lastShown(LocalDate date) async {
    final rows = await _db.dailySetDao.range(
      date.addDays(-historyDays),
      date.addDays(-1),
    );
    final out = <CardId, LocalDate>{};
    for (final r in rows) {
      try {
        for (final c in DailySet.decode(r.cardsJson, date: r.date).cards) {
          out[c.cardId] = r.date;
        }
      } on FormatException {
        // Poskodena stara sada neblokuje novu.
      }
    }
    return out;
  }

  @override
  Future<SeenResult> markSeen(
    LocalDate date,
    DailySetCard card, {
    CardContext context = CardContext.feed,
  }) => _pass(date, card, CardAction.seen, context);

  @override
  Future<SeenResult> markSkipped(
    LocalDate date,
    DailySetCard card, {
    CardContext context = CardContext.feed,
  }) => _pass(date, card, CardAction.skipped, context);

  Future<SeenResult> _pass(
    LocalDate date,
    DailySetCard card,
    CardAction action,
    CardContext context,
  ) async {
    final now = _clock.now();
    final result = await _db.transaction(() async {
      final state = await get(date);
      if (state == null) throw StateError('no daily set for $date');
      final newly = await logCardEvent(
        _db,
        date: date,
        card: card.cardId,
        action: action,
        context: context,
        now: now,
        pos: card.pos,
      );
      final cursor = await _contiguous(state);
      if (cursor > state.cursor) {
        await _db.dailySetDao.advanceCursor(date, cursor, now.toUtc());
      }
      final lastContent = state.set.contentCards.lastOrNull?.pos ?? 0;
      final completedNow =
          cursor >= lastContent &&
          await _db.dailySetDao.markCompleted(date, now.toUtc());
      return SeenResult(
        newlySeen: newly,
        cursor: cursor > state.cursor ? cursor : state.cursor,
        completedNow: completedNow,
      );
    });
    await _quests.syncAuto(date);
    return result;
  }

  /// Najvyssia pozicia prejdena bez medzery (seen, answered, skipped
  /// v kontexte feed alebo gate).
  Future<int> _contiguous(DailySetState state) async {
    final passed = <String>{};
    for (final action in [
      db.CardAction.seen,
      db.CardAction.answered,
      db.CardAction.skipped,
    ]) {
      for (final ctx in [db.CardContext.feed, db.CardContext.gate]) {
        passed.addAll(
          await _db.cardEventDao.cardIds(
            state.date,
            action: action,
            context: ctx,
          ),
        );
      }
    }
    var cursor = 0;
    for (final c in state.set.cards) {
      if (!passed.contains(c.cardId.format())) break;
      cursor = c.pos;
    }
    return cursor;
  }

  @override
  Future<void> markDoneShown(LocalDate date) async {
    final now = _clock.now();
    await logCardEvent(
      _db,
      date: date,
      card: DoneCardId(date),
      action: CardAction.seen,
      context: CardContext.feed,
      now: now,
    );
    await _db.dailySetDao.markCompleted(date, now.toUtc());
    await _quests.syncAuto(date);
  }
}
