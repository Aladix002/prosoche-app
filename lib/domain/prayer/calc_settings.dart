import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:meta/meta.dart';
import 'package:prosoche/domain/prayer/country_defaults.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';

/// Metoda vypoctu. [key] je hodnota `prayer.method` = nazov
/// `CalculationMethod` v adhan_dart (napr. `muslimWorldLeague`), okrem
/// [jakim], ktoru adhan_dart nema.
///
/// [indonesian] a [jakim] maju navyse ihtiyat (bezpecnostnu rezervu)
/// oficialnych tabuliek: +2 min ku kazdej modlitbe, vychod slnka -2 min.
/// Overene proti Kemenag (Jakarta) a JAKIM (Kuala Lumpur) v
/// `test/domain/prayer/reference/`.
enum PrayerMethod {
  muslimWorldLeague,
  northAmerica,
  egyptian,
  ummAlQura,
  karachi,
  turkiye,
  indonesian,
  singapore,
  dubai,
  qatar,
  kuwait,
  gulfRegion,
  algerian,
  morocco,
  tunisia,
  jordan,
  france,
  portugal,
  russia,
  tehran,
  jafari,
  moonsightingCommittee,

  /// JAKIM (Malajzia): fajr 18 st., isha 18 st., ihtiyat.
  jakim;

  String get key => name;

  /// Metoda podla kluca alebo null pri neznamom kluci.
  static PrayerMethod? tryParse(String? key) {
    for (final m in values) {
      if (m.key == key) return m;
    }
    return null;
  }

  adhan.CalculationParameters _parameters() => switch (this) {
    muslimWorldLeague => adhan.CalculationMethodParameters.muslimWorldLeague(),
    northAmerica => adhan.CalculationMethodParameters.northAmerica(),
    egyptian => adhan.CalculationMethodParameters.egyptian(),
    ummAlQura => adhan.CalculationMethodParameters.ummAlQura(),
    karachi => adhan.CalculationMethodParameters.karachi(),
    turkiye => adhan.CalculationMethodParameters.turkiye(),
    indonesian => _withIhtiyat(adhan.CalculationMethodParameters.indonesian()),
    singapore => adhan.CalculationMethodParameters.singapore(),
    dubai => adhan.CalculationMethodParameters.dubai(),
    qatar => adhan.CalculationMethodParameters.qatar(),
    kuwait => adhan.CalculationMethodParameters.kuwait(),
    gulfRegion => adhan.CalculationMethodParameters.gulfRegion(),
    algerian => adhan.CalculationMethodParameters.algerian(),
    morocco => adhan.CalculationMethodParameters.morocco(),
    tunisia => adhan.CalculationMethodParameters.tunisia(),
    jordan => adhan.CalculationMethodParameters.jordan(),
    france => adhan.CalculationMethodParameters.france(),
    portugal => adhan.CalculationMethodParameters.portugal(),
    russia => adhan.CalculationMethodParameters.russia(),
    tehran => adhan.CalculationMethodParameters.tehran(),
    jafari => adhan.CalculationMethodParameters.jafari(),
    moonsightingCommittee =>
      adhan.CalculationMethodParameters.moonsightingCommittee(),
    jakim => _withIhtiyat(
      adhan.CalculationParameters(
        method: adhan.CalculationMethod.other,
        fajrAngle: 18,
        ishaAngle: 18,
        methodAdjustments: {adhan.Prayer.dhuhr: 1},
      ),
    ),
  };

  /// Ihtiyat 2 min: modlitby neskor, vychod slnka (koniec fajr) skor.
  static adhan.CalculationParameters _withIhtiyat(
    adhan.CalculationParameters p,
  ) => p
    ..methodAdjustments = {
      for (final prayer in Prayer.values)
        prayer.adhanPrayer:
            (p.methodAdjustments[prayer.adhanPrayer] ?? 0) +
            (prayer == Prayer.sunrise ? -_ihtiyat : _ihtiyat),
    };

  static const _ihtiyat = 2;
}

/// Sposob vypoctu asr, hodnota `prayer.asr`.
enum AsrMadhab {
  shafi,
  hanafi;

  String get key => name;

  static AsrMadhab parse(String key) =>
      key == hanafi.key ? hanafi : AsrMadhab.shafi;
}

/// Pravidlo vysokych sirok, hodnota `prayer.high_lat_rule` (docs/02 0.7).
enum HighLatRule {
  middleOfNight('middle_of_night', adhan.HighLatitudeRule.middleOfTheNight),
  seventhOfNight('seventh_of_night', adhan.HighLatitudeRule.seventhOfTheNight),
  twilightAngle('twilight_angle', adhan.HighLatitudeRule.twilightAngle);

