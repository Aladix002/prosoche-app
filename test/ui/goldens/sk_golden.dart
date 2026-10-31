import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/ui/foundation/sk_text_scaling.dart';
import 'package:sakina/ui/gallery/gallery_catalog.dart';
import 'package:sakina/ui/theme/sakina_theme.dart';

/// Jednoduchy golden harness U-01 (alchemist). Harness pre 6 jazykov
/// (`test/helpers/golden/`, U-02) ho po merge nahradi alebo obali.
///
/// CI goldeny (zakryty text) bezia vsade; platformove goldeny so
/// skutocnymi fontmi len lokalne na Linuxe (nie v CI, kde by sa lisil
/// rendering).
AlchemistConfig skGoldenConfig() => AlchemistConfig(
  ciGoldensConfig: const CiGoldensConfig(),
  platformGoldensConfig: PlatformGoldensConfig(
    platforms: {HostPlatform.linux},
    enabled: Platform.environment['CI'] != 'true',
  ),
);

/// Text scale pre goldeny komponentov (docs/01 D12: aj 1.5).
const skGoldenTextScales = [1.0, 1.5, 2.0];

/// Sirka telefonu pre goldeny.
const skGoldenWidth = 360.0;

/// Pre kazdu temu (svetla, tmava) jeden golden s mriezkou
/// stav x textScale.
void skComponentGoldens(GalleryComponent component, {String? fileName}) {
  final slug =
      fileName ??
      component.name
          .toLowerCase()
          .replaceAll(RegExp('[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
  for (final (themeName, theme) in [
    ('light', SakinaTheme.light()),
    ('dark', SakinaTheme.dark()),
  ]) {
    // goldenTest len registruje test (ako testWidgets).
    unawaited(
      goldenTest(
        '${component.name} $themeName',
        fileName: '${slug}_$themeName',
        pumpBeforeTest: _pumpFrames,
        builder: () => GoldenTestGroup(
          columns: skGoldenTextScales.length,
          scenarioConstraints: const BoxConstraints(maxWidth: skGoldenWidth),
          children: [
            for (final entry in component.entries)
              for (final scale in skGoldenTextScales)
                GoldenTestScenario(
                  name: '${entry.name} x$scale',
                  child: SkGoldenFrame(
                    theme: theme,
                    textScale: scale,
                    child: Builder(builder: entry.builder),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Pevny pocet snimok namiesto pumpAndSettle (spinner v `loading` stave
/// by sa nikdy neustalil).
Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Tema + textScale + Sakina scaling okolo jedneho stavu.
class SkGoldenFrame extends StatelessWidget {
  const SkGoldenFrame({
    required this.theme,
    required this.textScale,
    required this.child,
    super.key,
  });

  final ThemeData theme;
  final double textScale;
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
    data: theme,
    child: MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: SkTextScaling(
        child: Material(
          type: MaterialType.transparency,
          child: DefaultTextStyle(
            style: theme.textTheme.bodyLarge!,
            child: SizedBox(
              width: skGoldenWidth,
              child: GalleryFrame(child: child),
            ),
          ),
        ),
      ),
    ),
  );
}
