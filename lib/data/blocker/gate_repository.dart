import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/data/repositories/infra/card_events.dart';
import 'package:prosoche/data/repositories/infra/databases.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/quests.dart' as q;

export 'package:prosoche/data/db/user_enums.dart' show GateResult, UnlockSource;

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
  });

  final int id;

  /// Package name. Nikdy nelogovat.
  final String ref;
  final String? label;
  final int cardsRequired;
  final int unlockMinutes;
  final bool enabled;

  @override
  bool operator ==(Object other) =>
      other is GateTarget &&
      other.id == id &&
      other.ref == ref &&
      other.label == label &&
      other.cardsRequired == cardsRequired &&
      other.unlockMinutes == unlockMinutes &&
      other.enabled == enabled;

  @override
  int get hashCode =>
      Object.hash(id, ref, label, cardsRequired, unlockMinutes, enabled);
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
