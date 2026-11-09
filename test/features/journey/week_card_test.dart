import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/data/observability/analytics.dart';
import 'package:prosoche/data/observability/observability_providers.dart';
import 'package:prosoche/data/repositories/journey/week_repository.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/practice/routine.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/cards/cards.dart';
import 'package:prosoche/features/journey/journey_screen.dart';
import 'package:prosoche/features/journey/week/week_card.dart';
import 'package:prosoche/features/journey/week/week_share.dart';

import '../../fakes/fake_repositories.dart';
import '../../fakes/in_memory_settings_repository.dart';
import '../../helpers/pump_app.dart';
import 'journey_fixtures.dart';

class _FakeSharer implements CardSharer {
  final texts = <String>[];
  final images = <(Uint8List, String)>[];

  @override
  Future<void> shareText(String text) async => texts.add(text);

  @override
  Future<void> shareImage(Uint8List png, {required String text}) async =>
      images.add((png, text));
}

class _RecordingAnalytics implements Analytics {
  final events = <String>[];

  @override
  void track(String event, [Map<String, Object?> props = const {}]) =>
      events.add(event);
}

/// Tyzden 23. - 29. 10. 2026 (dnes v testoch je stvrtok 29. 10.).
WeekActivity busyWeek() => WeekActivity(
  firstActiveDay: LocalDate(2026, 9, 1),
  gateVisits: [
    for (var i = 0; i < 5; i++)
      GateVisit(
        at: DateTime(2026, 10, 24 + i, 20),
        outcome: i.isEven ? GateOutcome.dismissed : GateOutcome.passed,
        appLabel: i < 3 ? 'Social' : 'Video',
      ),
  ],
  cardsReadByDay: {LocalDate(2026, 10, 27): 9, journeyToday: 3},
  practice: {
    LocalDate(2026, 10, 27): const {RoutineKind.morning, RoutineKind.evening},
    journeyToday: const {RoutineKind.morning},
  },
);

