import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/blocker/gate_repository.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/feed.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:prosoche/domain/quests/quests.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/cards/cards.dart';
import 'package:prosoche/features/gate/gate_screen.dart';
import 'package:prosoche/ui/ui.dart';

import '../../fakes/fake_repositories.dart';
import 'gate_harness.dart';

/// Sada s hadisom, eventom v strede a kvizmi (pravidla brany A4).
DailySet _mixedSet(LocalDate date) => DailySet(
  date: date,
  phase: DayPhase.morning,
  cards: [
    DailySetCard(pos: 1, cardId: IntroCardId(date), slot: Slot.intro),
    DailySetCard(
      pos: 2,
      cardId: AyahCardId(AyahId(2, 2)),
      slot: Slot.ayah,
      khatm: true,
    ),
    DailySetCard(pos: 3, cardId: HadithCardId(7), slot: Slot.hadithDua),
    DailySetCard(
      pos: 4,
      cardId: AyahCardId(AyahId(2, 3)),
      slot: Slot.ayah,
      khatm: true,
    ),
  ],
);

class _PendingSets extends FakeDailySetRepository {
  @override
  Future<DailySetState> ensure(LocalDate date, {bool shorterSet = false}) =>
      Completer<DailySetState>().future;
}

void main() {
  group('loading and closing without UI', () {
    testWidgets('loading shows a spinner, then "Still loading…"', (
      tester,
    ) async {
      final t = GateTest(repos: FakeRepositories(dailySets: _PendingSets()));
      await t.pump(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Still loading…'), findsNothing);
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text('Still loading…'), findsOneWidget);
    });

    testWidgets('timeout after 3 s is the error state', (tester) async {
      final t = GateTest(gates: FakeGateRepository()..hang = true);
      await t.pump(tester);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(find.text("We couldn't load your cards"), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('app that is not blocked closes the gate into the app', (
      tester,
    ) async {
      final t = GateTest(gates: FakeGateRepository(apps: {}));
      await t.pump(tester);
      expect(t.blocker.lastCloseOpenTarget, isTrue);
      expect(t.blocker.calls, isNot(contains('unlockFor')));
      expect(t.gates.sessions, isEmpty);
      expect(t.closed, 1);
    });

    testWidgets('disabled app closes the gate into the app', (tester) async {
      final t = GateTest(
        gates: FakeGateRepository(
          apps: {igRef: FakeGateRepository.instagram(enabled: false)},
        ),
      );
      await t.pump(tester);
      expect(t.blocker.lastCloseOpenTarget, isTrue);
    });

    testWidgets('remote kill-switch blocker_overlay closes the gate', (
      tester,
    ) async {
      final t = GateTest();
      await t.pump(tester, overlayEnabled: false);
      expect(t.blocker.lastCloseOpenTarget, isTrue);
      expect(t.gates.sessions, isEmpty);
    });
  });

  group('error', () {
    testWidgets('DB error: Continue unlocks for unlock_minutes, source=error', (
      tester,
    ) async {
      final t = GateTest(
        gates: FakeGateRepository()..appError = Exception('locked'),
      );
      await t.pump(tester);
      expect(find.text("We couldn't load your cards"), findsOneWidget);
      expect(
        find.text('This is our mistake, not yours. You can continue.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(t.blocker.isUnlocked(igRef), isTrue);
      expect(t.gates.unlocks, [(null, UnlockSource.error, 10)]);
      expect(t.blocker.lastCloseOpenTarget, isTrue);
    });

    testWidgets('set error after the app is known names the app', (
      tester,
    ) async {
      final repos = FakeRepositories()..dailySets.ensureError = Exception('db');
      final t = GateTest(repos: repos);
      await t.pump(tester);
      expect(find.text('Continue to Instagram'), findsOneWidget);
      await tester.tap(find.text('Continue to Instagram'));
      await tester.pump();
      expect(t.gates.unlocks, [(1, UnlockSource.error, 10)]);
      expect(t.gates.lastResult, GateResult.error);
      expect(t.blocker.lastCloseOpenTarget, isTrue);
    });

    testWidgets('native failure on Continue still lets the user through', (
      tester,
    ) async {
      final repos = FakeRepositories()..dailySets.ensureError = Exception('db');
      final t = GateTest(repos: repos);
      await t.pump(tester);
      t.blocker.failNext = const NativeFailure('internal', 'blocker');
      await tester.tap(find.text('Continue to Instagram'));
      await tester.pump();
      expect(t.gates.unlocks, isEmpty);
      expect(t.blocker.lastCloseOpenTarget, isTrue);
    });

    testWidgets('Go back from the error goes home', (tester) async {
      final repos = FakeRepositories()..dailySets.ensureError = Exception('db');
      final t = GateTest(repos: repos);
      await t.pump(tester);
      await tester.tap(find.text('Go back'));
      await tester.pump();
      expect(t.blocker.lastCloseOpenTarget, isFalse);
      expect(t.blocker.isUnlocked(igRef), isFalse);
      expect(t.gates.lastResult, GateResult.error);
    });
  });

  group('cards', () {
    testWidgets('header, dwell countdown and the first unseen card', (
      tester,
    ) async {
      final t = GateTest();
      await t.pump(tester);
      expect(find.text('A pause before Instagram'), findsOneWidget);
      expect(find.text('3 cards, then Instagram opens.'), findsOneWidget);
      expect(find.byType(SkDailyProgress), findsOneWidget);
      // Intro sa preskoci a oznaci seen s context=gate.
      expect(t.repos.dailySets.seen, [
        (gateToday, IntroCardId(gateToday), CardContext.gate),
      ]);
      expect(find.byType(CardView), findsOneWidget);
      expect(find.text('4 s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('3 s'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
      // Read in context je v brane skryte.
      expect(find.text('Read in context'), findsNothing);
    });

    testWidgets('dwell is max(card.seen_dwell_ms, 4 s)', (tester) async {
      final repos = FakeRepositories();
      await repos.settings.set(SettingsKeys.cardSeenDwellMs, 6000);
      final t = GateTest(repos: repos);
      await t.pump(tester);
      expect(find.text('6 s'), findsOneWidget);
    });

    testWidgets('3 cards unlock for 10 min and continue opens the app', (
      tester,
    ) async {
      final t = GateTest();
      await t.pump(tester);
      await passCard(tester);
      await passCard(tester);
      expect(t.blocker.calls, isNot(contains('unlockFor')));
      await passCard(tester, next: false);
      await tester.pump();
      expect(t.blocker.isUnlocked(igRef), isTrue);
      expect(t.gates.unlocks, [(1, UnlockSource.cards, 10)]);
      expect(t.gates.lastResult, GateResult.passed);
      final seen = t.repos.dailySets.seen
          .where((s) => s.$2 is AyahCardId)
          .map((s) => (s.$2, s.$3));
      expect(seen, [
        (AyahCardId(AyahId(2, 2)), CardContext.gate),
        (AyahCardId(AyahId(2, 3)), CardContext.gate),
        (AyahCardId(AyahId(2, 4)), CardContext.gate),
      ]);
      // Cursor sady sa posunul (spolocny s Feedom).
      final state = await t.repos.dailySets.get(gateToday);
      expect(state!.cursor, 4);
      expect(find.text('Instagram is open for 10 minutes'), findsOneWidget);
      expect(find.text('Use them well.'), findsOneWidget);
      await tester.tap(find.text('Continue to Instagram'));
      await tester.pump();
      expect(t.blocker.lastCloseOpenTarget, isTrue);
      expect(t.closed, 1);
    });

    testWidgets('unlocked screen continues automatically after 5 s', (
      tester,
    ) async {
      final t = GateTest(
        gates: FakeGateRepository(
          apps: {igRef: FakeGateRepository.instagram(cardsRequired: 1)},
        ),
      );
      await t.pump(tester);
      await passCard(tester, next: false);
      await tester.pump();
      expect(find.text('Instagram is open for 10 minutes'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(t.blocker.lastCloseOpenTarget, isTrue);
    });

    testWidgets('Close instead goes home, the unlock stays', (tester) async {
      final t = GateTest(
        gates: FakeGateRepository(
          apps: {igRef: FakeGateRepository.instagram(cardsRequired: 1)},
        ),
      );
      await t.pump(tester);
      await passCard(tester, next: false);
      await tester.pump();
      await tester.tap(find.text('Close Instagram instead'));
      await tester.pump();
      expect(t.blocker.lastCloseOpenTarget, isFalse);
      expect(t.gates.lastResult, GateResult.passed);
    });

    testWidgets('Keep reading shows more cards, then Continue', (tester) async {
      final t = GateTest(
        gates: FakeGateRepository(
          apps: {igRef: FakeGateRepository.instagram(cardsRequired: 1)},
        ),
      );
      await t.pump(tester);
      await passCard(tester, next: false);
      await tester.pump();
      await tester.tap(find.text('Keep reading'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(CardView), findsOneWidget);
      expect(find.text('Hold to open now'), findsNothing);
      // No auto-continue while reading.
      await passCard(tester, next: false);
      expect(t.blocker.lastCloseOpenTarget, isNull);
      expect(t.gates.sessions[1]!.cardsSeen, 1);
      await tester.tap(find.text('Continue to Instagram'));
      await tester.pump();
      expect(t.blocker.lastCloseOpenTarget, isTrue);
      expect(t.gates.sessions[1], (result: GateResult.passed, cardsSeen: 2));
      expect(t.gates.unlocks, hasLength(1));
    });

    testWidgets('Go back closes to home, nothing unlocked', (tester) async {
      final t = GateTest();
      await t.pump(tester);
      await passCard(tester);
      await tester.tap(find.text('Go back'));
      await tester.pump();
      expect(t.blocker.lastCloseOpenTarget, isFalse);
      expect(t.blocker.isUnlocked(igRef), isFalse);
      expect(t.gates.unlocks, isEmpty);
      expect(t.gates.sessions[1], (result: GateResult.dismissed, cardsSeen: 1));
    });

    testWidgets('Android back closes to home', (tester) async {
      final t = GateTest();
      await t.pump(tester);
      final popped = await tester.binding.handlePopRoute();
      await tester.pump();
      expect(popped, isTrue);
      expect(t.blocker.lastCloseOpenTarget, isFalse);
    });

    testWidgets('event and intro are skipped, max one quiz', (tester) async {
      DailySet build(LocalDate date) => DailySet(
        date: date,
        phase: DayPhase.morning,
        cards: [
          DailySetCard(pos: 1, cardId: IntroCardId(date), slot: Slot.intro),
          DailySetCard(pos: 2, cardId: HadithCardId(7), slot: Slot.hadithDua),
          DailySetCard(
            pos: 3,
            cardId: EventCardId('example', date),
            slot: Slot.event,
          ),
          DailySetCard(pos: 4, cardId: DuaCardId(3), slot: Slot.hadithDua),
        ],
      );
      final repos = FakeRepositories(
        dailySets: FakeDailySetRepository(build: build),
      );
      final t = GateTest(
        repos: repos,
        gates: FakeGateRepository(
          apps: {igRef: FakeGateRepository.instagram(cardsRequired: 2)},
        ),
      );
      await t.pump(tester);
      await passCard(tester);
      await passCard(tester, next: false);
      await tester.pump();
      expect(t.repos.dailySets.seen.map((s) => s.$2), [
        IntroCardId(gateToday),
        HadithCardId(7),
        EventCardId('example', gateToday),
        DuaCardId(3),
      ]);
      expect(
        t.repos.dailySets.seen.every((s) => s.$3 == CardContext.gate),
        isTrue,
      );
      expect(find.text('Instagram is open for 10 minutes'), findsOneWidget);
      // Dua bola posledna karta sady.
      expect(find.text("You finished today's set."), findsOneWidget);
    });

    testWidgets('missing content is skipped and does not count', (
      tester,
    ) async {
      final repos = FakeRepositories(
        dailySets: FakeDailySetRepository(build: _mixedSet),
        cards: FakeCardContentRepository(missing: {HadithCardId(7)}),
      );
      final t = GateTest(
        repos: repos,
        gates: FakeGateRepository(
          apps: {igRef: FakeGateRepository.instagram(cardsRequired: 2)},
        ),
      );
      await t.pump(tester);
      await passCard(tester);
      await tester.pump();
      expect(t.repos.dailySets.skipped, [HadithCardId(7)]);
      await passCard(tester, next: false);
      await tester.pump();
      expect(t.gates.unlocks, [(1, UnlockSource.cards, 10)]);
      expect(t.gates.sessions[1]!.cardsSeen, 2);
    });

    testWidgets('only missing content ends in the empty state', (tester) async {
      final missing = {
        for (var a = 1; a <= 20; a++) AyahCardId(AyahId(2, a)) as CardId,
      };
      final repos = FakeRepositories(
        cards: FakeCardContentRepository(missing: missing),
      );
      final t = GateTest(repos: repos);
      await t.pump(tester);
      for (var i = 0; i < 30; i++) {
        await tester.pump();
      }
      expect(
        find.text('Nothing to show right now. Instagram is open.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Continue to Instagram'));
      await tester.pump();
      expect(t.gates.unlocks, [(1, UnlockSource.error, 10)]);
      expect(t.blocker.lastCloseOpenTarget, isTrue);
    });
  });

  group('free reading', () {
    testWidgets('finished set shows verses from reading_position+1', (
      tester,
    ) async {
      final repos = FakeRepositories();
      repos.dailySets.put(
        DailySetState(
          set: fakeDailySet(gateToday),
          cursor: 10,
          completedAt: gateNow,
        ),
      );
      final t = GateTest(
        repos: repos,
        gates: FakeGateRepository(position: AyahId(18, 4)),
      );
      await t.pump(tester);
      expect(
        find.text(
          "Today's cards are done. Here are a few verses from where you "
          'left off.',
        ),
        findsOneWidget,
      );
      await passCard(tester);
      await passCard(tester);
      await passCard(tester, next: false);
      await tester.pump();
      expect(t.gates.freeReading, [
        AyahId(18, 5),
        AyahId(18, 6),
        AyahId(18, 7),
      ]);
      expect(t.gates.position, AyahId(18, 7));
      expect(t.repos.dailySets.seen, isEmpty);
      expect(t.gates.unlocks, [(1, UnlockSource.cards, 10)]);
    });

    testWidgets('gate that finishes the set says so', (tester) async {
      final repos = FakeRepositories(
        dailySets: FakeDailySetRepository(build: _mixedSet),
      );
      final t = GateTest(repos: repos);
      await t.pump(tester);
      await passCard(tester);
      await passCard(tester);
      await passCard(tester, next: false);
      await tester.pump();
      expect(find.text("You finished today's set."), findsOneWidget);
      // Volne citanie pokracuje za poslednym khatm versom sady (2:3).
      await tester.tap(find.text('Keep reading'));
      await tester.pump();
      await tester.pump();
      await passCard(tester, next: false);
      expect(t.gates.freeReading, [AyahId(2, 4)]);
    });
  });

  group('emergency', () {
    Finder hold() => find.text('Emergency');

    testWidgets('release before 1.5 s unlocks nothing', (tester) async {
      final t = GateTest();
      await t.pump(tester);
      final gesture = await tester.startGesture(tester.getCenter(hold()));
      await tester.pump(const Duration(milliseconds: 1000));
      await gesture.up();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Opening Instagram'), findsNothing);
      expect(t.blocker.calls, isNot(contains('unlockFor')));
    });

    testWidgets('hold 1.5 s and Cancel unlocks nothing', (tester) async {
      final t = GateTest();
      await t.pump(tester);
      final gesture = await tester.startGesture(tester.getCenter(hold()));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 1600));
      await gesture.up();
      await tester.pump();
      expect(find.text('Opening Instagram'), findsOneWidget);
      expect(find.text('Opening in 10 seconds.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Opening in 7 seconds.'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 12));
      expect(t.blocker.calls, isNot(contains('unlockFor')));
      expect(find.byType(CardView), findsOneWidget);
    });

    testWidgets('hold 1.5 s and wait 10 s unlocks for 5 min', (tester) async {
      final t = GateTest();
      await t.pump(tester);
      final gesture = await tester.startGesture(tester.getCenter(hold()));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 1600));
      await gesture.up();
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(t.blocker.isUnlocked(igRef), isTrue);
      expect(t.gates.unlocks, [(1, UnlockSource.emergency, 5)]);
      expect(t.gates.lastResult, GateResult.emergency);
      expect(t.blocker.lastCloseOpenTarget, isTrue);
    });

    testWidgets('Android back during the countdown cancels it', (tester) async {
      final t = GateTest();
      await t.pump(tester);
      final gesture = await tester.startGesture(tester.getCenter(hold()));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 1600));
      await gesture.up();
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(CardView), findsOneWidget);
      expect(t.blocker.lastCloseOpenTarget, isNull);
    });

    testWidgets('TalkBack opens a dialog with the same countdown', (
      tester,
    ) async {
      final t = GateTest();
      await t.pump(tester, accessibleNavigation: true);
      await tester.tap(hold());
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Open Instagram without cards? It opens in 10 seconds for 5 '
          'minutes.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Emergency').last);
      await tester.pumpAndSettle();
      expect(find.text('Opening Instagram'), findsOneWidget);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(t.gates.unlocks, [(1, UnlockSource.emergency, 5)]);
    });
  });

  group('prayer lock', () {
    final asr = DateTime(2026, 10, 29, 8, 55);

    GateTest prayerGate() => GateTest(
      gates: FakeGateRepository(
        apps: {igRef: FakeGateRepository.instagram(prayerLock: true)},
      ),
    );

    testWidgets("I'll pray first goes home", (tester) async {
      final t = prayerGate();
      await t.pump(tester, extra: [_currentPrayer(Prayer.asr, asr)]);
      expect(find.text("It's time for Asr"), findsOneWidget);
      expect(
        find.text('Instagram will still be here after you pray.'),
        findsOneWidget,
      );
      await tester.tap(find.text("I'll pray first"));
      await tester.pump();
      expect(t.blocker.lastCloseOpenTarget, isFalse);
      expect(t.gates.lastResult, GateResult.prayerLocked);
    });

    testWidgets('Show cards anyway: cards unlock as usual', (tester) async {
      final t = prayerGate();
      await t.pump(tester, extra: [_currentPrayer(Prayer.asr, asr)]);
      await tester.tap(find.text('Show cards anyway'));
      await tester.pump();
      await tester.pump();
      await passCard(tester);
      await passCard(tester);
      await passCard(tester, next: false);
      await tester.pump();
      expect(t.gates.unlocks, [(1, UnlockSource.cards, 10)]);
    });

    testWidgets('outside the window there is no reminder', (tester) async {
      final t = prayerGate();
      await t.pump(
        tester,
        extra: [_currentPrayer(Prayer.asr, DateTime(2026, 10, 29, 8, 30))],
      );
      expect(find.text("It's time for Asr"), findsNothing);
      expect(find.byType(CardView), findsOneWidget);
    });

    testWidgets('window follows blocker.prayer_lock_minutes', (tester) async {
      for (final (minutes, reminder) in [(3, false), (0, false), (30, true)]) {
        final t = prayerGate();
        await t.repos.settings.set(
          SettingsKeys.blockerPrayerLockMinutes,
          minutes,
        );
        await t.pump(tester, extra: [_currentPrayer(Prayer.asr, asr)]);
        expect(
          find.text("It's time for Asr"),
          reminder ? findsOneWidget : findsNothing,
          reason: '$minutes min',
        );
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('sunrise is not a prayer lock', (tester) async {
      final t = prayerGate();
      await t.pump(tester, extra: [_currentPrayer(Prayer.sunrise, asr)]);
      expect(find.byType(CardView), findsOneWidget);
    });
  });
}

/// Aktualna modlitba bez polohy a adhan vypoctu.
Override _currentPrayer(Prayer prayer, DateTime start) =>
    gateCurrentPrayerProvider.overrideWithValue(
      () async => (prayer: prayer, start: start),
    );
