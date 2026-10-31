import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/onboarding/onboarding_steps.dart';
import 'package:prosoche/features/onboarding/steps/intention_step.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

import '../../fakes/fake_repositories.dart';
import '../../fakes/in_memory_settings_repository.dart';
import 'onboarding_test_helpers.dart';

/// Krok onboardingu bez routera vo svetlej teme Prosoche.
Future<void> pumpStep(
  WidgetTester tester,
  OnboardingHarness h,
  OnboardingStep step, {
  Locale locale = ProsocheLocales.en,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ProsocheTheme.light(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: h.step(step),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('O1 welcome', () {
    testWidgets('app name, short text and Continue', (tester) async {
      final h = OnboardingHarness();
      await pumpStep(tester, h, OnboardingStep.welcome);
      expect(find.text('Prosoche'), findsOneWidget);
      expect(find.textContaining('Stoics'), findsOneWidget);
      expect(find.text('Skip'), findsNothing);
      expect(isPrimaryEnabled(tester, 'Continue'), isTrue);
    });
  });

  group('O2 intention', () {
    testWidgets('restores stored presets and text', (tester) async {
      final settings = InMemorySettingsRepository();
      await settings.set(SettingsKeys.intentionPreset, 'reflect,calm');
      await settings.set(SettingsKeys.intentionText, 'Mine');
      final h = OnboardingHarness(repos: FakeRepositories(settings: settings));
      await pumpStep(tester, h, OnboardingStep.intention);
      FilterChip chip(String id) =>
          tester.widget<FilterChip>(find.byKey(ValueKey('intention:$id')));
      expect(chip('calm').selected, isTrue);
      expect(chip('reflect').selected, isTrue);
      expect(chip('read_daily').selected, isFalse);
      expect(chip('own').selected, isTrue);
      expect(find.text('Mine'), findsOneWidget);
    });

    test('preset encoding keeps the canonical order', () {
      expect(encodeIntentionPresets({'reflect', 'calm'}), 'calm,reflect');
      expect(encodeIntentionPresets({}), isNull);
      expect(parseIntentionPresets('less_scrolling, evil,calm'), {
        'less_scrolling',
        'calm',
      });
      expect(parseIntentionPresets(null), isEmpty);
    });
  });

  group('O4 notifications', () {
    testWidgets('denied permission links to system settings', (tester) async {
      final h = OnboardingHarness(
        notifications: FakeOnboardingNotifications(grant: false, exact: true),
      );
      await pumpStep(tester, h, OnboardingStep.notifications);
      await tapVisible(tester, find.text('Allow notifications'));
      expect(
        find.text(
          'Notifications are off. You can turn them on anytime in Settings.',
        ),
        findsOneWidget,
      );
      await tapVisible(tester, find.text('Open settings'));
      expect(h.notifications.settingsOpened, 1);
      // Pokracovat sa da aj bez povolenia.
      expect(isPrimaryEnabled(tester, 'Continue'), isTrue);
    });

    testWidgets('morning and private switches, no prayer reminders', (
      tester,
    ) async {
      final h = OnboardingHarness(
        notifications: FakeOnboardingNotifications(enabled: true),
      );
      await pumpStep(tester, h, OnboardingStep.notifications);
      expect(find.text('Notifications are on'), findsOneWidget);
      expect(find.text('Morning reminder at 07:30'), findsOneWidget);
      expect(find.textContaining('prayer'), findsNothing);
      expect(find.byKey(const ValueKey('notif:prayers')), findsNothing);
      // Ulozenie po Continue overuje onboarding_flow_test (bez routera).
      expect(find.byKey(const ValueKey('notif:morning')), findsOneWidget);
    });

    testWidgets('status is read again when the app resumes', (tester) async {
      final notifications = FakeOnboardingNotifications();
      final h = OnboardingHarness(notifications: notifications);
      await pumpStep(tester, h, OnboardingStep.notifications);
      expect(find.text('Allow notifications'), findsOneWidget);
      notifications.enabled = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Notifications are on'), findsOneWidget);
    });
  });

  group('O7 privacy', () {
    testWidgets('choices are disabled until age is confirmed', (tester) async {
      final h = OnboardingHarness();
      await pumpStep(tester, h, OnboardingStep.privacy);
      SegmentedButton<bool> choice(String id) => tester
          .widget<SegmentedButton<bool>>(find.byKey(ValueKey('privacy:$id')));
      expect(choice('analytics').onSelectionChanged, isNull);
      expect(choice('crash').onSelectionChanged, isNull);
      expect(choice('analytics').selected, isEmpty);
      expect(
        find.text('Sharing is available only if you are 16 or older.'),
        findsOneWidget,
      );

      await tapVisible(tester, find.byKey(const ValueKey('privacy:age')));
      await tapVisible(tester, find.byKey(const ValueKey('privacy:crash:yes')));
      expect(choice('crash').selected, {true});
      // Odskrtnutie veku zrusi volby.
      await tapVisible(tester, find.byKey(const ValueKey('privacy:age')));
      expect(choice('crash').selected, isEmpty);
    });

    testWidgets('what we collect opens a sheet', (tester) async {
      final h = OnboardingHarness();
      await pumpStep(tester, h, OnboardingStep.privacy);
      await tapVisible(tester, find.text('What we collect'));
      expect(
        find.textContaining('Never what you read or write'),
        findsOneWidget,
      );
    });
  });

  group('semantics', () {
    testWidgets('step titles are headers and controls have labels', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final h = OnboardingHarness();
      for (final step in [
        OnboardingStep.welcome,
        OnboardingStep.notifications,
        OnboardingStep.privacy,
      ]) {
        await pumpStep(tester, h, step);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      }
      await pumpStep(tester, h, OnboardingStep.intention);
      expect(
        tester.getSemantics(find.text('Why are you here?')),
        matchesSemantics(isHeader: true, label: 'Why are you here?'),
      );
      semantics.dispose();
    });
  });
}
