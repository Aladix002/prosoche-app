import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:prosoche/ui/theme/sk_context.dart';

/// Motiv Prosoche (docs/DESIGN.md 5): meander, rimsa, stlp, oblúk a portal
/// kreslene v kode. Len dekor: `ExcludeSemantics`, `IgnorePointer`,
/// nikdy pod textom, nikdy nositel informacie.

/// Spolocny stetec pre linie motivu.
Paint _stroke(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeJoin = StrokeJoin.miter
  ..strokeCap = StrokeCap.square
  ..isAntiAlias = true;

/// Nakresli [path] po cast [progress] (0..1) celkovej dlzky vsetkych tahov.
void _drawProgress(Canvas canvas, Path path, Paint paint, double progress) {
  if (progress >= 1) {
    canvas.drawPath(path, paint);
    return;
  }
  if (progress <= 0) return;
  final metrics = path.computeMetrics().toList();
  final total = metrics.fold<double>(0, (s, m) => s + m.length);
  var left = total * progress;
  for (final m in metrics) {
    if (left <= 0) break;
    final len = math.min(left, m.length);
    canvas.drawPath(m.extractPath(0, len), paint);
    left -= len;
  }
}

// ---------------------------------------------------------------------------
// Meander
// ---------------------------------------------------------------------------

/// Jednociarovy grecky kluc. Modul je stvorec 5 x 5 jednotiek (`unit`),
/// linie maju rozostup 1 jednotku. Body jedneho modulu (v jednotkach,
/// y dole): (0,5) (0,0) (4,0) (4,3) (2,3) (2,2) (3,2) (3,1) (1,1) (1,5)
/// (5,5) = zaciatok dalsieho modulu.
const List<Offset> skMeanderModule = [
  Offset(0, 5),
  Offset.zero,
  Offset(4, 0),
  Offset(4, 3),
  Offset(2, 3),
  Offset(2, 2),
  Offset(3, 2),
  Offset(3, 1),
  Offset(1, 1),
  Offset(1, 5),
  Offset(5, 5),
];

/// Cesta meandra s [count] modulmi od [origin] (lavy horny roh pasu).
Path skMeanderPath(Offset origin, double unit, int count) {
  final path = Path();
  for (var i = 0; i < count; i++) {
    final dx = origin.dx + i * 5 * unit;
    for (var j = 0; j < skMeanderModule.length; j++) {
      final p = skMeanderModule[j];
      final x = dx + p.dx * unit;
      final y = origin.dy + p.dy * unit;
      if (i == 0 && j == 0) {
        path.moveTo(x, y);
      } else if (j > 0) {
        path.lineTo(x, y);
      }
    }
  }
  // Uzavretie: posledny zvisly tah, aby pas nekoncil polovicou kluca.
  if (count > 0) {
    final end = origin.dx + count * 5 * unit;
    path.lineTo(end, origin.dy);
  }
  return path;
}

/// Pas meandra cez celu sirku, vycentrovany, len cele moduly.
class SkMeanderPainter extends CustomPainter {
  const SkMeanderPainter({
    required this.color,
    this.unit = 3,
    this.strokeWidth = 1.25,
    this.framed = true,
    this.progress = 1,
  });

  final Color color;

  /// Velkost jednotky mriezky v logickych bodoch.
  final double unit;
  final double strokeWidth;

  /// Tenka linia nad a pod pasom (1 jednotka od meandra).
  final bool framed;

  /// 0..1 postupne vykreslenie (done karta).
  final double progress;

  /// Vyska pasu pre danu jednotku.
  static double heightFor(double unit, {bool framed = true}) =>
      unit * (framed ? 7 : 5);

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0 || size.isEmpty) return;
    final module = 5 * unit;
    final count = ((size.width - unit) / module).floor();
    if (count < 1) return;
    final width = count * module;
    final left = (size.width - width) / 2;
    final top = (size.height - heightFor(unit, framed: framed)) / 2;
    final keyTop = top + (framed ? unit : 0);
    final path = skMeanderPath(Offset(left, keyTop), unit, count);
    if (framed) {
      path
        ..moveTo(left, top)
        ..lineTo(left + width, top)
        ..moveTo(left, keyTop + 6 * unit)
        ..lineTo(left + width, keyTop + 6 * unit);
    }
    _drawProgress(canvas, path, _stroke(color, strokeWidth), progress);
  }

  @override
  bool shouldRepaint(SkMeanderPainter old) =>
      old.color != color ||
      old.unit != unit ||
      old.strokeWidth != strokeWidth ||
      old.framed != framed ||
      old.progress != progress;
}

