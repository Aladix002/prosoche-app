// Nastroj, nie test: vyrenderuje ukazky zdielaneho obrazka (docs/DESIGN.md
// 7.9) v realnych fontoch do PNG na posudenie dizajnu.
//
//   flutter test test/tool/render_share_images_test.dart \
//     --dart-define=RENDER_SHARE_DIR=/cesta/k/adresaru
//
// Bez define sa preskoci.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/features/cards/card_share.dart';
import 'package:prosoche/ui/ui.dart';

import '../helpers/golden/golden_harness.dart';

const String _dir = String.fromEnvironment('RENDER_SHARE_DIR');

void main() {
  setUpAll(loadProsocheFonts);

  for (final (name, theme) in [
    ('light', ProsocheTheme.light()),
    ('dark', ProsocheTheme.dark()),
  ]) {
    for (final (format, text) in [
      ('1080x1350', '[PLACEHOLDER quote] The sample shows a short quote.'),
      (
        '1080x1920',
        List.filled(6, '[PLACEHOLDER passage] A longer sample line.').join(' '),
      ),
    ]) {
      testWidgets('share image $name $format', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(body: SizedBox()),
          ),
        );
        final context = tester.element(find.byType(SizedBox).last);
        final png = await tester.runAsync(
          () => renderWidgetToPng(
            context,
            CardShareImage(
              data: CardShareData(
                reference: 'Meditations 2.1',
                text: text,
                attribution: 'Marcus Aurelius, tr. George Long',
              ),
              appName: 'Prosoche',
            ),
          ),
        );
        File('$_dir/share_${format}_$name.png').writeAsBytesSync(png!);
      }, skip: _dir.isEmpty);
    }
  }
}
