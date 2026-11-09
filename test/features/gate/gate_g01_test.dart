import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/blocker/gate_repository.dart';
import 'package:prosoche/data/repositories/settings/settings_providers.dart';
import 'package:prosoche/domain/blocker/gate_friction.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/cards/cards.dart';
import 'package:prosoche/features/gate/gate_controller.dart';
import 'package:prosoche/features/gate/gate_screen.dart';
import 'package:prosoche/features/gate/gate_views.dart';

import '../../fakes/in_memory_settings_repository.dart';
import 'gate_harness.dart';

/// G-01: otazka zameru, pocitadlo s rastucim odporom, ranny zamok.
void main() {
  const practice = PracticeFirstRule(enabled: true, until: '10:00');

  Future<void> hold(WidgetTester tester) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Emergency')),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 1600));
    await gesture.up();
    await tester.pump();
  }

  group('intent question', () {
    testWidgets('one tap saves the reason locally and shows the cards', (
      tester,
    ) async {
      final t = GateTest(options: const GateOptions(askIntent: true));
      await t.pump(tester);
      expect(find.text('Why are you opening Instagram?'), findsOneWidget);
      expect(
        find.text('Noticing your reason is already a choice of your own.'),
        findsOneWidget,
      );
      for (final label in [
        'Boredom',
        'A message',
        'Work',
        'Habit',
        'Something else',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(CardView), findsNothing);
      // Dwell nebezi, kym je otazka na obrazovke.
      await tester.pump(const Duration(seconds: 6));
      expect(t.repos.dailySets.seen.where((s) => s.$2.type.isContent), isEmpty);

      await tester.tap(find.text('Habit'));
      await tester.pump();
      await tester.pump();
      expect(t.gates.intents, {1: GateIntent.habit});
      expect(find.byType(CardView), findsOneWidget);
      expect(find.text('4 s'), findsOneWidget);
      await passCard(tester);
      expect(
        t.repos.dailySets.seen.where((s) => s.$2.type.isContent),
        hasLength(1),
      );
    });

    testWidgets('Skip saves nothing', (tester) async {
      final t = GateTest(options: const GateOptions(askIntent: true));
      await t.pump(tester);
      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump();
      expect(t.gates.intents, isEmpty);
      expect(find.byType(CardView), findsOneWidget);
    });

    testWidgets('turned off goes straight to the cards', (tester) async {
      final t = GateTest();
      await t.pump(tester);
      expect(find.text('Why are you opening Instagram?'), findsNothing);
      expect(find.byType(CardView), findsOneWidget);
    });

    testWidgets('Emergency works from the question', (tester) async {
      final t = GateTest(options: const GateOptions(askIntent: true));
      await t.pump(tester);
      await hold(tester);
      expect(find.text('Opening Instagram'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(find.text('Why are you opening Instagram?'), findsOneWidget);
      await hold(tester);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(t.gates.unlocks, [(1, UnlockSource.emergency, 5)]);
    });
  });

  group('count and rising friction', () {
    testWidgets('first opening: 1st, normal dwell and cards', (tester) async {
      final t = GateTest(options: const GateOptions(risingFriction: true));
      await t.pump(tester);
      expect(
        find.text('This is your 1st time opening Instagram today.'),
        findsOneWidget,
      );
      expect(find.text('3 cards, then Instagram opens.'), findsOneWidget);
      expect(find.text('4 s'), findsOneWidget);
      expect(t.gates.opensChecks, [(1, gateToday)]);
    });

    testWidgets('3rd opening waits 1.5x longer', (tester) async {
      final t = GateTest(
        gates: FakeGateRepository()..opensBefore = 2,
        options: const GateOptions(risingFriction: true),
      );
      await t.pump(tester);
      expect(
        find.text(
          'This is your 3rd time opening Instagram today. '
          'Each return today asks for a little more time.',
        ),
        findsOneWidget,
      );
      expect(find.text('6 s'), findsOneWidget);
      expect(find.text('3 cards, then Instagram opens.'), findsOneWidget);
    });

    testWidgets('from the 4th opening one more card, dwell capped at 2x', (
      tester,
    ) async {
      final t = GateTest(
        gates: FakeGateRepository()..opensBefore = 10,
        options: const GateOptions(risingFriction: true),
      );
      await t.pump(tester);
      expect(
        find.textContaining('This is your 11th time opening Instagram'),
        findsOneWidget,
      );
      expect(find.text('4 cards, then Instagram opens.'), findsOneWidget);
      expect(find.text('8 s'), findsOneWidget);
      // Emergency ostava.
      expect(find.text('Emergency'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        for (var s = 0; s < 9; s++) {
          await tester.pump(const Duration(seconds: 1));
        }
        await tester.tap(find.text('Next'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
      }
      expect(t.gates.unlocks, isEmpty);
      for (var s = 0; s < 9; s++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pump();
      expect(t.gates.unlocks, [(1, UnlockSource.cards, 10)]);
    });

    testWidgets('turned off: no count, normal dwell', (tester) async {
      final t = GateTest(gates: FakeGateRepository()..opensBefore = 10);
      await t.pump(tester);
      expect(find.byKey(const ValueKey('gate:opens')), findsNothing);
      expect(find.text('4 s'), findsOneWidget);
      expect(t.gates.opensChecks, isEmpty);
    });

    testWidgets('count is also shown above the intent question', (
      tester,
    ) async {
      final t = GateTest(
        gates: FakeGateRepository()..opensBefore = 1,
        options: const GateOptions(askIntent: true, risingFriction: true),
      );
      await t.pump(tester);
      expect(
        find.textContaining('This is your 2nd time opening Instagram today.'),
        findsOneWidget,
      );
    });
  });

  test('English ordinal categories (CLDR)', () {
    const en = Locale('en');
    String form(int n) => ordinalCategory(en, n);
    expect(
      [
        for (final n in [1, 2, 3, 4, 11, 12, 13, 21, 22, 23, 101, 111, 112])
          form(n),
      ],
      [
        'one',
        'two',
        'few',
        'other',
        'other',
        'other',
        'other',
        'one',
        'two',
        'few',
        'one',
        'other',
        'other',
      ],
    );
    expect(ordinalCategory(const Locale('de'), 1), 'other');
  });

  group('practice first', () {
    testWidgets('locks before 10:00 and opens Practice', (tester) async {
      final t = GateTest(
        options: const GateOptions(askIntent: true, practiceFirst: practice),
      );
      await t.pump(tester);
      expect(find.text('Practice first'), findsOneWidget);
      expect(
        find.text(
          'Instagram stays closed until you finish your morning '
          'preparation, or until 10:00 AM.',
        ),
        findsOneWidget,
      );
      expect(find.byType(CardView), findsNothing);
      expect(find.text('Why are you opening Instagram?'), findsNothing);
      expect(find.text('Emergency'), findsOneWidget);
      expect(t.gates.morningChecks, [gateToday]);
      await tester.tap(find.text('Start morning preparation'));
      await tester.pump();
      expect(t.blocker.practiceOpened, 1);
      expect(t.blocker.calls, isNot(contains('unlockFor')));
      expect(t.gates.lastResult, GateResult.dismissed);
      expect(t.closed, 1);
    });

    testWidgets('onPractice is used instead of onClosed', (tester) async {
      final t = GateTest(options: const GateOptions(practiceFirst: practice));
      var practiceRoute = 0;
      await t.pump(
        tester,
        home: GateScreen(
          app: igRef,
          onClosed: () => t.closed++,
          onPractice: () => practiceRoute++,
        ),
      );
      await tester.tap(find.text('Start morning preparation'));
      await tester.pump();
      expect(practiceRoute, 1);
      expect(t.closed, 0);
    });

    testWidgets('native failure goes home instead', (tester) async {
      final t = GateTest(options: const GateOptions(practiceFirst: practice));
      await t.pump(tester);
      t.blocker.failNext = const NativeFailure('boom', 'blocker');
      await tester.tap(find.text('Start morning preparation'));
      await tester.pump();
      expect(t.blocker.lastCloseOpenTarget, isFalse);
      expect(t.closed, 1);
    });

    testWidgets('Go back goes home, nothing unlocked', (tester) async {
      final t = GateTest(options: const GateOptions(practiceFirst: practice));
      await t.pump(tester);
      await tester.tap(find.text('Go back'));
      await tester.pump();
      expect(t.blocker.lastCloseOpenTarget, isFalse);
      expect(t.gates.unlocks, isEmpty);
    });

    testWidgets('Emergency stays available', (tester) async {
      final t = GateTest(options: const GateOptions(practiceFirst: practice));
      await t.pump(tester);
      await hold(tester);
      expect(find.text('Opening Instagram'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(find.text('Start morning preparation'), findsOneWidget);
      await hold(tester);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(t.blocker.isUnlocked(igRef), isTrue);
      expect(t.gates.unlocks, [(1, UnlockSource.emergency, 5)]);
    });

    testWidgets('after morning preparation the gate works normally', (
      tester,
    ) async {
      final t = GateTest(
        gates: FakeGateRepository()..morningDone = true,
        options: const GateOptions(practiceFirst: practice),
      );
      await t.pump(tester);
      expect(find.text('Start morning preparation'), findsNothing);
      expect(find.byType(CardView), findsOneWidget);
    });

    testWidgets('after the chosen time the gate works normally', (
      tester,
    ) async {
      final t = GateTest(
        options: const GateOptions(
          practiceFirst: PracticeFirstRule(enabled: true, until: '08:30'),
        ),
      );
      await t.pump(tester);
      expect(find.byType(CardView), findsOneWidget);
    });

    testWidgets('app not chosen for the lock works normally', (tester) async {
      final t = GateTest(
        gates: FakeGateRepository(
          apps: {
            igRef: const GateTarget(
              id: 1,
              ref: igRef,
              label: 'Instagram',
              cardsRequired: 3,
              unlockMinutes: 10,
              practiceFirst: false,
            ),
          },
        ),
        options: const GateOptions(practiceFirst: practice),
      );
      await t.pump(tester);
      expect(find.byType(CardView), findsOneWidget);
      expect(t.gates.morningChecks, isEmpty);
    });
  });

  test('gateOptionsProvider reads the settings, defaults on/on/off', () async {
    final settings = InMemorySettingsRepository();
    final c = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(settings)],
    );
    addTearDown(c.dispose);
    var o = await c.read(gateOptionsProvider)();
    expect(o.askIntent, isTrue);
    expect(o.risingFriction, isTrue);
    expect(o.practiceFirst.enabled, isFalse);
    expect(o.practiceFirst.until, '10:00');
    await settings.set(SettingsKeys.gateAskIntent, false);
    await settings.set(SettingsKeys.gateRisingFriction, false);
    await settings.set(SettingsKeys.gatePracticeFirst, true);
    await settings.set(SettingsKeys.gatePracticeFirstUntil, '09:15');
    o = await c.read(gateOptionsProvider)();
    expect(o.askIntent, isFalse);
    expect(o.risingFriction, isFalse);
    expect(o.practiceFirst.enabled, isTrue);
    expect(o.practiceFirst.untilMinutes, 555);
  });
}
