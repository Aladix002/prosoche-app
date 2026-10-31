import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/ui/i18n/i18n.dart';

import 'golden.dart';

/// Vzorovy widget pre harness: texty z ARB (EN fallback), smerove
/// odsadenie, zrkadlena ikona a cas v cisliciach jazyka.
class _Sample extends StatelessWidget {
  const _Sample();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final time = SakinaFormats(locale).time(DateTime(2026, 3, 7, 18, 5));
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 24, end: 8, top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.feedTitle, style: Theme.of(context).textTheme.titleLarge),
          Text(PseudoLocale.sentence(locale, words: 5)),
          Row(
            children: [
              Expanded(child: Text(l10n.tabPrayer)),
              Text(time),
              const DirectionalIcon(Icons.chevron_right),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Vsetky EN texty z ARB sablony (bez metadat).
Map<String, String> _enStrings() {
  final json = jsonDecode(
    File('lib/l10n/app_en.arb').readAsStringSync(),
  ) as Map<String, dynamic>;
  return {
    for (final MapEntry(:key, :value) in json.entries)
      if (!key.startsWith('@') && value is String) key: value,
  };
}

void main() {
  goldenAllLocales(
    'harness sample',
    fileName: 'harness_sample',
    textScales: cardTextScales,
    builder: (_) => const _Sample(),
  );

  group('LocalizedTestApp', () {
    for (final locale in SakinaLocales.all) {
      testWidgets('${locale.languageCode}: locale, direction, font, scale', (
        tester,
      ) async {
        late BuildContext ctx;
        await tester.pumpWidget(
          LocalizedTestApp(
            locale: locale,
            brightness: Brightness.dark,
            textScale: 2,
            child: Builder(
              builder: (context) {
                ctx = context;
                return const SizedBox();
              },
            ),
          ),
        );
        expect(Localizations.localeOf(ctx), locale);
        expect(Directionality.of(ctx), textDirectionForLocale(locale));
        expect(Theme.of(ctx).brightness, Brightness.dark);
        expect(
          Theme.of(ctx).textTheme.bodyMedium!.fontFamily,
          LocaleFonts.forLocale(locale).family,
        );
        expect(MediaQuery.textScalerOf(ctx).scale(10), 20);
        expect(AppLocalizations.of(ctx).tabToday, isNotEmpty);
      });
    }

    testWidgets('size constrains the surface', (tester) async {
      await tester.pumpWidget(
        const LocalizedTestApp(
          locale: SakinaLocales.en,
          size: Size(200, 100),
          child: SizedBox.expand(),
        ),
      );
      expect(tester.getSize(find.byType(Material)), const Size(200, 100));
    });
  });

  test('goldenScenarioName', () {
    expect(
      goldenScenarioName(SakinaLocales.ur, Brightness.dark, 2),
      'ur dark x2.0',
    );
    expect(fullGoldenLocales.length + smokeLocales.length, 6);
  });

  group('PseudoLocale', () {
    test('uses the script of the locale and keeps placeholders', () {
      const src = 'Hello {name}, 3 cards';
      final ur = PseudoLocale.localize(src, SakinaLocales.ur);
      final bn = PseudoLocale.localize(src, SakinaLocales.bn);
      final ar = PseudoLocale.localize(src, SakinaLocales.ar);
      final tr = PseudoLocale.localize(src, SakinaLocales.tr);
      final en = PseudoLocale.localize(src, SakinaLocales.en);
      for (final s in [ur, bn, ar, tr, en]) {
        expect(s, startsWith('['));
        expect(s, endsWith(']'));
        expect(s, contains('{name}'));
        expect(s, contains('3'));
        expect(s.length, greaterThan(src.length * 1.3));
      }
      expect(RegExp('[؀-ۿ]').hasMatch(ur), isTrue);
      expect(RegExp('[؀-ۿ]').hasMatch(ar), isTrue);
      expect(RegExp('[ঀ-৿]').hasMatch(bn), isTrue);
      expect(RegExp('[ğüşıöçĞÜŞİÖÇ]').hasMatch(tr), isTrue);
      expect(en, isNot(contains('Hello')));
    });

    test('never produces Arabic alif, lam or ha', () {
      final all = [
        for (final l in SakinaLocales.all) PseudoLocale.sentence(l, words: 40),
      ].join();
      expect(all, isNot(matches('[اله]')));
    });

    test('empty input stays empty inside brackets', () {
      expect(PseudoLocale.localize('', SakinaLocales.ar), '[]');
    });
  });

  group('UR and BN at textScale 2.0 are not clipped', () {
    // Realne fonty (Nastaliq ma najvacsiu vysku), nie testovaci font.
    setUpAll(loadSakinaFonts);
    final strings = _enStrings();
    test('ARB template has strings', () => expect(strings, isNotEmpty));

    for (final locale in [
      SakinaLocales.ur,
      SakinaLocales.bn,
      SakinaLocales.ar,
    ]) {
      testWidgets(locale.languageCode, (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          LocalizedTestApp(
            locale: locale,
            textScale: 2,
            size: const Size(360, 640),
            child: ListView(
              children: [
                for (final MapEntry(:key, :value) in strings.entries) ...[
                  ListTile(
                    key: ValueKey(key),
                    title: Text(PseudoLocale.localize(value, locale)),
                    trailing: const DirectionalIcon(Icons.chevron_right),
                  ),
                  FilledButton(
                    onPressed: () {},
                    child: Text(PseudoLocale.localize(value, locale)),
                  ),
                ],
              ],
            ),
          ),
        );
        expectNoTextClipping(tester);
        expect(
          tester.renderObject<RenderBox>(find.byType(ListTile).first).size,
          isNot(Size.zero),
        );
      });
    }
  });

  testWidgets('expectNoTextClipping detects an ellipsized text', (
    tester,
  ) async {
    await tester.pumpWidget(
      LocalizedTestApp(
        locale: SakinaLocales.ur,
        textScale: 2,
        child: SizedBox(
          width: 100,
          child: Text(
            PseudoLocale.sentence(SakinaLocales.ur, words: 20),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
    expect(() => expectNoTextClipping(tester), throwsA(isA<TestFailure>()));
  });

  testWidgets('expectNoTextClipping detects a layout overflow', (tester) async {
    await tester.pumpWidget(
      LocalizedTestApp(
        locale: SakinaLocales.bn,
        textScale: 2,
        child: SizedBox(
          width: 100,
          child: Row(children: [Text(PseudoLocale.sentence(SakinaLocales.bn))]),
        ),
      ),
    );
    expect(() => expectNoTextClipping(tester), throwsA(isA<TestFailure>()));
  });
}
