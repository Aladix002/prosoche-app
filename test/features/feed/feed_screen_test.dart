import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/clock/clock_provider.dart';
import 'package:sakina/core/router/routes.dart';
import 'package:sakina/data/observability/analytics.dart';
import 'package:sakina/data/observability/observability_providers.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/feed/feed.dart';
import 'package:sakina/domain/quests/quests.dart';
import 'package:sakina/features/cards/cards.dart';
import 'package:sakina/features/feed/feed_screen.dart';
import 'package:sakina/features/today/today_screen.dart';
import 'package:sakina/ui/i18n/i18n.dart';
import 'package:sakina/ui/ui.dart';

import '../../fakes/fake_repositories.dart';
import '../../helpers/golden/golden.dart';
import '../../ui/helpers/arabic_text_guard.dart';
import '../today/f02_harness.dart';

const _dwell = Duration(milliseconds: 2600);

class _Analytics implements Analytics {
  final events = <(String, Map<String, Object?>)>[];

  @override
  void track(String event, [Map<String, Object?> props = const {}]) =>
      events.add((event, props));
}

class _PendingDailySets extends FakeDailySetRepository {
  @override
  Future<DailySetState> ensure(LocalDate date, {bool shorterSet = false}) =>
      Completer<DailySetState>().future;
}

/// Questy s READ cielom [readTarget] (pocet versov v sade).
List<QuestView> _quests(LocalDate date, {int readTarget = 2, int read = 0}) {
  final done = read >= readTarget;
  return [
    QuestView(
      quest: DailyQuest(
        date: date,
        slot: QuestSlot.read,
        questId: GenericQuest.readVerses.id,
        origin: QuestOrigin.generic,
        rule: GenericQuest.readVerses.rule(readTarget),
      ),
      status: done ? QuestStatus.done : QuestStatus.pending,
      doneAt: done ? DateTime(2026, 10, 29, 9, 10) : null,
      progress: QuestProgress(
        current: read > readTarget ? readTarget : read,
        target: readTarget,
        completedAt: done ? DateTime(2026, 10, 29, 9, 10) : null,
      ),
    ),
    QuestView(
      quest: DailyQuest(
        date: date,
        slot: QuestSlot.act,
        questId: 'act.fake.placeholder',
        origin: QuestOrigin.weighted,
      ),
      status: QuestStatus.pending,
      title: '[PLACEHOLDER act quest]',
    ),
  ];
}

/// Sada, ktorej `seen` versa posuva READ quest (ako `QuestRepository
/// .syncAuto` po zapise `card_event`).
class _LinkedDailySets extends FakeDailySetRepository {
  _LinkedDailySets(this.quests, {super.build});

  final FakeQuestRepository quests;
  int verses = 0;

  @override
  Future<SeenResult> markSeen(
    LocalDate date,
    DailySetCard card, {
    CardContext context = CardContext.feed,
  }) async {
    final result = await super.markSeen(date, card, context: context);
    if (result.newlySeen && card.cardId is AyahCardId) {
      verses++;
      quests.put(date, _quests(date, read: verses));
    }
    return result;
  }
}

class _FailingCards extends FakeCardContentRepository {
  _FailingCards(this.failing);

  final CardId failing;

  @override
  Future<CardContent?> load(CardId id, {required String lang}) async {
    if (id == failing) throw StateError('broken');
    return await super.load(id, lang: lang);
  }
}

/// Vers 2:3 s velmi dlhym prekladom (B0.5, napr. 2:282).
class _LongCards extends FakeCardContentRepository {
  @override
  Future<CardContent?> load(CardId id, {required String lang}) async {
    final c = await super.load(id, lang: lang);
    if (c is AyahContent && c.ayah.id == AyahId(2, 3)) {
      final long = List.filled(50, '[PLACEHOLDER long translation]').join(' ');
      return AyahContent(
        c.id as AyahCardId,
        surah: c.surah,
        ayah: AyahView(
          id: c.ayah.id,
          textUthmani: List.filled(10, c.ayah.textUthmani).join(' '),
          juz: 1,
          page: 1,
          translation: TranslationText(
            text: long,
            sourceId: 'fake-en',
            lang: 'en',
          ),
        ),
      );
    }
    return c;
  }
}

