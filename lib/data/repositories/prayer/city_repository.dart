import 'package:meta/meta.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';

/// Mesto z offline tabulky `city` (docs/02 D9, A7.3).
@immutable
final class City {
  const City({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.lat,
    required this.lng,
    required this.tz,
    this.countryName,
  });

  final int id;
  final String name;

  /// ISO 3166-1 alpha-2.
  final String countryCode;

  /// Anglicky nazov krajiny z GeoNames (null ak chyba v `country`).
  final String? countryName;
  final double lat;
  final double lng;
  final String tz;

  /// "Bratislava, Slovakia".
  String get label => countryName == null ? name : '$name, $countryName';

  /// Hodnota `prayer.location` (suradnice zaokruhlene na 2 desatinne miesta).
  PrayerLocation toPrayerLocation() => PrayerLocation(
    lat: lat,
    lng: lng,
    country: countryCode,
    tz: tz,
    city: name,
  );

  @override
  bool operator ==(Object other) => other is City && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'City($id, $name, $countryCode)';
}

/// Offline vyhladavanie miest (A7.3, O3). Ziadna sietova sluzba.
abstract interface class CityRepository {
  /// Prefix v `name`/`ascii_name`, najvacsie mesta prve, max [limit].
  Future<List<City>> search(String prefix, {int limit = 30});

  /// Najblizsie mesto k polohe z GPS (bez reverse geocodingu, O3).
  Future<City?> nearest(double lat, double lng);
}

class ContentCityRepository implements CityRepository {
  ContentCityRepository(this._db);

  final Future<ContentDb> _db;
  Map<String, String>? _countries;

  Future<Map<String, String>> _countryNames(ContentDb db) async =>
      _countries ??= await db.placesDao.countryNames();

  City _city(CityRow r, Map<String, String> countries) => City(
    id: r.id,
    name: r.name,
    countryCode: r.countryCode,
    countryName: countries[r.countryCode],
    lat: r.lat,
    lng: r.lng,
    tz: r.tz,
  );

  @override
  Future<List<City>> search(String prefix, {int limit = 30}) async {
    final db = await _db;
    final countries = await _countryNames(db);
    return [
      for (final r in await db.placesDao.searchCities(prefix, limit: limit))
        _city(r, countries),
    ];
  }

  @override
  Future<City?> nearest(double lat, double lng) async {
    final db = await _db;
    final row = await db.placesDao.nearestCity(lat, lng);
    return row == null ? null : _city(row, await _countryNames(db));
  }
}
