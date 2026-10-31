import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:prosoche/ui/i18n/i18n.dart';

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

  group('ProsocheFormats', () {
    test('time 24h and 12h', () {
      expect(ProsocheFormats(ProsocheLocales.en).time(evening), '18:05');
      expect(
        ProsocheFormats(ProsocheLocales.en).time(evening, use24h: false),
        '6:05\u202FPM', // intl: uzka nedelitelna medzera
      );
      expect(ProsocheFormats(const Locale('id')).time(evening), '18.05');
      expect(ProsocheFormats(const Locale('bn')).time(evening), '১৮:০৫');
      expect(
        ProsocheFormats(
          const Locale('ar'),
          digits: DigitStyle.arabicIndic,
        ).time(evening),
        '١٨:٠٥',
      );
    });

    test('numbers with grouping and native separators', () {
      expect(ProsocheFormats(ProsocheLocales.en).number(1234.5), '1,234.5');
      expect(ProsocheFormats(const Locale('tr')).number(1234.5), '1.234,5');
      expect(ProsocheFormats(const Locale('bn')).number(1234.5), '১,২৩৪.৫');
      expect(
        ProsocheFormats(
          const Locale('ar'),
          digits: DigitStyle.arabicIndic,
        ).number(1234.5),
        '١٬٢٣٤٫٥',
      );
      expect(
        ProsocheFormats(
          const Locale('ur'),
          digits: DigitStyle.extendedArabicIndic,
        ).number(1234.5),
        '۱٬۲۳۴٫۵',
      );
      expect(
        ProsocheFormats(const Locale('ar'), digits: DigitStyle.latin).number(7),
        '7',
      );
    });

    test('dates use intl month names and chosen digits', () {
      expect(ProsocheFormats(ProsocheLocales.en).date(evening), 'Mar 7, 2026');
      expect(
        ProsocheFormats(const Locale('bn')).date(evening),
        contains('২০২৬'),
      );
      expect(
        ProsocheFormats(
          const Locale('ar'),
          digits: DigitStyle.arabicIndic,
        ).date(evening),
        contains('٢٠٢٦'),
      );
      expect(
        ProsocheFormats(ProsocheLocales.en).weekdayDate(evening),
        'Saturday, March 7',
      );
    });

    test('defaults digits from the locale', () {
      expect(ProsocheFormats(const Locale('bn')).digits, DigitStyle.bengali);
      expect(ProsocheFormats(const Locale('ar')).digits, DigitStyle.latin);
      expect(ProsocheFormats(const Locale('ur')).locale, const Locale('ur'));
    });
  });
}
