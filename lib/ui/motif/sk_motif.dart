import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:prosoche/ui/motif/sk_greek_motif.dart';
import 'package:prosoche/ui/theme/sk_context.dart';

/// Zlozene prvky motivu Prosoche (docs/DESIGN.md 5): odznak s oblukom,
/// oddelovac, bod pozornosti a ramcek plnej karty. Zakladne tvary
/// (meander, rimsa, oblúk, stlp, portal) su v `sk_greek_motif.dart`.
///
/// Pravidla: len dekor (`ExcludeSemantics`), striedmo, nikdy pod textom
/// karty, ziadne pismo, ziadne zobrazenia ludi, busty ani sochy.

/// Bod pozornosti: plny kruh, volitelne v tenkom kruhu. Symbol prosoche
/// (pozornost na jeden bod). [progress] 0..1 postupne vykresli kruh.
class SkAttentionPainter extends CustomPainter {
  const SkAttentionPainter({
    required this.color,
    this.dotColor,
    this.progress = 1,
    this.strokeWidth = 1.25,
    this.ring = true,
  });

  final Color color;

  /// Farba bodu; default [color].
  final Color? dotColor;
  final double progress;
  final double strokeWidth;
  final bool ring;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - strokeWidth;
    final t = progress.clamp(0.0, 1.0);
    if (ring) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * t,
        false,
        paint,
      );
    }
    final dot = Paint()..color = (dotColor ?? color).withValues(alpha: t);
    canvas.drawCircle(c, math.max(1.5, r * (ring ? 0.22 : 0.5)), dot);
  }

  @override
  bool shouldRepaint(SkAttentionPainter old) =>
      old.color != color ||
      old.dotColor != dotColor ||
      old.progress != progress ||
      old.strokeWidth != strokeWidth ||
      old.ring != ring;
}

/// Bod pozornosti (dekor). Pri [animate] sa kruh pomaly dokresli
/// (`motion.calm`); pri reduce motion staticky.
class SkAttentionMark extends StatelessWidget {
  const SkAttentionMark({
    this.size = 24,
    this.color,
    this.strokeWidth = 1.25,
    this.ring = true,
    this.animate = false,
    super.key,
  });

  final double size;

  /// Default `goldDeco` (okra); bod je v `accentText` (terakota).
  final Color? color;
  final double strokeWidth;
  final bool ring;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final paint = color ?? sk.colors.goldDeco;
    final calm = sk.motion.calm;
    Widget draw(double t) => CustomPaint(
      size: Size.square(size),
      painter: SkAttentionPainter(
        color: paint,
        dotColor: color ?? sk.colors.accentText,
        progress: t,
        strokeWidth: strokeWidth,
        ring: ring,
      ),
    );
    final child = !animate || calm.duration == Duration.zero
        ? draw(1)
        : TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: calm.duration * 2,
            curve: calm.curve,
            builder: (context, t, _) => draw(t),
          );
    return ExcludeSemantics(
      child: SizedBox.square(dimension: size, child: child),
    );
  }
}

/// Stary nazov z forku (Mursa); dnes bod pozornosti.
typedef SkRosette = SkAttentionMark;

/// Odznak pre prazdne stavy, onboarding a zaver dna: oblúk a v jeho
/// otvore volitelna ikona (inak bod pozornosti).
class SkMotifBadge extends StatelessWidget {
  const SkMotifBadge({
    this.icon,
    this.size = 88,
    this.animate = false,
    super.key,
  });

  final IconData? icon;

  /// Vyska odznaku.
  final double size;

  /// Oblúk sa pomaly vykresli (zaverecna karta).
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final c = sk.colors;
    final width = size / SkArchPainter.aspect;
    final calm = sk.motion.calm;
    Widget arch(double t) => CustomPaint(
      size: Size(width, size),
      painter: SkArchPainter(
        color: c.goldDeco.withValues(alpha: 0.8),
        dotColor: icon == null ? c.accentText : null,
        dot: 0.6,
        strokeWidth: size >= 80 ? 1.5 : 1.25,
        progress: t,
      ),
    );
    final drawn = !animate || calm.duration == Duration.zero
        ? arch(1)
        : TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: calm.duration * 2,
            curve: calm.curve,
            builder: (context, t, _) => arch(t),
          );
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            drawn,
            if (icon != null)
              Align(
                alignment: const Alignment(0, 0.3),
                child: Icon(icon, size: size * 0.26, color: c.primary),
              ),
          ],
        ),
      ),
    );
  }
}

/// Oddelovac: linia - bod pozornosti - linia (`goldDeco`, dekor).
class SkOrnamentDivider extends StatelessWidget {
  const SkOrnamentDivider({this.width = 120, super.key});

  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.sk.colors;
    return ExcludeSemantics(
      child: SizedBox(
        height: 12,
        child: Center(
          child: CustomPaint(
            size: Size(width, 12),
            painter: _DividerPainter(
              c.goldDeco.withValues(alpha: 0.7),
              c.accentText,
            ),
          ),
        ),
      ),
    );
  }
}

class _DividerPainter extends CustomPainter {
  const _DividerPainter(this.color, this.dot);

  final Color color;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const gap = 10.0;
    final line = Paint()
      ..color = color
      ..strokeWidth = 1;
    canvas
      ..drawLine(Offset(0, c.dy), Offset(c.dx - gap, c.dy), line)
      ..drawLine(Offset(c.dx + gap, c.dy), Offset(size.width, c.dy), line)
      ..drawCircle(c, 2.5, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(_DividerPainter old) =>
      old.color != color || old.dot != dot;
}

/// Ramcek plnej karty: tenka linia vnutri okraja a rimsa (tri dentily)
/// uprostred hornej hrany. Kresli sa za obsahom, v odsadeni karty (nikdy
/// nezasahuje do textu, docs/DESIGN.md 4).
class SkCardFramePainter extends CustomPainter {
  const SkCardFramePainter({
    required this.color,
    this.inset = 8,
    this.radius = 6,
  });

  final Color color;
  final double inset;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < inset * 4 || size.height < inset * 4) return;
    final rect = (Offset.zero & size).deflate(inset);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const dentilW = 3.0;
    const dentilH = 4.0;
    const gap = 3.0;
    const group = dentilW * 3 + gap * 2;
    final top = Offset(rect.center.dx, rect.top);
    // Linia sa pod dentilmi prerusi.
    canvas
      ..save()
      ..clipPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(Offset.zero & size)
          ..addRect(Rect.fromCenter(center: top, width: group + 8, height: 10)),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        stroke,
      )
      ..restore();
    final fill = Paint()..color = color;
    var x = top.dx - group / 2;
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(x, top.dy - dentilH / 2, dentilW, dentilH),
        fill,
      );
      x += dentilW + gap;
    }
  }

  @override
  bool shouldRepaint(SkCardFramePainter old) =>
      old.color != color || old.inset != inset || old.radius != radius;
}
