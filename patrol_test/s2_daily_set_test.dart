import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:prosoche/ui/ui.dart';

import 'support/app_harness.dart';
import 'support/flows.dart';

/// TECHNICKY_PLAN 17.5/2: dokoncenie dennej sady. Questy `read` a `learn`
/// sa splnia, zobrazi sa "Dnes si hotovy" a feed sa zavrie (na Dnes uz
/// nie je vstup do sady).
void main() {
  patrolTest('s2 denna sada - questy read a learn splnene, feed zavrety', (
    $,
  ) async {
    await startApp($);
    await completeOnboarding($);

    await openFeed($, text("Begin today's cards"));
    expect(currentCardPos($), 1);
    await finishFeed($);

    expect(text("You're done for today"), findsOneWidget);
    expect(text('The cards are closed until tomorrow.'), findsOneWidget);
    await tapUntil($, text('Back to Today'), text("Today's intentions"));

    await waitFor($, text("Today's cards are complete"));
    expect(text("Begin today's cards"), findsNothing);
    expect(find.textContaining('Continue ·'), findsNothing);

    for (final slot in ['read', 'learn']) {
      final item = key('quest-$slot');
      await waitFor($, item);
      final state = $.tester.widget<SkQuestItem>(item).state;
      debugPrint('E2E: quest $slot = $state');
      expect(state, SkQuestState.done, reason: 'quest $slot');
    }
  });
}
