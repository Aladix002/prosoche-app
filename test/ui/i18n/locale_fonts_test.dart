import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/ui/i18n/i18n.dart';

void main() {
  test('font family per language', () {
    expect(
      {
        for (final l in ProsocheLocales.all)
          l.languageCode: LocaleFonts.forLocale(l).family,
      },
      {
        'en': 'Inter',
        'ar': 'NotoNaskhArabic',
        'id': 'Inter',
        'ur': 'NotoNastaliqUrdu',
        'bn': 'NotoSansBengali',
        'tr': 'Inter',
      },
    );
  });

  test('Nastaliq gets the tallest line height', () {
    double h(Locale l) => LocaleFonts.forLocale(l).scaleHeight(1.5)!;
    expect(h(ProsocheLocales.en), 1.5);
    expect(h(ProsocheLocales.ur), greaterThan(h(ProsocheLocales.ar)));
    expect(h(ProsocheLocales.ur), greaterThan(h(ProsocheLocales.bn)));
    expect(h(ProsocheLocales.ur), greaterThanOrEqualTo(2.2));
    expect(h(ProsocheLocales.bn), greaterThan(h(ProsocheLocales.en)));
  });

  test('scaleHeight respects minimum and null height', () {
    expect(LocaleFonts.urdu.scaleHeight(1), 2.2);
    expect(LocaleFonts.urdu.scaleHeight(null), 2.2);
    expect(LocaleFonts.latin.scaleHeight(null), isNull);
    expect(LocaleFonts.arabic.scaleHeight(2), closeTo(2.3, 1e-9));
  });

  test('every spec has a fallback with Latin coverage or Arabic', () {
    for (final l in ProsocheLocales.all) {
      final spec = LocaleFonts.forLocale(l);
      expect(spec.fallback, isNotEmpty);
      expect(spec.fallback, isNot(contains(spec.family)));
    }
  });

  test('applyLocaleFont sets family, fallback and even leading', () {
    const base = TextStyle(fontSize: 16, height: 1.5, fontFamily: 'X');
    final ur = applyLocaleFont(base, ProsocheLocales.ur);
    expect(ur.fontFamily, ProsocheFontFamilies.notoNastaliqUrdu);
    expect(ur.fontFamilyFallback, LocaleFonts.urdu.fallback);
    expect(ur.height, 2.25);
    expect(ur.fontSize, 16);
    expect(ur.leadingDistribution, TextLeadingDistribution.even);
  });

  test('applyLocaleFontToTextTheme maps every style', () {
    final theme = ThemeData(brightness: Brightness.light).textTheme;
    final bn = applyLocaleFontToTextTheme(theme, ProsocheLocales.bn);
    final styles = [
      bn.displayLarge,
      bn.displayMedium,
      bn.displaySmall,
      bn.headlineLarge,
      bn.headlineMedium,
      bn.headlineSmall,
      bn.titleLarge,
      bn.titleMedium,
      bn.titleSmall,
      bn.bodyLarge,
      bn.bodyMedium,
      bn.bodySmall,
      bn.labelLarge,
      bn.labelMedium,
      bn.labelSmall,
    ];
    for (final s in styles) {
      expect(s!.fontFamily, ProsocheFontFamilies.notoSansBengali);
    }
    final empty = applyLocaleFontToTextTheme(
      const TextTheme(),
      ProsocheLocales.bn,
    );
    expect(empty.bodyLarge, isNull);
  });

  test('every UI font family is bundled in pubspec.yaml', () {
    // Nezhoda nazvu = tichy fallback na systemovy font (a v testoch na
    // testovaci font), goldeny by neodhalili zly font.
    final declared = {
      for (final m in RegExp(
        r'^\s*- family:\s*(\S+)\s*$',
        multiLine: true,
      ).allMatches(File('pubspec.yaml').readAsStringSync()))
        m[1],
    };
    final used = {
      for (final spec in [
        LocaleFonts.latin,
        LocaleFonts.arabic,
        LocaleFonts.urdu,
        LocaleFonts.bengali,
      ]) ...[spec.family, ...spec.fallback],
      ProsocheFontFamilies.literata,
    };
    expect(declared, containsAll(used));
  });
}
