import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/data/blocker/blocker_gateway.dart';
import 'package:prosoche/data/blocker/fake_blocker_gateway.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/onboarding/onboarding_screen.dart';
import 'package:prosoche/features/onboarding/onboarding_steps.dart';
import 'package:prosoche/features/onboarding/steps/intention_step.dart';
import 'package:prosoche/features/onboarding/steps/notifications_step.dart';
import 'package:prosoche/features/onboarding/steps/privacy_step.dart';
import 'package:prosoche/features/onboarding/steps/welcome_step.dart';
import 'package:prosoche/features/today/today_screen.dart';

import '../../fakes/fake_repositories.dart';
import '../../fakes/in_memory_settings_repository.dart';
import 'onboarding_test_helpers.dart';

void main() {
  testWidgets('whole onboarding lite with fake repositories', (tester) async {
    final h = OnboardingHarness();
    final settings = h.repos.settings;
    final router = await h.pumpApp(tester);

    // Guard: nedokonceny onboarding -> O1.
    expect(router.state.uri.path, '/onboarding/welcome');
    expect(find.byType(WelcomeStep), findsOneWidget);
    expect(find.text('Step 1 of 4'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);
    expect(find.text('Skip'), findsNothing);

    await tapPrimary(tester, 'Continue');
    expect(await settings.get(SettingsKeys.onboardingStep), 'intention');

    // O2: preset + vlastny text (odreze sa na 140 znakov).
    expect(find.byType(IntentionStep), findsOneWidget);
    expect(find.text('Step 2 of 4'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('intention:calm')));
    await tapVisible(tester, find.byKey(const ValueKey('intention:own')));
    await tester.enterText(
      find.byKey(const ValueKey('intention:text')),
      'x' * 200,
    );
    await tapPrimary(tester, 'Continue');
    expect(await settings.get(SettingsKeys.intentionPreset), 'calm');
    expect(await settings.get(SettingsKeys.intentionText), hasLength(140));

    // O4: povolenie notifikacii, bez polohy a modlitieb.
    expect(find.byType(NotificationsStep), findsOneWidget);
    expect(find.textContaining('prayer'), findsNothing);
    await tapVisible(tester, find.text('Allow notifications'));
    expect(h.notifications.requests, 1);
    expect(find.text('Notifications are on'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('notif:morning')));
    await tapPrimary(tester, 'Continue');
    expect(await settings.get(SettingsKeys.notifMorningEnabled), isFalse);

    // O7: suhlas az po veku 16+, dve samostatne volby.
    expect(find.byType(PrivacyStep), findsOneWidget);
    expect(find.text('Step 4 of 4'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    await tapVisible(tester, find.byKey(const ValueKey('privacy:age')));
    await tapVisible(
      tester,
      find.byKey(const ValueKey('privacy:analytics:yes')),
    );
    await tapVisible(tester, find.byKey(const ValueKey('privacy:crash:no')));
    await tapPrimary(tester, 'Finish');

    expect(router.state.uri.path, '/today');
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(await settings.get(SettingsKeys.onboardingCompleted), isTrue);
    expect(await settings.get(SettingsKeys.analyticsOptIn), isTrue);
    expect(await settings.get(SettingsKeys.crashReports), isFalse);
    expect(await settings.get(SettingsKeys.ageConfirmed16), isTrue);
    // Prva denna sada a preplanovanie notifikacii.
    expect(await h.repos.dailySets.get(testToday), isNotNull);
    expect(h.reschedules, 1);
    // Buffer odisiel az po suhlase, bez obsahu.
    expect(h.sent.map((e) => e.name), contains('onboarding_completed'));
    expect(
      h.sent.where((e) => e.name == 'onboarding_step').map((e) => e.props),
      [
        {'step': 'welcome', 'skipped': false},
        {'step': 'intention', 'skipped': false},
        {'step': 'notifications', 'skipped': false},
        {'step': 'privacy', 'skipped': false},
      ],
    );
    expect(h.sent.firstWhere((e) => e.name == 'onboarding_completed').props, {
      'blocker_enabled': false,
      'notif_granted': true,
    });

    // Dokonceny onboarding: /onboarding/* -> /today.
    router.go('/onboarding/welcome');
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/today');
  });

  testWidgets('skipping everything finishes without consent', (tester) async {
    final h = OnboardingHarness();
    await h.pumpApp(tester);
    await tapPrimary(tester, 'Continue');
    for (var i = 0; i < 2; i++) {
      await tapVisible(tester, find.text('Skip'));
    }
    expect(find.byType(PrivacyStep), findsOneWidget);
    // Bez veku su volby nedostupne a Finish je aktivne.
    await tapVisible(
      tester,
      find.byKey(const ValueKey('privacy:analytics:yes')),
    );
    await tapPrimary(tester, 'Finish');
    expect(find.byType(TodayScreen), findsOneWidget);
    final s = h.repos.settings;
    expect(await s.get(SettingsKeys.analyticsOptIn), isFalse);
    expect(await s.get(SettingsKeys.crashReports), isFalse);
    expect(await s.get(SettingsKeys.intentionText), isNull);
    // Bez suhlasu sa buffer zahodi.
    expect(h.sent, isEmpty);
  });

  testWidgets('resumes at the stored onboarding.step', (tester) async {
    final settings = InMemorySettingsRepository();
    await settings.set(SettingsKeys.onboardingStep, 'notifications');
    final h = OnboardingHarness(repos: FakeRepositories(settings: settings));
    final router = await h.pumpApp(tester, location: '/journey');
    expect(router.state.uri.path, '/onboarding/notifications');
    expect(find.text('Step 3 of 4'), findsOneWidget);
  });

  testWidgets('gate step stored in lite resumes at the next lite step', (
    tester,
  ) async {
    final settings = InMemorySettingsRepository();
    await settings.set(SettingsKeys.onboardingStep, 'gate_apps');
    final h = OnboardingHarness(repos: FakeRepositories(settings: settings));
    final router = await h.pumpApp(tester);
    expect(router.state.uri.path, '/onboarding/privacy');

    router.go('/onboarding/permissions');
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/onboarding/welcome');
  });

  testWidgets('gate flavor has 6 steps with gate apps and permissions', (
    tester,
  ) async {
    final settings = InMemorySettingsRepository();
    await settings.set(SettingsKeys.onboardingStep, 'notifications');
    final blocker = FakeBlockerGateway(
      apps: const [
        LaunchableApp(ref: 'com.example.notes', label: 'Notes'),
        LaunchableApp(ref: 'com.instagram.android', label: 'Instagram'),
        LaunchableApp(ref: 'com.zhiliaoapp.musically', label: 'TikTok'),
      ],
      permissionsState: const BlockerPermissions(
        usageAccess: false,
        overlay: false,
        notifications: true,
        exactAlarm: true,
        batteryOptimized: true,
      ),
    );
    final h = OnboardingHarness(
      repos: FakeRepositories(settings: settings),
      blocker: blocker,
      flags: FeatureFlags.all,
    );
    await h.pumpApp(tester);
    expect(find.text('Step 3 of 6'), findsOneWidget);
    await tapVisible(tester, find.text('Skip'));

    // O5: socialne siete su predvybrate, pocet kariet a minut.
    expect(find.text('Which apps should wait?'), findsOneWidget);
    expect(find.text('Step 4 of 6'), findsOneWidget);
    await tapVisible(tester, find.text('TikTok'));
    await tapPrimary(tester, 'Continue with 1 app');
    expect(h.blockedApps.current.single.ref, 'com.instagram.android');
    expect(h.blockedApps.current.single.cardsRequired, 3);
    expect(h.blockedApps.current.single.unlockMinutes, 10);
    expect(blocker.targets.single.ref, 'com.instagram.android');

    // O6: disclosure pred tlacidlom, Turn on az po povoleniach.
    expect(find.text('Permissions for the gate'), findsOneWidget);
    expect(find.text('Step 5 of 6'), findsOneWidget);
    expect(find.textContaining('Usage Access to notice'), findsOneWidget);
    expect(isPrimaryEnabled(tester, 'Turn on the gate'), isFalse);
    blocker.permissionsState = BlockerPermissions.allGranted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    await tapPrimary(tester, 'Turn on the gate');
    expect(blocker.enabled, isTrue);
    expect(await settings.get(SettingsKeys.blockerEnabled), isTrue);
    expect(find.byType(PrivacyStep), findsOneWidget);
  });

  testWidgets('gate flavor: no apps skips permissions', (tester) async {
    final settings = InMemorySettingsRepository();
    await settings.set(SettingsKeys.onboardingStep, 'gate_apps');
    final h = OnboardingHarness(
      repos: FakeRepositories(settings: settings),
      blocker: FakeBlockerGateway(
        apps: const [LaunchableApp(ref: 'com.example.notes', label: 'Notes')],
      ),
      flags: FeatureFlags.all,
    );
    await h.pumpApp(tester);
    await tapPrimary(tester, 'Continue without the gate');
    expect(find.byType(PrivacyStep), findsOneWidget);
    expect(h.blockedApps.current, isEmpty);
    expect(await settings.get(SettingsKeys.blockerEnabled), isFalse);
  });

  testWidgets('completed onboarding opens Today directly', (tester) async {
    final settings = InMemorySettingsRepository();
    await settings.set(SettingsKeys.onboardingCompleted, true);
    final h = OnboardingHarness(repos: FakeRepositories(settings: settings));
    final router = await h.pumpApp(tester);
    expect(router.state.uri.path, '/today');
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('gate deep link is not redirected to onboarding', (tester) async {
    final h = OnboardingHarness(flags: FeatureFlags.all);
    final router = await h.pumpApp(
      tester,
      location: '/gate?app=com.instagram.android',
    );
    expect(router.state.uri.path, '/gate');
  });

  group('back (docs/02 C5)', () {
    testWidgets('goes to the previous step, first step lets the app close', (
      tester,
    ) async {
      final h = OnboardingHarness();
      final router = await h.pumpApp(tester);
      PopScope<Object?> popScope() => tester.widget<PopScope<Object?>>(
        find.descendant(
          of: find.byType(OnboardingScreen),
          matching: find.byWidgetPredicate((w) => w is PopScope),
        ),
      );
      expect(popScope().canPop, isTrue);

      await tapPrimary(tester, 'Continue');
      expect(find.byType(IntentionStep), findsOneWidget);
      expect(popScope().canPop, isFalse);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/onboarding/welcome');

      await tapPrimary(tester, 'Continue');
      await tapVisible(tester, find.byTooltip('Back'));
      expect(find.byType(WelcomeStep), findsOneWidget);
    });
  });

  test('flow order and resume mapping', () {
    const lite = OnboardingFlow(gate: false);
    const full = OnboardingFlow(gate: true);
    expect(lite.steps.map((s) => s.key), [
      'welcome',
      'intention',
      'notifications',
      'privacy',
    ]);
    expect(full.total, 6);
    expect(
      SettingsKeys.onboardingSteps,
      OnboardingStep.values.map((s) => s.key),
    );
    expect(lite.resume('permissions'), OnboardingStep.privacy);
    expect(full.resume('permissions'), OnboardingStep.permissions);
    expect(lite.resume(null), OnboardingStep.welcome);
    expect(lite.resume('evil'), OnboardingStep.welcome);
    expect(lite.next(OnboardingStep.privacy), isNull);
    expect(lite.next(OnboardingStep.gateApps), isNull);
    expect(lite.previous(OnboardingStep.welcome), isNull);
    expect(lite.previous(OnboardingStep.privacy), OnboardingStep.notifications);
    expect(full.number(OnboardingStep.privacy), 6);
  });
}
