import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/settings/settings_keys.dart';

import '../fakes/fake_repositories.dart';
import '../fakes/in_memory_settings_repository.dart';
import '../helpers/golden/no_clipping.dart';
import '../helpers/pump_app.dart';

/// Q-03: pristupnost hlavnych obrazoviek (docs/01 8.7, TECHNICKY_PLAN 12.3).
///
/// Kazda obrazovka s fakes v EN pri textScale 2.0 na sirke
/// telefonu (412 dp): tap target 48x48 (Android), labely tap targetov,
/// kontrast textu (WCAG AA, svetla aj tmava tema) a ziadny orezany text.
/// Nalez A11Y-1 (orezane titulky AppBar) opravil I-03 cez `skAppBar`,
/// ziadna obrazovka nema vynimku.
void main() {
  // S-01: Prosoche ma zatial len EN; RTL kod ostava pre buduce jazyky.
  for (final locale in ['en']) {
    group('$locale textScale 2.0', () {
      for (final screen in _screens) {
        for (final g in _Guideline.values) {
          testWidgets('${screen.location} ${g.name}', (tester) async {
            await _pump(tester, screen.location, locale, dark: g.dark);
            if (g.guideline case final guideline?) {
              await expectLater(tester, meetsGuideline(guideline));
            } else {
              expectNoTextClipping(tester);
            }
          });
        }
      }
    });
  }
}

enum _Guideline {
  tapTarget(androidTapTargetGuideline),
  labeled(labeledTapTargetGuideline),
  contrast(textContrastGuideline),

  /// Kontrast aj v tmavej teme (plan 12.3).
  contrastDark(textContrastGuideline, dark: true),

  /// Ziadny orezany text ani chyba layoutu (docs/01 8.3, plan 12.3).
  noClipping(null);

  _Guideline(this.guideline, {this.dark = false});

  final AccessibilityGuideline? guideline;
  final bool dark;
}

class _Screen {
  const _Screen(this.location);

  final String location;
}

const _screens = [
  _Screen('/today'),
  _Screen('/feed'),
  _Screen('/library'),
  _Screen('/practice'),
  _Screen('/journey'),
  _Screen('/journey/saved'),
  _Screen('/settings'),
  _Screen('/settings/notifications'),
  _Screen('/settings/display'),
  _Screen('/settings/privacy'),
  _Screen('/settings/sources'),
  _Screen('/settings/about'),
  _Screen('/onboarding/welcome'),
  _Screen('/onboarding/intention'),
  _Screen('/onboarding/notifications'),
  _Screen('/onboarding/privacy'),
];

Future<void> _pump(
  WidgetTester tester,
  String location,
  String locale, {
  required bool dark,
}) async {
  tester.view
    ..physicalSize = const Size(412, 915) * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  if (dark) {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  }
  final settings = InMemorySettingsRepository();
  await settings.set(SettingsKeys.uiLocale, locale);
  final router = await tester.pumpProsoche(
    location: location,
    fakes: FakeRepositories(settings: settings),
  );
  // Ziadne presmerovanie: testuje sa naozaj [location].
  expect(router.state.uri.path, location);
  expect(
    Directionality.of(tester.element(find.byType(Scaffold).last)),
    locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
  );
}
