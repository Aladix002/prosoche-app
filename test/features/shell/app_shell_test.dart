import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/app.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/core/router/app_router.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/journey/journey_screen.dart';
import 'package:sakina/features/quran/quran_screen.dart';
import 'package:sakina/features/shell/app_locale.dart';
import 'package:sakina/features/shell/app_shell.dart';
import 'package:sakina/features/shell/settings_button.dart';
import 'package:sakina/features/today/today_screen.dart';
import 'package:sakina/ui/i18n/i18n.dart';

import '../../fakes/fake_repositories.dart';
import '../../fakes/in_memory_settings_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  group('back (docs/02 C5)', () {
    testWidgets('tab root other than Today switches to Today', (tester) async {
      await tester.pumpSakina();
      for (final (label, screen) in [
        ('Quran', QuranScreen),
        ('Journey', JourneyScreen),
      ]) {
        await tester.tap(
          find.descendant(of: navBar, matching: find.text(label)),
        );
        await tester.pumpAndSettle();
        expect(find.byType(screen), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(TodayScreen), findsOneWidget);
      }
    });

    testWidgets('Today lets the system close the app', (tester) async {
      await tester.pumpSakina();
      final scope = tester.widget<PopScope<Object?>>(
        find
            .descendant(
              of: find.byType(AppShell),
              matching: find.byWidgetPredicate((w) => w is PopScope),
            )
            .first,
      );
      expect(scope.canPop, isTrue);
    });
  });

  testWidgets('settings button pushes Settings over the shell', (tester) async {
    // Today a Journey (F-02, F-06) ho vlozia do app baru; tu samostatne.
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: ShellSettingsButton()),
            ),
            GoRoute(
              path: '/settings',
              builder: (_, _) => const Scaffold(body: Text('settings')),
            ),
          ],
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
      ),
    );
    expect(find.byTooltip('Settings'), findsOneWidget);
    await tester.tap(find.byType(ShellSettingsButton));
    await tester.pumpAndSettle();
    expect(find.text('settings'), findsOneWidget);
  });

  group('app locale from ui.locale', () {
    test('resolves stored and device languages', () {
      expect(
        resolveAppLocales([const Locale('de')], const []),
        SakinaLocales.en,
      );
      expect(
        resolveAppLocales([
          const Locale('de'),
          const Locale('ur', 'PK'),
        ], const []),
        SakinaLocales.ur,
      );
      expect(resolveAppLocales(null, const []), SakinaLocales.en);
    });

    Future<void> pumpWith(WidgetTester tester, String? stored) async {
      final settings = InMemorySettingsRepository();
      if (stored != null) await settings.set(SettingsKeys.uiLocale, stored);
      final router = buildAppRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            // Today je skutocna obrazovka (F-02): repozitare su fakes.
            ...FakeRepositories(settings: settings)
                .overrides(now: DateTime(2026, 10, 29, 9)),
            appRouterProvider.overrideWithValue(router),
          ],
          child: const SakinaApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('stored Arabic makes the app RTL', (tester) async {
      await pumpWith(tester, 'ar');
      final context = tester.element(find.byType(TodayScreen));
      expect(Localizations.localeOf(context), SakinaLocales.ar);
      expect(Directionality.of(context), TextDirection.rtl);
    });

    testWidgets('unsupported system language falls back to English', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = [const Locale('de')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await pumpWith(tester, null);
      final context = tester.element(find.byType(TodayScreen));
      expect(Localizations.localeOf(context), SakinaLocales.en);
    });
  });
}
