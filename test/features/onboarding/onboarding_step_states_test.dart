import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/data/repositories/prayer/city_repository.dart';
import 'package:sakina/data/repositories/quran/quran_repository.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/onboarding/onboarding_platform.dart';
import 'package:sakina/features/onboarding/onboarding_steps.dart';
import 'package:sakina/features/onboarding/steps/niyyah_step.dart';
import 'package:sakina/ui/i18n/i18n.dart';
import 'package:sakina/ui/ui.dart';

import '../../fakes/fake_repositories.dart';
import '../../fakes/in_memory_settings_repository.dart';
import 'onboarding_test_helpers.dart';

class _BrokenQuran extends FakeQuranRepository {
  @override
  Future<List<TranslationSource>> translationSources(String lang) =>
      Future.error(StateError('content.db'));
}

class _SlowQuran extends FakeQuranRepository {
  @override
  Future<List<TranslationSource>> translationSources(String lang) =>
      Future.delayed(const Duration(seconds: 1), () => const []);
}

class _BrokenCities extends FakeCityRepository {
  @override
  Future<List<City>> search(String prefix, {int limit = 30}) =>
      Future.error(StateError('content.db'));
}

/// Krok onboardingu bez routera vo svetlej teme Sakina.
Future<void> pumpStep(
  WidgetTester tester,
  OnboardingHarness h,
  OnboardingStep step, {
  Locale locale = SakinaLocales.en,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: SakinaTheme.light(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: h.step(step),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('O1 language', () {
    testWidgets('content.db that cannot be opened is a fatal state', (
      tester,
    ) async {
      final h = OnboardingHarness(
        repos: FakeRepositories(quran: _BrokenQuran()),
      );
      await pumpStep(tester, h, OnboardingStep.language);
      expect(find.byType(SkErrorState), findsOneWidget);
      expect(find.text('Please reinstall the app.'), findsOneWidget);
    });

    testWidgets('Continue waits for translations to load', (tester) async {
      final h = OnboardingHarness(repos: FakeRepositories(quran: _SlowQuran()));
      await pumpStep(tester, h, OnboardingStep.language);
      expect(find.byType(SkSkeletonBox), findsOneWidget);
      expect(isPrimaryEnabled(tester, 'Continue'), isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(isPrimaryEnabled(tester, 'Continue'), isTrue);
    });
  });

  group('O2 niyyah', () {
    testWidgets('restores stored presets and text', (tester) async {
      final settings = InMemorySettingsRepository();
      await settings.set(SettingsKeys.niyyahPreset, 'prayer,khatm');
      await settings.set(SettingsKeys.niyyahText, 'Mine');
      final h = OnboardingHarness(repos: FakeRepositories(settings: settings));
      await pumpStep(tester, h, OnboardingStep.niyyah);
      FilterChip chip(String id) =>
          tester.widget<FilterChip>(find.byKey(ValueKey('niyyah:$id')));
      expect(chip('khatm').selected, isTrue);
      expect(chip('prayer').selected, isTrue);
      expect(chip('arabic').selected, isFalse);
      expect(chip('own').selected, isTrue);
      expect(find.text('Mine'), findsOneWidget);
    });

    test('preset encoding keeps the canonical order', () {
      expect(encodeNiyyahPresets({'prayer', 'khatm'}), 'khatm,prayer');
      expect(encodeNiyyahPresets({}), isNull);
      expect(parseNiyyahPresets('less_social, evil,arabic'), {
        'less_social',
        'arabic',
      });
      expect(parseNiyyahPresets(null), isEmpty);
    });
  });

  group('O3 location', () {
    testWidgets('denied permission offers the city search first', (
      tester,
    ) async {
      final h = OnboardingHarness(
        location: FakeDeviceLocation(const LocationDenied()),
      );
      await pumpStep(tester, h, OnboardingStep.location);
      await tapVisible(tester, find.text('Use my location'));
      expect(
        find.text('Location is off. Choose your city instead.'),
        findsOneWidget,
      );
      expect(isPrimaryEnabled(tester, 'Continue'), isFalse);

      await tapVisible(tester, find.text('Choose a city instead'));
      await tester.enterText(find.byKey(const ValueKey('city:search')), 'xyz');
      await tester.pumpAndSettle();
      expect(
        find.text('No city found. Try a nearby larger city.'),
        findsOneWidget,
      );
      await tester.enterText(find.byKey(const ValueKey('city:search')), 'Sar');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('city:2')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('location:city')), findsOneWidget);
      expect(find.text('Sarajevo'), findsOneWidget);
      // Sarajevo (43.85) nie je vysoka sirka.
      expect(find.textContaining('Middle of the night'), findsNothing);
      expect(isPrimaryEnabled(tester, 'Continue'), isTrue);
      expect((await h.repos.prayer.config())!.location.country, 'BA');
    });

    testWidgets('GPS timeout shows a snackbar and the manual choice', (
      tester,
    ) async {
      final h = OnboardingHarness(
        location: FakeDeviceLocation(const LocationFailed()),
      );
      await pumpStep(tester, h, OnboardingStep.location);
      await tapVisible(tester, find.text('Use my location'));
      expect(
        find.text("Couldn't get your location. Choose your city instead."),
        findsNWidgets(2),
      );
    });

    testWidgets('no city near the location', (tester) async {
      final h = OnboardingHarness(
        repos: FakeRepositories(cities: FakeCityRepository(const [])),
      );
      await pumpStep(tester, h, OnboardingStep.location);
      await tapVisible(tester, find.text('Use my location'));
      expect(
        find.text('No city found nearby. Choose your city instead.'),
        findsOneWidget,
      );
    });

    testWidgets('city search error', (tester) async {
      final h = OnboardingHarness(
        repos: FakeRepositories(cities: _BrokenCities()),
      );
      await pumpStep(tester, h, OnboardingStep.location);
      await tapVisible(tester, find.text('Choose a city instead'));
      await tester.enterText(find.byKey(const ValueKey('city:search')), 'B');
      await tester.pumpAndSettle();
      expect(find.text('Cities could not be loaded.'), findsOneWidget);
    });

    testWidgets('method and asr changes are saved and recalculated', (
      tester,
    ) async {
      final h = OnboardingHarness(
        repos: FakeRepositories(
          prayer: FakePrayerRepository(location: bratislava),
        ),
      );
      await pumpStep(tester, h, OnboardingStep.location);
      expect(find.text('Muslim World League'), findsOneWidget);
      await tapVisible(
        tester,
        find.text("Standard (Shafi'i, Maliki, Hanbali)"),
      );
      await tester.tap(find.text('Hanafi').last);
      await tester.pumpAndSettle();
      final config = (await h.repos.prayer.config())!;
      expect(config.settings.asr.key, 'hanafi');
      expect(h.repos.prayer.changes, greaterThan(0));
      // Nahlad dnesnych casov (5 modlitieb).
      expect(find.textContaining('Dhuhr '), findsOneWidget);
      expect(find.textContaining('Maghrib '), findsOneWidget);
    });
  });

  group('O4 notifications', () {
    testWidgets('denied permission links to system settings', (tester) async {
      final h = OnboardingHarness(
        notifications: FakeOnboardingNotifications(grant: false, exact: true),
        repos: FakeRepositories(
          prayer: FakePrayerRepository(location: bratislava),
        ),
      );
      await pumpStep(tester, h, OnboardingStep.notifications);
      expect(find.text('On-time prayer reminders'), findsNothing);
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

    testWidgets('without location the prayer switch is disabled', (
      tester,
    ) async {
      final h = OnboardingHarness(
        notifications: FakeOnboardingNotifications(enabled: true, exact: true),
      );
      await pumpStep(tester, h, OnboardingStep.notifications);
      expect(find.text('Set your location first'), findsOneWidget);
      final prayers = tester.widget<SwitchListTile>(
        find.byKey(const ValueKey('notif:prayers')),
      );
      expect(prayers.onChanged, isNull);
      expect(prayers.value, isFalse);
      expect(find.text('Notifications are on'), findsOneWidget);
      expect(find.text('Morning reminder at 07:30'), findsOneWidget);
    });

    testWidgets('status is read again when the app resumes', (tester) async {
      final notifications = FakeOnboardingNotifications(enabled: true);
      final h = OnboardingHarness(notifications: notifications);
      await pumpStep(tester, h, OnboardingStep.notifications);
      expect(find.text('On-time prayer reminders'), findsOneWidget);
      notifications.exact = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('On-time prayer reminders'), findsNothing);
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
        find.textContaining('Never what you read or pray'),
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
        OnboardingStep.language,
        OnboardingStep.location,
        OnboardingStep.privacy,
      ]) {
        await pumpStep(tester, h, step);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      }
      await pumpStep(tester, h, OnboardingStep.niyyah);
      expect(
        tester.getSemantics(find.text('Why are you here?')),
        matchesSemantics(isHeader: true, label: 'Why are you here?'),
      );
      semantics.dispose();
    });
  });
}
