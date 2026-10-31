// Testovaci subor pre sakina_lints: kazdy riadok s `expect:` musi byt
// nahlaseny presne tymto pravidlom, ziadny iny riadok nesmie byt nahlaseny.
// Subor sa neanalyzuje (analysis_options exclude), je to len vstup.
// ignore_for_file: type=lint
import 'package:flutter/widgets.dart';
import 'package:flutter/widgets.dart' as w;

class Forbidden extends StatelessWidget {
  const Forbidden({super.key});

  static const a = EdgeInsets.only(left: 8); // expect: sakina_edge_insets_left_right
  static const b = EdgeInsets.only(top: 4, right: 8); // expect: sakina_edge_insets_left_right
  static const c = Alignment.centerLeft; // expect: sakina_alignment_left_right
  static const d = Alignment.topRight; // expect: sakina_alignment_left_right
  static const e = FractionalOffset.bottomLeft; // expect: sakina_alignment_left_right
  static const f = w.Alignment.bottomRight; // expect: sakina_alignment_left_right
  static const g = TextDirection.ltr; // expect: sakina_hardcoded_text_direction
  static const h = TextAlign.left; // expect: sakina_text_align_left_right
  static const i = TextAlign.right; // expect: sakina_text_align_left_right
  static const j = BorderRadius.only(topLeft: Radius.circular(4)); // expect: sakina_border_radius_left_right
  static const k = BorderRadius.horizontal(right: Radius.circular(4)); // expect: sakina_border_radius_left_right
  static const l = 'بسم'; // expect: sakina_arabic_text_outside_sk_arabic_text
  static const m = 'Sura ا'; // expect: sakina_arabic_text_outside_sk_arabic_text
  static const n = 'اردو'; // expect: sakina_arabic_text_outside_sk_arabic_text

  @override
  Widget build(BuildContext context) {
    final x = 3;
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(right: 2), // expect: sakina_edge_insets_left_right
          child: w.Padding(
            padding: w.EdgeInsets.only(left: 1), // expect: sakina_edge_insets_left_right
            child: Text('$x ١٢', textAlign: .left), // expect: sakina_arabic_text_outside_sk_arabic_text, sakina_text_align_left_right
          ),
        ),
        Positioned(left: 0, child: Text('a')), // expect: sakina_positioned_left_right
        const Positioned(right: 0, child: Text('b')), // expect: sakina_positioned_left_right
        Positioned.fill(left: 2, child: Text('c')), // expect: sakina_positioned_left_right
        Align(alignment: .centerRight, child: Text('d')), // expect: sakina_alignment_left_right
        Directionality(textDirection: .ltr, child: Text('e')), // expect: sakina_hardcoded_text_direction
        Container(padding: .only(left: 3)), // expect: sakina_edge_insets_left_right
        Container(margin: const .only(right: 3)), // expect: sakina_edge_insets_left_right
        Directionality(textDirection: w.TextDirection.ltr, child: Text('f')), // expect: sakina_hardcoded_text_direction
      ],
    );
  }
}
