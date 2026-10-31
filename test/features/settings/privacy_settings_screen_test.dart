import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/data/blocker/blocker_gateway.dart';
import 'package:prosoche/data/blocker/blocker_gateway_provider.dart';
import 'package:prosoche/data/blocker/fake_blocker_gateway.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/onboarding/onboarding_guard.dart';
import 'package:prosoche/features/settings/privacy_settings_screen.dart';
import 'package:prosoche/features/settings/settings_providers.dart';
import 'package:prosoche/features/settings/settings_routes.dart';

import '../../fakes/fake_repositories.dart';
import '../../fakes/in_memory_settings_repository.dart';
import 'settings_test_app.dart';

void main() {
  group('PrivacySettingsScreen (A10.9)', () {
    testWidgets('sharing needs age 16+, unchecking turns both off', (
      tester,
    ) async {
      // Onboarding O7 zapise obe volby (bez suhlasu false).
      final settings = InMemorySettingsRepository();
      await settings.set(SettingsKeys.crashReports, false);
      await pumpSettings(
        tester,
        location: SettingsPaths.privacy,
        overrides: settingsOverrides(
          fakes: FakeRepositories(settings: settings),
        ),
      );
      SwitchListTile tile(String id) =>
          tester.widget(find.byKey(ValueKey('privacy:$id')));
      expect(tile('analytics').onChanged, isNull);
      expect(tile('crash').onChanged, isNull);

      await tester.tap(find.byKey(const ValueKey('privacy:age')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('privacy:analytics')));
      await tester.tap(find.byKey(const ValueKey('privacy:crash')));
      await tester.pumpAndSettle();
      expect(await settings.get(SettingsKeys.ageConfirmed16), isTrue);
      expect(await settings.get(SettingsKeys.analyticsOptIn), isTrue);
      expect(await settings.get(SettingsKeys.crashReports), isTrue);

      await tester.tap(find.byKey(const ValueKey('privacy:age')));
      await tester.pumpAndSettle();
      expect(await settings.get(SettingsKeys.analyticsOptIn), isFalse);
      expect(await settings.get(SettingsKeys.crashReports), isFalse);
    });

    testWidgets('what we collect and privacy policy', (tester) async {
      final links = LinkLog();
      await pumpSettings(
        tester,
        location: SettingsPaths.privacy,
        overrides: settingsOverrides(
          fakes: FakeRepositories(),
          links: links,
          appLinks: const AppLinks(privacyPolicy: 'https://example.invalid/p'),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('privacy:policy')));
      expect(links.opened.single.path, '/p');
      await tester.tap(find.byKey(const ValueKey('privacy:collect')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Never what you read'), findsWidgets);
    });

    testWidgets('delete needs typing DELETE, then runs deleteAllData', (
      tester,
    ) async {
      final actions = <_RecordingActions>[];
      await pumpSettings(
        tester,
        location: SettingsPaths.privacy,
        overrides: [
          ...settingsOverrides(fakes: FakeRepositories()),
          settingsActionsProvider.overrideWith(
            (ref) => _RecordingActions(ref)..also(actions.add),
          ),
        ],
      );
      await tester.tap(find.byKey(const ValueKey('privacy:delete')));
      await tester.pumpAndSettle();
      expect(find.byType(DeleteAllDataDialog), findsOneWidget);
      TextButton go() => tester.widget(find.byKey(const ValueKey('delete:go')));
      expect(go().onPressed, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('delete:confirm')),
        'delete',
      );
      await tester.pump();
      expect(go().onPressed, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('delete:confirm')),
        deleteConfirmWord,
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('delete:go')));
      await tester.pumpAndSettle();
      expect(find.byType(DeleteAllDataDialog), findsNothing);
      expect(actions.single.deleted, 1);
    });

    testWidgets('cancel keeps data', (tester) async {
      final actions = <_RecordingActions>[];
      await pumpSettings(
        tester,
        location: SettingsPaths.privacy,
        overrides: [
          ...settingsOverrides(fakes: FakeRepositories()),
          settingsActionsProvider.overrideWith(
            (ref) => _RecordingActions(ref)..also(actions.add),
          ),
        ],
      );
      await tester.tap(find.byKey(const ValueKey('privacy:delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(DeleteAllDataDialog), findsNothing);
      expect(actions.every((a) => a.deleted == 0), isTrue);
    });
  });

  group('SettingsActions.deleteAllData', () {
    test('turns off the gate, recreates the onboarding guard', () async {
      final user = UserDb.memory();
      addTearDown(user.close);
      final blocker = FakeBlockerGateway()
        ..enabled = true
        ..targets = const [
          BlockTarget(ref: 'a', cardsRequired: 3, unlockMinutes: 10),
        ];
      final container = ProviderContainer(
        overrides: [
          userDbProvider.overrideWithValue(user),
          featureFlagsProvider.overrideWithValue(FeatureFlags.all),
          blockerGatewayProvider.overrideWithValue(blocker),
          afterDataDeletedProvider.overrideWithValue(
            () async => throw StateError('hook'),
          ),
        ],
      );
      addTearDown(container.dispose);
      final settings = container.read(settingsRepositoryProvider);
      await settings.set(SettingsKeys.onboardingCompleted, true);
      await settings.set(SettingsKeys.simpleMode, true);
      final guard = container.read(onboardingGuardProvider);

      await container.read(settingsActionsProvider).deleteAllData();

      expect(blocker.enabled, isFalse);
      expect(blocker.targets, isEmpty);
      expect(await settings.get(SettingsKeys.onboardingCompleted), isFalse);
      expect(await settings.get(SettingsKeys.simpleMode), isFalse);
      expect(container.read(onboardingGuardProvider), isNot(same(guard)));
    });
  });
}

class _RecordingActions extends SettingsActions {
  _RecordingActions(super.ref);

  int deleted = 0;

  void also(void Function(_RecordingActions) f) => f(this);

  @override
  Future<void> deleteAllData() async => deleted++;
}
