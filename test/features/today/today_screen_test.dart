import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/quests.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/domain/streak/streak.dart';
import 'package:prosoche/features/feed/feed_screen.dart';
import 'package:prosoche/features/today/today_screen.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

import '../../fakes/fake_repositories.dart';
import '../../fakes/in_memory_settings_repository.dart';
import '../../helpers/golden/golden.dart';
import 'f02_harness.dart';

/// Sada, ktorej generovanie nikdy neskonci (stav loading).
class _PendingDailySets extends FakeDailySetRepository {
  final pending = Completer<DailySetState>();

  @override
  Future<DailySetState> ensure(LocalDate date, {bool shorterSet = false}) =>
      pending.future;
}

class _PendingQuests extends FakeQuestRepository {
  @override
  Stream<List<QuestView>> watch(LocalDate date) => const Stream.empty();
}

DailySetState _state({int cursor = 0, bool completed = false}) => DailySetState(
  set: fakeDailySet(f02Today),
  cursor: cursor,
  startedAt: cursor > 0 ? DateTime(2026, 10, 29, 8) : null,
  completedAt: completed ? DateTime(2026, 10, 29, 8, 20) : null,
);

void main() {
  setUpAll(loadProsocheFonts);

  testWidgets('data: dates, quests, begin CTA and streak', (tester) async {
    await pumpF02(tester);
    await tester.pumpAndSettle();

    expect(find.byType(TodayScreen), findsOneWidget);
    // D-01: datum len raz (eyebrow verzalkami), nadpis "Today".
    expect(find.text('THURSDAY, OCTOBER 29'), findsOneWidget);
    expect(find.text('October 29, 2026'), findsNothing);
    expect(find.text('Today'), findsWidgets);
    expect(find.text("Today's intentions"), findsOneWidget);
    expect(find.text('Read 5 cards'), findsOneWidget);
    expect(find.text('Learn one idea'), findsOneWidget);
    expect(find.text('[PLACEHOLDER act quest]'), findsOneWidget);
    expect(find.text("Begin today's cards"), findsOneWidget);
    expect(find.text('10 cards'), findsOneWidget);
    expect(
      find.text(
        '${Bidi.isolate('5-day streak')} · ${Bidi.isolate('2 grace days')}',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('prayer'), findsNothing);
    expectNoTextClipping(tester);
  });

  testWidgets('loading: CTA already opens the feed, quests show skeleton', (
    tester,
  ) async {
    final repos = FakeRepositories(
      dailySets: _PendingDailySets(),
      quests: _PendingQuests(),
    );
    await pumpF02(tester, repos: repos);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SkSkeleton), findsOneWidget);
    expect(find.text("Begin today's cards"), findsOneWidget);
    expect(find.text('10 cards'), findsNothing);

    await tester.tap(find.text("Begin today's cards"));
    await tester.pump();
    await tester.pump();
    expect(find.byType(FeedScreen), findsOneWidget);
  });

  testWidgets('loading longer than 10 s turns into the error state', (
    tester,
  ) async {
    await pumpF02(
      tester,
      repos: FakeRepositories(dailySets: _PendingDailySets()),
    );
    await tester.pump(TodaySetCta.timeout + const Duration(seconds: 1));
    expect(find.text("Today's cards didn't load"), findsOneWidget);
  });

  testWidgets('error: E-FEED-1 with Try again, quests stay visible', (
    tester,
  ) async {
    final sets = FakeDailySetRepository()..ensureError = Exception('db');
    await pumpF02(tester, repos: FakeRepositories(dailySets: sets));
    await tester.pumpAndSettle();
    expect(find.text("Today's cards didn't load"), findsOneWidget);
    expect(
      find.text('Please try again. Your progress is safe.'),
      findsOneWidget,
    );
    expect(find.text('Read 5 cards'), findsOneWidget);

    sets.ensureError = null;
    await tester.ensureVisible(find.text('Try again'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text("Begin today's cards"), findsOneWidget);
  });

  testWidgets('empty: first day without quests, streak or intention', (
    tester,
  ) async {
    final repos = FakeRepositories(
      quests: FakeQuestRepository(build: (_) => const []),
      streak: FakeStreakRepository(
        summary: StreakSummary(
          state: StreakState.initial(f02Today),
          todayDone: false,
        ),
      ),
    );
    await pumpF02(tester, repos: repos);
    await tester.pumpAndSettle();
    expect(find.byType(SkQuestItem), findsNothing);
    expect(find.textContaining('streak'), findsNothing);
    expect(find.text("Begin today's cards"), findsOneWidget);
  });

  testWidgets('in progress: Continue · 5 of 10 (docs/02 A2 AC)', (
    tester,
  ) async {
    final sets = FakeDailySetRepository()..put(_state(cursor: 5));
    await pumpF02(tester, repos: FakeRepositories(dailySets: sets));
    await tester.pumpAndSettle();
    expect(find.text(Bidi.isolate('Continue · 5 of 10')), findsOneWidget);
  });

  testWidgets('completed: complete state, keep reading opens Library', (
    tester,
  ) async {
    final sets = FakeDailySetRepository()
      ..put(_state(cursor: 10, completed: true));
    final repos = FakeRepositories(dailySets: sets);
    await pumpF02(tester, repos: repos);
    await tester.pumpAndSettle();
    expect(find.text("Today's cards are complete"), findsOneWidget);
    await tester.ensureVisible(find.text('Keep reading'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep reading'));
    await tester.pumpAndSettle();
    expect(find.text('stub:/library'), findsOneWidget);
  });

  testWidgets('simple mode hides streak and grace days', (tester) async {
    final settings = InMemorySettingsRepository();
    await settings.set(SettingsKeys.simpleMode, true);
    await settings.set(SettingsKeys.intentionText, 'My own words');
    await pumpF02(tester, repos: FakeRepositories(settings: settings));
    await tester.pumpAndSettle();
    expect(find.textContaining('streak'), findsNothing);
    expect(find.textContaining('grace'), findsNothing);
    expect(find.text('“My own words”'), findsOneWidget);
  });

  testWidgets('ACT quest: I did it, Undo, Skip for today', (tester) async {
    final repos = FakeRepositories();
    await pumpF02(tester, repos: repos);
    await tester.pumpAndSettle();

    await tester.tap(find.text('I did it'));
    await tester.pumpAndSettle();
    expect(repos.quests.actChanges, [QuestStatus.done]);
    expect(find.text('Marked as done.'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(repos.quests.actChanges.last, QuestStatus.pending);

    await tester.longPress(find.text('[PLACEHOLDER act quest]'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip for today'));
    await tester.pumpAndSettle();
    expect(repos.quests.actChanges.last, QuestStatus.skipped);
    expect(find.text('Skipped for today'), findsOneWidget);
  });

  testWidgets('READ quest opens the feed', (tester) async {
    await pumpF02(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Read 5 cards'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(FeedScreen), findsOneWidget);
  });

  testWidgets('gear opens settings', (tester) async {
    await pumpF02(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('stub:/settings'), findsOneWidget);
  });

  testWidgets('midnight: new date and a fresh CTA within 60 s', (tester) async {
    final sets = FakeDailySetRepository()
      ..put(_state(cursor: 10, completed: true));
    final start = DateTime(2026, 10, 29, 23, 59);
    await pumpF02(
      tester,
      repos: FakeRepositories(dailySets: sets),
      now: start,
      clock: advancingClock(tester, start),
    );
    await tester.pumpAndSettle();
    expect(find.text("Today's cards are complete"), findsOneWidget);

    await tester.pump(const Duration(seconds: 61));
    await tester.pumpAndSettle();
    expect(find.text('FRIDAY, OCTOBER 30'), findsOneWidget);
    expect(find.text("Begin today's cards"), findsOneWidget);
  });

  testWidgets('semantics: header and quest states', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpF02(tester);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel("Today's intentions"), findsOneWidget);
    final quest = tester.getSemantics(find.byType(SkQuestItem).first);
    expect(quest.value, '0 of 5');
    expect(quest.label, contains('Read 5 cards'));
    handle.dispose();
  });

  testWidgets('text scale 2 without clipping', (tester) async {
    await pumpF02(tester, textScale: 2);
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(TodayScreen));
    expect(Directionality.of(ctx), TextDirection.ltr);
    expectNoTextClipping(tester);
  });
}
