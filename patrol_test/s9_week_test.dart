import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:prosoche/features/journey/week/week_share.dart';

import 'support/app_harness.dart';
import 'support/flows.dart';

/// J-01 tyzdenny prehlad: po vecernej praxi ju karta "This week" na
/// Journey zapocita; Share otvori nahlad obrazka bez mien appiek.
void main() {
  patrolTest('s9 week - this week card and share preview', ($) async {
    await startApp($);
    await completeOnboarding($);

    await openTab($, AppTab.practice);
    await waitFor($, key('routine:evening'));
    await tapUntil($, key('routine:evening'), key('routine:body:evening'));
    await $.tester.scrollUntilVisible(
      key('routine:done'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tapUntil($, key('routine:done'), key('routine:undo'));
    await $.tester.pageBack();
    await wait($, const Duration(seconds: 1));

    await openTab($, AppTab.journey);
    await $.tester.scrollUntilVisible(
      key('journey:week'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await waitFor($, text('THIS WEEK'));
    expect(text('day with practice'), findsOneWidget);
    expect(find.textContaining('Morning 0 · Evening 1'), findsOneWidget);
    // Lite edicia: bez riadkov brany.
    expect(find.textContaining('pause'), findsNothing);

    await $.tester.scrollUntilVisible(
      key('week:share'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tapUntil($, key('week:share'), text('Share your week'));
    await waitFor($, find.byType(WeekShareImage));
    expect(find.byType(SwitchListTile), findsNothing);
    await waitUntil($, () {
      final b = $.tester.widget<ButtonStyleButton>(
        find.descendant(
          of: key('week:share-image'),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );
      return b.onPressed != null;
    });
  });
}
