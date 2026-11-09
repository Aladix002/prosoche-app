import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/data/repositories/catalog/content_catalog.dart';
import 'package:prosoche/data/repositories/journey/week_repository.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/practice/routine.dart';

import '../../db/fixtures/content_fixture.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late UserDb db;
  late ContentDb content;
  late DriftWeekRepository repo;
  var disabled = <CardId>{};

  // Nedela 8. 11. 2026 v lokalnej zone stroja.
  final today = LocalDate(2026, 11, 8);
  final window = WeekWindow.endingOn(today);

  setUp(() {
    db = UserDb.memory();
    content = openContentFixture();
    disabled = {};
    repo = DriftWeekRepository(
      userDb: db,
      catalog: ContentCatalog(Future.value(content)),
      disabledIds: () => disabled,
    );
  });
  tearDown(() async {
    await db.close();
    await content.close();
  });

  Future<int> session(DateTime localAt, GateResult? result, {int? app}) async {
    final id = await db.blockerDao.openSession(app, localAt.toUtc());
    if (result != null) {
      await db.blockerDao.closeSession(
        id,
        result: result,
        cardsSeen: 1,
        now: localAt.toUtc(),
      );
    }
    return id;
  }

  Future<void> seen(LocalDate d, CardId id, CardContext c) =>
      db.cardEventDao.log(
        date: d,
        card: id,
        context: c,
        action: CardAction.seen,
        ts: d.toLocalDateTime().toUtc(),
      );

  test('empty database', () async {
    final a = await repo.load(window);
    expect(a.gateVisits, isEmpty);
    expect(a.cardsReadByDay, isEmpty);
    expect(a.practice, isEmpty);
    expect(a.firstActiveDay, isNull);
  });

  test('gate sessions inside local window with app label', () async {
    final app = await db.blockerDao.addApp(
      platformRef: 'com.example.social',
      label: 'Social',
      now: DateTime.utc(2026),
    );
    await session(DateTime(2026, 11, 1, 23, 59), GateResult.dismissed);
    await session(DateTime(2026, 11, 2), GateResult.dismissed, app: app.id);
    await session(DateTime(2026, 11, 4, 8), GateResult.passed, app: app.id);
    await session(DateTime(2026, 11, 5, 8), GateResult.emergency);
    await session(DateTime(2026, 11, 6, 8), GateResult.error);
    await session(DateTime(2026, 11, 8, 23, 59), null);
    await session(DateTime(2026, 11, 9), GateResult.dismissed);

    final a = await repo.load(window);
    expect(a.gateVisits.map((v) => v.outcome), [
      GateOutcome.dismissed,
      GateOutcome.passed,
      GateOutcome.emergency,
      GateOutcome.error,
      GateOutcome.open,
    ]);
    expect(a.gateVisits.first.at, DateTime(2026, 11, 2));
    expect(a.gateVisits.first.appLabel, 'Social');
    expect(a.gateVisits[2].appLabel, isNull);

    // Odstranena appka: session ostane, bez nazvu.
    await db.blockerDao.removeApp(app.id);
    final b = await repo.load(window);
    expect(b.gateVisits, hasLength(5));
    expect(b.gateVisits.first.appLabel, isNull);
  });

  test('cards read: distinct per day, any context, no intro/done', () async {
    final q1 = ContentCardId.quote(fixtureQuoteId(1));
    final q2 = ContentCardId.quote(fixtureQuoteId(2));
    final d = LocalDate(2026, 11, 3);
    await seen(d, q1, CardContext.feed);
    await seen(d, q1, CardContext.gate);
    await seen(d, q2, CardContext.reader);
    await seen(d, IntroCardId(d), CardContext.feed);
    await seen(d, DoneCardId(d), CardContext.feed);
    await seen(today, q1, CardContext.feed);
    await seen(LocalDate(2026, 11, 1), q2, CardContext.feed);
    await seen(LocalDate(2026, 11, 9), q2, CardContext.feed);
    // Ina akcia nez seen sa nepocita.
    await db.cardEventDao.log(
      date: d,
      card: ContentCardId.quote(fixtureQuoteId(3)),
      context: CardContext.feed,
      action: CardAction.saved,
      ts: DateTime.utc(2026, 11, 3),
    );

    final a = await repo.load(window);
    expect(a.cardsReadByDay, {d: 2, today: 1});
    expect(a.firstActiveDay, LocalDate(2026, 11, 1));
  });

  test('practice days by routine', () async {
    final now = DateTime.utc(2026, 11, 8);
    await db.practiceLogDao.markDone(
      LocalDate(2026, 11, 1),
      JournalKind.morning,
      now,
    );
    await db.practiceLogDao.markDone(
      LocalDate(2026, 11, 2),
      JournalKind.morning,
      now,
    );
    await db.practiceLogDao.markDone(
      LocalDate(2026, 11, 2),
      JournalKind.evening,
      now,
    );
    await db.practiceLogDao.markDone(today, JournalKind.evening, now);

    final a = await repo.load(window);
    expect(a.practice, {
      LocalDate(2026, 11, 2): {RoutineKind.morning, RoutineKind.evening},
      today: {RoutineKind.evening},
    });
    expect(a.firstActiveDay, LocalDate(2026, 11, 1));
  });

  test('watch emits again after a write', () async {
    final values = <WeekActivity>[];
    final sub = repo.watch(window).listen(values.add);
    await pumpEventQueue();
    expect(values, hasLength(1));
    await seen(today, ContentCardId.quote(fixtureQuoteId(1)), CardContext.feed);
    await pumpEventQueue();
    await sub.cancel();
    expect(values.length, greaterThanOrEqualTo(2));
    expect(values.last.cardsReadByDay, {today: 1});
  });

  group('quote', () {
    test(
      'short quote with reference and translator, stable per week',
      () async {
        final q = await repo.quote(today);
        expect(q, isNotNull);
        expect(q!.text.length, lessThanOrEqualTo(weekQuoteMaxChars));
        expect(q.translation?.translator, isNotEmpty);
        expect(q.reference, isNotEmpty);
        // Pondelok az nedela rovnaky citat, dalsi tyzden iny.
        final monday = LocalDate(2026, 11, 2);
        expect((await repo.quote(monday))!.id, q.id);
        expect((await repo.quote(monday.addDays(-1)))!.id, isNot(q.id));
      },
    );

    test('respects max length and disabled ids', () async {
      expect(await repo.quote(today, maxChars: 3), isNull);
      final q = await repo.quote(today);
      disabled = {q!.id};
      expect((await repo.quote(today))!.id, isNot(q.id));
    });
  });
}
