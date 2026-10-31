import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/features/shell/day_phase.dart';
import 'package:prosoche/ui/ui.dart';

Widget _app(Widget child, {bool reduce = false}) => MaterialApp(
  theme: ProsocheTheme.light(),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: Scaffold(body: Center(child: child)),
  ),
);

/// D-01: motiv (meander, rimsa, oblúk, stlp, portal) je len dekor (bez
/// semantiky), animacia respektuje reduce motion a cast dna sa urci
/// podla hodiny.
void main() {
  test('meander module is one orthogonal line on a 5 x 5 grid', () {
    const m = skMeanderModule;
    expect(m.first, const Offset(0, 5));
    expect(m.last, const Offset(5, 5));
    for (var i = 1; i < m.length; i++) {
      final d = m[i] - m[i - 1];
      // Kazdy tah je zvisly alebo vodorovny.
      expect(d.dx == 0 || d.dy == 0, isTrue, reason: '$i');
      expect(m[i].dx, inInclusiveRange(0, 5));
      expect(m[i].dy, inInclusiveRange(0, 5));
    }
    // Pas z 3 modulov konci zvislym tahom na celom module.
    final bounds = skMeanderPath(Offset.zero, 2, 3).getBounds();
    expect(bounds.width, 30);
    expect(bounds.height, 10);
  });

  test('meander band height follows the unit', () {
    expect(SkMeanderPainter.heightFor(3), 21);
    expect(SkMeanderPainter.heightFor(3, framed: false), 15);
  });

  testWidgets('motif widgets paint without semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 200, child: SkMeanderBand()),
            SkCornice(width: 120),
            SkArch(),
            SkColumn(),
            SkPortalMark(),
            SkAttentionMark(),
            SkMotifBadge(icon: Icons.check),
            SkMotifBadge(),
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

  for (final (name, widget) in [
    ('attention mark', const SkAttentionMark(animate: true)),
    (
      'meander band',
      const SizedBox(width: 200, child: SkMeanderBand(animate: true)),
    ),
    ('motif badge', const SkMotifBadge(animate: true)),
  ]) {
    testWidgets('animated $name is static under reduce motion', (tester) async {
      await tester.pumpWidget(_app(widget, reduce: true));
      expect(find.byType(TweenAnimationBuilder<double>), findsNothing);

      await tester.pumpWidget(_app(widget));
      expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
      await tester.pumpAndSettle();
    });
  }

  test('painters repaint only on change', () {
    const c = Color(0xFF000000);
    const a = SkArchPainter(color: c);
    expect(a.shouldRepaint(const SkArchPainter(color: c)), isFalse);
    expect(a.shouldRepaint(const SkArchPainter(color: c, dot: 0.2)), isTrue);
    const m = SkMeanderPainter(color: c);
    expect(m.shouldRepaint(const SkMeanderPainter(color: c, unit: 4)), isTrue);
    const col = SkColumnPainter(color: c);
    expect(col.shouldRepaint(const SkColumnPainter(color: c)), isFalse);
    const p = SkPortalMarkPainter(color: c, dotColor: c);
    expect(
      p.shouldRepaint(const SkPortalMarkPainter(color: c, dotColor: c)),
      isFalse,
    );
    const k = SkCornicePainter(color: c);
    expect(k.shouldRepaint(const SkCornicePainter(color: c)), isFalse);
  });

  test('day phase follows the hour', () {
    expect(dayPhaseFor(DateTime(2026, 10, 30, 12)), SkDayPhase.midday);
    expect(dayPhaseFor(DateTime(2026, 10, 30, 19)), SkDayPhase.dusk);
    expect(SkDayPhase.fromHour(5), SkDayPhase.dawn);
    expect(SkDayPhase.fromHour(23), SkDayPhase.night);
    expect(SkDayPhase.fromHour(2), SkDayPhase.night);
  });
}
