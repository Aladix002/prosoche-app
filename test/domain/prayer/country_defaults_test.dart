import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/domain/prayer/calc_settings.dart';
import 'package:sakina/domain/prayer/country_defaults.dart';

void main() {
  test('DoD presets (PLAN_VYVOJA P-01)', () {
    expect(
      CountryDefaults.forCountry('TR'),
      const CountryDefaults(PrayerMethod.turkiye, verified: true),
    );
    expect(CountryDefaults.forCountry('ID').method, PrayerMethod.indonesian);
    expect(CountryDefaults.forCountry('MY').method, PrayerMethod.jakim);
    expect(
      CountryDefaults.forCountry('PK'),
      const CountryDefaults(
        PrayerMethod.karachi,
        asr: AsrMadhab.hanafi,
        verified: true,
      ),
    );
    // BD: Karachi + Hanafi je [OVERIT], oficialna tabulka chyba.
    final bd = CountryDefaults.forCountry('BD');
    expect(
      (bd.method, bd.asr, bd.verified),
      (PrayerMethod.karachi, AsrMadhab.hanafi, false),
    );
  });

  test('Europe and unknown countries use MWL', () {
    for (final c in ['SK', 'BA', 'GB', 'NO', 'IS', 'XX']) {
      expect(CountryDefaults.forCountry(c), CountryDefaults.fallback);
    }
    expect(CountryDefaults.fallback.method, PrayerMethod.muslimWorldLeague);
  });

  test('country code is case insensitive', () {
    expect(CountryDefaults.forCountry('tr').method, PrayerMethod.turkiye);
  });

  test('value semantics', () {
    const a = CountryDefaults(PrayerMethod.dubai);
    expect(a, const CountryDefaults(PrayerMethod.dubai));
    expect(a.hashCode, const CountryDefaults(PrayerMethod.dubai).hashCode);
    expect(a, isNot(const CountryDefaults(PrayerMethod.dubai, verified: true)));
    expect(a.toString(), 'CountryDefaults(dubai, shafi)');
  });
}
