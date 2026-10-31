import 'package:meta/meta.dart';
import 'package:prosoche/domain/prayer/calc_settings.dart';

/// Predvolba metody a asr podla krajiny (TECHNICKY_PLAN 8.1, docs/01 5.6).
///
/// Pouzije sa, ked `prayer.method` je null. Asr sa v nastaveniach ma default
/// `shafi`, preto onboarding a zmena polohy maju pri automatickej metode
/// zapisat aj [asr] (napr. Pakistan = hanafi).
@immutable
final class CountryDefaults {
  const CountryDefaults(
    this.method, {
    this.asr = AsrMadhab.shafi,
    this.verified = false,
  });

  /// Predvolba pre ISO alpha-2 kod [country]; neznama krajina = MWL.
  static CountryDefaults forCountry(String country) =>
      _byCountry[country.toUpperCase()] ?? fallback;

  /// Muslim World League (Slovensko a vacsina Europy).
  static const CountryDefaults fallback = CountryDefaults(
    PrayerMethod.muslimWorldLeague,
    verified: true,
  );

  final PrayerMethod method;
  final AsrMadhab asr;

  /// true = overene porovnanim s tabulkou v `test/domain/prayer/reference/`
  /// (+-2 min). false = `[OVERIT]` u reviewera (napr. BD: Islamic Foundation
  /// Bangladesh tabulku sa nepodarilo ziskat).
  final bool verified;

  @override
  bool operator ==(Object other) =>
      other is CountryDefaults &&
      other.method == method &&
      other.asr == asr &&
      other.verified == verified;

  @override
  int get hashCode => Object.hash(method, asr, verified);

  @override
  String toString() => 'CountryDefaults(${method.key}, ${asr.key})';

  static const AsrMadhab _hanafi = AsrMadhab.hanafi;

  static const Map<String, CountryDefaults> _byCountry = {
    // Overene proti oficialnej tabulke (Diyanet, Kemenag, JAKIM).
    'TR': CountryDefaults(PrayerMethod.turkiye, verified: true),
    'ID': CountryDefaults(PrayerMethod.indonesian, verified: true),
    'MY': CountryDefaults(PrayerMethod.jakim, verified: true),
    // Overene proti verejnej tabulke AlAdhan (Karachi, Lahore, Mekka);
    // oficialnu statnu tabulku Pakistan ani Saudska Arabia nema verejne.
    'PK': CountryDefaults(PrayerMethod.karachi, asr: _hanafi, verified: true),
    'SA': CountryDefaults(PrayerMethod.ummAlQura, verified: true),
    // [OVERIT] podla zvyklosti a popisu metod v adhan_dart, bez tabulky.
    'BD': CountryDefaults(PrayerMethod.karachi, asr: _hanafi),
    'IN': CountryDefaults(PrayerMethod.karachi, asr: _hanafi),
    'AF': CountryDefaults(PrayerMethod.karachi, asr: _hanafi),
    'SG': CountryDefaults(PrayerMethod.singapore),
    'BN': CountryDefaults(PrayerMethod.singapore),
    'AE': CountryDefaults(PrayerMethod.dubai),
    'QA': CountryDefaults(PrayerMethod.qatar),
    'KW': CountryDefaults(PrayerMethod.kuwait),
    'EG': CountryDefaults(PrayerMethod.egyptian),
    'DZ': CountryDefaults(PrayerMethod.algerian),
    'MA': CountryDefaults(PrayerMethod.morocco),
    'TN': CountryDefaults(PrayerMethod.tunisia),
    'JO': CountryDefaults(PrayerMethod.jordan),
    'PT': CountryDefaults(PrayerMethod.portugal),
    'RU': CountryDefaults(PrayerMethod.russia),
    'US': CountryDefaults(PrayerMethod.northAmerica),
    'CA': CountryDefaults(PrayerMethod.northAmerica),
  };
}
