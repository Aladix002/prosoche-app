@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/ui/gallery/gallery_catalog.dart';

import 'sk_golden.dart';

/// Goldeny vsetkych komponentov: svetla/tmava x textScale 1.0/1.5/2.0,
/// EN + arabsky ukazkovy text (PLAN U-01 DoD).
///
///   flutter test --update-goldens test/ui/goldens
void main() {
  AlchemistConfig.runWithConfig(
    config: skGoldenConfig(),
    run: () {
      GalleryCatalog.components.forEach(skComponentGoldens);
    },
  );
}
