// Nastroj, nie test: vyrenderuje docasnu ikonu appky (docs/DESIGN.md 9)
// z SkPortalMarkPainter do PNG pre Android mipmap (pod API 26) a iOS.
//
//   flutter test test/tool/render_app_icon_test.dart \
//     --dart-define=RENDER_APP_ICON=true
//
// Bez define sa preskoci (beh v check.sh nic nezapisuje).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/ui/ui.dart';

const bool _render = bool.fromEnvironment('RENDER_APP_ICON');

Future<List<int>> _png(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const c = ProsocheColors.dark;
  // Rovnake proporcie ako adaptivna ikona: znacka v zone 56/108.
  SkPortalMarkPainter(
    color: c.goldDeco,
    dotColor: ProsocheColors.light.bg,
    background: ProsocheColors.light.primary,
    padding: 26 / 108,
  ).paint(canvas, Size.square(size.toDouble()));
  final image = await recorder.endRecording().toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  test('render app icon', () async {
    const android = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    for (final MapEntry(key: dpi, value: size) in android.entries) {
      File('android/app/src/main/res/mipmap-$dpi/ic_launcher.png')
          .writeAsBytesSync(await _png(size));
    }
    final ios = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
    final re = RegExp(r'Icon-App-([\d.]+)x[\d.]+@(\d)x\.png$');
    for (final f in ios.listSync().whereType<File>()) {
      final m = re.firstMatch(f.path);
      if (m == null) continue;
      final px = (double.parse(m[1]!) * int.parse(m[2]!)).round();
      f.writeAsBytesSync(await _png(px));
    }
  }, skip: !_render);
}
