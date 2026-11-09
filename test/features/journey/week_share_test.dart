import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/journey/week_summary.dart';
import 'package:prosoche/domain/practice/routine.dart';
import 'package:prosoche/features/cards/cards.dart';
import 'package:prosoche/features/journey/week/week_share.dart';
import 'package:prosoche/ui/ui.dart';

import '../../fakes/fake_week_repository.dart';
import '../../helpers/golden/golden_harness.dart';

/// Ukazky PNG na posudenie dizajnu:
/// `--dart-define=RENDER_WEEK_DIR=/cesta`.
const String _dir = String.fromEnvironment('RENDER_WEEK_DIR');

/// Najhorsi pripad: vsetky riadky, appky a citat max. dlzky.
WeekSummary fullSummary() => WeekSummary.compute(
  window: WeekWindow.endingOn(LocalDate(2026, 11, 8)),
  gateAvailable: true,
  streak: 128,
  activity: WeekActivity(
    gateVisits: [
      for (var i = 0; i < 120; i++)
        GateVisit(
          at: DateTime(2026, 11, 2 + i % 7, 12),
          outcome: i.isEven ? GateOutcome.dismissed : GateOutcome.passed,
          appLabel: ['Social network app', 'Video app', 'News app'][i % 3],
        ),
    ],
    cardsReadByDay: {LocalDate(2026, 11, 3): 140},
    practice: {
      for (var d = 2; d <= 8; d++)
        LocalDate(2026, 11, d): {RoutineKind.morning, RoutineKind.evening},
    },
  ),
);

/// Ukotvena appka s realnymi fontmi a l10n, vrati context na render.
Future<BuildContext> host(WidgetTester tester, ThemeData theme) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SizedBox.expand()),
    ),
  );
  return tester.element(find.byType(SizedBox).last);
}

Future<Uint8List?> render(
  WidgetTester tester,
  BuildContext context, {
  bool withApps = true,
}) async {
  final content = weekShareContent(
    context,
    fullSummary(),
    quote: fakeWeekQuote(),
    withApps: withApps,
  );
  return await tester.runAsync<Uint8List?>(
    () => renderWidgetToPng(
      context,
      WeekShareImage(content: content, appName: 'Prosoche'),
      maxHeight: weekImageHeight,
      heights: const [weekImageHeight],
    ),
  );
}

(int, int) pngSize(Uint8List png) {
  final b = ByteData.sublistView(png);
  return (b.getUint32(16), b.getUint32(20));
}

void main() {
  setUpAll(loadProsocheFonts);

  for (final (name, theme) in [
    ('light', ProsocheTheme.light()),
    ('dark', ProsocheTheme.dark()),
  ]) {
    testWidgets('worst case fits 1080 x 1350 ($name)', (tester) async {
      final context = await host(tester, theme);
      final png = await render(tester, context);
      expect(png, isNotNull, reason: 'content must fit 4:5');
      expect(pngSize(png!), (1080, 1350));
      if (_dir.isNotEmpty) {
        File('$_dir/week_1080x1350_$name.png').writeAsBytesSync(png);
      }
    });
  }

  testWidgets('content: no zero rows, apps only on request', (tester) async {
    final context = await host(tester, ProsocheTheme.light());
    final summary = WeekSummary.compute(
      window: WeekWindow.endingOn(LocalDate(2026, 11, 8)),
      gateAvailable: true,
      activity: WeekActivity(
        cardsReadByDay: {LocalDate(2026, 11, 8): 1},
        gateVisits: [
          GateVisit(
            at: DateTime(2026, 11, 8, 9),
            outcome: GateOutcome.passed,
            appLabel: 'Social',
          ),
        ],
      ),
    );
    final c = weekShareContent(context, summary);
    expect(c.stats.map((s) => s.label), ['pause before an app', 'card read']);
    expect(c.numbers, ['1', '1']);
    expect(c.apps, isNull);
    expect(c.quote, isNull);
    final text = weekShareText(context, c);
    expect(text, 'My week\n1 pause before an app\n1 card read\n\nvia Prosoche');

    final withApps = weekShareContent(context, summary, withApps: true);
    expect(withApps.apps, 'Most paused: Social');
    expect(weekShareText(context, withApps), contains('Most paused: Social'));
  });
}
