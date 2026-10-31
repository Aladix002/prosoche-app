import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/ui/foundation/sk_text_scaling.dart';
import 'package:prosoche/ui/theme/prosoche_theme.dart';

extension PumpSk on WidgetTester {
  /// Napumpuje [child] v Prosoche teme so zvolenym textScale a a11y priznakmi.
  Future<void> pumpSk(
    Widget child, {
    ThemeData? theme,
    double textScale = 1,
    bool accessibleNavigation = false,
    bool disableAnimations = false,
    bool scroll = true,
  }) async {
    await pumpWidget(
      MaterialApp(
        theme: theme ?? ProsocheTheme.light(),
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            accessibleNavigation: accessibleNavigation,
            disableAnimations: disableAnimations,
          ),
          child: SkTextScaling(child: app!),
        ),
        home: Scaffold(
          body: scroll
              ? SingleChildScrollView(child: child)
              : Center(child: child),
        ),
      ),
    );
  }
}
