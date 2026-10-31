import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/ui/ui.dart';

/// A11Y-1: titulok AppBar sa pri velkom pisme zalomi, neoreze.
void main() {
  Future<AppBar> pump(
    WidgetTester tester,
    String title, {
    double textScale = 1,
  }) async {
    tester.view
      ..physicalSize = const Size(412, 915) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    late AppBar bar;
    await tester.pumpWidget(
      MaterialApp(
        theme: ProsocheTheme.light(),
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: app!,
        ),
        home: Builder(
          builder: (context) {
            bar = skAppBar(context, title: title);
            return Scaffold(appBar: bar, body: const SizedBox());
          },
        ),
      ),
    );
    return bar;
  }

  RenderParagraph titleParagraph(WidgetTester tester, String title) =>
      tester.renderObject<RenderParagraph>(
        find.descendant(of: find.byType(AppBar), matching: find.text(title)),
      );

  testWidgets('short title keeps the standard toolbar', (tester) async {
    final bar = await pump(tester, 'Today');
    expect(bar.toolbarHeight, kToolbarHeight);
  });

  testWidgets('long title at textScale 2.0 wraps and grows the toolbar', (
    tester,
  ) async {
    const title = 'Notifications and reminders';
    final bar = await pump(tester, title, textScale: 2);
    expect(bar.toolbarHeight, greaterThan(kToolbarHeight));
    final p = titleParagraph(tester, title);
    expect(p.didExceedMaxLines, isFalse);
    expect(p.size.height, lessThanOrEqualTo(bar.toolbarHeight!));
    expect(tester.takeException(), isNull);
  });

  testWidgets('title scale is clamped like Material AppBar', (tester) async {
    await pump(tester, 'Language', textScale: 2);
    final p = titleParagraph(tester, 'Language');
    expect(p.textScaler.scale(10), closeTo(10 * skAppBarTitleMaxScale, 0.01));
  });
}
