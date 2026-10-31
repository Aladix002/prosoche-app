// Kreslenie je citatelnejsie po krokoch nez v jednej kaskade.
// ignore_for_file: cascade_invocations
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sakina/ui/ui.dart';

/// Kompas qibly (docs/01 3.2 `SkQiblaDial`). Ruzica sa otaca podla
/// [heading]; ciara a znacka Kaaby ukazuju [bearing]. Bez senzora
/// ([heading] null) je sever hore a smer je staticky.
///
/// Kompas sa v RTL nezrkadli (sever je vzdy sever).
class QiblaDial extends StatelessWidget {
  const QiblaDial({
    required this.bearing,
    required this.semanticLabel,
    required this.northLabel,
    this.heading,
    this.aligned = false,
    super.key,
  });

  /// Azimut qibly od severu.
  final double bearing;

  /// Smer vrchnej hrany telefonu od severu; null = bez kompasu.
  final double? heading;
  final bool aligned;
  final String semanticLabel;
  final String northLabel;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final c = sk.colors;
    return Semantics(
      image: true,
      label: semanticLabel,
      child: AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: _DialPainter(
            bearing: bearing,
            heading: heading,
            ring: c.outlineStrong,
            tick: c.textTertiary,
            north: c.textPrimary,
            qibla: aligned ? c.success : c.primary,
            pointer: c.accentText,
            face: c.surfaceAlt,
            northText: TextPainter(
              text: TextSpan(
                text: northLabel,
                style: sk.text.titleMedium!.copyWith(color: c.textPrimary),
              ),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout(),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.bearing,
    required this.heading,
    required this.ring,
    required this.tick,
    required this.north,
    required this.qibla,
    required this.pointer,
    required this.face,
    required this.northText,
  });

  final double bearing;
  final double? heading;
  final Color ring;
  final Color tick;
  final Color north;
  final Color qibla;
  final Color pointer;
  final Color face;
  final TextPainter northText;

  static double _rad(double deg) => deg * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 12;
    canvas
      ..drawCircle(center, r, Paint()..color = face)
      ..drawCircle(
        center,
        r,
        Paint()
          ..color = ring
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

    // Ruzica otocena tak, aby sever ukazoval na skutocny sever.
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(_rad(-(heading ?? 0)));
    final tickPaint = Paint()
      ..color = tick
      ..strokeWidth = 2;
    for (var d = 0; d < 360; d += 30) {
      final a = _rad(d.toDouble());
      final dir = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(dir * (r - 10), dir * r, tickPaint);
    }
    northText.paint(canvas, Offset(-northText.width / 2, -r + 14));

    // Smer qibly.
    final qa = _rad(bearing);
    final qdir = Offset(math.sin(qa), -math.cos(qa));
    canvas.drawLine(
      Offset.zero,
      qdir * (r - 28),
      Paint()
        ..color = qibla
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    // Kaaba: plny stvorec na konci ciary, otoceny po smere.
    canvas
      ..save()
      ..translate(qdir.dx * (r - 28), qdir.dy * (r - 28))
      ..rotate(qa)
      ..drawRect(
        Rect.fromCenter(center: Offset.zero, width: 18, height: 18),
        Paint()..color = qibla,
      )
      ..restore()
      ..drawCircle(Offset.zero, 6, Paint()..color = north)
      ..restore();

    // Pevna znacka smeru telefonu (hore), len s kompasom.
    if (heading != null) {
      final path = Path()
        ..moveTo(center.dx, center.dy - r - 10)
        ..lineTo(center.dx - 9, center.dy - r + 6)
        ..lineTo(center.dx + 9, center.dy - r + 6)
        ..close();
      canvas.drawPath(path, Paint()..color = pointer);
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.bearing != bearing ||
      old.heading != heading ||
      old.qibla != qibla ||
      old.ring != ring ||
      old.face != face ||
      old.northText.text != northText.text;
}
