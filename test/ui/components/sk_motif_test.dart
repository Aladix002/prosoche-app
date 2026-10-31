import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:prosoche/features/shell/day_phase.dart';
import 'package:prosoche/ui/ui.dart';

Widget _app(Widget child, {bool reduce = false}) => MaterialApp(
  theme: ProsocheTheme.light(),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: Scaffold(body: Center(child: child)),
  ),
);

/// D-05: motiv je len dekor (bez semantiky), animacia respektuje reduce
/// motion a cast dna sa urci z najblizsej modlitby.
void main() {
  test('star has 16 points on two radii', () {
    final pts = skStarPoints(Offset.zero, 10);
    expect(pts, hasLength(16));
    expect(pts.first.dy, closeTo(-10, 1e-9));
    final inner = pts[1].distance;
    expect(inner, lessThan(10));
    expect(inner, greaterThan(7));
  });

  testWidgets('motif widgets paint without semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 200, height: 100, child: SkPatternField()),
            SkMotifBadge(icon: Icons.check),
            SkOrnamentDivider(),
            SkAtmospherePanel(phase: SkDayPhase.dusk, child: Text('x')),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel(RegExp('.')), findsOneWidget); // len 'x'
    handle.dispose();
  });

  testWidgets('animated rosette is static under reduce motion', (tester) async {
    await tester.pumpWidget(_app(const SkRosette(animate: true), reduce: true));
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);

    await tester.pumpWidget(_app(const SkRosette(animate: true)));
    expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
    await tester.pumpAndSettle();
  });

  test('day phase follows the next prayer, hour without location', () {
    final noon = DateTime(2026, 10, 30, 12);
    expect(dayPhaseFor(Prayer.fajr, noon), SkDayPhase.night);
    expect(dayPhaseFor(Prayer.sunrise, noon), SkDayPhase.dawn);
    expect(dayPhaseFor(Prayer.dhuhr, noon), SkDayPhase.morning);
    expect(dayPhaseFor(Prayer.asr, noon), SkDayPhase.midday);
    expect(dayPhaseFor(Prayer.maghrib, noon), SkDayPhase.afternoon);
    expect(dayPhaseFor(Prayer.isha, noon), SkDayPhase.dusk);
    expect(dayPhaseFor(null, noon), SkDayPhase.midday);
    expect(SkDayPhase.fromHour(5), SkDayPhase.dawn);
    expect(SkDayPhase.fromHour(23), SkDayPhase.night);
    expect(SkDayPhase.fromHour(2), SkDayPhase.night);
  });
}
