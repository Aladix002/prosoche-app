import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/app.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/core/router/app_router.dart';
import 'package:prosoche/domain/settings/settings_keys.dart';
import 'package:prosoche/features/settings/display_settings_screen.dart';
import 'package:prosoche/ui/foundation/sk_text_scaling.dart';
import 'package:prosoche/ui/foundation/sk_ui_strings.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/theme/prosoche_colors.dart';
import 'package:prosoche/ui/tokens/sk_fonts.dart';

import 'fakes/fake_repositories.dart';
import 'helpers/pump_app.dart';

void main() {
  group('prosocheAppTheme', () {
    test('uses Prosoche colors and high contrast variants', () {
      ProsocheColors colors(ThemeData t) => t.extension<ProsocheColors>()!;
      for (final (b, hc, expected) in [
        (Brightness.light, false, ProsocheColors.light),
        (Brightness.dark, false, ProsocheColors.dark),
        (Brightness.light, true, ProsocheColors.lightHighContrast),
        (Brightness.dark, true, ProsocheColors.darkHighContrast),
      ]) {
        final theme = prosocheAppTheme(
          brightness: b,
          highContrast: hc,
          locale: ProsocheLocales.en,
        );
        expect(theme.brightness, b);
        expect(colors(theme), expected);
      }
    });

    test('text theme follows the font of the language', () {
      for (final locale in ProsocheLocales.all) {
        final theme = prosocheAppTheme(
          brightness: Brightness.light,
          locale: locale,
        );
        final spec = LocaleFonts.forLocale(locale);
        expect(theme.textTheme.bodyLarge!.fontFamily, spec.family);
        expect(theme.textTheme.bodyLarge!.fontFamilyFallback, spec.fallback);
        // Komponentove temy (tlacidla) maju rovnaku rodinu.
        final button = theme.filledButtonTheme.style!.textStyle!.resolve({});
        expect(button!.fontFamily, spec.family);
      }
    });

    test('EN uses Inter with the scale line height', () {
      final en = prosocheAppTheme(
        brightness: Brightness.light,
        locale: ProsocheLocales.en,
      ).textTheme.bodyLarge!;
      expect(en.fontFamily, SkFonts.inter);
      expect(en.height, LocaleFonts.latin.scaleHeight(24 / 16));
    });
  });

  test('EN SkUiStrings from ARB match the component fallback', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final s = skUiStringsOf(l10n);
    const f = SkUiStrings.fallbackEn;
    List<String> all(SkUiStrings x) => [
      x.loading,
      x.stillLoading,
      x.tryAgain,
      x.dismiss,
      x.undo,
      x.cancel,
      x.done,
      x.skippedForToday,
      x.iDidIt,
      x.freeReading,
      x.dailyCards,
      x.scrollForMore,
      x.holdToConfirm,
      x.contentUnavailableTitle,
      x.contentUnavailableBody,
      x.progressOf(5, 12),
    ];
    expect(all(s), all(f));
  });

  testWidgets('app wraps routes in Prosoche theme, scaling and UI strings', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpProsoche();
    final context = tester.element(navBar);
    expect(Theme.of(context).extension<ProsocheColors>(), ProsocheColors.light);
    expect(Theme.of(context).textTheme.bodyLarge!.fontFamily, SkFonts.inter);
    expect(SkUiStrings.of(context).tryAgain, 'Try again');
    // SkTextScaling: UI clamp na 2.0, citacie texty dostanu neclampnuty scaler.
    expect(MediaQuery.textScalerOf(context).scale(10), 20);
    expect(SkTextScaling.unclampedOf(context).scale(10), 30);
  });

  testWidgets('dark platform brightness selects the dark Prosoche theme', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpProsoche();
    final context = tester.element(navBar);
    expect(Theme.of(context).extension<ProsocheColors>(), ProsocheColors.dark);
  });

  group('system back after a language change (I-03)', () {
    /// Hodnoty `SystemNavigator.setFrameworkHandlesBack` poslane enginu.
    List<bool> recordHandlesBack(WidgetTester tester) {
      final calls = <bool>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
            calls.add(call.arguments as bool);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      return calls;
    }

    testWidgets('router instance survives a locale change', (tester) async {
      final fakes = FakeRepositories();
      final container = ProviderContainer(
        overrides: [
          ...fakes.overrides(now: DateTime(2026, 10, 29, 9)),
          featureFlagsProvider.overrideWithValue(FeatureFlags.all),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);
      await fakes.settings.set(SettingsKeys.uiLocale, 'de');
      await tester.pump();
      expect(identical(container.read(appRouterProvider), router), isTrue);
    });

    testWidgets('framework keeps handling back while routes can pop', (
      tester,
    ) async {
      final calls = recordHandlesBack(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final fakes = FakeRepositories();
      final router = await tester.pumpProsoche(fakes: fakes);
      unawaited(router.push('/settings'));
      await tester.pumpAndSettle();
      unawaited(router.push('/settings/display'));
      await tester.pumpAndSettle();
      expect(calls.last, isTrue);

      await fakes.settings.set(SettingsKeys.uiLocale, 'de');
      await tester.pumpAndSettle();
      expect(router.canPop(), isTrue);
      expect(find.byType(DisplaySettingsScreen), findsOneWidget);

      // Notifikacia "nemam co popnut" zvonka root navigatora (napr. po
      // prebudovani stromu) nesmie enginu povedat, ze back nespracujeme.
      const NavigationNotification(canHandlePop: false)
          .dispatch(tester.element(find.byType(SkTextScaling)));
      expect(calls.last, isTrue);

      // Systemovy back popne obrazovku Zobrazenie, appka ostane.
      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(find.byType(DisplaySettingsScreen), findsNothing);
      expect(router.canPop(), isTrue);
    });

    testWidgets('on the root tab back is left to the system', (tester) async {
      final calls = recordHandlesBack(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpProsoche();
      const NavigationNotification(canHandlePop: false)
          .dispatch(tester.element(find.byType(SkTextScaling)));
      expect(calls.last, isFalse);
    });

    testWidgets('engine learns about pushed routes before any lifecycle '
        'event (lifecycleState null, E2E cold start)', (tester) async {
      final calls = recordHandlesBack(tester);
      tester.binding.resetInternalState();
      expect(tester.binding.lifecycleState, isNull);
      final router = await tester.pumpProsoche();
      unawaited(router.push('/settings'));
      await tester.pumpAndSettle();
      expect(tester.binding.lifecycleState, isNull);
      expect(calls, isNotEmpty);
      expect(calls.last, isTrue);
    });
  });
}
