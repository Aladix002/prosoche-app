import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/data/blocker/blocked_apps_repository.dart';
import 'package:prosoche/data/blocker/blocker_gateway_provider.dart';
import 'package:prosoche/data/blocker/fake_blocked_apps_repository.dart';
import 'package:prosoche/data/blocker/fake_blocker_gateway.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/settings/about_screen.dart';
import 'package:prosoche/features/settings/blocking/blocking_screen.dart';
import 'package:prosoche/features/settings/settings_providers.dart';
import 'package:prosoche/features/settings/settings_routes.dart';
import 'package:prosoche/features/settings/sources_screen.dart';

import '../../fakes/fake_repositories.dart';
import '../../fakes/in_memory_settings_repository.dart';
import 'settings_test_app.dart';

void main() {
  group('SettingsScreen (A10.0)', () {
    testWidgets('lite: rows without gate, prayer or language', (tester) async {
      final settings = InMemorySettingsRepository();
      await pumpSettings(
        tester,
        overrides: settingsOverrides(
          fakes: FakeRepositories(settings: settings),
        ),
      );
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('The gate'), findsNothing);
      expect(find.text('Audio'), findsNothing);
      expect(find.textContaining('Backup'), findsNothing);
      for (final row in [
        'Notifications',
        'Daily set & display',
        'Privacy',
        'Sources & licenses',
        'About',
      ]) {
        expect(find.text(row), findsOneWidget, reason: row);
      }
      expect(find.textContaining('Prayer'), findsNothing);
      expect(find.textContaining('Hijri'), findsNothing);
      expect(find.textContaining('Language'), findsNothing);
    });

    testWidgets('full: gate row', (tester) async {
      final settings = InMemorySettingsRepository();
      await settings.set(SettingsKeys.blockerEnabled, true);
      await pumpSettings(
        tester,
        gate: true,
        overrides: [
          ...settingsOverrides(
            fakes: FakeRepositories(settings: settings),
            flags: FeatureFlags.all,
          ),
          blockerGatewayProvider.overrideWithValue(FakeBlockerGateway()),
          blockedAppsRepositoryProvider.overrideWithValue(
            FakeBlockedAppsRepository(),
          ),
        ],
      );
      expect(find.text('The gate'), findsOneWidget);
      expect(find.text('On'), findsOneWidget);
      await tester.tap(find.text('The gate'));
      await tester.pumpAndSettle();
      expect(find.byType(BlockingScreen), findsOneWidget);
    });

    testWidgets('rows open their screens', (tester) async {
      final router = await pumpSettings(
        tester,
        overrides: settingsOverrides(fakes: FakeRepositories()),
      );
      await tester.tap(find.text('Sources & licenses'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, SettingsPaths.sources);
      expect(find.byType(SourcesScreen), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();
      expect(find.byType(AboutScreen), findsOneWidget);
    });
  });

  group('AboutScreen (A10.10)', () {
    test('version label', () {
      expect(appVersionLabel('1.2.3', '42'), '1.2.3+42');
      expect(appVersionLabel('1.2.3', null), '1.2.3');
      expect(appVersionLabel('1.2.3', ''), '1.2.3');
    });

    testWidgets('version, content version and disclaimers', (tester) async {
      await pumpSettings(
        tester,
        location: SettingsPaths.about,
        overrides: settingsOverrides(
          fakes: FakeRepositories(),
          content: contentFixture(),
        ),
      );
      expect(find.text('1.2.3+42'), findsOneWidget);
      expect(find.text('fixture'), findsOneWidget);
      expect(find.textContaining('public domain'), findsOneWidget);
      expect(find.textContaining('not medical'), findsOneWidget);
      expect(find.textContaining('mosque'), findsNothing);
      // Bez nastavenych URL sa riadky neukazu.
      expect(find.byKey(const ValueKey('about:feedback')), findsNothing);
      expect(find.byKey(const ValueKey('about:policy')), findsNothing);
    });

    testWidgets('content version unavailable on error', (tester) async {
      await pumpSettings(
        tester,
        location: SettingsPaths.about,
        overrides: [
          ...settingsOverrides(fakes: FakeRepositories()),
          sourcesInfoProvider.overrideWith(
            (ref) async => throw StateError('x'),
          ),
        ],
      );
      expect(find.text('Unavailable'), findsOneWidget);
    });

    testWidgets('feedback and privacy links open the browser', (tester) async {
      final links = LinkLog();
      await pumpSettings(
        tester,
        location: SettingsPaths.about,
        overrides: settingsOverrides(
          fakes: FakeRepositories(),
          content: contentFixture(),
          links: links,
          appLinks: const AppLinks(
            privacyPolicy: 'https://example.invalid/privacy',
            feedback: 'https://example.invalid/feedback',
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('about:feedback')));
      await tester.tap(find.byKey(const ValueKey('about:policy')));
      await tester.pump();
      expect(links.opened.map((u) => u.path), ['/feedback', '/privacy']);
    });

    testWidgets('links to sources and open-source licenses', (tester) async {
      await pumpSettings(
        tester,
        location: SettingsPaths.about,
        overrides: settingsOverrides(
          fakes: FakeRepositories(),
          content: contentFixture(),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('about:oss')));
      await tester.pumpAndSettle();
      expect(find.byType(LicensePage), findsOneWidget);
    });

    test('invalid link URLs are ignored', () {
      const links = AppLinks(privacyPolicy: 'not a url', feedback: '');
      expect(links.privacyPolicyUri, isNull);
      expect(links.feedbackUri, isNull);
      expect(AppLinks.fromEnvironment.privacyPolicyUri, isNull);
    });
  });
}
