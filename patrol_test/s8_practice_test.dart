import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:prosoche/ui/ui.dart';

import 'support/app_harness.dart';
import 'support/flows.dart';

/// F-01 Practice: vecerna reflexia s odpovedou do lokalneho dennika,
/// "Done" splni act quest, dennik zobrazi zaznam, memento mori.
void main() {
  patrolTest('s8 practice - reflexia, dennik, act quest, memento', ($) async {
    await startApp($);
    await completeOnboarding($);

    await openTab($, AppTab.practice);
    await waitFor($, key('routine:evening'));
    await tapUntil($, key('routine:evening'), key('routine:body:evening'));
    expect(find.textContaining('On Anger 3.36'), findsWidgets);

    await $.tester.scrollUntilVisible(
      key('answer:practice:evening-review#1'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final field = find
        .descendant(
          of: find.byType(SkJournalField),
          matching: find.byType(TextField),
        )
        .first;
    await $.tester.enterText(field, 'E2E answer');
    await wait($, const Duration(seconds: 2));
    await $.tester.scrollUntilVisible(
      key('routine:done'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tapUntil($, key('routine:done'), key('routine:undo'));

    await $.tester.pageBack();
    await wait($, const Duration(seconds: 1));
    await tapUntil($, key('practice:journal'), key('journal:list'));
    expect(text('E2E answer'), findsOneWidget);
    await $.tester.pageBack();
    await wait($, const Duration(seconds: 1));

    await tapUntil($, key('practice:memento'), key('memento:list'));
    await $.tester.pageBack();

    await openTab($, AppTab.today);
    await waitFor($, key('quest-act'));
    expect(
      $.tester.widget<SkQuestItem>(key('quest-act')).state,
      SkQuestState.done,
    );
  });
}
