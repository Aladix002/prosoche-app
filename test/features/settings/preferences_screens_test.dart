import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/flags/feature_flags.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/settings/notification_settings_screen.dart';
import 'package:sakina/features/settings/settings_providers.dart';
import 'package:sakina/features/settings/settings_routes.dart';
import 'package:sakina/ui/ui.dart';

import '../../fakes/fake_repositories.dart';
import '../../fakes/in_memory_settings_repository.dart';
import 'settings_test_app.dart';

/// Dva zdroje prekladu pre `en` (vyber v A10.5).
class _TwoTranslations extends FakeQuranRepository {
  static const second = TranslationSource(
    id: 'fake-en-2',
    lang: 'en',
    name: 'Second translation',
    version: '2',
    attribution: '[PLACEHOLDER attribution 2]',
    license: 'test-only',
  );

  @override
  Future<List<TranslationSource>> translationSources(String lang) async =>
      lang == 'en' ? [...FakeQuranRepository.sources, second] : const [];
}

void main() {
  late InMemorySettingsRepository settings;
  setUp(() => settings = InMemorySettingsRepository());

  group('LanguageSettingsScreen (A10.5)', () {
    testWidgets('picking a language writes ui.locale, device resets it', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        location: SettingsPaths.language,
        overrides: settingsOverrides(
          fakes: FakeRepositories(settings: settings),
        ),
      );
      // BN je skryta (docs/02 O1).
      expect(find.byKey(const ValueKey('language:bn')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('language:tr')));
      await tester.pumpAndSettle();
      expect(await settings.get(SettingsKeys.uiLocale), 'tr');
      await tester.tap(find.byKey(const ValueKey('language:device')));
      await tester.pumpAndSettle();
      expect(await settings.get(SettingsKeys.uiLocale), isNull);
    });

    testWidgets('translation choice and transliteration', (tester) async {
      final quran = _TwoTranslations();
      await pumpSettings(
        tester,
        location: SettingsPaths.language,
        overrides: settingsOverrides(
          fakes: FakeRepositories(settings: settings, quran: quran),
        ),
      );
      expect(find.text('Version 2 · License: test-only'), findsOneWidget);
      expect(find.textContaining('not the Qur'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('translation:fake-en-2')));
      await tester.pumpAndSettle();
      expect(quran.selected['en']?.id, 'fake-en-2');

      await tester.tap(find.byKey(const ValueKey('translit')));
      await tester.pumpAndSettle();
      expect(await settings.get(SettingsKeys.displayTranslit), isTrue);
    });

    testWidgets('arabic has no translation, empty language shows a note', (
      tester,
    ) async {
      await settings.set(SettingsKeys.uiLocale, 'ar');
      await pumpSettings(
        tester,
        location: SettingsPaths.language,
        overrides: settingsOverrides(
          fakes: FakeRepositories(settings: settings),
        ),
      );
      expect(find.textContaining('without a translation'), findsOneWidget);

      await settings.set(SettingsKeys.uiLocale, 'tr');
      await tester.pumpAndSettle();
      expect(find.textContaining('No translation'), findsOneWidget);
    });

    testWidgets('translation load error can be retried', (tester) async {
      await pumpSettings(
        tester,
        location: SettingsPaths.language,
        overrides: settingsOverrides(
          fakes: FakeRepositories(settings: settings, quran: _FailingQuran()),
        ),
      );
      expect(find.byType(SkErrorState), findsOneWidget);
    });
  });

  group('DisplaySettingsScreen (A10.6)', () {
    testWidgets('theme, arabic size and simple mode', (tester) async {
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

      await tester.tap(find.text('XL'));
      await tester.pumpAndSettle();
      expect(
        await settings.get(SettingsKeys.displayArabicScale),
        SkArabicScale.xl.factor,
      );
      // Nahlad z content.db (fake: placeholder 1:1).
      expect(find.byType(SkArabicText), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('simple_mode')));
      await tester.pumpAndSettle();
      expect(await settings.get(SettingsKeys.simpleMode), isTrue);
      // Bez FEATURE_WORDS sa pocet kariet nenastavuje.
      expect(find.byKey(const ValueKey('cards:8')), findsNothing);
    });

    testWidgets('cards per day only with words', (tester) async {
      await pumpSettings(
        tester,
        location: SettingsPaths.display,
        overrides: settingsOverrides(
          fakes: FakeRepositories(settings: settings),
          flags: const FeatureFlags(words: true),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('cards:8')));
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
      expect(find.text('Allowed'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('notif:isha')));
      await tester.tap(find.byKey(const ValueKey('notif:private')));
      await tester.tap(find.byKey(const ValueKey('notif:morning')));
      await tester.pumpAndSettle();
      expect(await settings.get(SettingsKeys.notifPrayer('isha')), isFalse);
      expect(await settings.get(SettingsKeys.notifPrivateLockscreen), isFalse);
      expect(await settings.get(SettingsKeys.notifMorningEnabled), isFalse);
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

    testWidgets('blocked notifications and exact alarms', (tester) async {
      final access = FakeNotificationAccess(enabled: false, exact: false);
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
      expect(find.text('Not allowed'), findsOneWidget);
      await tester.tap(find.text('Allow'));
      expect(access.exactRequests, 1);

      // Navrat do appky obnovi stav.
      access
        ..enabled = true
        ..exact = true;
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
      expect(find.text('Allowed'), findsOneWidget);
    });
  });
}

/// Zlyhanie nacitania prekladov (chybovy stav A10.5).
class _FailingQuran extends FakeQuranRepository {
  @override
  Future<List<TranslationSource>> translationSources(String lang) async =>
      throw StateError('no db');
}
