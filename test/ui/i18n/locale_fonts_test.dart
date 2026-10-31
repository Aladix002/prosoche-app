import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/ui/i18n/i18n.dart';

void main() {
  test('font family per language (v1: latin only)', () {
    for (final l in ProsocheLocales.all) {
      expect(LocaleFonts.forLocale(l), LocaleFonts.latin);
    }
    expect(LocaleFonts.forLanguage('de').family, ProsocheFontFamilies.inter);
  });

  test('scaleHeight respects minimum and null height', () {
    expect(LocaleFonts.latin.scaleHeight(null), isNull);
    expect(LocaleFonts.latin.scaleHeight(1.5), 1.5);
    const tall = LocaleFontSpec(
      family: 'X',
      fallback: [],
      lineHeightScale: 1.5,
      minLineHeight: 2.2,
    );
    expect(tall.scaleHeight(1), 2.2);
    expect(tall.scaleHeight(null), 2.2);
    expect(tall.scaleHeight(2), 3);
  });

  test('applyLocaleFont sets family, fallback and even leading', () {
    const base = TextStyle(fontSize: 16, height: 1.5, fontFamily: 'X');
    final en = applyLocaleFont(base, ProsocheLocales.en);
    expect(en.fontFamily, ProsocheFontFamilies.inter);
    expect(en.fontFamilyFallback, LocaleFonts.latin.fallback);
    expect(en.height, 1.5);
    expect(en.fontSize, 16);
    expect(en.leadingDistribution, TextLeadingDistribution.even);
  });

  test('applyLocaleFontToTextTheme maps every style', () {
    final theme = ThemeData(brightness: Brightness.light).textTheme;
    final en = applyLocaleFontToTextTheme(theme, ProsocheLocales.en);
    final styles = [
      en.displayLarge,
      en.displayMedium,
      en.displaySmall,
      en.headlineLarge,
      en.headlineMedium,
      en.headlineSmall,
      en.titleLarge,
      en.titleMedium,
      en.titleSmall,
      en.bodyLarge,
      en.bodyMedium,
      en.bodySmall,
      en.labelLarge,
      en.labelMedium,
      en.labelSmall,
    ];
    for (final s in styles) {
      expect(s!.fontFamily, ProsocheFontFamilies.inter);
    }
    final empty = applyLocaleFontToTextTheme(
      const TextTheme(),
      ProsocheLocales.en,
    );
    expect(empty.bodyLarge, isNull);
  });

  test('every UI font family is bundled in pubspec.yaml', () {
    // Nezhoda nazvu = tichy fallback na systemovy font (a v testoch na
    // testovaci font), goldeny by neodhalili zly font.
    final declared = {
      for (final m in RegExp(
        r'^\s*- family:\s*(.+?)\s*$',
        multiLine: true,
      ).allMatches(File('pubspec.yaml').readAsStringSync()))
        m[1],
    };
    expect(declared, {
      ProsocheFontFamilies.inter,
      ProsocheFontFamilies.serif,
      ProsocheFontFamilies.display,
    });
  });
}
