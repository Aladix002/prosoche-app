import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/ui/i18n/i18n.dart';

import '../../helpers/pump_app.dart';

void main() {
  test('generated supportedLocales match SakinaLocales.all', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
      SakinaLocales.all.map((l) => l.languageCode).toSet(),
    );
    expect(SakinaLocales.all, hasLength(6));
  });

  test('every locale falls back to the EN template text', () {
    final en = lookupAppLocalizations(SakinaLocales.en);
    for (final locale in SakinaLocales.all) {
      final l10n = lookupAppLocalizations(locale);
      expect(l10n.localeName, locale.languageCode);
      // Kym ludia nedodaju preklad, nikdy prazdny retazec (docs/04 5.1).
      expect(l10n.tabToday, isNotEmpty);
      expect(l10n.errorGeneric, isNotEmpty);
      if (locale == SakinaLocales.en) expect(l10n.tabToday, en.tabToday);
    }
  });

  test('RTL only for ar and ur', () {
    expect(
      [for (final l in SakinaLocales.all) SakinaLocales.isRtl(l)],
      [false, true, false, true, false, false],
    );
    expect(textDirectionForLocale(SakinaLocales.ur), TextDirection.rtl);
    expect(textDirectionForLocale(SakinaLocales.tr), TextDirection.ltr);
    expect(textDirectionForLanguage('ar'), TextDirection.rtl);
    expect(textDirectionForLanguage('en'), TextDirection.ltr);
  });

  group('resolve', () {
    test('stored choice wins', () {
      expect(
        SakinaLocales.resolve(
          stored: 'bn',
          deviceLocales: const [Locale('ar')],
        ),
        SakinaLocales.bn,
      );
    });

    test('unknown stored value falls through to device locales', () {
      expect(
        SakinaLocales.resolve(
          stored: 'bs',
          deviceLocales: const [Locale('de'), Locale('ar', 'EG')],
        ),
        SakinaLocales.ar,
      );
    });

    test('falls back to en', () {
      expect(SakinaLocales.resolve(), SakinaLocales.en);
      expect(
        SakinaLocales.resolve(deviceLocales: const [Locale('sk')]),
        SakinaLocales.en,
      );
    });

    test('isSupported ignores the region', () {
      expect(SakinaLocales.isSupported(const Locale('ur', 'PK')), isTrue);
      expect(SakinaLocales.isSupported(const Locale('bs')), isFalse);
    });
  });

  group('app follows the device locale', () {
    for (final locale in SakinaLocales.all) {
      testWidgets('${locale.languageCode} sets direction', (tester) async {
        tester.platformDispatcher.localesTestValue = [locale];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        await tester.pumpSakina();

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
