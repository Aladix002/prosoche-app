import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/core/router/app_router.dart';
import 'package:prosoche/domain/common/local_date.dart';
import 'package:prosoche/features/calendar/hijri_offset.dart';
import 'package:prosoche/features/gate/gate_screen.dart';
import 'package:prosoche/features/journey/journey_day_screen.dart';
import 'package:prosoche/features/journey/journey_routes.dart';
import 'package:prosoche/features/journey/journey_screen.dart';
import 'package:prosoche/features/journey/saved_screen.dart';
import 'package:prosoche/features/onboarding/onboarding_routes.dart';
import 'package:prosoche/features/onboarding/onboarding_screen.dart';
import 'package:prosoche/features/prayer/prayer_routes.dart';
import 'package:prosoche/features/quran/quran_routes.dart';
import 'package:prosoche/features/quran/quran_screen.dart';
import 'package:prosoche/features/quran/reader/quran_reader_screen.dart';
import 'package:prosoche/features/quran/search/quran_search_screen.dart';
import 'package:prosoche/features/settings/about_screen.dart';
import 'package:prosoche/features/settings/blocking/blocking_screen.dart';
import 'package:prosoche/features/settings/blocking/blocking_subscreens.dart'
    show BlockingPermissionsScreen;
import 'package:prosoche/features/settings/display_settings_screen.dart';
import 'package:prosoche/features/settings/language_settings_screen.dart';
import 'package:prosoche/features/settings/notification_settings_screen.dart';
import 'package:prosoche/features/settings/privacy_settings_screen.dart';
import 'package:prosoche/features/settings/settings_screen.dart';
import 'package:prosoche/features/settings/sources_screen.dart';
import 'package:prosoche/features/today/today_screen.dart';
import 'package:prosoche/features/words/words_routes.dart';

import '../../helpers/pump_app.dart';

Finder placeholder(String screen) =>
    find.byKey(ValueKey('placeholder:$screen'));

void main() {
  // Routa -> nazov obrazovky z docs/02 C2 (stuby featur).
  const stubs = {
    '/words': 'words',
    '/words/lemma/1043': 'lemma_detail',
    '/words/quiz': 'words_quiz',
    '/settings/audio': 'settings_audio',
    '/settings/backup': 'settings_backup',
  };

  for (final MapEntry(key: location, value: screen) in stubs.entries) {
    testWidgets('$location shows $screen stub', (tester) async {
      await tester.pumpProsoche(location: location);
      expect(placeholder(screen), findsOneWidget);
    });
  }

  // B-03 brana v nastaveniach (len FEATURE_GATE).
  for (final (location, screen) in [
    ('/settings/blocking', BlockingScreen),
    ('/settings/blocking/permissions', BlockingPermissionsScreen),
  ]) {
    testWidgets('$location shows $screen', (tester) async {
      await tester.pumpProsoche(location: location);
      expect(find.byType(screen), findsOneWidget);
    });
  }

  // F-06 Moja cesta (detail dna, ulozene karty).
  for (final (location, screen) in [
    ('/journey/day/2026-10-29', JourneyDayScreen),
    ('/journey/saved?type=ayah', SavedCardsScreen),
  ]) {
    testWidgets('$location shows $screen', (tester) async {
      await tester.pumpProsoche(location: location);
      expect(find.byType(screen), findsOneWidget);
    });
  }

  // F-05 obrazovky v nastaveniach (integracia I-01).
  for (final (location, screen) in [
    ('/settings/prayer', PrayerSettingsScreen),
    ('/settings/prayer/location', CitySearchScreen),
    ('/settings/prayer/location/search', CitySearchScreen),
    ('/settings/calendar', HijriOffsetScreen),
    // Obrazovky F-07.
    ('/settings', SettingsScreen),
    ('/settings/notifications', NotificationSettingsScreen),
    ('/settings/language', LanguageSettingsScreen),
    ('/settings/display', DisplaySettingsScreen),
    ('/settings/privacy', PrivacySettingsScreen),
    ('/settings/sources', SourcesScreen),
    ('/settings/about', AboutScreen),
  ]) {
    testWidgets('$location shows $screen', (tester) async {
      await tester.pumpProsoche(location: location);
      expect(find.byType(screen), findsOneWidget);
    });
  }

  testWidgets('quran reader is fullscreen, search keeps the nav bar', (
    tester,
  ) async {
    await tester.pumpProsoche(location: QuranRoutes.read(18, ayahId: 18001));
    expect(find.byType(QuranReaderScreen), findsOneWidget);
    expect(navBar, findsNothing);

    await tester.pumpProsoche(location: QuranRoutes.searchFor('mercy'));
    expect(find.byType(QuranSearchScreen), findsOneWidget);
    expect(navBar, findsOneWidget);
  });

  group('invalid parameters redirect (docs/02 C2)', () {
    for (final (location, screen) in [
      ('/quran/read/115', QuranScreen),
      ('/quran/read/x', QuranScreen),
      ('/journey/day/2026-02-30', JourneyScreen),
      ('/journey/day/2026-10-30', JourneyScreen),
    ]) {
      testWidgets(location, (tester) async {
        await tester.pumpProsoche(location: location);
        expect(find.byType(screen), findsOneWidget);
      });
    }

    testWidgets('lemma id', (tester) async {
      await tester.pumpProsoche(location: '/words/lemma/abc');
      expect(placeholder('words'), findsOneWidget);
    });

    testWidgets('onboarding step', (tester) async {
      final router = await tester.pumpProsoche(location: '/onboarding/evil');
      expect(router.state.uri.path, OnboardingRoutes.step('language'));
      await tester.pumpProsoche(location: OnboardingRoutes.root);
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });
  });

  group('disabled features', () {
    const lite = FeatureFlags.none;

    testWidgets('gate redirects to Today', (tester) async {
      await tester.pumpProsoche(
        location: 'prosoche://gate?app=com.instagram.android',
        flags: lite,
      );
      expect(find.byType(GateScreen), findsNothing);
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets('blocking settings redirect to Today', (tester) async {
      await tester.pumpProsoche(location: '/settings/blocking', flags: lite);
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets('words redirect to Journey', (tester) async {
      await tester.pumpProsoche(location: WordsRoutes.quiz, flags: lite);
      expect(find.byType(JourneyScreen), findsOneWidget);
    });

    testWidgets('other settings stay available', (tester) async {
      await tester.pumpProsoche(location: '/settings/about', flags: lite);
      expect(find.byType(AboutScreen), findsOneWidget);
    });
  });

  test('route helpers', () {
    expect(
      QuranRoutes.read(2, ayahId: 2255, mode: 'khatm'),
      '/quran/read/2?ayah=2255&mode=khatm',
    );
    expect(QuranRoutes.read(1), '/quran/read/1');
    expect(QuranRoutes.parseSurah('0'), isNull);
    expect(JourneyRoutes.day(LocalDate(2026, 1, 5)), '/journey/day/2026-01-05');
    expect(WordsRoutes.lemma(5), '/words/lemma/5');
  });

  test('redirect keeps unrelated paths', () {
    expect(redirect(Uri.parse('/today'), FeatureFlags.all), isNull);
    expect(redirect(Uri.parse('/gatekeeper'), FeatureFlags.none), isNull);
  });

  test('redirect hides /dev without devTools', () {
    final gallery = Uri.parse('/dev/gallery');
    expect(redirect(gallery, FeatureFlags.all), '/today');
    expect(redirect(gallery, FeatureFlags.all, devTools: true), isNull);
    expect(redirect(Uri.parse('/devx'), FeatureFlags.all), isNull);
  });
}
