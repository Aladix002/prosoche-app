import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Overi, ze sa ziadny text neorezal: ziadna chyba layoutu (napr.
/// `RenderFlex overflowed`) a ziadny `Text` neprekrocil `maxLines`
/// (ellipsis). PLAN_VYVOJA U-02 DoD: UR a BN pri textScale 2.0.
void expectNoTextClipping(WidgetTester tester) {
  final exception = tester.takeException();
  expect(exception, isNull, reason: 'Chyba layoutu: $exception');
  for (final element in find.byType(RichText).evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: 'Orezany text: "${paragraph.text.toPlainText()}"',
    );
  }
}
