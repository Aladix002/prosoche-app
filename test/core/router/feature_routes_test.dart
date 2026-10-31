import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/core/router/app_router.dart';
import 'package:prosoche/domain/common/local_date.dart';
import 'package:prosoche/features/gate/gate_screen.dart';
import 'package:prosoche/features/journey/journey_day_screen.dart';
import 'package:prosoche/features/journey/journey_routes.dart';
import 'package:prosoche/features/journey/journey_screen.dart';
import 'package:prosoche/features/journey/saved_screen.dart';
import 'package:prosoche/features/onboarding/onboarding_routes.dart';
import 'package:prosoche/features/onboarding/onboarding_screen.dart';
import 'package:prosoche/features/settings/about_screen.dart';
import 'package:prosoche/features/settings/blocking/blocking_screen.dart';
import 'package:prosoche/features/settings/blocking/blocking_subscreens.dart'
    show BlockingPermissionsScreen;
import 'package:prosoche/features/settings/display_settings_screen.dart';
import 'package:prosoche/features/settings/notification_settings_screen.dart';
import 'package:prosoche/features/settings/privacy_settings_screen.dart';
import 'package:prosoche/features/settings/settings_screen.dart';
import 'package:prosoche/features/settings/sources_screen.dart';
import 'package:prosoche/features/today/today_screen.dart';

import '../../helpers/pump_app.dart';

Finder placeholder(String screen) =>
    find.byKey(ValueKey('placeholder:$screen'));

void main() {
  // Routa -> nazov obrazovky z docs/02 C2 (stuby featur).
  const stubs = {'/settings/backup': 'settings_backup'};

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
    ('/journey/saved?type=quote', SavedCardsScreen),
  ]) {
    testWidgets('$location shows $screen', (tester) async {
      await tester.pumpProsoche(location: location);
      expect(find.byType(screen), findsOneWidget);
    });
  }

  // Obrazovky F-07.
  for (final (location, screen) in [
    ('/settings', SettingsScreen),
    ('/settings/notifications', NotificationSettingsScreen),
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

  group('invalid parameters redirect (docs/02 C2)', () {
    for (final (location, screen) in [
      ('/journey/day/2026-02-30', JourneyScreen),
      ('/journey/day/2026-10-30', JourneyScreen),
    ]) {
      testWidgets(location, (tester) async {
        await tester.pumpProsoche(location: location);
        expect(find.byType(screen), findsOneWidget);
      });
    }

    testWidgets('onboarding step', (tester) async {
      final router = await tester.pumpProsoche(location: '/onboarding/evil');
      expect(router.state.uri.path, OnboardingRoutes.step('welcome'));
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

    testWidgets('other settings stay available', (tester) async {
      await tester.pumpProsoche(location: '/settings/about', flags: lite);
      expect(find.byType(AboutScreen), findsOneWidget);
    });
  });

  test('route helpers', () {
    expect(JourneyRoutes.day(LocalDate(2026, 1, 5)), '/journey/day/2026-01-05');
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
