import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:sakina/data/repositories/providers.dart';

import 'support/app_harness.dart';
import 'support/flows.dart';

/// Restart appky uprostred feedu: proces sa ukonci s otvorenym feedom
/// (koniec testu a), novy proces (test b, Android Test Orchestrator)
/// pokracuje na prvej nevidenej karte.
///
/// Testy su zavisle a musia bezat v tomto poradi v jednom behu
/// (`tool/e2e.sh`); b bez a zlyha na chybajucom progrese.
void main() {
  patrolTest('s6a restart - feed otvoreny po 3 kartach', ($) async {
    await startApp($);
    await completeOnboarding($);

    await openFeed($, text("Begin today's cards"));
    for (var i = 0; i < 3; i++) {
      await nextCard($);
    }
    expect(currentCardPos($), 4);
    // Koniec testu = koniec procesu, feed ostava otvoreny.
  });

  patrolTest('s6b restart - pokracuje na prvej nevidenej karte', ($) async {
    await startApp($, resetData: false);

    // Bez onboardingu rovno Dnes s rozpracovanou sadou.
    final cta = find.textContaining('Continue ·');
    await waitFor($, cta, timeout: const Duration(seconds: 60));

    final date = await appContainer.read(activeSetDateProvider.future);
    final state = await appContainer.read(dailySetProvider(date).future);
    debugPrint('E2E: cursor po restarte ${state.cursor}');
    // Karty 1-3 su `seen`; karta 4 mohla dobehnut dwell pred koncom procesu.
    expect(state.cursor, inInclusiveRange(3, 4));

    await openFeed($, cta);
    expect(currentCardPos($), state.cursor + 1);
  });
}
