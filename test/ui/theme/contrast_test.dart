import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/ui/motif/sk_atmosphere.dart';
import 'package:prosoche/ui/theme/contrast.dart';
import 'package:prosoche/ui/theme/prosoche_colors.dart';

/// Kontrastny test z tokenov (docs/01 2.1.3, D10). Kazda nova kombinacia
/// farieb v komponentoch sa prida sem.
void main() {
  test('formula matches values computed in docs/01 2.1.3', () {
    const l = ProsocheColors.light;
    const d = ProsocheColors.dark;
    expect(SkContrast.ratio(l.textPrimary, l.bg), closeTo(13.37, 0.01));
    expect(SkContrast.ratio(l.outlineStrong, l.bg), closeTo(3.48, 0.01));
    expect(SkContrast.ratio(l.onPrimary, l.primary), closeTo(7.53, 0.01));
    expect(SkContrast.ratio(d.textTertiary, d.surfaceAlt), closeTo(4.91, 0.01));
    expect(SkContrast.ratio(d.lead, d.bg), closeTo(15.56, 0.01));
    // Symetria.
    expect(
      SkContrast.ratio(l.bg, l.textPrimary),
      SkContrast.ratio(l.textPrimary, l.bg),
    );
  });

  final themes = <String, ProsocheColors>{
    'light': ProsocheColors.light,
    'dark': ProsocheColors.dark,
    'light high contrast': ProsocheColors.lightHighContrast,
    'dark high contrast': ProsocheColors.darkHighContrast,
  };

  for (final MapEntry(key: name, value: c) in themes.entries) {
    group('$name theme', () {
      final backgrounds = {
        'bg': c.bg,
        'surface': c.surface,
        'surfaceAlt': c.surfaceAlt,
      };

      final textTokens = {
        'textPrimary': c.textPrimary,
        'textSecondary': c.textSecondary,
        'textTertiary': c.textTertiary,
        'lead': c.lead,
        'primary': c.primary,
        'accentText': c.accentText,
        'error': c.error,
        'success': c.success,
        'warning': c.warning,
      };

      // (popredie, pozadie, minimum)
      final pairs = <String, (Color, Color, double)>{
        for (final MapEntry(key: fg, value: f) in textTokens.entries)
          for (final MapEntry(key: bg, value: b) in backgrounds.entries)
            '$fg / $bg': (f, b, SkContrast.text),
        for (final MapEntry(key: bg, value: b) in backgrounds.entries)
          'outlineStrong / $bg (UI)': (c.outlineStrong, b, SkContrast.nonText),
        'onPrimary / primary': (c.onPrimary, c.primary, SkContrast.text),
        'onPrimaryContainer / primaryContainer': (
          c.onPrimaryContainer,
          c.primaryContainer,
          SkContrast.text,
        ),
        'textPrimary / primaryContainer': (
          c.textPrimary,
          c.primaryContainer,
          SkContrast.text,
        ),
        'textSecondary / primaryContainer': (
          c.textSecondary,
          c.primaryContainer,
          SkContrast.text,
        ),
        'primary / primaryContainer (progress)': (
          c.primary,
          c.primaryContainer,
          SkContrast.nonText,
        ),
        'onError / error': (c.onError, c.error, SkContrast.text),
        'onErrorContainer / errorContainer': (
          c.onErrorContainer,
          c.errorContainer,
          SkContrast.text,
        ),
        'onWarningContainer / warningContainer': (
          c.onWarningContainer,
          c.warningContainer,
          SkContrast.text,
        ),
        'onInverseSurface / inverseSurface': (
          c.onInverseSurface,
          c.inverseSurface,
          SkContrast.text,
        ),
        'inversePrimary / inverseSurface': (
          c.inversePrimary,
          c.inverseSurface,
          SkContrast.text,
        ),
        'focusRing / bg (UI)': (c.focusRing, c.bg, SkContrast.nonText),
        'focusRing / surface (UI)': (
          c.focusRing,
          c.surface,
          SkContrast.nonText,
        ),
      };

      for (final MapEntry(key: label, value: (fg, bg, min)) in pairs.entries) {
        test('$label >= $min', () {
          final ratio = SkContrast.ratio(fg, bg);
          expect(
            ratio,
            greaterThanOrEqualTo(min),
            reason: '$label = ${ratio.toStringAsFixed(2)}',
          );
        });
      }

      test('every color token is checked or explicitly exempt', () {
        const exempt = {
          // Pozadia (su na druhej strane parov).
          'bg', 'surface', 'surfaceAlt',
          // Disabled = WCAG vynimka; scrim nie je text.
          'textDisabled', 'scrim',
          // Pozadia kontajnerov, overene cez on* pary.
          'primaryContainer', 'errorContainer', 'warningContainer',
          'inverseSurface',
        };
        final checked = {
          ...textTokens.keys,
          'outlineStrong',
          'onPrimary',
          'onPrimaryContainer',
          'onError',
          'onErrorContainer',
          'onWarningContainer',
          'onInverseSurface',
          'inversePrimary',
          'focusRing',
        };
        final missing = c.asMap().keys.toSet()
          ..removeAll(checked)
          ..removeAll(exempt)
          ..removeAll(ProsocheColors.decorativeOnly);
        expect(missing, isEmpty);
      });
    });
  }

  // D-05: atmosfera hlavicky (gradient podla casti dna). Text lezi na
  // hornom odtieni aj na spodnom `surface`; oba musia drzat AA.
  for (final MapEntry(key: name, value: c) in themes.entries) {
    group('$name atmosphere', () {
      for (final phase in SkDayPhase.values) {
        final a = SkAtmosphereColors.of(phase, c);
        final fg = {
          'textPrimary': c.textPrimary,
          'textSecondary': c.textSecondary,
          'textTertiary': c.textTertiary,
          'primary': c.primary,
          'accentText': c.accentText,
        };
        for (final MapEntry(key: token, value: f) in fg.entries) {
          for (final (where, bg) in [('top', a.top), ('bottom', a.bottom)]) {
            test('$token / ${phase.name} $where >= ${SkContrast.text}', () {
              final ratio = SkContrast.ratio(f, bg);
              expect(
                ratio,
                greaterThanOrEqualTo(SkContrast.text),
                reason: ratio.toStringAsFixed(2),
              );
            });
          }
        }
        // Tlacidlo (primary) musi byt odlisitelne od pozadia (UI 3:1).
        test('primary button / ${phase.name} top (UI)', () {
          expect(
            SkContrast.ratio(c.primary, a.top),
            greaterThanOrEqualTo(SkContrast.nonText),
          );
        });
      }
    });
  }

  test('high contrast variants follow docs/01 8.5', () {
    for (final (base, hc) in [
      (ProsocheColors.light, ProsocheColors.lightHighContrast),
      (ProsocheColors.dark, ProsocheColors.darkHighContrast),
    ]) {
      expect(hc.textSecondary, base.textPrimary);
      expect(
        SkContrast.ratio(hc.outlineStrong, hc.bg),
        greaterThan(SkContrast.ratio(base.outlineStrong, base.bg)),
      );
    }
  });
}
