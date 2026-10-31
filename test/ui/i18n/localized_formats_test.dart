import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sakina/ui/i18n/i18n.dart';

void main() {
  setUpAll(initializeDateFormatting);

  final evening = DateTime(2026, 3, 7, 18, 5);

  group('DigitStyle.systemDefault (intl/CLDR, docs/04 5.2 bod 3)', () {
    test('per locale', () {
      expect(DigitStyle.systemDefault(const Locale('en')), DigitStyle.latin);
      expect(DigitStyle.systemDefault(const Locale('ar')), DigitStyle.latin);
      expect(
        DigitStyle.systemDefault(const Locale('ar', 'SA')),
        DigitStyle.latin,
      );
      expect(
        DigitStyle.systemDefault(const Locale('ar', 'EG')),
        DigitStyle.arabicIndic,
      );
      expect(DigitStyle.systemDefault(const Locale('ur')), DigitStyle.latin);
      expect(DigitStyle.systemDefault(const Locale('bn')), DigitStyle.bengali);
      expect(DigitStyle.systemDefault(const Locale('tr')), DigitStyle.latin);
      expect(DigitStyle.systemDefault(const Locale('id')), DigitStyle.latin);
    });

    test('unknown locale falls back to latin', () {
      expect(DigitStyle.systemDefault(const Locale('xx')), DigitStyle.latin);
      expect(
        DigitStyle.systemDefault(const Locale('ar', 'XX')),
        DigitStyle.latin,
      );
    });
  });

  test('localizeDigits converts between all digit sets', () {
    expect(localizeDigits('2:255', DigitStyle.arabicIndic), '٢:٢٥٥');
    expect(localizeDigits('2:255', DigitStyle.extendedArabicIndic), '۲:۲۵۵');
    expect(localizeDigits('10', DigitStyle.bengali), '১০');
    expect(localizeDigits('٢:٢٥٥ ১০ ۹', DigitStyle.latin), '2:255 10 9');
    expect(localizeDigits('Asr', DigitStyle.arabicIndic), 'Asr');
  });

  group('SakinaFormats', () {
    test('time 24h and 12h', () {
      expect(SakinaFormats(SakinaLocales.en).time(evening), '18:05');
      expect(
        SakinaFormats(SakinaLocales.en).time(evening, use24h: false),
        '6:05\u202FPM', // intl: uzka nedelitelna medzera
      );
      expect(SakinaFormats(SakinaLocales.id).time(evening), '18.05');
      expect(SakinaFormats(SakinaLocales.bn).time(evening), '১৮:০৫');
      expect(
        SakinaFormats(
          SakinaLocales.ar,
          digits: DigitStyle.arabicIndic,
        ).time(evening),
        '١٨:٠٥',
      );
    });

    test('numbers with grouping and native separators', () {
      expect(SakinaFormats(SakinaLocales.en).number(1234.5), '1,234.5');
      expect(SakinaFormats(SakinaLocales.tr).number(1234.5), '1.234,5');
      expect(SakinaFormats(SakinaLocales.bn).number(1234.5), '১,২৩৪.৫');
      expect(
        SakinaFormats(
          SakinaLocales.ar,
          digits: DigitStyle.arabicIndic,
        ).number(1234.5),
        '١٬٢٣٤٫٥',
      );
      expect(
        SakinaFormats(
          SakinaLocales.ur,
          digits: DigitStyle.extendedArabicIndic,
        ).number(1234.5),
        '۱٬۲۳۴٫۵',
      );
      expect(
        SakinaFormats(SakinaLocales.ar, digits: DigitStyle.latin).number(7),
        '7',
      );
    });

    test('dates use intl month names and chosen digits', () {
      expect(SakinaFormats(SakinaLocales.en).date(evening), 'Mar 7, 2026');
      expect(SakinaFormats(SakinaLocales.bn).date(evening), contains('২০২৬'));
      expect(
        SakinaFormats(
          SakinaLocales.ar,
          digits: DigitStyle.arabicIndic,
        ).date(evening),
        contains('٢٠٢٦'),
      );
      expect(
        SakinaFormats(SakinaLocales.en).weekdayDate(evening),
        'Saturday, March 7',
      );
    });

    test('ayahRef is isolated and localized', () {
      final ref = SakinaFormats(
        SakinaLocales.ar,
        digits: DigitStyle.arabicIndic,
      ).ayahRef(2, 255);
      expect(ref, '${Bidi.fsi}٢:٢٥٥${Bidi.pdi}');
      expect(
        Bidi.strip(SakinaFormats(SakinaLocales.en).ayahRef(2, 255)),
        '2:255',
      );
    });

    test('defaults digits from the locale', () {
      expect(SakinaFormats(SakinaLocales.bn).digits, DigitStyle.bengali);
      expect(SakinaFormats(SakinaLocales.ar).digits, DigitStyle.latin);
      expect(SakinaFormats(SakinaLocales.ur).locale, SakinaLocales.ur);
    });
  });
}
