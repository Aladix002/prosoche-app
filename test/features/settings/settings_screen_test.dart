import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sakina/core/flags/feature_flags.dart';
import 'package:sakina/data/blocker/blocked_apps_repository.dart';
import 'package:sakina/data/blocker/blocker_gateway_provider.dart';
import 'package:sakina/data/blocker/fake_blocked_apps_repository.dart';
import 'package:sakina/data/blocker/fake_blocker_gateway.dart';
import 'package:sakina/data/content/hadith_extra_pack_providers.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/settings/about_screen.dart';
import 'package:sakina/features/settings/blocking/blocking_screen.dart';
import 'package:sakina/features/settings/settings_providers.dart';
import 'package:sakina/features/settings/settings_routes.dart';
import 'package:sakina/features/settings/sources_screen.dart';

import '../../fakes/fake_repositories.dart';
import '../../fakes/in_memory_settings_repository.dart';
import 'settings_test_app.dart';

void main() {
  group('SettingsScreen (A10.0)', () {
    testWidgets('lite: rows with current values, no gate or audio', (
      tester,
    ) async {
      final settings = InMemorySettingsRepository();
      await settings.set(SettingsKeys.hijriOffset, 1);
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
        'Prayer times',
        'Notifications',
        'Language & translation',
        'Daily set & display',
        'Hijri calendar',
        'Privacy',
        'Sources & licenses',
        'About',
      ]) {
        expect(find.text(row), findsOneWidget, reason: row);
      }
      expect(find.text('English'), findsOneWidget);
      expect(find.text('+1 day'), findsOneWidget);
    });

    testWidgets('full: gate and audio rows', (tester) async {
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
      expect(find.text('Audio'), findsOneWidget);
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
      expect(find.textContaining('local mosque'), findsOneWidget);
      expect(find.textContaining('not the Qur'), findsOneWidget);
      expect(find.textContaining('fatwas'), findsOneWidget);
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

    testWidgets('downloaded hadith explanations can be deleted', (
      tester,
    ) async {
      final service = _MockPackService();
      when(service.delete)
          .thenAnswer((_) async => const HadithExtraNotDownloaded());
      await pumpSettings(
        tester,
        location: SettingsPaths.about,
        overrides: [
          ...settingsOverrides(
            fakes: FakeRepositories(),
            content: contentFixture(),
          ),
          hadithExtraPackStatusProvider.overrideWith(
            (ref) => Stream.value(
              const HadithExtraReady(sizeBytes: 2 * 1024 * 1024),
            ),
          ),
          hadithExtraPackServiceProvider.overrideWithValue(service),
        ],
      );
      expect(find.text('2.0 MB on this phone'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('about:hadith_extra')),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      verify(service.delete).called(1);
    });

    test('invalid link URLs are ignored', () {
      const links = AppLinks(privacyPolicy: 'not a url', feedback: '');
      expect(links.privacyPolicyUri, isNull);
      expect(links.feedbackUri, isNull);
      expect(AppLinks.fromEnvironment.privacyPolicyUri, isNull);
    });
  });
}

class _MockPackService extends Mock implements HadithExtraPackService;
