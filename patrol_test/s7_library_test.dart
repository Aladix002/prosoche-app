import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/app_harness.dart';
import 'support/flows.dart';

/// F-01 Library nad realnou content.db: zoznam diel, citacka Meditations,
/// pozicia citania (Keep reading v Today), zalozka a FTS5 vyhladavanie.
void main() {
  patrolTest('s7 library - citacka, pozicia, zalozka, vyhladavanie', ($) async {
    await startApp($);
    await completeOnboarding($);

    await openTab($, AppTab.library);
    await waitFor($, key('work:meditations'));
    expect(text('MARCUS AURELIUS  AD 121-180'), findsOneWidget);
    expect(find.textContaining('Translated by George Long'), findsWidgets);
    expect(find.textContaining('Gutenberg'), findsNothing);

    await tapUntil($, key('work:meditations'), key('reader:pages'));
    await waitFor($, key('reader:section:meditations.1.1'));
    await tapUntil(
      $,
      key('reader:next'),
      key('reader:section:meditations.1.2'),
    );
    await tapUntil(
      $,
      key('reader:bookmark'),
      find.byTooltip('Remove bookmark'),
    );
    await $.tester.pageBack();
    await wait($, const Duration(seconds: 1));
    await waitFor($, key('library:continue'));

    await openTab($, AppTab.today);
    await waitFor($, key('today:keepReading'));
    expect(find.textContaining('Meditations 1.2'), findsWidgets);

    await openTab($, AppTab.library);
    await tapUntil($, key('library:search'), key('search:field'));
    await $.tester.enterText(key('search:field'), 'busybody');
    await waitFor($, find.byKey(const ValueKey('search:results')));
    await $.tester.tap(find.textContaining('Meditations').first);
    await waitFor($, key('reader:pages'));
  });
}
