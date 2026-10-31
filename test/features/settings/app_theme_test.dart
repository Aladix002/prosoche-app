import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/today/today_screen.dart';
import 'package:sakina/ui/ui.dart';

import '../../fakes/fake_repositories.dart';
import '../../fakes/in_memory_settings_repository.dart';
import '../../helpers/pump_app.dart';

/// Volba temy a velkosti arabciny z nastaveni plati v celej appke
/// (lib/app.dart, docs/02 A10.6).
void main() {
  testWidgets('display.theme and arabic scale reach the app theme', (
    tester,
  ) async {
    final settings = InMemorySettingsRepository();
    await settings.set(SettingsKeys.displayTheme, 'dark');
    await settings.set(SettingsKeys.displayArabicScale, 1.45);
    await tester.pumpSakina(fakes: FakeRepositories(settings: settings));
    final context = tester.element(find.byType(TodayScreen));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(context.sk.type.arabicScale, SkArabicScale.xl);

    await settings.set(SettingsKeys.displayTheme, 'light');
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(TodayScreen))).brightness,
      Brightness.light,
    );
  });
}
