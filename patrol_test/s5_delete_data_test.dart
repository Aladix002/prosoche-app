import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/app_harness.dart';
import 'support/flows.dart';

/// Nastavenia > Sukromie > "Delete all my data" (docs/02 A10.9): po
/// dvojitom potvrdeni zacne appka znova onboardingom.
void main() {
  patrolTest('s5 Delete all my data - onboarding', ($) async {
    await startApp($);
    await completeOnboarding($);

    // Nejake data: prva karta sady je `seen`.
    await openFeed($, text("Begin today's cards"));
    await nextCard($);
    await tapUntil($, find.byTooltip('Close'), text("Today's intentions"));
    await waitFor($, find.textContaining('Continue ·'));

    await openSettingsFromToday($);
    await tapUntil($, text('Privacy'), key('privacy:delete'));
    await tapUntil($, key('privacy:delete'), key('delete:confirm'));
    await $.tester.enterText(key('delete:confirm'), 'DELETE');
    await $.tester.pump();
    await $.tester.tap(key('delete:go'));

    await waitFor($, text('Choose your language'));
    expect(text('Step 1 of 5'), findsOneWidget);

    // Po novom onboardingu je den bez progresu.
    await completeOnboarding($);
    await waitFor($, text("Begin today's cards"));
  });
}
