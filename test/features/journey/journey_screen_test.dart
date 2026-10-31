import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/data/repositories/repositories.dart' show ReaderMode;
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/quests.dart' show CardContext;
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/domain/streak/streak.dart';
import 'package:prosoche/features/journey/journey_calendar.dart';
import 'package:prosoche/features/journey/journey_day_screen.dart';
import 'package:prosoche/features/journey/journey_screen.dart';
import 'package:prosoche/features/journey/saved_screen.dart';
import 'package:prosoche/features/journey/surah_map.dart';
import 'package:prosoche/features/quran/reader/quran_reader_screen.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

import '../../fakes/fake_repositories.dart';
import '../../fakes/in_memory_settings_repository.dart';
import '../../helpers/pump_app.dart';
import 'journey_fixtures.dart';

/// Posunie zoznam Moja cesta, kym nie je [finder] viditelny.
Future<void> scrollTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .descendant(
            of: find.byType(JourneyScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );

Finder dayCells(String month, String state) =>
    find.bySemanticsLabel(RegExp('^[A-Za-z]+, $month \\d+, $state\$'));

void main() {
  group('journeyDayMark', () {
    final today = LocalDate(2026, 10, 29);
    DayLogEntry entry(DayStatus s) =>
        DayLogEntry(date: LocalDate(2026, 10, 1), status: s);

    test('future, today and closed days', () {
      JourneyDayMark mark(
        LocalDate d, {
        DayLogEntry? e,
        bool done = false,
        bool simple = false,
      }) => journeyDayMark(
        date: d,
        today: today,
        entry: e,
        todayDone: done,
        simple: simple,
      );
      expect(mark(today.addDays(1)), JourneyDayMark.future);
      expect(mark(today), JourneyDayMark.none);
      expect(mark(today, done: true), JourneyDayMark.done);
      expect(mark(today.addDays(-1)), JourneyDayMark.none);
      for (final (s, m) in [
        (DayStatus.done, JourneyDayMark.done),
        (DayStatus.grace, JourneyDayMark.grace),
        (DayStatus.missed, JourneyDayMark.missed),
        (DayStatus.excused, JourneyDayMark.excused),
      ]) {
        expect(mark(LocalDate(2026, 10, 1), e: entry(s)), m);
      }
    });

    test('simple mode shows only completed days', () {
      for (final s in DayStatus.values) {
        expect(
          journeyDayMark(
            date: LocalDate(2026, 10, 1),
            today: today,
            entry: entry(s),
            todayDone: false,
            simple: true,
          ),
          s == DayStatus.done ? JourneyDayMark.done : JourneyDayMark.none,
        );
      }
    });

    test('wire values', () {
      expect(JourneyDayMark.none.wire(today: true), 'today');
      expect(JourneyDayMark.none.wire(today: false), 'none');
      expect(JourneyDayMark.grace.wire(today: false), 'grace');
    });
  });

  test('month helpers', () {
    expect(shiftJourneyMonth((2026, 1), -1), (2025, 12));
    expect(shiftJourneyMonth((2026, 12), 1), (2027, 1));
    expect(journeyMonthsBetween((2026, 8), (2026, 10)), 2);
    expect(journeyMonthsBetween((2025, 11), (2026, 10)), 11);
  });

  test('read percent', () {
    expect(readPercent(0, 7), 0);
    expect(readPercent(1, 286), 1);
    expect(readPercent(143, 286), 50);
    expect(readPercent(286, 286), 100);
    expect(quranReadPercent({1: 7, 2: 286}), 4);
    expect(quranReadPercent({}), 0);
  });

  group('JourneyScreen', () {
    Future<FakeRepositories> pump(
      WidgetTester tester, {
      FakeRepositories? repos,
      FeatureFlags flags = FeatureFlags.none,
      bool settle = true,
    }) async {
      phoneView(tester);
      final r =
          repos ??
          FakeRepositories(
            streak: fixtureStreak(),
            quran: JourneyQuranRepository(counts: {1: 7, 2: 143}, khatms: 1),
          );
      await tester.pumpProsoche(location: '/journey', flags: flags, fakes: r);
      return r;
    }

    testWidgets('data: 60 days, streak, grace days and legend', (tester) async {
      await pump(tester);
      expect(find.text('My journey'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);
      expect(
        find.text(
          '${Bidi.isolate('6-day streak')} · ${Bidi.isolate('Longest 14')}',
        ),
        findsOneWidget,
      );
      expect(find.text(Bidi.isolate('1 grace day')), findsOneWidget);
      expect(
        find.text('Grace days refill on Monday, November 2'),
        findsOneWidget,
      );
      expect(find.text('Grace day'), findsOneWidget);
      expect(dayCells('October', 'Completed'), findsNWidgets(22));
      expect(dayCells('October', 'Covered by a grace day'), findsNWidgets(3));
      expect(dayCells('October', 'Not completed'), findsNWidgets(3));
      expect(
        find.bySemanticsLabel('Thursday, October 29, Today'),
        findsOneWidget,
      );
      expect(dayCells('October', 'Upcoming'), findsNWidgets(2));

      // Spat do septembra a augusta (zvysok 60 dni).
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);
      expect(dayCells('September', 'Covered by a grace day'), findsNWidgets(3));
      expect(dayCells('September', 'Not completed'), findsNWidgets(3));
      expect(dayCells('September', 'Excused'), findsOneWidget);
      expect(dayCells('September', 'Completed'), findsNWidgets(23));
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      expect(dayCells('August', 'Completed'), findsNWidgets(2));
      expect(dayCells('August', 'No record'), findsNWidgets(29));

      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byTooltip('Next month'));
        await tester.pumpAndSettle();
      }
      expect(find.text('October 2026'), findsOneWidget);
      final next = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip('Next month'),
          matching: find.byType(IconButton),
        ),
      );
      expect(next.onPressed, isNull);
    });

    testWidgets('today done counts as completed', (tester) async {
      await pump(
        tester,
        repos: FakeRepositories(
          streak: FakeStreakRepository(
            summary: fixtureSummary(current: 7, todayDone: true),
            days: sixtyDays,
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Thursday, October 29, Today, Completed'),
        findsOneWidget,
      );
      // Dnesok sa pripocita k streaku (StreakSummary.current).
      expect(find.textContaining('8-day streak'), findsOneWidget);
    });

    testWidgets('simple mode hides every streak number', (tester) async {
      final settings = InMemorySettingsRepository();
      await settings.set(SettingsKeys.simpleMode, true);
      await pump(
        tester,
        repos: FakeRepositories(settings: settings, streak: fixtureStreak()),
      );
      expect(find.byType(JourneyStreakSummary), findsNothing);
      expect(find.textContaining('streak'), findsNothing);
      expect(find.textContaining('grace'), findsNothing);
      expect(find.text('Grace day'), findsNothing);
      expect(find.text('Completed'), findsOneWidget);
      expect(dayCells('October', 'Completed'), findsNWidgets(22));
      expect(dayCells('October', 'Covered by a grace day'), findsNothing);
      expect(dayCells('October', 'Not completed'), findsNothing);
    });

    testWidgets('zero streak shows no loss number', (tester) async {
      await pump(
        tester,
        repos: FakeRepositories(
          streak: FakeStreakRepository(
            summary: fixtureSummary(current: 0, graceLeft: 0),
            days: sixtyDays,
          ),
        ),
      );
      expect(find.textContaining('-day streak'), findsNothing);
      expect(find.text(Bidi.isolate('Longest 14')), findsOneWidget);
      expect(find.text(Bidi.isolate('no grace days left')), findsOneWidget);
    });

    testWidgets('empty: new user sees the calendar with today', (tester) async {
      await pump(
        tester,
        repos: FakeRepositories(
          streak: FakeStreakRepository(
            summary: fixtureSummary(current: 0, longest: 0, graceLeft: 2),
          ),
        ),
      );
      expect(find.text('Your journey starts today'), findsOneWidget);
      expect(find.byType(JourneyCalendar), findsOneWidget);
      expect(
        find.bySemanticsLabel('Thursday, October 29, Today'),
        findsOneWidget,
      );
      // D-05: uvodny panel je vyssi, mapa sur moze byt pod okrajom.
      await tester.scrollUntilVisible(
        find.text('Verses you read will fill this map.'),
        200,
      );
      expect(find.text('Verses you read will fill this map.'), findsOneWidget);
      expect(find.text('0% read'), findsOneWidget);
    });

    testWidgets('loading shows the calendar skeleton', (tester) async {
      phoneView(tester);
      await tester.pumpProsoche(
        location: '/journey',
        flags: FeatureFlags.none,
        fakes: FakeRepositories(streak: StuckStreakRepository()),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SkSkeleton), findsWidgets);
      expect(find.byType(JourneyCalendar), findsNothing);
    });

    testWidgets('error shows E-DB-1 with retry', (tester) async {
      phoneView(tester);
      await tester.pumpProsoche(
        location: '/journey',
        flags: FeatureFlags.none,
        fakes: FakeRepositories(streak: StuckStreakRepository(error: 'db')),
      );
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Your data is safe. Please try again.'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('tap a day opens its detail, future days are inert', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.bySemanticsLabel('Friday, October 30, Upcoming'));
      await tester.pumpAndSettle();
      expect(find.byType(JourneyDayScreen), findsNothing);

      await tester.tap(
        find.bySemanticsLabel('Wednesday, October 28, Completed'),
      );
      await tester.pumpAndSettle();
      final screen = tester.widget<JourneyDayScreen>(
        find.byType(JourneyDayScreen),
      );
      expect(screen.date, LocalDate(2026, 10, 28));
    });

    testWidgets('surah map: progress labels, khatm and reader links', (
      tester,
    ) async {
      phoneView(tester);
      await tester.pumpProsoche(
        location: '/journey',
        flags: FeatureFlags.none,
        fakes: FakeRepositories(
          streak: fixtureStreak(),
          quran: JourneyQuranRepository(counts: {1: 7, 2: 143}, khatms: 1),
        ),
      );
      await scrollTo(tester, find.text('Khatm: 1'));
      expect(find.text('2% read'), findsOneWidget);
      expect(find.text('Khatm: 1'), findsOneWidget);
      expect(find.text('Next verse \u20681:1\u2069'), findsOneWidget);
      expect(find.bySemanticsLabel('Placeholder 1, 100% read'), findsOneWidget);
      expect(find.bySemanticsLabel('Placeholder 2, 50% read'), findsOneWidget);
      expect(find.bySemanticsLabel('Placeholder 3, 0% read'), findsOneWidget);
      expect(
        find.text(
          'Each square is a surah. The fuller it is, the more of it you '
          'have read.',
        ),
        findsOneWidget,
      );

      final tile = find.bySemanticsLabel('Placeholder 2, 50% read');
      await tester.scrollUntilVisible(
        tile,
        -100,
        scrollable: find
            .descendant(
              of: find.byType(JourneyScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();
      final reader = tester.widget<QuranReaderScreen>(
        find.byType(QuranReaderScreen),
      );
      expect((reader.surah, reader.mode), (2, ReaderMode.browse));
    });

    testWidgets('saved cards button shows the count and opens Saved', (
      tester,
    ) async {
      final repos = FakeRepositories(streak: fixtureStreak());
      await repos.actions.save(
        journeyToday,
        AyahCardId(AyahId(2, 255)),
        context: CardContext.feed,
      );
      await repos.actions.save(
        journeyToday,
        HadithCardId(13),
        context: CardContext.feed,
      );
      await pump(tester, repos: repos);
      final button = find.text('Saved cards (2)');
      await scrollTo(tester, button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(SavedCardsScreen), findsOneWidget);
    });

    testWidgets('words row only with FEATURE_WORDS', (tester) async {
      await pump(tester);
      await scrollTo(tester, find.textContaining('Saved cards'));
      expect(find.text('Words'), findsNothing);
      await pump(tester, flags: FeatureFlags.all);
      await scrollTo(tester, find.text('Words'));
      expect(find.text('Words'), findsOneWidget);
    });

    testWidgets('edit intention writes niyyah settings', (tester) async {
      final repos = await pump(tester);
      expect(find.text('Add your intention'), findsOneWidget);
      await tester.tap(find.byTooltip('Edit intention'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('journey-niyyah:khatm')));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(await repos.settings.get(SettingsKeys.niyyahPreset), 'khatm');
      expect(find.text('Read the Quran regularly'), findsOneWidget);

      await tester.tap(find.byTooltip('Edit intention'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('journey-niyyah:own')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('journey-niyyah:text')),
        '[PLACEHOLDER own words]',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        await repos.settings.get(SettingsKeys.niyyahText),
        '[PLACEHOLDER own words]',
      );
      expect(find.text('“[PLACEHOLDER own words]”'), findsOneWidget);

      await tester.tap(find.byTooltip('Edit intention'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('“[PLACEHOLDER own words]”'), findsOneWidget);
    });

    testWidgets('meets tap target and label guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });
}
