// Testovaci subor pre prosoche_lints: kazdy riadok s `expect:` musi byt
// nahlaseny presne tymto pravidlom, ziadny iny riadok nesmie byt nahlaseny.
// Subor sa neanalyzuje (analysis_options exclude), je to len vstup.
// ignore_for_file: type=lint
import 'package:flutter/widgets.dart';
import 'package:flutter/widgets.dart' as w;

class Forbidden extends StatelessWidget {
  const Forbidden({super.key});

  static const a = EdgeInsets.only(left: 8); // expect: prosoche_edge_insets_left_right
  static const b = EdgeInsets.only(top: 4, right: 8); // expect: prosoche_edge_insets_left_right
  static const c = Alignment.centerLeft; // expect: prosoche_alignment_left_right
  static const d = Alignment.topRight; // expect: prosoche_alignment_left_right
  static const e = FractionalOffset.bottomLeft; // expect: prosoche_alignment_left_right
  static const f = w.Alignment.bottomRight; // expect: prosoche_alignment_left_right
  static const g = TextDirection.ltr; // expect: prosoche_hardcoded_text_direction
  static const h = TextAlign.left; // expect: prosoche_text_align_left_right
  static const i = TextAlign.right; // expect: prosoche_text_align_left_right
  static const j = BorderRadius.only(topLeft: Radius.circular(4)); // expect: prosoche_border_radius_left_right
  static const k = BorderRadius.horizontal(right: Radius.circular(4)); // expect: prosoche_border_radius_left_right
  static const l = 'بسم'; // expect: prosoche_arabic_text_outside_sk_arabic_text
  static const m = 'Sura ا'; // expect: prosoche_arabic_text_outside_sk_arabic_text
  static const n = 'اردو'; // expect: prosoche_arabic_text_outside_sk_arabic_text

  @override
  Widget build(BuildContext context) {
    final x = 3;
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(right: 2), // expect: prosoche_edge_insets_left_right
          child: w.Padding(
            padding: w.EdgeInsets.only(left: 1), // expect: prosoche_edge_insets_left_right
            child: Text('$x ١٢', textAlign: .left), // expect: prosoche_arabic_text_outside_sk_arabic_text, prosoche_text_align_left_right
          ),
        ),
        Positioned(left: 0, child: Text('a')), // expect: prosoche_positioned_left_right
        const Positioned(right: 0, child: Text('b')), // expect: prosoche_positioned_left_right
        Positioned.fill(left: 2, child: Text('c')), // expect: prosoche_positioned_left_right
        Align(alignment: .centerRight, child: Text('d')), // expect: prosoche_alignment_left_right
        Directionality(textDirection: .ltr, child: Text('e')), // expect: prosoche_hardcoded_text_direction
        Container(padding: .only(left: 3)), // expect: prosoche_edge_insets_left_right
        Container(margin: const .only(right: 3)), // expect: prosoche_edge_insets_left_right
        Directionality(textDirection: w.TextDirection.ltr, child: Text('f')), // expect: prosoche_hardcoded_text_direction
      ],
    );
  }
}
