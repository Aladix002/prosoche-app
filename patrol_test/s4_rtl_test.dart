import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:prosoche/features/today/today_screen.dart';

import 'support/app_harness.dart';
import 'support/flows.dart';

/// TECHNICKY_PLAN 17.5/4: zmena jazyka na AR (a UR) v nastaveniach, cele
/// UI v RTL. Pretecenie layoutu (RenderFlex overflow) je chyba frameworku
/// a zhodi test, preto sa v kazdom jazyku prejdu vsetky taby.
void main() {
  patrolTest('s4 jazyk AR a UR v nastaveniach - RTL', ($) async {
    await startApp($);
    await completeOnboarding($);
    expect(_direction($, find.byType(TodayScreen)), TextDirection.ltr);

    for (final lang in ['ar', 'ur']) {
      // Dnes > Nastavenia > Jazyk (ikony, texty su uz v jazyku UI).
      await openTab($, AppTab.today);
      await tapUntil(
        $,
        find.byIcon(Icons.settings_outlined),
        find.byIcon(Icons.translate),
      );
      await tapUntil($, find.byIcon(Icons.translate), key('language:$lang'));
      await $.tester.ensureVisible(key('language:$lang'));
      await $.tester.tap(key('language:$lang'));
      await waitUntil($, () => _locale($) == lang);
      expect(_direction($, key('language:$lang')), TextDirection.rtl);

      // Spat na Dnes systemovym backom (Jazyk -> Nastavenia -> Dnes).
      // Appka sa nesmie zavriet (I-03: predictive back po zmene jazyka).
      expect(find.byType(BackButton), findsWidgets);
      await $.platform.android.pressBack();
      await waitFor($, find.byIcon(Icons.translate));
      await $.platform.android.pressBack();
      await waitUntil(
        $,
        () =>
            find.byType(TodayScreen).evaluate().isNotEmpty &&
            find.byIcon(Icons.translate).evaluate().isEmpty,
      );
      expect(_direction($, find.byType(TodayScreen)), TextDirection.rtl);

      for (final tab in AppTab.values) {
        await openTab($, tab);
        await wait($, const Duration(seconds: 2));
        expect(_direction($, find.byType(NavigationBar)), TextDirection.rtl);
        debugPrint('E2E: $lang ${tab.name} RTL ok');
      }
    }
  });
}

TextDirection _direction(PatrolIntegrationTester $, Finder f) =>
    Directionality.of($.tester.element(f.first));

String? _locale(PatrolIntegrationTester $) {
  final any = find.byType(Scaffold);
  if (any.evaluate().isEmpty) return null;
  return Localizations.localeOf($.tester.element(any.first)).languageCode;
}
