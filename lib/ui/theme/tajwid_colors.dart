// Generovane z tabuliek docs/01 (U-01). Hodnoty menit len spolu s
// docs/01 a test/ui/theme/contrast_test.dart.
import 'package:flutter/material.dart';

/// Tajwid farby (docs/01 2.2). Renderuju sa iba na `surface` alebo `bg`.
@immutable
class TajwidColors extends ThemeExtension<TajwidColors> {
  const TajwidColors({
    required this.madd6,
    required this.madd45,
    required this.madd246,
    required this.madd2,
    required this.ghunna,
    required this.qalqala,
    required this.tafkhim,
    required this.silent,
  });

  static const light = TajwidColors(
    madd6: Color(0xFFA31515),
    madd45: Color(0xFFC0263A),
    madd246: Color(0xFFA84D00),
    madd2: Color(0xFF7D6400),
    ghunna: Color(0xFF276B2B),
    qalqala: Color(0xFF0B62A3),
    tafkhim: Color(0xFF1A3E8C),
    silent: Color(0xFF6A706C),
  );

  static const dark = TajwidColors(
    madd6: Color(0xFFFF8A80),
    madd45: Color(0xFFF7A1B0),
    madd246: Color(0xFFFFB070),
    madd2: Color(0xFFE3CC6E),
    ghunna: Color(0xFF7FD08A),
    qalqala: Color(0xFF7CC3F5),
    tafkhim: Color(0xFFA9BCF5),
    silent: Color(0xFF9AA19D),
  );

  /// Madd lazim (6 harakat).
  final Color madd6;

  /// Madd wajib muttasil (4-5).
  final Color madd45;

  /// Madd jaiz/arid (2, 4, 6).
  final Color madd246;

  /// Madd tabii (2).
  final Color madd2;

  /// Ghunna, ikhfa, iqlab, idgham s ghunnou.
  final Color ghunna;

  /// Qalqala.
  final Color qalqala;

  /// Tafkhim.
  final Color tafkhim;

  /// Neprecitane pismena.
  final Color silent;

  /// Vsetky tokeny podla mena (pre kontrastny test a legendu).
  Map<String, Color> asMap() => {
    'madd6': madd6,
    'madd45': madd45,
    'madd246': madd246,
    'madd2': madd2,
    'ghunna': ghunna,
    'qalqala': qalqala,
    'tafkhim': tafkhim,
    'silent': silent,
  };

  @override
  bool operator ==(Object other) =>
      other is TajwidColors &&
      other.madd6 == madd6 &&
      other.madd45 == madd45 &&
      other.madd246 == madd246 &&
      other.madd2 == madd2 &&
      other.ghunna == ghunna &&
      other.qalqala == qalqala &&
      other.tafkhim == tafkhim &&
      other.silent == silent;

  @override
  int get hashCode => Object.hashAll([
    madd6,
    madd45,
    madd246,
    madd2,
    ghunna,
    qalqala,
    tafkhim,
    silent,
  ]);

  @override
  TajwidColors copyWith({
    Color? madd6,
    Color? madd45,
    Color? madd246,
    Color? madd2,
    Color? ghunna,
    Color? qalqala,
    Color? tafkhim,
    Color? silent,
  }) => TajwidColors(
    madd6: madd6 ?? this.madd6,
    madd45: madd45 ?? this.madd45,
    madd246: madd246 ?? this.madd246,
    madd2: madd2 ?? this.madd2,
    ghunna: ghunna ?? this.ghunna,
    qalqala: qalqala ?? this.qalqala,
    tafkhim: tafkhim ?? this.tafkhim,
    silent: silent ?? this.silent,
  );

  @override
  TajwidColors lerp(covariant ThemeExtension<TajwidColors>? other, double t) {
    if (other is! TajwidColors) return this;
    return TajwidColors(
      madd6: Color.lerp(madd6, other.madd6, t)!,
      madd45: Color.lerp(madd45, other.madd45, t)!,
      madd246: Color.lerp(madd246, other.madd246, t)!,
      madd2: Color.lerp(madd2, other.madd2, t)!,
      ghunna: Color.lerp(ghunna, other.ghunna, t)!,
      qalqala: Color.lerp(qalqala, other.qalqala, t)!,
      tafkhim: Color.lerp(tafkhim, other.tafkhim, t)!,
      silent: Color.lerp(silent, other.silent, t)!,
    );
  }
}
