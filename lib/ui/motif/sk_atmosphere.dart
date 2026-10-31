import 'package:flutter/material.dart';
import 'package:prosoche/ui/theme/prosoche_colors.dart';
import 'package:prosoche/ui/theme/sk_context.dart';
import 'package:prosoche/ui/tokens/sk_space.dart';

/// Cast dna pre atmosferu hlavicky (D-05). Urci ju volajuci podla hodiny
/// ([SkDayPhase.fromHour]).
enum SkDayPhase {
  /// Svitanie.
  dawn,

  /// Doobeda.
  morning,

  /// Napoludnie.
  midday,

  /// Popoludnie.
  afternoon,

  /// Sumrak.
  dusk,

  /// Noc.
  night;

  /// Cast dna podla hodiny.
  static SkDayPhase fromHour(int hour) => switch (hour) {
    >= 4 && < 6 => dawn,
    >= 6 && < 11 => morning,
    >= 11 && < 15 => midday,
    >= 15 && < 18 => afternoon,
    >= 18 && < 20 => dusk,
    _ => night,
  };
}

/// Farby atmosfery: jemny tonalny prechod od [top] k [bottom] (= `bg`).
/// Vsetky odtiene su blizko `bg`, takze text tokenov drzi WCAG AA
/// (test/ui/theme/contrast_test.dart).
@immutable
class SkAtmosphereColors {
  const SkAtmosphereColors({required this.top, required this.bottom});

  /// Odtien podla casti dna a temy.
  factory SkAtmosphereColors.of(SkDayPhase phase, ProsocheColors c) {
    final dark = c.bg.computeLuminance() < 0.2;
    final tint = dark ? _darkTints[phase]! : _lightTints[phase]!;
    return SkAtmosphereColors(top: tint, bottom: c.surface);
  }

  final Color top;
  final Color bottom;

  // docs/DESIGN.md 2.3: mramor, ranne svetlo, vapenec, okra, terakota,
  // atrament.
  static const Map<SkDayPhase, Color> _lightTints = {
    SkDayPhase.dawn: Color(0xFFF3E6E0),
    SkDayPhase.morning: Color(0xFFE6EBF0),
    SkDayPhase.midday: Color(0xFFF4F0E6),
    SkDayPhase.afternoon: Color(0xFFF3E8D3),
    SkDayPhase.dusk: Color(0xFFF2E1D8),
    SkDayPhase.night: Color(0xFFE1E6EE),
  };

  static const Map<SkDayPhase, Color> _darkTints = {
    SkDayPhase.dawn: Color(0xFF221A1E),
    SkDayPhase.morning: Color(0xFF152030),
    SkDayPhase.midday: Color(0xFF1C2028),
    SkDayPhase.afternoon: Color(0xFF25211A),
    SkDayPhase.dusk: Color(0xFF2A1C1A),
    SkDayPhase.night: Color(0xFF0C1524),
  };

  /// Vsetky odtiene (pre kontrastny test a galeriu).
  static Iterable<Color> allTints({required bool dark}) =>
      (dark ? _darkTints : _lightTints).values;
}

/// Hlavicka s atmosferou: plocha s jemnym tonalnym prechodom podla casti
/// dna ("svetlo na kameni", docs/DESIGN.md 1). Bez vzoru: motiv patri
/// volajucemu (napr. rimsa pod nadpisom).
class SkAtmospherePanel extends StatelessWidget {
  const SkAtmospherePanel({
    required this.phase,
    required this.child,
    this.padding = const EdgeInsetsDirectional.fromSTEB(
      SkSpace.space24,
      SkSpace.space16,
      SkSpace.space16,
      SkSpace.space24,
    ),
    this.radius = SkRadius.xl,
    super.key,
  });

  final SkDayPhase phase;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.sk.colors;
    final a = SkAtmosphereColors.of(phase, c);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [a.top, a.bottom],
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
