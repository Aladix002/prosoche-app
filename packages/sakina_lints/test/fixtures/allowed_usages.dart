// Testovaci subor pre sakina_lints: nic tu nesmie byt nahlasene.
// Subor sa neanalyzuje (analysis_options exclude), je to len vstup.
// ignore_for_file: type=lint
import 'package:flutter/widgets.dart';

class SkArabicText {
  const SkArabicText.text(String text);
}

class Allowed extends StatelessWidget {
  const Allowed({super.key});

  static const a = EdgeInsetsDirectional.only(start: 8, end: 4);
  static const b = EdgeInsets.only(top: 4, bottom: 8);
  static const c = EdgeInsets.symmetric(horizontal: 8);
  static const d = AlignmentDirectional.centerStart;
  static const e = Alignment.center;
  static const f = Alignment.topCenter;
  static const g = TextDirection.rtl;
  static const h = TextAlign.start;
  static const i = TextAlign.center;
  static const j = BorderRadiusDirectional.only(topStart: Radius.circular(4));
  static const k = BorderRadius.vertical(top: Radius.circular(4));
  static const l = SkArabicText.text('بسم');
  static const m = 'Sakina 2:255';
  // sakina-lint: ignore sakina_text_align_left_right
  static const n = TextAlign.left;
  static const o = Alignment.centerLeft; // sakina-lint: ignore sakina_alignment_left_right

  @override
  Widget build(BuildContext context) {
    final sides = (left: 1, right: 2);
    return Stack(
      children: [
        PositionedDirectional(start: 0, child: Text('a')),
        Positioned(top: 0, bottom: 0, child: Text('b')),
        Align(alignment: .center, child: Text('c')),
        Directionality(textDirection: .rtl, child: Text('d')),
        Container(padding: .only(top: 3)),
        Container(padding: .symmetric(horizontal: 3)),
        SkArabicText.text('اردو ${sides.left}'),
        Text('${sides.right}', textAlign: .end),
        Text('x', style: TextStyle(fontFamily: 'Inter')),
      ],
    );
  }
}
