import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/features/quran/widgets/ayah_tile.dart';

import 'support/app_harness.dart';
import 'support/flows.dart';

/// Koran: vyhladanie referencie 2:255 otvori citanie na verse 255.
void main() {
  patrolTest('s3 Koran - 2:255 cez vyhladavanie', ($) async {
    await startApp($);
    await completeOnboarding($);

    await openTab($, AppTab.quran);
    await tapUntil(
      $,
      find.byTooltip('Search the Quran'),
      find.byType(TextField),
    );
    await $.tester.enterText(find.byType(TextField), '2:255');
    final goTo = find.textContaining('Go to ');
    await waitFor($, goTo);
    await $.tester.tap(goTo.first);

    // Vers 2:255 je na obrazovke (AyahTile, nie len v zozname).
    final verse = find.byWidgetPredicate(
      (w) => w is AyahTile && w.ayah.id == AyahId(2, 255),
    );
    await waitFor($, verse.hitTestable());
  });
}
