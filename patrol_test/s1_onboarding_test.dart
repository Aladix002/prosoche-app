import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:prosoche/data/observability/observability_providers.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'support/app_harness.dart';
import 'support/flows.dart';

/// TECHNICKY_PLAN 17.5/1: cerstva instalacia, onboarding v `lite` so
/// systemovym dialogom notifikacii, suhlas off, az po Dnes. PostHog ani
/// Sentry sa neinicializuju.
void main() {
  patrolTest('s1 cerstva instalacia - onboarding az po Dnes', ($) async {
    await startApp($);

    final report = await completeOnboarding($);

    // Po instalacii (tool/e2e.sh odinstaluje appku) musi prist systemovy
    // dialog; pri `--no-uninstall` uz moze byt povolene, staci stav "on".
    debugPrint('E2E: dialog notifikacii: ${report.notificationDialogShown}');
    expect(report.notificationsOn, isTrue);

    // Dnes: questy a vstup do sady.
    await waitFor($, text("Begin today's cards"));
    expect(text("Today's intentions"), findsOneWidget);

    // Suhlas off: ziadna analytika ani crash reporting.
    expect(appContainer.read(allowlistAnalyticsProvider).isEnabled, isFalse);
    expect(Sentry.isEnabled, isFalse);
  });
}
