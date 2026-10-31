import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/ui/i18n/i18n.dart';

import '../../helpers/pump_app.dart';

void main() {
  test('generated supportedLocales match ProsocheLocales.all (v1: en)', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
      ProsocheLocales.all.map((l) => l.languageCode).toSet(),
    );
    expect(ProsocheLocales.all, [ProsocheLocales.en]);
  });

  test('EN template texts are never empty', () {
    final l10n = lookupAppLocalizations(ProsocheLocales.en);
    expect(l10n.localeName, 'en');
    expect(l10n.tabToday, isNotEmpty);
    expect(l10n.errorGeneric, isNotEmpty);
  });

  test('RTL detection stays for future languages', () {
    expect(ProsocheLocales.isRtl(ProsocheLocales.en), isFalse);
    expect(ProsocheLocales.isRtl(const Locale('he')), isTrue);
    expect(textDirectionForLocale(ProsocheLocales.en), TextDirection.ltr);
    expect(textDirectionForLanguage('fa'), TextDirection.rtl);
    expect(textDirectionForLanguage('en'), TextDirection.ltr);
  });

  group('resolve', () {
    test('stored choice wins when supported', () {
      expect(ProsocheLocales.resolve(stored: 'en'), ProsocheLocales.en);
    });

    test('unknown stored value and device locales fall back to en', () {
      expect(
        ProsocheLocales.resolve(
          stored: 'bs',
          deviceLocales: const [Locale('de'), Locale('en', 'GB')],
        ),
        ProsocheLocales.en,
      );
      expect(ProsocheLocales.resolve(), ProsocheLocales.en);
      expect(
        ProsocheLocales.resolve(deviceLocales: const [Locale('sk')]),
        ProsocheLocales.en,
      );
    });

    test('isSupported ignores the region', () {
      expect(ProsocheLocales.isSupported(const Locale('en', 'US')), isTrue);
      expect(ProsocheLocales.isSupported(const Locale('bs')), isFalse);
    });
  });

  testWidgets('unsupported device locale falls back to EN, LTR', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = [const Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpProsoche();
    final context = tester.element(navBar);
    expect(Localizations.localeOf(context), ProsocheLocales.en);
    expect(Directionality.of(context), TextDirection.ltr);
    expect(find.text('Today'), findsWidgets);
  });
}