DailySetState _state({int cursor = 0, bool completed = false, int n = 10}) =>
    DailySetState(
      set: fakeDailySet(f02Today, n: n),
      cursor: cursor,
      startedAt: cursor > 0 ? DateTime(2026, 10, 29, 8) : null,
      completedAt: completed ? DateTime(2026, 10, 29, 8, 20) : null,
    );

PageController _controller(WidgetTester tester) =>
    tester.widget<PageView>(find.byType(PageView)).controller!;

int _page(WidgetTester tester) => _controller(tester).page!.round();

Future<void> _swipeUp(WidgetTester tester) async {
  await tester.fling(find.byType(PageView), const Offset(0, -400), 1500);
  await tester.pumpAndSettle();
}

Future<void> _swipeDown(WidgetTester tester) async {
  await tester.fling(find.byType(PageView), const Offset(0, 400), 1500);
  await tester.pumpAndSettle();
}

Future<void> _openFeed(
  WidgetTester tester, {
  FakeRepositories? repos,
  Locale locale = const Locale('en'),
  double textScale = 1,
  Clock? clock,
  DateTime? now,
}) async {
  await pumpF02(
    tester,
    repos: repos,
    location: AppRoutes.feed,
    below: AppRoutes.today,
    locale: locale,
    textScale: textScale,
    clock: clock,
    now: now,
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadSakinaFonts);

  testWidgets('loading: skeleton and close button', (tester) async {
    await _openFeed(
      tester,
      repos: FakeRepositories(dailySets: _PendingDailySets()),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SkSkeleton), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('error: E-FEED-1 and back to Today', (tester) async {
    final sets = FakeDailySetRepository()..ensureError = Exception('db');
    await _openFeed(tester, repos: FakeRepositories(dailySets: sets));
    expect(find.text("Today's cards didn't load"), findsOneWidget);
    await tester.tap(find.text('Back to Today'));
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('data: intro first, no skipping before the dwell', (
    tester,
  ) async {
    final repos = FakeRepositories();
    await _openFeed(tester, repos: repos);
    expect(find.byType(IntroCard), findsOneWidget);
    expect(find.text(Bidi.isolateLtr('0 / 10')), findsOneWidget);

    // Pred 2,5 s: karta odpruzi, hint "Take a moment", ziadne seen.
    await tester.pump(const Duration(seconds: 1));
    await _swipeUp(tester);
    expect(_page(tester), 0);
    expect(find.text('Take a moment'), findsOneWidget);
    expect(repos.dailySets.seen, isEmpty);

    await tester.pump(_dwell);
    expect(repos.dailySets.seen.map((s) => s.$2), [IntroCardId(f02Today)]);
    expect(find.text(Bidi.isolateLtr('1 / 10')), findsOneWidget);
    await _swipeUp(tester);
    expect(_page(tester), 1);
    expect(find.byType(AyahCard), findsOneWidget);
    expect(find.text('[PLACEHOLDER translation 2:2]'), findsOneWidget);
    expect(bareArabicTexts(tester), isEmpty);

    // Swipe dole vzdy, opakovane zobrazenie seen nezapise.
    await _swipeDown(tester);
    expect(_page(tester), 0);
    await tester.pump(_dwell);
    expect(repos.dailySets.seen, hasLength(1));
  });

  testWidgets('fast swiping resets the dwell (docs/02 A3)', (tester) async {
    final repos = FakeRepositories();
    repos.dailySets.put(_state(cursor: 2));
    await _openFeed(tester, repos: repos);
    expect(_page(tester), 2);
    await tester.pump(const Duration(seconds: 2));
    await _swipeDown(tester);
    await _swipeUp(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(repos.dailySets.seen, isEmpty);
    await tester.pump(const Duration(seconds: 2));
    expect(repos.dailySets.seen, hasLength(1));
  });

  testWidgets(
    'DoD: finishing the set completes READ and the feed closes to Today',
    (tester) async {
      final quests = FakeQuestRepository(build: _quests);
      final sets = _LinkedDailySets(
        quests,
        build: (d) => fakeDailySet(d, n: 3),
      );
      final repos = FakeRepositories(dailySets: sets, quests: quests);
      await _openFeed(tester, repos: repos);

      for (var i = 0; i < 3; i++) {
        await tester.pump(_dwell);
        await _swipeUp(tester);
      }
      expect(sets.seen, hasLength(3));
      expect((await sets.get(f02Today))!.isCompleted, isTrue);
      expect(find.byType(DoneCard), findsOneWidget);
      expect(find.text("You're done for today"), findsOneWidget);
      expect(find.text('3 cards · 2 verses'), findsOneWidget);
      expect(find.text('Intentions: 1 of 2'), findsOneWidget);
      expect(find.text('Still open: [PLACEHOLDER act quest]'), findsOneWidget);

      // Feed konci: swipe hore na done nic nerobi.
      await _swipeUp(tester);
      expect(find.byType(DoneCard), findsOneWidget);

      await tester.tap(find.text('Back to Today'));
      await tester.pumpAndSettle();
      expect(find.byType(FeedScreen), findsNothing);
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(find.text("Today's cards are complete"), findsOneWidget);
      final read = find.ancestor(
        of: find.text('Read 2 verses'),
        matching: find.byType(SkQuestItem),
      );
      expect(tester.widget<SkQuestItem>(read).state, SkQuestState.done);
    },
  );

  testWidgets('analytics: daily_set_started and daily_set_completed', (
    tester,
  ) async {
    final analytics = _Analytics();
    final repos = FakeRepositories();
    await pumpF02(
      tester,
      repos: repos,
      location: AppRoutes.feed,
      below: AppRoutes.today,
      overrides: [analyticsProvider.overrideWithValue(analytics)],
    );
    await tester.pumpAndSettle();
    await tester.pump(_dwell);
    expect(analytics.events.map((e) => e.$1), ['daily_set_started']);
    expect(analytics.events.single.$2, {'cards_count': 10});

    // Posledna karta: po nej "Dnes si hotovy" a `daily_set_completed`.
    final analytics2 = _Analytics();
    final repos2 = FakeRepositories();
    repos2.dailySets.put(_state(cursor: 9));
    await pumpF02(
      tester,
      repos: repos2,
      location: AppRoutes.feed,
      below: AppRoutes.today,
      overrides: [analyticsProvider.overrideWithValue(analytics2)],
    );
    await tester.pumpAndSettle();
    await tester.pump(_dwell);
    await _swipeUp(tester);
    expect(find.byType(DoneCard), findsOneWidget);
    expect(analytics2.events.map((e) => e.$1), ['daily_set_completed']);
    expect(analytics2.events.single.$2['cards_count'], 10);
    expect(analytics2.events.single.$2['duration_s'], isA<int>());
  });

  testWidgets('reopening continues at the first unseen card', (tester) async {
    final repos = FakeRepositories();
    repos.dailySets.put(_state(cursor: 6));
    await _openFeed(tester, repos: repos);
    expect(find.text('[PLACEHOLDER translation 2:7]'), findsOneWidget);
    expect(find.text(Bidi.isolateLtr('6 / 10')), findsOneWidget);
  });

  testWidgets('completed set: done card, review without new seen', (
    tester,
  ) async {
    final repos = FakeRepositories();
    repos.dailySets.put(_state(cursor: 10, completed: true));
    await _openFeed(tester, repos: repos);
    expect(find.byType(DoneCard), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await _swipeDown(tester);
    expect(find.text('[PLACEHOLDER translation 2:10]'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(repos.dailySets.seen, isEmpty);
  });

  testWidgets('missing content is skipped and the feed moves on', (
    tester,
  ) async {
    final missing = AyahCardId(AyahId(2, 2));
    final repos = FakeRepositories(
      cards: FakeCardContentRepository(missing: {missing}),
    );
    repos.dailySets.put(_state(cursor: 1));
    await _openFeed(tester, repos: repos);
    expect(repos.dailySets.skipped, [missing]);
    expect(find.text('[PLACEHOLDER translation 2:3]'), findsOneWidget);
  });

  testWidgets('a broken card offers "Skip this card"', (tester) async {
    final broken = AyahCardId(AyahId(2, 2));
    final repos = FakeRepositories(cards: _FailingCards(broken));
    repos.dailySets.put(_state(cursor: 1));
    await _openFeed(tester, repos: repos);
    expect(find.text("This card didn't load"), findsOneWidget);
    await tester.tap(find.text('Skip this card'));
    await tester.pumpAndSettle();
    expect(repos.dailySets.skipped, [broken]);
    expect(_page(tester), 2);
  });

  testWidgets('long verse scrolls inside the card, then moves on (B0.5)', (
    tester,
  ) async {
    final repos = FakeRepositories(cards: _LongCards());
    repos.dailySets.put(_state(cursor: 2));
    await _openFeed(tester, repos: repos, textScale: 2);
    expect(_page(tester), 2);
    expectNoTextClipping(tester);
    final inner = find.descendant(
      of: find.byType(AyahCard),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(inner.first).position;
    expect(position.maxScrollExtent, greaterThan(0));

    // Dwell pretekajucej karty je dlhsi (max 15 s).
    await tester.pump(_dwell);
    expect(repos.dailySets.seen, isEmpty);
    await tester.pump(const Duration(seconds: 13));
    expect(repos.dailySets.seen, hasLength(1));

    // Najprv sa posuva text karty, az na konci dalsia karta.
    await tester.drag(find.byType(AyahCard), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(_page(tester), 2);
    expect(position.pixels, greaterThan(0));
    for (var i = 0; i < 40 && _page(tester) == 2; i++) {
      await tester.drag(find.byType(AyahCard), const Offset(0, -600));
      await tester.pumpAndSettle();
    }
    expect(_page(tester), 3);
  });

  testWidgets('dwell counts only while the app is in the foreground', (
    tester,
  ) async {
    final repos = FakeRepositories();
    await _openFeed(tester, repos: repos);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 5));
    expect(repos.dailySets.seen, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(_dwell);
    expect(repos.dailySets.seen, hasLength(1));
  });

  testWidgets('new day while the feed is open asks which set to use', (
    tester,
  ) async {
    final start = DateTime(2026, 10, 29, 23, 58);
    await _openFeed(tester, now: start, clock: advancingClock(tester, start));
    expect(find.text('THURSDAY'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 5));
    // Polnoc: feed ostava na povodnom dni (docs/02 A3).
    expect(find.text('THURSDAY'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('A new day has started'), findsOneWidget);
    await tester.tap(find.text("Start today's"));
    await tester.pumpAndSettle();
    expect(find.text('FRIDAY'), findsOneWidget);
  });

  testWidgets('close button and Android back return to Today', (tester) async {
    await _openFeed(tester);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);

    await tester.tap(find.text("Begin today's cards"));
    await tester.pumpAndSettle();
    expect(find.byType(FeedScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('semantics: card position and next card action', (tester) async {
    final handle = tester.ensureSemantics();
    final repos = FakeRepositories();
    repos.dailySets.put(_state(cursor: 1));
    await _openFeed(tester, repos: repos);
    expect(
      find.bySemanticsLabel(RegExp('^Card 2 of 10, Placeholder 2, verse 2')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('language fallback: ID shows the verse with an EN tag', (
    tester,
  ) async {
    final repos = FakeRepositories();
    repos.dailySets.put(_state(cursor: 1));
    await _openFeed(tester, repos: repos, locale: const Locale('id'));
    expect(find.byType(AyahCard), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
    expect(find.text('[PLACEHOLDER translation 2:2]'), findsOneWidget);
  });

  testWidgets('Arabic UI: verse without translation, RTL, no clipping', (
    tester,
  ) async {
    final repos = FakeRepositories();
    repos.dailySets.put(_state(cursor: 1));
    await _openFeed(
      tester,
      repos: repos,
      locale: const Locale('ar'),
      textScale: 2,
    );
    // V AR je arabsky original sam textom: ziadna poznamka (BF-01).
    expect(
      find.text('Translation not yet available in your language'),
      findsNothing,
    );
    expectNoTextClipping(tester);
  });
}