  HighLatRule(this.key, this._adhan);

  final String key;
  final adhan.HighLatitudeRule _adhan;

  /// Pravidlo podla kluca alebo null pri neznamom kluci.
  static HighLatRule? tryParse(String? key) {
    for (final r in values) {
      if (r.key == key) return r;
    }
    return null;
  }

  /// Predvolba pri `prayer.high_lat_rule` = null (TECHNICKY_PLAN 8.1).
  ///
  /// Nad 48 stupnov `middle_of_night`. Pod 48 "bez pravidla": adhan_dart
  /// pravidlo vypnut nevie, pouzije sa tiez `middle_of_night`, ktore sa tam
  /// prejavi len ked sa uhol fajr/isha v danu noc nedosiahne.
  static HighLatRule defaultFor(double lat) => HighLatRule.middleOfNight;
}

/// Uplne nastavenie vypoctu po doplneni predvolieb.
@immutable
final class CalcSettings {
  CalcSettings({
    required this.method,
    this.asr = AsrMadhab.shafi,
    this.highLatRule = HighLatRule.middleOfNight,
    Map<Prayer, int> adjust = const {},
  }) : adjust = Map.unmodifiable(adjust);

  /// Nastavenie z hodnot klucov `prayer.*` (docs/02 0.7).
  ///
  /// Chybajuca alebo neznama metoda = predvolba krajiny [country], chybajuce
  /// pravidlo = [HighLatRule.defaultFor]. Neznamy kluc v [adjust] sa ignoruje.
  factory CalcSettings.resolve({
    required double lat,
    required String country,
    String? method,
    String asr = 'shafi',
    String? highLatRule,
    Map<String, int> adjust = const {},
  }) => CalcSettings(
    method:
        PrayerMethod.tryParse(method) ??
        CountryDefaults.forCountry(country).method,
    asr: AsrMadhab.parse(asr),
    highLatRule:
        HighLatRule.tryParse(highLatRule) ?? HighLatRule.defaultFor(lat),
    adjust: {
      for (final p in Prayer.values)
        if (adjust[p.name] case final int minutes) p: minutes,
    },
  );

  /// Nacita `prayer.*` z [settings]. Bez ulozenej polohy vrati null.
  static Future<(PrayerLocation, CalcSettings)?> load(
    SettingsRepository settings,
  ) async {
    final location = await settings.get(SettingsKeys.prayerLocation);
    if (location == null) return null;
    return (
      location,
      CalcSettings.resolve(
        lat: location.lat,
        country: location.country,
        method: await settings.get(SettingsKeys.prayerMethod),
        asr: await settings.get(SettingsKeys.prayerAsr),
        highLatRule: await settings.get(SettingsKeys.prayerHighLatRule),
        adjust: await settings.get(SettingsKeys.prayerAdjust),
      ),
    );
  }

  final PrayerMethod method;
  final AsrMadhab asr;
  final HighLatRule highLatRule;

  /// Rucny posun v minutach (TECHNICKY_PLAN 8.1), chybajuca modlitba = 0.
  final Map<Prayer, int> adjust;

  /// Parametre pre adhan_dart.
  adhan.CalculationParameters toAdhan() {
    final p = method._parameters()
      ..madhab = asr == AsrMadhab.hanafi
          ? adhan.Madhab.hanafi
          : adhan.Madhab.shafi
      ..highLatitudeRule = highLatRule._adhan
      // Za polarnym kruhom (Tromso v juni) by bez toho vypocet hodil
      // vynimku; pouzije sa najblizsi den so vychodom a zapadom slnka.
      ..polarCircleResolution = adhan.PolarCircleResolution.aqrabYaum
      ..adjustments = {
        for (final prayer in Prayer.values)
          prayer.adhanPrayer: adjust[prayer] ?? 0,
      };
    return p;
  }

  @override
  bool operator ==(Object other) =>
      other is CalcSettings &&
      other.method == method &&
      other.asr == asr &&
      other.highLatRule == highLatRule &&
      _mapEquals(other.adjust, adjust);

  @override
  int get hashCode => Object.hash(
    method,
    asr,
    highLatRule,
    Object.hashAllUnordered(adjust.entries.map((e) => (e.key, e.value))),
  );

  @override
  String toString() =>
      'CalcSettings(${method.key}, ${asr.key}, ${highLatRule.key}, $adjust)';

  static bool _mapEquals(Map<Prayer, int> a, Map<Prayer, int> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
}
