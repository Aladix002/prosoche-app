import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:prosoche/ui/theme/sk_context.dart';

/// Vizualny motiv znacky (D-05): jemny islamsky geometricky vzor kresleny
/// v kode. Osemcipa hviezda (dva prekryte stvorce) v osemuholniku na
/// mriezke 4.8.8 (osemuholniky a stvorce).
///
/// Pravidla (docs/01 1.3, 2.7): len dekor (`ExcludeSemantics`), striedmo
/// (hlavicky, onboarding, zaverecna karta, zdielany obrazok, prazdne
/// stavy), nikdy pod arabskym textom ani prekladom, ziadne pismo ani
/// kaligrafia, ziadne zobrazenia ludi ani zvierat.

/// Body osemcipej hviezdy (16 vrcholov) so stredom [c] a vonkajsim
/// polomerom [r]; [rotation] v radianoch (0 = hrot hore).
List<Offset> skStarPoints(Offset c, double r, {double rotation = 0}) {
  // Dva stvorce s rovnakym opisanym polomerom: vnutorne vrcholy lezia na
  // r * cos(45) / cos(22.5).
  final inner = r * math.cos(math.pi / 4) / math.cos(math.pi / 8);
  return [
    for (var i = 0; i < 16; i++)
      () {
        final a = rotation - math.pi / 2 + i * math.pi / 8;
        final rr = i.isEven ? r : inner;
        return c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      }(),
  ];
}

/// Uzavrety obrys osemcipej hviezdy.
Path skStarPath(Offset c, double r, {double rotation = 0}) =>
    Path()..addPolygon(skStarPoints(c, r, rotation: rotation), true);

/// Pravidelny n-uholnik (osemuholnik pre mriezku 4.8.8).
Path _polygon(Offset c, double r, int n, double rotation) =>
    Path()..addPolygon([
      for (var i = 0; i < n; i++)
        c +
            Offset(
              math.cos(rotation + i * 2 * math.pi / n) * r,
              math.sin(rotation + i * 2 * math.pi / n) * r,
            ),
    ], true);

/// Opakujuci sa geometricky vzor: v kazdej bunke osemuholnik s vpisanou
/// osemcipou hviezdou, medzi nimi stvorce otocene o 45 stupnov.
class SkPatternPainter extends CustomPainter {
  const SkPatternPainter({
    required this.color,
    this.tile = 56,
    this.strokeWidth = 1,
  });

  final Color color;

  /// Velkost bunky v logickych bodoch.
  final double tile;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0 || size.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.miter
      ..isAntiAlias = true;
    // Osemuholnik vpisany do bunky: apotema = tile / 2.
    final octR = tile / 2 / math.cos(math.pi / 8);
    final cols = (size.width / tile).ceil() + 1;
    final rows = (size.height / tile).ceil() + 1;
    canvas
      ..save()
      ..clipRect(Offset.zero & size);
    for (var y = 0; y <= rows; y++) {
      for (var x = 0; x <= cols; x++) {
        final c = Offset(x * tile, y * tile);
        canvas
          ..drawPath(_polygon(c, octR, 8, math.pi / 8), paint)
          ..drawPath(skStarPath(c, octR * 0.78, rotation: math.pi / 8), paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SkPatternPainter old) =>
      old.color != color || old.tile != tile || old.strokeWidth != strokeWidth;
}

/// Plocha so vzorom, ktory sa jemne strati smerom k [fadeTo]
/// (napr. k textu). Ciste dekor: bez semantiky a bez dotykov.
class SkPatternField extends StatelessWidget {
  const SkPatternField({
    this.color,
    this.opacity = 0.35,
    this.tile = 56,
    this.strokeWidth = 1,
    this.fadeFrom = AlignmentDirectional.topEnd,
    this.fadeTo = AlignmentDirectional.bottomStart,
    this.fadeStop = 0.75,
    super.key,
  });

  /// Default `goldDeco`.
  final Color? color;

  /// Nasobok alfy farby (docs/01 2.7: 30-60 % pre ornamenty).
  final double opacity;
  final double tile;
  final double strokeWidth;

  /// Smer, kde je vzor plny a kde zmizne (zrkadli sa v RTL).
  final AlignmentDirectional fadeFrom;
  final AlignmentDirectional fadeTo;

  /// Cast plochy (0..1), na ktorej vzor celkom zmizne.
  final double fadeStop;

  @override
  Widget build(BuildContext context) {
    final base = color ?? context.sk.colors.goldDeco;
    final dir = Directionality.of(context);
    final painted = base.withValues(alpha: base.a * opacity);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => LinearGradient(
              begin: fadeFrom.resolve(dir),
              end: fadeTo.resolve(dir),
              stops: [0, fadeStop],
              colors: const [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
            ).createShader(rect),
            child: CustomPaint(
              painter: SkPatternPainter(
                color: painted,
                tile: tile,
                strokeWidth: strokeWidth,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Medailon: kruh, osemcipa hviezda a vnutorny kruh. [progress] 0..1
/// postupne vykresli tahy (zaverecna karta, docs/01 2.8 `calm`).
class SkRosettePainter extends CustomPainter {
  const SkRosettePainter({
    required this.color,
    this.accent,
    this.progress = 1,
    this.strokeWidth = 1.25,
    this.ring = true,
  });

  final Color color;

  /// Farba vnutorneho kruhu a stredu; default [color].
  final Color? accent;
  final double progress;
  final double strokeWidth;

  /// Vonkajsi kruh okolo hviezdy.
  final bool ring;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - strokeWidth;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final paths = <Path>[
      if (ring) Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      skStarPath(c, ring ? r * 0.86 : r),
      skStarPath(c, (ring ? r * 0.86 : r) * 0.62, rotation: math.pi / 8),
    ];
    final t = progress.clamp(0.0, 1.0);
    for (final path in paths) {
      if (t >= 1) {
        canvas.drawPath(path, paint);
        continue;
      }
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * t), paint);
      }
    }
    final dot = Paint()..color = (accent ?? color).withValues(alpha: t);
    canvas.drawCircle(c, math.max(1.5, r * 0.08), dot);
  }

  @override
  bool shouldRepaint(SkRosettePainter old) =>
      old.color != color ||
      old.accent != accent ||
      old.progress != progress ||
      old.strokeWidth != strokeWidth ||
      old.ring != ring;
}

/// Staticky alebo pomaly vykresleny medailon (dekor).
class SkRosette extends StatelessWidget {
  const SkRosette({
    this.size = 48,
    this.color,
    this.strokeWidth = 1.25,
    this.ring = true,
    this.animate = false,
    super.key,
  });

  final double size;

  /// Default `goldDeco`.
  final Color? color;
  final double strokeWidth;
  final bool ring;

  /// Pomaly vykresli tahy (`motion.calm`); pri reduce motion staticky.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final paint = color ?? sk.colors.goldDeco;
    final calm = sk.motion.calm;
    Widget build(double t) => CustomPaint(
      size: Size.square(size),
      painter: SkRosettePainter(
        color: paint,
        progress: t,
        strokeWidth: strokeWidth,
        ring: ring,
      ),
    );
    final child = !animate || calm.duration == Duration.zero
        ? build(1)
        : TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            // Kreslenie ornamentu je pomalsie nez samotny fade (calm x 2).
            duration: calm.duration * 2,
            curve: calm.curve,
            builder: (context, t, _) => build(t),
          );
    return ExcludeSemantics(
      child: SizedBox.square(dimension: size, child: child),
    );
  }
}

/// Odznak pre prazdne stavy, onboarding a zaver dna: tonalny kruh,
/// medailon a volitelna ikona v strede.
class SkMotifBadge extends StatelessWidget {
  const SkMotifBadge({
    this.icon,
    this.size = 88,
    this.animate = false,
    super.key,
  });

