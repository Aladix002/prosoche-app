import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/flags/feature_flags.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/prayer/prayer.dart';
import 'package:sakina/domain/streak/streak.dart';
import 'package:sakina/features/journey/card_pager.dart';
import 'package:sakina/features/journey/journey_day_screen.dart';
import 'package:sakina/features/journey/journey_routes.dart';
import 'package:sakina/features/journey/journey_screen.dart';
import 'package:sakina/ui/ui.dart';

import '../../fakes/fake_repositories.dart';
import '../../helpers/pump_app.dart';
import 'journey_fixtures.dart';

void main() {
  final yesterday = LocalDate(2026, 10, 28);

  test('parseDay accepts only past days and today', () {
    expect(JourneyRoutes.parseDay('2026-10-29', journeyToday), journeyToday);
    expect(JourneyRoutes.parseDay('2026-10-30', journeyToday), isNull);
    expect(JourneyRoutes.parseDay('2026-02-30', journeyToday), isNull);
    expect(JourneyRoutes.parseDay(null, journeyToday), isNull);
  });

  Future<FakeRepositories> pump(
    WidgetTester tester, {
    FakeRepositories? repos,
    LocalDate? date,
  }) async {
    phoneView(tester);
    final r = repos ?? FakeRepositories(streak: fixtureStreak());
    await tester.pumpSakina(
      location: JourneyRoutes.day(date ?? yesterday),
      flags: FeatureFlags.none,
      fakes: r,
    );
    return r;
  }

  testWidgets('completed yesterday: 10/10, time, sources and prayers', (
    tester,
  ) async {
    final repos = FakeRepositories(streak: fixtureStreak());
    repos.dailySets.put(
      DailySetState(
        set: fakeDailySet(yesterday),
        cursor: 10,
        startedAt: DateTime(2026, 10, 28, 8, 50),
        completedAt: DateTime(2026, 10, 28, 9, 10),
      ),
    );
    await repos.prayer.setStatus(yesterday, Prayer.fajr, PrayerStatus.onTime);
    await repos.prayer.setStatus(yesterday, Prayer.isha, PrayerStatus.qada);
    await pump(tester, repos: repos);

    expect(find.text('Wednesday, October 28'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Daily cards completed'), findsOneWidget);
    expect(find.text('Daily cards: 10/10'), findsOneWidget);
    expect(find.text('Completed at 09:10'), findsOneWidget);
    expect(find.text('On time'), findsOneWidget);
    expect(find.text('Made up'), findsOneWidget);
    expect(find.text('Not logged'), findsNWidgets(3));
  });

  testWidgets('View cards opens the set read-only', (tester) async {
    final repos = FakeRepositories(streak: fixtureStreak());
    repos.dailySets.put(
      DailySetState(
        set: fakeDailySet(yesterday),
        cursor: 10,
        completedAt: DateTime(2026, 10, 28, 9, 10),
      ),
    );
    await pump(tester, repos: repos);
    await tester.tap(find.text('View cards'));
    await tester.pumpAndSettle();
    expect(find.byType(JourneyCardPager), findsOneWidget);
    expect(find.text('1 of 10'), findsOneWidget);
    expect(repos.dailySets.seen, isEmpty);
  });

  testWidgets('grace day without a set', (tester) async {
    await pump(tester, date: LocalDate(2026, 10, 22));
    expect(find.text('Covered by a grace day'), findsOneWidget);
    expect(find.text('No daily cards on this day.'), findsOneWidget);
    expect(find.text('View cards'), findsNothing);
  });

  testWidgets('today in progress', (tester) async {
    final repos = FakeRepositories(streak: fixtureStreak());
    repos.dailySets.put(
      DailySetState(set: fakeDailySet(journeyToday), cursor: 4),
    );
    await pump(tester, repos: repos, date: journeyToday);
    expect(
      find.descendant(
        of: find.byType(JourneyDayScreen),
        matching: find.text('Today'),
      ),
      findsOneWidget,
    );
    expect(find.text('Daily cards: 4/10'), findsOneWidget);
  });

  testWidgets('future and invalid dates redirect to Journey', (tester) async {
    await pump(tester, date: LocalDate(2026, 10, 30));
    expect(find.byType(JourneyDayScreen), findsNothing);
    expect(find.byType(JourneyScreen), findsOneWidget);
  });

  testWidgets('error state', (tester) async {
    phoneView(tester);
    await tester.pumpSakina(
      location: JourneyRoutes.day(yesterday),
      flags: FeatureFlags.none,
      fakes: FakeRepositories(
        streak: fixtureStreak(),
        dailySets: FailingDailySetRepository(),
      ),
    );
    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets('loading state', (tester) async {
    phoneView(tester);
    await tester.pumpSakina(
      location: JourneyRoutes.day(yesterday),
      flags: FeatureFlags.none,
      fakes: FakeRepositories(streak: StuckDayLogRepository()),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SkSkeleton), findsOneWidget);
  });
}

/// `day_log`, ktory sa nikdy nenacita.
class StuckDayLogRepository extends FakeStreakRepository {
  @override
  Stream<List<DayLogEntry>> watchDayLog(LocalDate from, LocalDate to) =>
      StreamController<List<DayLogEntry>>().stream;
}