void main() {
  late _FakeSharer sharer;
  late _RecordingAnalytics analytics;
  Uint8List? png;

  setUp(() {
    sharer = _FakeSharer();
    analytics = _RecordingAnalytics();
    png = Uint8List.fromList([1, 2, 3]);
  });

  Future<void> pump(
    WidgetTester tester, {
    WeekActivity? activity,
    FeatureFlags flags = FeatureFlags.all,
    bool blocker = true,
    bool simple = false,
    FakeStreakRepository? streak,
  }) async {
    phoneView(tester);
    final settings = InMemorySettingsRepository();
    await settings.set(SettingsKeys.blockerEnabled, blocker);
    await settings.set(SettingsKeys.simpleMode, simple);
    await tester.pumpProsoche(
      location: '/journey',
      flags: flags,
      fakes: FakeRepositories(
        settings: settings,
        streak: streak ?? fixtureStreak(),
        week: FakeWeekRepository(
          activity: activity ?? busyWeek(),
          quoteContent: fakeWeekQuote(),
        ),
      ),
      overrides: [
        cardSharerProvider.overrideWithValue(sharer),
        weekImageRendererProvider.overrideWithValue((_, _) async => png),
        analyticsProvider.overrideWithValue(analytics),
      ],
    );
    await tester.scrollUntilVisible(
      find.byType(WeekSummaryCard),
      200,
      scrollable: find
          .descendant(
            of: find.byType(JourneyScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('full week with gate, practice and streak', (tester) async {
    await pump(tester);
    expect(find.text('THIS WEEK'), findsOneWidget);
    expect(find.textContaining('Oct 23 – Oct 29'), findsOneWidget);
    expect(find.text('pauses before apps'), findsOneWidget);
    expect(find.text('times you chose not to open it'), findsOneWidget);
    expect(find.text('cards read'), findsOneWidget);
    expect(find.text('days with practice'), findsOneWidget);
    expect(find.textContaining('Morning 2 · Evening 1'), findsOneWidget);
    expect(find.text('days in your streak'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    // Cisla v riadkoch: 5 zastaveni, 3 neotvorene, 12 kariet, 2 dni.
    for (final n in ['5', '3', '12', '2', '6']) {
      expect(find.text(n), findsWidgets);
    }
    expect(find.bySemanticsLabel(RegExp(r'^12\s+cards read')), findsOneWidget);
  });

  testWidgets('lite edition shows no gate rows', (tester) async {
    await pump(
      tester,
      flags: FeatureFlags.none,
      activity: WeekActivity(
        firstActiveDay: LocalDate(2026, 9, 1),
        cardsReadByDay: {journeyToday: 4},
      ),
    );
    expect(find.text('cards read'), findsOneWidget);
    expect(find.textContaining('pause'), findsNothing);
    expect(find.textContaining('chose not to open'), findsNothing);
  });

  testWidgets('gate turned off and unused shows no gate rows', (tester) async {
    await pump(
      tester,
      blocker: false,
      activity: WeekActivity(cardsReadByDay: {journeyToday: 1}),
    );
    expect(find.text('card read'), findsOneWidget);
    expect(find.textContaining('pause'), findsNothing);
  });

  testWidgets('simple mode hides the streak row', (tester) async {
    await pump(tester, simple: true);
    expect(find.text('days in your streak'), findsNothing);
    expect(find.text('cards read'), findsOneWidget);
  });

  testWidgets('empty first week: message, no share', (tester) async {
    await pump(
      tester,
      activity: WeekActivity.empty,
      streak: FakeStreakRepository(
        summary: fixtureSummary(current: 0, longest: 0),
      ),
    );
    expect(find.textContaining('Your week will gather here'), findsOneWidget);
    expect(find.text('Share'), findsNothing);
  });

  testWidgets('first week shows the start day', (tester) async {
    await pump(
      tester,
      activity: WeekActivity(
        firstActiveDay: LocalDate(2026, 10, 27),
        cardsReadByDay: {journeyToday: 2},
      ),
    );
    expect(find.textContaining('Since Oct 27'), findsOneWidget);
  });

  testWidgets('share: preview, no app names by default, no analytics', (
    tester,
  ) async {
    await pump(tester);
    analytics.events.clear();
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(find.text('Share your week'), findsOneWidget);
    expect(find.byType(WeekShareImage), findsOneWidget);
    expect(find.text('Include app names'), findsOneWidget);
    final switchTile = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(switchTile.value, isFalse);
    // Nahlad bez mien appiek.
    expect(
      find.descendant(
        of: find.byType(WeekShareImage),
        matching: find.textContaining('Social'),
      ),
      findsNothing,
    );

    await tester.tap(find.text('Share image'));
    await tester.pumpAndSettle();
    expect(sharer.images, hasLength(1));
    final text = sharer.images.single.$2;
    expect(text, contains('My week'));
    expect(text, contains('12 cards read'));
    expect(text, contains('[PLACEHOLDER translator]'));
    expect(text, contains('via Prosoche'));
    expect(text, isNot(contains('Social')));
    expect(find.text('Share your week'), findsNothing);
    expect(analytics.events, isEmpty);
  });

  testWidgets('share with app names after opting in', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Include app names'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(WeekShareImage),
        matching: find.text('Most paused: Social, Video'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Share image'));
    await tester.pumpAndSettle();
    expect(sharer.images.single.$2, contains('Most paused: Social, Video'));
  });

  testWidgets('render failure shows a message', (tester) async {
    await pump(tester);
    png = null;
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share image'));
    await tester.pumpAndSettle();
    expect(sharer.images, isEmpty);
    expect(find.text('The image could not be created.'), findsOneWidget);
  });

  testWidgets('no gate apps: no switch', (tester) async {
    await pump(
      tester,
      flags: FeatureFlags.none,
      activity: WeekActivity(cardsReadByDay: {journeyToday: 4}),
    );
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(find.byType(SwitchListTile), findsNothing);
  });

  testWidgets('reloads the week when the app resumes', (tester) async {
    await pump(tester, activity: WeekActivity.empty);
    final fake = ProviderScope.containerOf(
      tester.element(find.byType(WeekSummaryCard)),
    ).read(weekRepositoryProvider) as FakeWeekRepository;
    final before = fake.windows.length;
    fake.activity = WeekActivity(cardsReadByDay: {journeyToday: 7});
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(fake.windows.length, greaterThan(before));
    expect(
      find.descendant(
        of: find.byType(WeekSummaryCard),
        matching: find.text('7'),
      ),
      findsOneWidget,
    );
  });
}
