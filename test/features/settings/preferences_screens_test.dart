import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/settings/notification_settings_screen.dart';
import 'package:prosoche/features/settings/settings_providers.dart';
import 'package:prosoche/features/settings/settings_routes.dart';

import '../../fakes/fake_repositories.dart';
import '../../fakes/in_memory_settings_repository.dart';
import 'settings_test_app.dart';

void main() {
  late InMemorySettingsRepository settings;
  setUp(() => settings = InMemorySettingsRepository());

  group('DisplaySettingsScreen (A10.6)', () {
    testWidgets('theme, simple mode and cards per day', (tester) async {
      await pumpSettings(
        tester,
        location: SettingsPaths.display,
        overrides: settingsOverrides(
          fakes: FakeRepositories(settings: settings),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('theme:dark')));
      await tester.pumpAndSettle();
      expect(await settings.get(SettingsKeys.displayTheme), 'dark');

      await tester.tap(find.byKey(const ValueKey('simple_mode')));
      await tester.pumpAndSettle();
      expect(await settings.get(SettingsKeys.simpleMode), isTrue);

      final cards = find.byKey(const ValueKey('cards:8'));
      await tester.ensureVisible(cards);
      await tester.pumpAndSettle();
      await tester.tap(cards);
      await tester.pumpAndSettle();
      expect(await settings.get(SettingsKeys.feedCardsCount), 8);
    });

    test('theme mode mapping', () {
      expect(themeModeOf('dark'), ThemeMode.dark);
      expect(themeModeOf('light'), ThemeMode.light);
      expect(themeModeOf('system'), ThemeMode.system);
      expect(brightnessFor(ThemeMode.dark, Brightness.light), Brightness.dark);
      expect(brightnessFor(ThemeMode.light, Brightness.dark), Brightness.light);
      expect(brightnessFor(ThemeMode.system, Brightness.dark), Brightness.dark);
    });

    test('appThemeModeProvider follows display.theme', () async {
      final container = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWithValue(settings)],
      );
      addTearDown(container.dispose);
      final sub = container.listen(appThemeModeProvider, (_, _) {});
      addTearDown(sub.close);
      await settings.set(SettingsKeys.displayTheme, 'light');
      await Future<void>.delayed(Duration.zero);
      expect(container.read(appThemeModeProvider), ThemeMode.light);
    });
  });

  group('NotificationSettingsScreen (A10.4)', () {
    test('morning time parse and format', () {
      expect(parseMorningTime('06:05'), const TimeOfDay(hour: 6, minute: 5));
      expect(parseMorningTime('x'), const TimeOfDay(hour: 7, minute: 30));
      expect(formatMorningTime(const TimeOfDay(hour: 21, minute: 3)), '21:03');
    });

    testWidgets('toggles write notif keys', (tester) async {
      await pumpSettings(
        tester,
        location: SettingsPaths.notifications,
        overrides: settingsOverrides(
          fakes: FakeRepositories(settings: settings),
        ),
      );
      expect(find.byKey(const ValueKey('notif:blocked')), findsNothing);
      // F-01: ziadne presne alarmy, len nepresne pripomienky.
      expect(find.text('Allowed'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('notif:private')));
      await tester.tap(find.byKey(const ValueKey('notif:morning')));
      await tester.pumpAndSettle();
      expect(await settings.get(SettingsKeys.notifPrivateLockscreen), isFalse);
      expect(await settings.get(SettingsKeys.notifMorningEnabled), isFalse);
      expect(await settings.get(SettingsKeys.notifEveningEnabled), isFalse);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('notif:evening')),
        100,
      );
      await tester.tap(find.byKey(const ValueKey('notif:evening')));
      await tester.pumpAndSettle();
      expect(await settings.get(SettingsKeys.notifEveningEnabled), isTrue);
      expect(find.text('9:00 PM'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('notif:evening_time')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(await settings.get(SettingsKeys.notifEveningTime), '21:00');
    });

    testWidgets('morning time picker', (tester) async {
      await pumpSettings(
        tester,
        location: SettingsPaths.notifications,
        overrides: settingsOverrides(
          fakes: FakeRepositories(settings: settings),
        ),
      );
      expect(find.text('7:30 AM'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('notif:morning_time')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(await settings.get(SettingsKeys.notifMorningTime), '07:30');
    });

    testWidgets('blocked notifications', (tester) async {
      final access = FakeNotificationAccess(enabled: false);
      await pumpSettings(
        tester,
        location: SettingsPaths.notifications,
        overrides: settingsOverrides(
          fakes: FakeRepositories(settings: settings),
          notifications: access,
        ),
      );
      expect(find.byKey(const ValueKey('notif:blocked')), findsOneWidget);
      await tester.tap(find.text('Open settings'));
      expect(access.settingsOpened, 1);

      // Navrat do appky obnovi stav.
      access.enabled = true;
      [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ].forEach(tester.binding.handleAppLifecycleStateChanged);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('notif:blocked')), findsNothing);
    });
  });
}
