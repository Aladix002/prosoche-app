import 'package:drift/drift.dart';
import 'package:prosoche/data/db/user_db.dart';

part 'blocker_dao.g.dart';

/// Brana: blokovane appky, sessions, odomknutia (docs/02 D12; A4, O5,
/// A10.1, A10.2).
@DriftAccessor(tables: [BlockedApps, GateSessions, UnlockEvents])
class BlockerDao extends DatabaseAccessor<UserDb> with _$BlockerDaoMixin {
  BlockerDao(super.attachedDatabase);

  SimpleSelectStatement<$BlockedAppsTable, BlockedAppRow> get _apps =>
      select(blockedApps)..orderBy([(t) => OrderingTerm.asc(t.id)]);

  Future<List<BlockedAppRow>> apps() => _apps.get();

  Stream<List<BlockedAppRow>> watchApps() => _apps.watch();

  Future<BlockedAppRow?> appByRef(String platformRef) => (select(
    blockedApps,
  )..where((t) => t.platformRef.equals(platformRef))).getSingleOrNull();

  /// Prida appku, existujucu (`platform_ref`) necha tak. Vrati jej riadok.
  Future<BlockedAppRow> addApp({
    required String platformRef,
    required DateTime now,
    String? label,
    int? cardsRequired,
    int? unlockMinutes,
  }) => transaction(() async {
    final existing = await appByRef(platformRef);
    if (existing != null) return existing;
    return await into(blockedApps).insertReturning(
      BlockedAppsCompanion.insert(
        platformRef: platformRef,
        label: Value(label),
        cardsRequired: Value.absentIfNull(cardsRequired),
        unlockMinutes: Value.absentIfNull(unlockMinutes),
        createdAt: now,
      ),
    );
  });

  /// Zmeni nastavenia appky (A10.2); null pole sa nemeni.
  Future<bool> updateApp(
    int id, {
    int? cardsRequired,
    int? unlockMinutes,
    bool? enabled,
    String? label,
    bool? practiceFirst,
  }) async {
    final n = await (update(blockedApps)..where((t) => t.id.equals(id))).write(
      BlockedAppsCompanion(
        cardsRequired: Value.absentIfNull(cardsRequired),
        unlockMinutes: Value.absentIfNull(unlockMinutes),
        enabled: Value.absentIfNull(enabled),
        label: Value.absentIfNull(label),
        practiceFirst: Value.absentIfNull(practiceFirst),
      ),
    );
    return n > 0;
  }

  /// Odstrani appku; jej sessions a odomknutia ostanu bez odkazu
  /// (`ON DELETE SET NULL`), tyzdenna statistika sa nemeni.
  Future<void> removeApp(int id) =>
      (delete(blockedApps)..where((t) => t.id.equals(id))).go();

  // ------------------------------------------------------------- sessions
  Future<int> openSession(int? blockedAppId, DateTime now) => into(gateSessions)
      .insert(
        GateSessionsCompanion.insert(
          blockedAppId: Value(blockedAppId),
          openedAt: now,
        ),
      );

  Future<void> closeSession(
    int sessionId, {
    required GateResult result,
    required int cardsSeen,
    required DateTime now,
  }) => (update(gateSessions)..where((t) => t.id.equals(sessionId))).write(
    GateSessionsCompanion(
      result: Value(result),
      cardsSeen: Value(cardsSeen),
      closedAt: Value(now),
    ),
  );

  /// Zamer otvorenia (G-01); null = preskocene.
  Future<void> setSessionIntent(int sessionId, GateIntent? intent) =>
      (update(gateSessions)..where((t) => t.id.equals(sessionId))).write(
        GateSessionsCompanion(intent: Value(intent)),
      );

  /// Pocet otvoreni brany appky [blockedAppId] od [since] (vratane),
  /// pocitadlo "{n}th time today" (G-01).
  Future<int> sessionCountSince(int blockedAppId, DateTime since) async {
    final c = gateSessions.id.count();
    final q = selectOnly(gateSessions)
      ..addColumns([c])
      ..where(
        gateSessions.blockedAppId.equals(blockedAppId) &
            gateSessions.openedAt.isBiggerOrEqualValue(
              since.millisecondsSinceEpoch,
            ),
      );
    final rows = await q.get();
    return rows.isEmpty ? 0 : rows.first.read<int>(c) ?? 0;
  }

  Future<GateSessionRow?> session(int id) =>
      (select(gateSessions)..where((t) => t.id.equals(id))).getSingleOrNull();

  // -------------------------------------------------------------- unlocks
  Future<int> logUnlock({
    required int? blockedAppId,
    required UnlockSource source,
    required int minutes,
    required DateTime ts,
  }) => into(unlockEvents).insert(
    UnlockEventsCompanion.insert(
      blockedAppId: Value(blockedAppId),
      ts: ts,
      source: source,
      minutes: minutes,
    ),
  );

  /// Pocet odomknuti od [since] podla zdroja, volitelne pre jednu appku
  /// (statistika tyzdna A10.1, A10.2).
  Future<Map<UnlockSource, int>> unlockCounts(
    DateTime since, {
    int? blockedAppId,
  }) async {
    final c = unlockEvents.id.count();
    var where = unlockEvents.ts.isBiggerOrEqualValue(
      since.millisecondsSinceEpoch,
    );
    if (blockedAppId != null) {
      where &= unlockEvents.blockedAppId.equals(blockedAppId);
    }
    final q = selectOnly(unlockEvents)
      ..addColumns([unlockEvents.source, c])
      ..where(where)
      ..groupBy([unlockEvents.source]);
    return {
      for (final r in await q.get())
        r.readWithConverter(unlockEvents.source)!: r.read(c)!,
    };
  }
}
