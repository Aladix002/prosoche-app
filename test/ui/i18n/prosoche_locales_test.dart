import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/ui/i18n/i18n.dart';

import '../../helpers/pump_app.dart';

void main() {
  test('generated supportedLocales match ProsocheLocales.all', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
      ProsocheLocales.all.map((l) => l.languageCode).toSet(),
    );
    expect(ProsocheLocales.all, hasLength(6));
  });

  test('every locale falls back to the EN template text', () {
    final en = lookupAppLocalizations(ProsocheLocales.en);
    for (final locale in ProsocheLocales.all) {
      final l10n = lookupAppLocalizations(locale);
      expect(l10n.localeName, locale.languageCode);
      // Kym ludia nedodaju preklad, nikdy prazdny retazec (docs/04 5.1).
      expect(l10n.tabToday, isNotEmpty);
      expect(l10n.errorGeneric, isNotEmpty);
      if (locale == ProsocheLocales.en) expect(l10n.tabToday, en.tabToday);
    }
  });

  test('RTL only for ar and ur', () {
    expect(
      [for (final l in ProsocheLocales.all) ProsocheLocales.isRtl(l)],
      [false, true, false, true, false, false],
    );
    expect(textDirectionForLocale(ProsocheLocales.ur), TextDirection.rtl);
    expect(textDirectionForLocale(ProsocheLocales.tr), TextDirection.ltr);
    expect(textDirectionForLanguage('ar'), TextDirection.rtl);
    expect(textDirectionForLanguage('en'), TextDirection.ltr);
  });

  group('resolve', () {
    test('stored choice wins', () {
      expect(
        ProsocheLocales.resolve(
          stored: 'bn',
          deviceLocales: const [Locale('ar')],
        ),
        ProsocheLocales.bn,
      );
    });

    test('unknown stored value falls through to device locales', () {
      expect(
        ProsocheLocales.resolve(
          stored: 'bs',
          deviceLocales: const [Locale('de'), Locale('ar', 'EG')],
        ),
        ProsocheLocales.ar,
      );
    });

    test('falls back to en', () {
      expect(ProsocheLocales.resolve(), ProsocheLocales.en);
      expect(
        ProsocheLocales.resolve(deviceLocales: const [Locale('sk')]),
        ProsocheLocales.en,
      );
    });

    test('isSupported ignores the region', () {
      expect(ProsocheLocales.isSupported(const Locale('ur', 'PK')), isTrue);
      expect(ProsocheLocales.isSupported(const Locale('bs')), isFalse);
    });
  });

  group('app follows the device locale', () {
    for (final locale in ProsocheLocales.all) {
      testWidgets('${locale.languageCode} sets direction', (tester) async {
        tester.platformDispatcher.localesTestValue = [locale];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        await tester.pumpProsoche();

        final context = tester.element(navBar);
        expect(Localizations.localeOf(context), locale);
        expect(Directionality.of(context), textDirectionForLocale(locale));
        // EN fallback textu, kym nie je preklad.
        expect(
          find.text(lookupAppLocalizations(locale).tabToday),
          findsWidgets,
        );
      });
    }
  });
}
