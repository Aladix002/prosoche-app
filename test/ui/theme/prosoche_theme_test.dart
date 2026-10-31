import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/ui/ui.dart';

import '../helpers/pump_sk.dart';

void main() {
  group('ProsocheTheme', () {
    test('ColorScheme is composed from tokens, not fromSeed (D10)', () {
      for (final (theme, c) in [
        (ProsocheTheme.light(), ProsocheColors.light),
        (ProsocheTheme.dark(), ProsocheColors.dark),
      ]) {
        final s = theme.colorScheme;
        expect(s.primary, c.primary);
        expect(s.onPrimary, c.onPrimary);
        expect(s.primaryContainer, c.primaryContainer);
        expect(s.surface, c.bg);
        expect(s.surfaceContainerLowest, c.surface);
        expect(s.surfaceContainerHigh, c.surfaceAlt);
        expect(s.onSurface, c.textPrimary);
        expect(s.onSurfaceVariant, c.textSecondary);
        expect(s.tertiary, c.accentText);
        expect(s.outline, c.outlineStrong);
        expect(s.outlineVariant, c.outline);
        expect(s.error, c.error);
        expect(s.inverseSurface, c.inverseSurface);
        expect(s.surfaceTint.a, 0);
        expect(theme.scaffoldBackgroundColor, c.bg);
        expect(theme.cardTheme.elevation, 0);
      }
    });

    test('brightness and extensions', () {
      final light = ProsocheTheme.light();
      final dark = ProsocheTheme.dark();
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.extension<ProsocheColors>(), ProsocheColors.light);
      expect(dark.extension<ProsocheColors>(), ProsocheColors.dark);
      expect(light.extension<ProsocheTypography>(), isNotNull);
      expect(light.extension<ProsocheSpacing>(), isNotNull);
      expect(light.extension<ProsocheMotion>(), ProsocheMotion.standard);
    });

    test('options: high contrast, reduce motion, font', () {
      final t = ProsocheTheme.light(
        highContrast: true,
        reduceMotion: true,
        uiFontFamily: SkFonts.literata,
        uiHeightFactor: 1.2,
      );
      expect(t.extension<ProsocheColors>(), ProsocheColors.lightHighContrast);
      expect(t.extension<ProsocheMotion>()!.reduced, isTrue);
      expect(t.textTheme.bodyLarge!.fontFamily, SkFonts.literata);
      expect(t.textTheme.bodyLarge!.height, closeTo(24 / 16 * 1.2, 1e-9));
      expect(
        ProsocheTheme.dark(highContrast: true).extension<ProsocheColors>(),
        ProsocheColors.darkHighContrast,
      );
    });

    test('UI type scale follows docs/01 2.3.2', () {
      final t = ProsocheTheme.light().textTheme;
      void check(TextStyle? s, double size, double line, FontWeight w) {
        expect(s!.fontSize, size);
        expect(s.height! * size, closeTo(line, 1e-9));
        expect(s.fontWeight, w);
        expect(s.fontFamily, SkFonts.inter);
        expect(s.fontFamilyFallback, SkFonts.uiFallback);
      }

      check(t.displaySmall, 34, 40, FontWeight.w600);
      check(t.headlineSmall, 26, 32, FontWeight.w600);
      check(t.titleLarge, 20, 28, FontWeight.w600);
      check(t.titleMedium, 17, 24, FontWeight.w500);
      check(t.bodyLarge, 16, 24, FontWeight.w400);
      check(t.bodyMedium, 14, 20, FontWeight.w400);
      check(t.labelLarge, 14, 20, FontWeight.w500);
      check(t.labelSmall, 12, 16, FontWeight.w500);
      check(t.bodySmall, 12, 16, FontWeight.w400);
      // Minimum 12 sp.
      for (final s in [
        t.displayLarge,
        t.displayMedium,
        t.headlineLarge,
        t.headlineMedium,
        t.titleSmall,
        t.labelMedium,
      ]) {
        expect(s!.fontSize, greaterThanOrEqualTo(12));
      }
    });
  });

  group('typography tokens', () {
    final type = ProsocheTypography.forColor(const Color(0xFF000000));

    test('reading tokens use Literata', () {
      expect(type.translation.fontFamily, SkFonts.literata);
      expect(type.translation.fontSize, 18);
      expect(type.reflection.fontSize, 19);
      expect(type.translationReader.fontSize, 17);
    });

    test('tabular figures', () {
      final s = ProsocheTypography.tabular(const TextStyle());
      expect(s.fontFeatures, [const FontFeature.tabularFigures()]);
    });

    test('copyWith and lerp', () {
      final other = ProsocheTypography.forColor(const Color(0xFFFFFFFF));
      expect(type.copyWith(), isA<ProsocheTypography>());
      expect(
        type.copyWith(reflection: other.reflection).reflection,
        other.reflection,
      );
      expect(type.lerp(other, 1).translation.color, const Color(0xFFFFFFFF));
      expect(type.lerp(null, 0.5), same(type));
    });
  });

  group('extensions copyWith/lerp', () {
    test('ProsocheColors', () {
      const l = ProsocheColors.light;
      const d = ProsocheColors.dark;
      expect(l.lerp(d, 0), l);
      expect(l.lerp(d, 1), d);
      expect(l.lerp(null, 0.5), same(l));
      expect(l.copyWith(), l);
      expect(l.copyWith(bg: d.bg).bg, d.bg);
      expect(l.asMap(), hasLength(29));
    });

    test('ProsocheMotion', () {
      const m = ProsocheMotion.standard;
      expect(m.medium.duration, const Duration(milliseconds: 300));
      expect(m.long.duration, const Duration(milliseconds: 450));
      expect(m.calm.duration, const Duration(milliseconds: 800));
      expect(m.copyWith(reduced: true), ProsocheMotion.reducedMotion);
      expect(m.copyWith(), m);
      expect(m.lerp(ProsocheMotion.reducedMotion, 0.2), m);
      expect(
        m.lerp(ProsocheMotion.reducedMotion, 0.8),
        ProsocheMotion.reducedMotion,
      );
      const r = ProsocheMotion.reducedMotion;
      for (final t in [r.instant, r.short, r.medium, r.long, r.calm, r.exit]) {
        expect(t.duration, Duration.zero);
      }
      expect(r.crossfade.duration, const Duration(milliseconds: 150));
      expect(m.short == SkMotionToken(m.short.duration, m.short.curve), isTrue);
      expect(m.short.hashCode, m.short.hashCode);
    });

    test('ProsocheSpacing and SkSpace', () {
      const s = ProsocheSpacing();
      expect(s.gutter(360), 16);
      expect(s.gutter(700), 24);
      expect(s.copyWith(gutterPhone: 12).gutterPhone, 12);
      expect(s.copyWith().maxContentWidth, 640);
      expect(s.lerp(s.copyWith(gutterPhone: 8), 1).gutterPhone, 8);
      expect(s.lerp(null, 1), same(s));
      expect(SkSpace.gutterFor(599), 16);
      expect(SkSpace.gutterFor(600), 24);
    });
  });

  group('context.sk', () {
    testWidgets('falls back to defaults without extensions', (tester) async {
      late SkTokens sk;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (context) {
              sk = context.sk;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(sk.colors, ProsocheColors.dark);
      expect(sk.type.translation.fontSize, 18);
      expect(sk.space.gutterPhone, 16);
      expect(sk.motion, ProsocheMotion.standard);
      expect(sk.largeText, isFalse);
    });

    testWidgets('motion is reduced by system setting', (tester) async {
      late SkTokens sk;
      await tester.pumpSk(
        Builder(
          builder: (context) {
            sk = context.sk;
            return const SizedBox();
          },
        ),
        disableAnimations: true,
        textScale: 1.3,
      );
      expect(sk.motion.reduced, isTrue);
      expect(sk.largeText, isTrue);
      expect(sk.text.bodyLarge!.fontSize, 16);
    });
  });

  group('SkTextScaling', () {
    testWidgets('clamps UI to 2.0 but keeps unclamped scaler', (tester) async {
      late TextScaler clamped;
      late TextScaler unclamped;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(3)),
          child: SkTextScaling(
            child: Builder(
              builder: (context) {
                clamped = MediaQuery.textScalerOf(context);
                unclamped = SkTextScaling.unclampedOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(clamped.scale(10), 20);
      expect(unclamped.scale(10), 30);
    });

    testWidgets('without SkTextScaling falls back to MediaQuery', (
      tester,
    ) async {
      late TextScaler unclamped;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Builder(
            builder: (context) {
              unclamped = SkTextScaling.unclampedOf(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(unclamped.scale(10), 15);
    });
  });

  testWidgets('fade page transition respects reduce motion', (tester) async {
    const builder = SkFadePageTransitionsBuilder();
    expect(builder.transitionDuration, const Duration(milliseconds: 450));
    final route = MaterialPageRoute<void>(builder: (_) => const SizedBox());
    for (final disable in [false, true]) {
      late Widget built;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: disable),
          child: Builder(
            builder: (context) => built = builder.buildTransitions(
              route,
              context,
              kAlwaysCompleteAnimation,
              kAlwaysDismissedAnimation,
              const Text('x', textDirection: TextDirection.ltr),
            ),
          ),
        ),
      );
      expect(built is FadeTransition, !disable);
    }
    route.dispose();
  });

  group('fonts', () {
    test('every declared font file and OFL.txt exists', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final assets = RegExp(r'asset: (assets/fonts/\S+)')
          .allMatches(pubspec)
          .map((m) => m.group(1)!)
          .toList();
      expect(assets, isNotEmpty);
      for (final a in assets) {
        expect(File(a).existsSync(), isTrue, reason: a);
      }
      for (final dir in SkFonts.licenseDirs.values) {
        final ofl = File('assets/fonts/$dir/OFL.txt');
        expect(ofl.existsSync(), isTrue, reason: dir);
        expect(ofl.readAsStringSync(), contains('SIL Open Font License'));
      }
      for (final family in [SkFonts.inter, SkFonts.literata]) {
        expect(pubspec, contains('family: $family'));
      }
    });

    testWidgets('font licenses are registered', (tester) async {
      registerProsocheFontLicenses();
      final entries = await tester.runAsync(
        () => LicenseRegistry.licenses.toList(),
      );
      final packages = entries!.expand((e) => e.packages).toSet();
      for (final name in SkFonts.licenseDirs.keys) {
        expect(packages, contains('font: $name'));
      }
    });
  });
}
