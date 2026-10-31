import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/ui/i18n/i18n.dart';

import 'golden.dart';

/// Vzorovy widget pre harness: texty z ARB (EN fallback), smerove
/// odsadenie, zrkadlena ikona a cas v cisliciach jazyka.
class _Sample extends StatelessWidget {
  const _Sample();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final time = ProsocheFormats(locale).time(DateTime(2026, 3, 7, 18, 5));
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 24, end: 8, top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.tabToday, style: Theme.of(context).textTheme.titleLarge),
          const Text('[PLACEHOLDER] A short sample sentence.'),
          Row(
            children: [
              Expanded(child: Text(l10n.tabPractice)),
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
    for (final locale in ProsocheLocales.all) {
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
          locale: ProsocheLocales.en,
          size: Size(200, 100),
          child: SizedBox.expand(),
        ),
      );
      expect(tester.getSize(find.byType(Material)), const Size(200, 100));
    });
  });

  test('goldenScenarioName', () {
    expect(
      goldenScenarioName(ProsocheLocales.en, Brightness.dark, 2),
      'en dark x2.0',
    );
    expect(fullGoldenLocales.length + smokeLocales.length, 1);
  });

  group('EN at textScale 2.0 is not clipped', () {
    // Realne fonty, nie testovaci font.
    setUpAll(loadProsocheFonts);
    final strings = _enStrings();
    test('ARB template has strings', () => expect(strings, isNotEmpty));

    testWidgets('all ARB strings in list tiles and buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        LocalizedTestApp(
          locale: ProsocheLocales.en,
          textScale: 2,
          size: const Size(360, 640),
          child: ListView(
            children: [
              for (final MapEntry(:key, :value) in strings.entries) ...[
                ListTile(
                  key: ValueKey(key),
                  title: Text(value),
                  trailing: const DirectionalIcon(Icons.chevron_right),
                ),
                FilledButton(onPressed: () {}, child: Text(value)),
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
  });

  testWidgets('expectNoTextClipping detects an ellipsized text', (
    tester,
  ) async {
    await tester.pumpWidget(
      const LocalizedTestApp(
        locale: ProsocheLocales.en,
        textScale: 2,
        size: Size(360, 640),
        child: SizedBox(
          width: 100,
          child: Text(
            'A long sentence that will never fit into one short line here.',
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
      const LocalizedTestApp(
        locale: ProsocheLocales.en,
        textScale: 2,
        size: Size(360, 640),
        child: SizedBox(
          width: 100,
          child: Row(
            children: [
              Text('A long sentence that overflows a narrow row for sure.'),
            ],
          ),
        ),
      ),
    );
    expect(() => expectNoTextClipping(tester), throwsA(isA<TestFailure>()));
  });
}
