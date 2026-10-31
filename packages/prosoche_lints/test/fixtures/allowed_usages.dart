// Testovaci subor pre prosoche_lints: nic tu nesmie byt nahlasene.
// Subor sa neanalyzuje (analysis_options exclude), je to len vstup.
// ignore_for_file: type=lint
import 'package:flutter/widgets.dart';

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
  static const m = 'Prosoche 2:255';
  // prosoche-lint: ignore prosoche_text_align_left_right
  static const n = TextAlign.left;
  static const o = Alignment.centerLeft; // prosoche-lint: ignore prosoche_alignment_left_right

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
        Text('${sides.left}'),
        Text('${sides.right}', textAlign: .end),
        Text('x', style: TextStyle(fontFamily: 'Inter')),
      ],
    );
  }
}
