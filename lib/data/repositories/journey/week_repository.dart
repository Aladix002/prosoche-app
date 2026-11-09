import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/data/repositories/cards/card_content_repository.dart';
import 'package:prosoche/data/repositories/catalog/content_catalog.dart';
import 'package:prosoche/data/repositories/infra/databases.dart';
import 'package:prosoche/data/repositories/providers.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/journey/week_summary.dart';
import 'package:prosoche/domain/practice/routine.dart';

export 'package:prosoche/domain/journey/week_summary.dart';

/// Data tyzdenneho prehladu (J-01). Len citanie existujucich tabuliek
/// user.db (`gate_session`, `blocked_app`, `card_event`, `practice_log`,
/// `daily_set`); dennik (journal.db) sa necita. Nic z toho nejde do
/// analytiky.
abstract interface class WeekRepository {
  /// Aktivita v okne [window]; nova hodnota pri kazdej zmene tabuliek.
  Stream<WeekActivity> watch(WeekWindow window);

  /// Kratky citat (`quote`, najviac [maxChars] znakov) pre zdielany
  /// obrazok. Vyber je deterministicky podla tyzdna dna [day] (cely
  /// tyzden rovnaky citat). null = ziadny vhodny citat.
  Future<QuoteContent?> quote(LocalDate day, {int maxChars});
}

/// Najdlhsi citat na obrazku tyzdna (zmesti sa vedla prehladu do 4:5).
const weekQuoteMaxChars = 120;

class DriftWeekRepository implements WeekRepository {
  DriftWeekRepository({
    required UserDb userDb,
    required this._catalog,
    Set<CardId> Function()? disabledIds,
  }) : _db = userDb,
       _disabledIds = disabledIds ?? (() => const {});

  final UserDb _db;
  final ContentCatalog _catalog;
  final Set<CardId> Function() _disabledIds;

  @override
  Stream<WeekActivity> watch(WeekWindow window) =>
      // Spustac: drift ho emituje hned a po kazdej zmene tychto tabuliek;
      // asyncMap drzi poradie nacitani.
      _db
          .customSelect(
            'SELECT 1',
            readsFrom: {
              _db.gateSessions,
              _db.blockedApps,
              _db.cardEvents,
              _db.practiceLogs,
              _db.dailySets,
            },
          )
          .watch()
          .asyncMap((_) => load(window));

  /// Jednorazove nacitanie (testy, [watch]).
  Future<WeekActivity> load(WeekWindow window) async {
    return WeekActivity(
      gateVisits: await _gateVisits(window),
      cardsReadByDay: await _cardsRead(window),
      practice: await _practice(window),
      firstActiveDay: await _firstActiveDay(),
    );
  }

  Future<List<GateVisit>> _gateVisits(WeekWindow window) async {
    final s = _db.gateSessions;
    final a = _db.blockedApps;
    final q =
        _db.select(s).join([leftOuterJoin(a, a.id.equalsExp(s.blockedAppId))])
          ..where(
            s.openedAt.isBiggerOrEqualValue(
                  window.from.toUtc().millisecondsSinceEpoch,
                ) &
                s.openedAt.isSmallerThanValue(
                  window.until.toUtc().millisecondsSinceEpoch,
                ),
          )
          ..orderBy([OrderingTerm.asc(s.openedAt)]);
    return [
      for (final r in await q.get())
        GateVisit(
          at: r.readTable(s).openedAt.toLocal(),
          outcome: _outcome(r.readTable(s).result),
          appLabel: r.readTableOrNull(a)?.label,
        ),
    ];
  }

  static GateOutcome _outcome(GateResult? r) => switch (r) {
    null => GateOutcome.open,
    GateResult.passed => GateOutcome.passed,
    GateResult.emergency => GateOutcome.emergency,
    GateResult.dismissed => GateOutcome.dismissed,
    GateResult.error => GateOutcome.error,
  };

  /// Rozne karty dna s `seen` z ktorehokolvek kontextu (feed, brana,
  /// citacka, ulozene), bez uvodnej a zaverecnej karty.
  Future<Map<LocalDate, int>> _cardsRead(WeekWindow window) async {
    final rows = await _db
        .customSelect(
          'SELECT date, COUNT(DISTINCT card_id) AS n FROM card_event '
          "WHERE action = 'seen' AND type NOT IN ('intro', 'done') "
          'AND date BETWEEN ? AND ? GROUP BY date',
          variables: [
            Variable.withString(window.start.toString()),
            Variable.withString(window.end.toString()),
          ],
          readsFrom: {_db.cardEvents},
        )
        .get();
    return {
      for (final r in rows)
        LocalDate.parse(r.read<String>('date')): r.read<int>('n'),
    };
  }

  Future<Map<LocalDate, Set<RoutineKind>>> _practice(WeekWindow window) async {
    final t = _db.practiceLogs;
    final rows =
        await (_db.select(t)..where(
              (t) => t.date.isBetweenValues(
                window.start.toString(),
                window.end.toString(),
              ),
            ))
            .get();
    final out = <LocalDate, Set<RoutineKind>>{};
    for (final r in rows) {
      final kind = switch (r.routine) {
        JournalKind.morning => RoutineKind.morning,
        JournalKind.evening => RoutineKind.evening,
        JournalKind.note => null,
      };
      if (kind != null) (out[r.date] ??= {}).add(kind);
    }
    return out;
  }

  Future<LocalDate?> _firstActiveDay() async {
    final row = await _db
        .customSelect(
          'SELECT MIN(d) AS d FROM ( '
          'SELECT MIN(date) AS d FROM daily_set '
          'UNION ALL SELECT MIN(date) FROM card_event '
          'UNION ALL SELECT MIN(date) FROM practice_log)',
          readsFrom: {_db.dailySets, _db.cardEvents, _db.practiceLogs},
        )
        .getSingle();
    final d = row.readNullable<String>('d');
    return d == null ? null : LocalDate.tryParse(d);
  }

  @override
  Future<QuoteContent?> quote(
    LocalDate day, {
    int maxChars = weekQuoteMaxChars,
  }) async {
    final db = await _catalog.db;
    final disabled = _disabledIds();
    final rows = [
      for (final r in await db.cardDao.ofType(CardType.quote.wire))
        if (r.textContent.length <= maxChars &&
            !r.textContent.contains('\n') &&
            !disabled.contains(CardId.tryParse(r.id)))
          r,
    ];
    if (rows.isEmpty) return null;
    // Index tyzdna od epochy (pondelok 5. 1. 1970 = tyzden 0).
    final epochDays = day.daysSince(LocalDate(1970, 1, 5));
    final row = rows[(epochDays ~/ 7) % rows.length];
    final id = CardId.tryParse(row.id);
    if (id is! ContentCardId) return null;
    final content = await contentFromRow(db, id, row);
    return content is QuoteContent ? content : null;
  }
}

/// V testoch `weekRepositoryProvider.overrideWithValue(...)`.
final Provider<WeekRepository> weekRepositoryProvider =
    Provider<WeekRepository>(
      (ref) => DriftWeekRepository(
        userDb: ref.watch(userDbProvider),
        catalog: ref.watch(contentCatalogProvider),
        disabledIds: () => ref.read(disabledCardIdsProvider),
      ),
      name: 'weekRepositoryProvider',
    );
