import 'dart:async';
import 'dart:convert';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/ui/i18n/i18n.dart';

/// Tema pre golden. Kym U-01 nedoda temu, default je cisty Material 3.
typedef GoldenThemeBuilder = ThemeData Function(Brightness brightness);

ThemeData _defaultTheme(Brightness brightness) =>
    ThemeData(brightness: brightness, colorSchemeSeed: const Color(0xFF2E6B5E));

/// Nacita pribalene fonty z `FontManifest.json` (Inter, Literata), aby
/// widget testy merali text realnymi fontmi a nie testovacim fontom.
/// Alchemist to robi sam len pred `goldenTest`; widget testy (napr.
/// `expectNoTextClipping`) by inak zaviseli od poradia testov v subore.
Future<void> loadProsocheFonts() async {
  final manifest = jsonDecode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

/// Jazyky pre goldeny: v1 len EN (PLAN.md). Dalsie jazyky sa pridaju
/// s prekladmi; smoke jazyky maju len svetlu temu a 1.0.
const List<Locale> fullGoldenLocales = [ProsocheLocales.en];

const List<Locale> smokeLocales = <Locale>[];

/// textScale pre obrazovky; karty pridavaju 1.5 ([cardTextScales]).
const List<double> screenTextScales = [1.0, 2.0];
const List<double> cardTextScales = [1.0, 1.5, 2.0];

const List<Brightness> bothBrightness = [Brightness.light, Brightness.dark];

/// Obali [child] do lokalizacie, smeru, temy s fontom jazyka a textScale
/// bez `MaterialApp` (bez routera). Pouzitelne v goldenoch aj widget
/// testoch.
class LocalizedTestApp extends StatelessWidget {
  const LocalizedTestApp({
    required this.locale,
    required this.child,
    super.key,
    this.brightness = Brightness.light,
    this.textScale = 1.0,
    this.theme = _defaultTheme,
    this.size,
  });

  final Locale locale;
  final Brightness brightness;
  final double textScale;
  final GoldenThemeBuilder theme;

  /// Velkost plochy (napr. 360x640 pre obrazovku); null = podla obsahu.
  final Size? size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = theme(brightness);
    final data = base.copyWith(
      textTheme: applyLocaleFontToTextTheme(base.textTheme, locale),
    );
    Widget content = Material(child: child);
    if (size != null) {
      content = Align(
        alignment: AlignmentDirectional.topStart,
        child: SizedBox.fromSize(size: size, child: content),
      );
    }
    return MediaQuery(
      data: MediaQueryData(
        size: size ?? const Size(360, 640),
        textScaler: TextScaler.linear(textScale),
      ),
      child: Localizations(
        locale: locale,
        delegates: AppLocalizations.localizationsDelegates,
        // Localizations vlozi Directionality podla jazyka.
        child: Theme(data: data, child: content),
      ),
    );
  }
}

/// Nazov scenara v golden obrazku, napr. `ar dark x2.0`.
String goldenScenarioName(
  Locale locale,
  Brightness brightness,
  double textScale,
) => '${locale.languageCode} ${brightness.name} x$textScale';

/// Golden test pre jazyky x tema x textScale (PLAN_VYVOJA U-02).
///
/// Pre kazdy jazyk z [locales] vznikne jeden golden subor
/// `goldens/ci/<fileName>_<lang>.png` s mriezkou [brightness] x
/// [textScales]. Jazyky zo [smokeLocales] maju len svetlu temu a 1.0.
///
/// Pouzite CI goldeny alchemistu (text zakryty blokmi); platform goldeny
/// su vypnute. Layout textu meraju pribalene fonty z `assets/fonts/`
/// (rovnake TTF na kazdom stroji, flutter_tester nepouziva systemove
/// fonty), takze obrazky su deterministicke. Rodiny z [LocaleFonts]
/// musia byt v pubspec.yaml (test/ui/i18n/locale_fonts_test.dart).
@isTestGroup
void goldenAllLocales(
  String description, {
  required String fileName,
  required WidgetBuilder builder,
  List<Locale> locales = ProsocheLocales.all,
  List<Brightness> brightness = bothBrightness,
  List<double> textScales = screenTextScales,
  GoldenThemeBuilder theme = _defaultTheme,
  BoxConstraints constraints = const BoxConstraints(maxWidth: 360),
  int columns = 2,
  List<String> tags = const ['golden'],
}) {
  final config = AlchemistConfig.current().merge(
    const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: false),
    ),
  );
  group(description, () {
    for (final locale in locales) {
      final smoke = smokeLocales.contains(locale);
      final variants = [
        for (final b in smoke ? [Brightness.light] : brightness)
          for (final s in smoke ? [1.0] : textScales) (b, s),
      ];
      AlchemistConfig.runWithConfig(
        config: config,
        run: () => unawaited(
          goldenTest(
            locale.languageCode,
            fileName: '${fileName}_${locale.languageCode}',
            tags: tags,
            builder: () => GoldenTestGroup(
              columns: variants.length < columns ? variants.length : columns,
              children: [
                for (final (b, s) in variants)
                  GoldenTestScenario(
                    name: goldenScenarioName(locale, b, s),
                    constraints: constraints,
                    child: LocalizedTestApp(
                      locale: locale,
                      brightness: b,
                      textScale: s,
                      theme: theme,
                      child: Builder(builder: builder),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
  });
}
