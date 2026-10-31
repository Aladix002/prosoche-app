import 'package:flutter/material.dart';
import 'package:sakina/ui/motif/sk_motif.dart';
import 'package:sakina/ui/theme/sakina_colors.dart';
import 'package:sakina/ui/theme/sk_context.dart';
import 'package:sakina/ui/tokens/sk_space.dart';

/// Cast dna pre atmosferu hlavicky (D-05). Urci ju volajuci podla
/// najblizsej modlitby, bez polohy podla hodiny ([SkDayPhase.fromHour]).
enum SkDayPhase {
  /// Pred vychodom slnka (dalsia je sunrise).
  dawn,

  /// Doobeda (dalsi je Dhuhr).
  morning,

  /// Napoludnie (dalsi je Asr).
  midday,

  /// Popoludnie (dalsi je Maghrib).
  afternoon,

  /// Po zapade (dalsia je Isha).
  dusk,

  /// Noc (dalsi je Fajr).
  night;

  /// Odhad bez casov modlitieb (bez polohy).
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
  factory SkAtmosphereColors.of(SkDayPhase phase, SakinaColors c) {
    final dark = c.bg.computeLuminance() < 0.2;
    final tint = dark ? _darkTints[phase]! : _lightTints[phase]!;
    return SkAtmosphereColors(top: tint, bottom: c.surface);
  }

  final Color top;
  final Color bottom;

  static const Map<SkDayPhase, Color> _lightTints = {
    SkDayPhase.dawn: Color(0xFFF4EAE7),
    SkDayPhase.morning: Color(0xFFE6F0EB),
    SkDayPhase.midday: Color(0xFFF5F0E1),
    SkDayPhase.afternoon: Color(0xFFF6ECD5),
    SkDayPhase.dusk: Color(0xFFF6E8DF),
    SkDayPhase.night: Color(0xFFE4EBEC),
  };

  static const Map<SkDayPhase, Color> _darkTints = {
    SkDayPhase.dawn: Color(0xFF221D24),
    SkDayPhase.morning: Color(0xFF16272A),
    SkDayPhase.midday: Color(0xFF1E2620),
    SkDayPhase.afternoon: Color(0xFF262316),
    SkDayPhase.dusk: Color(0xFF281D1C),
    SkDayPhase.night: Color(0xFF0E1A22),
  };

  /// Vsetky odtiene (pre kontrastny test a galeriu).
  static Iterable<Color> allTints({required bool dark}) =>
      (dark ? _darkTints : _lightTints).values;
}

/// Hlavicka s atmosferou: zaobleny panel s gradientom podla casti dna
/// a geometrickym vzorom v hornom rohu (na strane konca, v RTL zrkadleny),
/// ktory sa strati skor, nez zacne text.
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
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [a.top, a.bottom],
        ),
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: Stack(
          children: [
            const PositionedDirectional(
              top: 0,
              end: 0,
              width: 200,
              height: 150,
              child: SkPatternField(opacity: 0.28, fadeStop: 0.8),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}
