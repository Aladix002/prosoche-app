import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeExtension;

/// Jeden motion token: trvanie + krivka.
@immutable
class SkMotionToken {
  const SkMotionToken(this.duration, this.curve);

  final Duration duration;
  final Curve curve;

  @override
  bool operator ==(Object other) =>
      other is SkMotionToken &&
      other.duration == duration &&
      other.curve == curve;

  @override
  int get hashCode => Object.hash(duration, curve);
}

/// Motion tokeny (docs/01 2.8). Pristup: `context.sk.motion`, ktory uz
/// zohladnuje reduce motion (system aj in-app prepinac).
///
/// Ziadny overshoot ani bounce.
@immutable
class SakinaMotion extends ThemeExtension<SakinaMotion> {
  const SakinaMotion({
    required this.instant,
    required this.short,
    required this.medium,
    required this.long,
    required this.calm,
    required this.exit,
    required this.crossfade,
    required this.reduced,
  });

  static const _standard = Cubic(0.2, 0, 0, 1);

  static const standard = SakinaMotion(
    instant: SkMotionToken(Duration(milliseconds: 100), Curves.linear),
    short: SkMotionToken(Duration(milliseconds: 200), _standard),
    medium: SkMotionToken(Duration(milliseconds: 300), _standard),
    long: SkMotionToken(Duration(milliseconds: 450), Cubic(0.05, 0.7, 0.1, 1)),
    calm: SkMotionToken(Duration(milliseconds: 800), Cubic(0.4, 0, 0.2, 1)),
    exit: SkMotionToken(Duration(milliseconds: 200), Cubic(0.3, 0, 1, 1)),
    crossfade: SkMotionToken(Duration(milliseconds: 200), _standard),
    reduced: false,
  );

  /// Reduce motion: vsetko 0 ms okrem crossfade 150 ms pri zmene obsahu.
  static const reducedMotion = SakinaMotion(
    instant: SkMotionToken(Duration.zero, Curves.linear),
    short: SkMotionToken(Duration.zero, Curves.linear),
    medium: SkMotionToken(Duration.zero, Curves.linear),
    long: SkMotionToken(Duration.zero, Curves.linear),
    calm: SkMotionToken(Duration.zero, Curves.linear),
    exit: SkMotionToken(Duration.zero, Curves.linear),
    crossfade: SkMotionToken(Duration(milliseconds: 150), Curves.linear),
    reduced: true,
  );

  /// Stlacenie tlacidla, ripple.
  final SkMotionToken instant;

  /// Quest check, toggle, chip.
  final SkMotionToken short;

  /// Prechod karty, progres segment, sheet.
  final SkMotionToken medium;

  /// Prechod obrazovky (fade-through).
  final SkMotionToken long;

  /// Zaverecna karta.
  final SkMotionToken calm;

  /// Odchod sheetu/dialogu.
  final SkMotionToken exit;

  /// Crossfade pri zmene obsahu (zostava aj pri reduce motion).
  final SkMotionToken crossfade;

  /// True, ak su animacie potlacene.
  final bool reduced;

  @override
  SakinaMotion copyWith({bool? reduced}) =>
      (reduced ?? this.reduced) ? reducedMotion : standard;

  @override
  SakinaMotion lerp(covariant ThemeExtension<SakinaMotion>? other, double t) =>
      other is SakinaMotion && t >= 0.5 ? other : this;
}