/// Pas meandra (zdielany obrazok, done karta). Pri [animate] sa pomaly
/// "vytesa" (`motion.calm` x 2); pri reduce motion je staticky.
class SkMeanderBand extends StatelessWidget {
  const SkMeanderBand({
    this.unit = 3,
    this.color,
    this.opacity = 0.6,
    this.framed = true,
    this.animate = false,
    this.width,
    super.key,
  });

  final double unit;

  /// Default `goldDeco` (okra).
  final Color? color;
  final double opacity;
  final bool framed;
  final bool animate;

  /// Pevna sirka; inak cela dostupna sirka.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final base = color ?? sk.colors.goldDeco;
    final paint = base.withValues(alpha: base.a * opacity);
    final calm = sk.motion.calm;
    final height = SkMeanderPainter.heightFor(unit, framed: framed);
    Widget draw(double t) => CustomPaint(
      painter: SkMeanderPainter(
        color: paint,
        unit: unit,
        framed: framed,
        progress: t,
      ),
      size: Size(width ?? double.infinity, height),
    );
    final child = !animate || calm.duration == Duration.zero
        ? draw(1)
        : TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: calm.duration * 2,
            curve: calm.curve,
            builder: (context, t, _) => draw(t),
          );
    return IgnorePointer(
      child: ExcludeSemantics(
        child: SizedBox(width: width, height: height, child: child),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rimsa (cornice)
// ---------------------------------------------------------------------------

/// Linia rimsy: horna linia, rad dentilov, spodna linia.
class SkCornicePainter extends CustomPainter {
  const SkCornicePainter({required this.color, this.strokeWidth = 1});

  final Color color;
  final double strokeWidth;

  /// Vyska rimsy v logickych bodoch.
  static const double height = 12;

  static const double _dentilW = 3;
  static const double _dentilH = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0 || size.width <= 0) return;
    final top = (size.height - height) / 2;
    final line = _stroke(color, strokeWidth);
    final fill = Paint()..color = color;
    final y1 = top + strokeWidth / 2;
    final y2 = top + height - strokeWidth / 2;
    canvas
      ..drawLine(Offset(0, y1), Offset(size.width, y1), line)
      ..drawLine(Offset(0, y2), Offset(size.width, y2), line);
    const step = _dentilW + _gap;
    final count = ((size.width - _gap) / step).floor();
    final used = count * step - _gap;
    var x = (size.width - used) / 2;
    final dy = top + (height - _dentilH) / 2;
    for (var i = 0; i < count; i++) {
      canvas.drawRect(Rect.fromLTWH(x, dy, _dentilW, _dentilH), fill);
      x += step;
    }
  }

  @override
  bool shouldRepaint(SkCornicePainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

/// Oddelovac sekcie v tvare rimsy (Today, Library, nadpis knihy).
class SkCornice extends StatelessWidget {
  const SkCornice({this.width, this.color, this.opacity = 0.55, super.key});

  final double? width;

  /// Default `goldDeco`.
  final Color? color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final base = color ?? context.sk.colors.goldDeco;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: SkCornicePainter.height,
          child: CustomPaint(
            painter: SkCornicePainter(
              color: base.withValues(alpha: base.a * opacity),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Oblúk (arch)
// ---------------------------------------------------------------------------

/// Polkruhovy oblúk na dvoch pilieroch s archivoltou, klenákom a bodom
/// pozornosti. Kresli sa do plochy sirka : vyska = 1 : 1.2.
class SkArchPainter extends CustomPainter {
  const SkArchPainter({
    required this.color,
    this.dotColor,
    this.dot = 0.55,
    this.keystone = true,
    this.strokeWidth = 1.25,
    this.progress = 1,
  });

  final Color color;

  /// Farba bodu; null = bez bodu.
  final Color? dotColor;

  /// Vyska bodu v otvore: 0 = vrchol oblúka, 1 = prah.
  final double dot;
  final bool keystone;
  final double strokeWidth;
  final double progress;

  static const double aspect = 1.2;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = math.min(size.width, size.height / aspect);
    final h = w * aspect;
    final left = (size.width - w) / 2;
    final top = (size.height - h) / 2;
    final sw = strokeWidth;
    final outerR = w / 2 - sw;
    final innerR = outerR * 0.84;
    final cx = left + w / 2;
    final spring = top + sw + outerR; // stred polkruhu
    final base = top + h - sw;
    Path arch(double r) => Path()
      ..moveTo(cx - r, base)
      ..lineTo(cx - r, spring)
      ..arcToPoint(Offset(cx + r, spring), radius: Radius.circular(r))
      ..lineTo(cx + r, base);
    final path = arch(outerR)
      ..addPath(arch(innerR), Offset.zero)
      // Prah.
      ..moveTo(cx - outerR - sw * 2, base)
      ..lineTo(cx + outerR + sw * 2, base)
      // Hlavice pilierov (impost).
      ..moveTo(cx - outerR, spring)
      ..lineTo(cx - innerR, spring)
      ..moveTo(cx + innerR, spring)
      ..lineTo(cx + outerR, spring);
    if (keystone) {
      final k = (outerR - innerR) * 0.55;
      final topOuter = spring - outerR;
      final topInner = spring - innerR;
      path
        ..moveTo(cx - k * 0.8, topInner)
        ..lineTo(cx - k, topOuter)
        ..moveTo(cx + k * 0.8, topInner)
        ..lineTo(cx + k, topOuter);
    }
    _drawProgress(canvas, path, _stroke(color, sw), progress);
    final dc = dotColor;
    if (dc != null && progress >= 1) {
      final openingTop = spring - innerR;
      final y = openingTop + (base - openingTop) * dot.clamp(0.1, 0.9);
      canvas.drawCircle(
        Offset(cx, y),
        math.max(2, w * 0.035),
        Paint()..color = dc,
      );
    }
  }

  @override
  bool shouldRepaint(SkArchPainter old) =>
      old.color != color ||
      old.dotColor != dotColor ||
      old.dot != dot ||
      old.keystone != keystone ||
      old.strokeWidth != strokeWidth ||
      old.progress != progress;
}

/// Oblúk (brana, Practice, intro karta, prazdne stavy). Dekor.
class SkArch extends StatelessWidget {
  const SkArch({
    this.size = 96,
    this.dot = 0.55,
    this.showDot = true,
    this.keystone = true,
    this.color,
    this.opacity = 0.7,
    this.strokeWidth = 1.25,
    super.key,
  });

  /// Sirka; vyska je 1.2 x sirka.
  final double size;

  /// Vyska bodu (0 vrchol, 1 prah).
  final double dot;
  final bool showDot;
  final bool keystone;

  /// Default `goldDeco`.
  final Color? color;
  final double opacity;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.sk.colors;
    final base = color ?? c.goldDeco;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size * SkArchPainter.aspect,
          child: CustomPaint(
            painter: SkArchPainter(
              color: base.withValues(alpha: base.a * opacity),
              dotColor: showDot ? c.accentText : null,
              dot: dot,
              keystone: keystone,
              strokeWidth: strokeWidth,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stlp (column)
// ---------------------------------------------------------------------------

/// Doricky stlp v obryse: abakus, echinus, drik so zliabkami, stylobat.
/// Pomer sirka : vyska = 1 : 4 (sirka = abakus).
class SkColumnPainter extends CustomPainter {
  const SkColumnPainter({required this.color, this.strokeWidth = 1.25});

  final Color color;
  final double strokeWidth;

  static const double aspect = 4;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = math.min(size.width, size.height / aspect);
    final h = w * aspect;
    final left = (size.width - w) / 2;
    final top = (size.height - h) / 2;
    final cx = left + w / 2;
    final sw = strokeWidth;
    final abacusH = h * 0.05;
    final echinusH = h * 0.04;
    final baseH = h * 0.04;
    final shaftTop = top + abacusH + echinusH;
    final shaftBottom = top + h - baseH;
    final topHalf = w * 0.31;
    final bottomHalf = w * 0.36;
    final path = Path()
      // Abakus.
      ..addRect(Rect.fromLTWH(left + sw / 2, top + sw / 2, w - sw, abacusH))
      // Echinus: krivka od abakusu k driku.
      ..moveTo(left + w * 0.08, top + abacusH)
      ..quadraticBezierTo(
        cx - topHalf,
        top + abacusH + echinusH * 0.2,
        cx - topHalf,
        shaftTop,
      )
      ..moveTo(left + w * 0.92, top + abacusH)
      ..quadraticBezierTo(
        cx + topHalf,
        top + abacusH + echinusH * 0.2,
        cx + topHalf,
        shaftTop,
      )
      // Drik (jemne sa zuzuje).
      ..moveTo(cx - topHalf, shaftTop)
      ..lineTo(cx - bottomHalf, shaftBottom)
      ..moveTo(cx + topHalf, shaftTop)
      ..lineTo(cx + bottomHalf, shaftBottom);
    // Zliabky.
    for (final f in const [-0.33, 0.0, 0.33]) {
      path
        ..moveTo(cx + topHalf * f, shaftTop + h * 0.03)
        ..lineTo(cx + bottomHalf * f, shaftBottom - h * 0.03);
    }
    // Stylobat (dva stupne).
    path
      ..addRect(
        Rect.fromLTWH(
          cx - bottomHalf - w * 0.06,
          shaftBottom,
          (bottomHalf + w * 0.06) * 2,
          baseH / 2,
        ),
      )
      ..moveTo(left, shaftBottom + baseH - sw / 2)
      ..lineTo(left + w, shaftBottom + baseH - sw / 2);
    canvas.drawPath(path, _stroke(color, sw));
  }

  @override
  bool shouldRepaint(SkColumnPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

/// Stlp (onboarding, autor, prazdne stavy). Dekor.
class SkColumn extends StatelessWidget {
  const SkColumn({this.height = 96, this.color, this.opacity = 0.7, super.key});

  final double height;

  /// Default `goldDeco`.
  final Color? color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final base = color ?? context.sk.colors.goldDeco;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: SizedBox(
          width: height / SkColumnPainter.aspect,
          height: height,
          child: CustomPaint(
            painter: SkColumnPainter(
              color: base.withValues(alpha: base.a * opacity),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Portal (znacka appky)
// ---------------------------------------------------------------------------

/// Znacka Prosoche: dva stlpy a architrav (tvar Π) a bod pozornosti pod
/// architravom. Plne tvary (vynimka z linioveho motivu, je to logo).
/// Kresli sa do stvorca; [padding] je cast strany ako okraj (ikona appky
/// pouziva bezpecnu zonu).
class SkPortalMarkPainter extends CustomPainter {
  const SkPortalMarkPainter({
    required this.color,
    required this.dotColor,
    this.background,
    this.padding = 0.12,
  });

  final Color color;
  final Color dotColor;

  /// Plne pozadie stvorca (ikona); null = priehladne.
  final Color? background;
  final double padding;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final o = Offset((size.width - s) / 2, (size.height - s) / 2);
    if (background != null) {
      canvas.drawRect(o & Size.square(s), Paint()..color = background!);
    }
    final inner = s * (1 - 2 * padding);
    final x0 = o.dx + s * padding;
    final y0 = o.dy + s * padding;
    double x(double f) => x0 + inner * f;
    double y(double f) => y0 + inner * f;
    final fill = Paint()
      ..color = color
      ..isAntiAlias = true;
    // Architrav s jemnym presahom (rimsa).
    canvas
      ..drawRect(Rect.fromLTRB(x(0.06), y(0.14), x(0.94), y(0.22)), fill)
      ..drawRect(Rect.fromLTRB(x(0.12), y(0.24), x(0.88), y(0.28)), fill);
    // Stlpy: zuzene lichobezniky.
    Path post(double c) => Path()
      ..moveTo(x(c - 0.065), y(0.31))
      ..lineTo(x(c + 0.065), y(0.31))
      ..lineTo(x(c + 0.08), y(0.80))
      ..lineTo(x(c - 0.08), y(0.80))
      ..close();
    canvas
      ..drawPath(post(0.24), fill)
      ..drawPath(post(0.76), fill)
      // Stylobat.
      ..drawRect(Rect.fromLTRB(x(0.06), y(0.83), x(0.94), y(0.87)), fill)
      // Bod pozornosti.
      ..drawCircle(
        Offset(x(0.5), y(0.47)),
        inner * 0.06,
        Paint()..color = dotColor,
      );
  }

  @override
  bool shouldRepaint(SkPortalMarkPainter old) =>
      old.color != color ||
      old.dotColor != dotColor ||
      old.background != background ||
      old.padding != padding;
}

/// Znacka appky (onboarding, zdielany obrazok, o appke). Dekor.
class SkPortalMark extends StatelessWidget {
  const SkPortalMark({this.size = 48, this.color, this.dotColor, super.key});

  final double size;

  /// Default `primary`.
  final Color? color;

  /// Default `accentText` (terakota).
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final c = context.sk.colors;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: SkPortalMarkPainter(
              color: color ?? c.primary,
              dotColor: dotColor ?? c.accentText,
            ),
          ),
        ),
      ),
    );
  }
}