  final IconData? icon;
  final double size;

  /// Medailon sa pomaly vykresli (zaverecna karta).
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final c = context.sk.colors;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [c.surfaceAlt, c.surfaceAlt.withValues(alpha: 0)],
              stops: const [0.55, 1],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SkRosette(
                size: size * 0.92,
                color: c.goldDeco.withValues(alpha: icon == null ? 0.9 : 0.55),
                animate: animate,
              ),
              if (icon != null)
                Container(
                  width: size * 0.42,
                  height: size * 0.42,
                  decoration: BoxDecoration(
                    color: c.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: size * 0.24, color: c.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Oddelovac: linka - mala hviezda - linka (`goldDeco`, dekor).
class SkOrnamentDivider extends StatelessWidget {
  const SkOrnamentDivider({this.width = 120, super.key});

  final double width;

  @override
  Widget build(BuildContext context) {
    final color = context.sk.colors.goldDeco.withValues(alpha: 0.6);
    return ExcludeSemantics(
      child: SizedBox(
        height: 14,
        child: Center(
          child: CustomPaint(
            size: Size(width, 14),
            painter: _DividerPainter(color),
          ),
        ),
      ),
    );
  }
}

class _DividerPainter extends CustomPainter {
  const _DividerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const r = 6.0;
    final line = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color;
    const gap = r + 6;
    canvas
      ..drawLine(Offset(0, c.dy), Offset(c.dx - gap, c.dy), line)
      ..drawLine(Offset(c.dx + gap, c.dy), Offset(size.width, c.dy), line)
      ..drawPath(skStarPath(c, r), fill)
      ..drawCircle(Offset(c.dx - gap + 2, c.dy), 1.5, fill)
      ..drawCircle(Offset(c.dx + gap - 2, c.dy), 1.5, fill);
  }

  @override
  bool shouldRepaint(_DividerPainter old) => old.color != color;
}

/// Jemny ramcek plnej karty: tenka linka vnutri okraja a mala hviezda
/// uprostred hornej hrany. Kresli sa za obsahom, v odsadeni karty (nikdy
/// nezasahuje do textu, docs/01 1.3 bod 3).
class SkCardFramePainter extends CustomPainter {
  const SkCardFramePainter({
    required this.color,
    this.inset = 8,
    this.radius = 16,
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
    final top = Offset(rect.center.dx, rect.top);
    const r = 5.0;
    // Linka sa pod hviezdou prerusi.
    canvas
      ..save()
      ..clipPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(Offset.zero & size)
          ..addRect(Rect.fromCircle(center: top, radius: r + 4)),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        stroke,
      )
      ..restore()
      ..drawPath(skStarPath(top, r), Paint()..color = color);
  }

  @override
  bool shouldRepaint(SkCardFramePainter old) =>
      old.color != color || old.inset != inset || old.radius != radius;
}
