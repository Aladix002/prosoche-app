import 'package:flutter/widgets.dart';

/// Ikona so smerom (sipka dalej/spat, chevron), ktora sa v RTL zrkadli
/// (docs/01 8.6). Ikony bez smeru (play, bookmark) sa nezrkadlia, pre tie
/// pouzi obycajny `Icon`.
class DirectionalIcon extends StatelessWidget {
  const DirectionalIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final child = Icon(
      icon,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );
    // Ikony s matchTextDirection (napr. Icons.arrow_back) zrkadli uz Icon.
    if (icon.matchTextDirection ||
        Directionality.of(context) == TextDirection.ltr) {
      return child;
    }
    return Transform.flip(flipX: true, child: child);
  }
}

/// Logicky smer horizontalneho gesta voci smeru citania.
enum ReadingSwipe {
  /// Dalsia polozka (v LTR swipe dolava, v RTL doprava).
  forward,

  /// Predchadzajuca polozka.
  backward,

  /// Pod prahom alebo bez pohybu.
  none,
}

/// Prelozi horizontalnu rychlost/posun [dx] (kladne = doprava) na
/// [ReadingSwipe] podla [direction] (docs/04 5.2: swipe podla
/// `Directionality.of(context)`).
ReadingSwipe readingSwipe(
  double dx,
  TextDirection direction, {
  double threshold = 0,
}) {
  if (dx.abs() <= threshold) return ReadingSwipe.none;
  final towardsEnd = direction == TextDirection.ltr ? dx < 0 : dx > 0;
  return towardsEnd ? ReadingSwipe.forward : ReadingSwipe.backward;
}

/// `start` strana pre [direction] ako fyzicka strana (napr. pre
/// `Dismissible` a animacie, ktore pracuju s fyzickym posunom).
/// Vracia -1 pre lavu stranu, 1 pre pravu.
double startSign(TextDirection direction) =>
    direction == TextDirection.ltr ? -1 : 1;
