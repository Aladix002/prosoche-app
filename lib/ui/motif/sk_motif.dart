import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:prosoche/ui/theme/sk_context.dart';

/// Vizualny motiv znacky: zatial neutralny geometricky dekor (koso stvorce
/// a kruhy) kresleny v kode. Vlastnu identitu (meander, stlp, oblúk,
/// PLAN.md kap. 4) dodá D-01.
///
/// Pravidla (docs/01 1.3, 2.7): len dekor (`ExcludeSemantics`), striedmo
/// (hlavicky, onboarding, zaverecna karta, zdielany obrazok, prazdne
/// stavy), nikdy pod textom karty, ziadne pismo, ziadne zobrazenia ludi
/// ani zvierat.

/// Vrcholy kosostvorca (stvorec otoceny o 45 stupnov) so stredom [c]
/// a polomerom [r]; [rotation] v radianoch (0 = hrot hore).
List<Offset> skDiamondPoints(Offset c, double r, {double rotation = 0}) => [
  for (var i = 0; i < 4; i++)
    c +
        Offset(
          math.cos(rotation - math.pi / 2 + i * math.pi / 2) * r,
          math.sin(rotation - math.pi / 2 + i * math.pi / 2) * r,
        ),
];

/// Uzavrety obrys kosostvorca.
Path skDiamondPath(Offset c, double r, {double rotation = 0}) =>
    Path()..addPolygon(skDiamondPoints(c, r, rotation: rotation), true);

/// Opakujuci sa neutralny vzor: v kazdej bunke maly kosostvorec, medzi
/// nimi bodky.
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
    final dot = Paint()..color = color;
    final cols = (size.width / tile).ceil() + 1;
    final rows = (size.height / tile).ceil() + 1;
    canvas
      ..save()
      ..clipRect(Offset.zero & size);
    for (var y = 0; y <= rows; y++) {
      for (var x = 0; x <= cols; x++) {
        final c = Offset(x * tile, y * tile);
        canvas
          ..drawPath(skDiamondPath(c, tile * 0.18), paint)
          ..drawCircle(c + Offset(tile / 2, tile / 2), strokeWidth, dot);
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

/// Medailon: kruh, kosostvorec a vnutorny kruh. [progress] 0..1
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

  /// Vonkajsi kruh okolo kosostvorca.
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
      skDiamondPath(c, ring ? r * 0.86 : r),
      Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.42)),
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

/// Oddelovac: linka - maly kosostvorec - linka (`goldDeco`, dekor).
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
      ..drawPath(skDiamondPath(c, r), fill)
      ..drawCircle(Offset(c.dx - gap + 2, c.dy), 1.5, fill)
      ..drawCircle(Offset(c.dx + gap - 2, c.dy), 1.5, fill);
  }

  @override
  bool shouldRepaint(_DividerPainter old) => old.color != color;
}

/// Jemny ramcek plnej karty: tenka linka vnutri okraja a maly kosostvorec
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
    // Linka sa pod kosostvorcom prerusi.
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
      ..drawPath(skDiamondPath(top, r), Paint()..color = color);
  }

  @override
  bool shouldRepaint(SkCardFramePainter old) =>
      old.color != color || old.inset != inset || old.radius != radius;
}
