import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/data/repositories/infra/card_events.dart';
import 'package:prosoche/data/repositories/infra/databases.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/quests.dart' as q;

export 'package:prosoche/data/db/user_enums.dart'
    show GateIntent, GateResult, UnlockSource;

/// Blokovana appka, ako ju vidi brana (`blocked_app`, docs/02 A4, D12).
@immutable
final class GateTarget {
  const GateTarget({
    required this.id,
    required this.ref,
    required this.cardsRequired,
    required this.unlockMinutes,
    this.label,
    this.enabled = true,
    this.practiceFirst = true,
  });

  final int id;

  /// Package name. Nikdy nelogovat.
  final String ref;
  final String? label;
  final int cardsRequired;
  final int unlockMinutes;
  final bool enabled;

  /// Plati pre nu ranny zamok "Practice first" (G-01).
  final bool practiceFirst;

  @override
  bool operator ==(Object other) =>
      other is GateTarget &&
      other.id == id &&
      other.ref == ref &&
      other.label == label &&
      other.cardsRequired == cardsRequired &&
      other.unlockMinutes == unlockMinutes &&
      other.enabled == enabled &&
      other.practiceFirst == practiceFirst;

  @override
  int get hashCode => Object.hash(
    id,
    ref,
    label,
    cardsRequired,
    unlockMinutes,
    enabled,
    practiceFirst,
  );
}

/// Zapisy brany do user.db: `gate_session`, `unlock_event` a volne citanie
/// (B11). Kratke transakcie, user.db je vo WAL rezime a pristupuje k nej aj
/// engine hlavnej appky (ADR-16 dosledky, docs/02 D14).
abstract interface class GateRepository {
  /// Appka z `blocked_app` podla package name; null = nie je blokovana.
  Future<GateTarget?> app(String ref);

  /// Otvori `gate_session` (result null, kym brana bezi).
  Future<int> openSession(int? appId);

  /// Uzavrie session; opakovane volanie prepise vysledok a pocet kariet.
  Future<void> closeSession(
    int sessionId, {
    required GateResult result,
    required int cardsSeen,
  });

  Future<void> logUnlock(
    int? appId, {
    required UnlockSource source,
    required int minutes,
  });

  /// Karta volneho citania v brane (B11): `card_event{seen, context=gate,
  /// pos=null}`.
  Future<void> markFreeReading(LocalDate date, CardId card);

  /// Zamer otvorenia k session (G-01); null = preskocene.
  Future<void> setIntent(int sessionId, GateIntent? intent);

  /// Kolkokrat sa brana appky [appId] otvorila od lokalnej polnoci dna
  /// [date] (vratane aktualnej session, G-01).
  Future<int> opensOn(int appId, LocalDate date);

  /// Ranna priprava dna [date] je dokoncena (`practice_log`, G-01).
  Future<bool> morningPracticeDone(LocalDate date);
}

class DriftGateRepository implements GateRepository {
  DriftGateRepository({required UserDb userDb, required this._clock})
    : _db = userDb;

  final UserDb _db;
  final Clock _clock;

  @override
  Future<GateTarget?> app(String ref) async {
    final row = await _db.blockerDao.appByRef(ref);
    if (row == null) return null;
    return GateTarget(
      id: row.id,
      ref: row.platformRef,
      label: row.label,
      cardsRequired: row.cardsRequired,
      unlockMinutes: row.unlockMinutes,
      enabled: row.enabled,
      practiceFirst: row.practiceFirst,
    );
  }

  @override
  Future<int> openSession(int? appId) =>
      _db.blockerDao.openSession(appId, _clock.now().toUtc());

  @override
  Future<void> closeSession(
    int sessionId, {
    required GateResult result,
    required int cardsSeen,
  }) => _db.blockerDao.closeSession(
    sessionId,
    result: result,
    cardsSeen: cardsSeen,
    now: _clock.now().toUtc(),
  );

  @override
  Future<void> logUnlock(
    int? appId, {
    required UnlockSource source,
    required int minutes,
  }) => _db.blockerDao.logUnlock(
    blockedAppId: appId,
    source: source,
    minutes: minutes,
    ts: _clock.now().toUtc(),
  );

  @override
  Future<void> markFreeReading(LocalDate date, CardId card) async {
    await logCardEvent(
      _db,
      date: date,
      card: card,
      action: q.CardAction.seen,
      context: q.CardContext.gate,
      now: _clock.now(),
    );
  }

  @override
  Future<void> setIntent(int sessionId, GateIntent? intent) =>
      _db.blockerDao.setSessionIntent(sessionId, intent);

  @override
  Future<int> opensOn(int appId, LocalDate date) =>
      _db.blockerDao.sessionCountSince(appId, date.toLocalDateTime().toUtc());

  @override
  Future<bool> morningPracticeDone(LocalDate date) async =>
      (await _db.practiceLogDao.watchDone(date).first).contains(
        JournalKind.morning,
      );
}

/// Zapisy brany. V testoch `gateRepositoryProvider.overrideWithValue(...)`.
final Provider<GateRepository> gateRepositoryProvider =
    Provider<GateRepository>(
      (ref) => DriftGateRepository(
        userDb: ref.watch(userDbProvider),
        clock: ref.watch(appClockProvider),
      ),
      name: 'gateRepositoryProvider',
    );
