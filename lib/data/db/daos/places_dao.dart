import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:sakina/data/db/content_db.dart';

part 'places_dao.g.dart';

/// Offline mesta a krajiny (docs/02 D9, A7.3, O3).
@DriftAccessor(tables: [Cities, Countries])
class PlacesDao extends DatabaseAccessor<ContentDb> with _$PlacesDaoMixin {
  PlacesDao(super.attachedDatabase);

  Future<CityRow?> city(int id) =>
      (select(cities)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<CountryRow?> country(String iso2) =>
      (select(countries)..where((t) => t.iso2.equals(iso2))).getSingleOrNull();

  /// Nazvy krajin (`iso2` -> anglicky nazov GeoNames) pre zoznam miest.
  Future<Map<String, String>> countryNames() async => {
    for (final r in await select(countries).get()) r.iso2: r.name,
  };

  /// Prefixove hladanie v `name` a `ascii_name`, najvacsie mesta prve.
  Future<List<CityRow>> searchCities(String prefix, {int limit = 30}) {
    final p = prefix.trim();
    if (p.isEmpty) return Future.value(const []);
    final like = '${_escapeLike(p)}%';
    return (select(cities)
          ..where(
            (t) =>
                t.name.like(like, escapeChar: r'\') |
                t.asciiName.like(like, escapeChar: r'\'),
          )
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.population,
              mode: OrderingMode.desc,
              nulls: NullsOrder.last,
            ),
            (t) => OrderingTerm.asc(t.id),
          ])
          ..limit(limit))
        .get();
  }

  /// Najblizsie mesto k [lat], [lng] (poloha bez reverse geocodingu, O3).
  /// Hlada v stvorci +-[radiusDeg], ktory sa zvacsuje, kym nic nenajde.
  Future<CityRow?> nearestCity(
    double lat,
    double lng, {
    double radiusDeg = 1,
  }) async {
    for (var r = radiusDeg; r <= 32; r *= 2) {
      final rows =
          await (select(cities)..where(
                (t) =>
                    t.lat.isBetweenValues(lat - r, lat + r) &
                    t.lng.isBetweenValues(lng - r, lng + r),
              ))
              .get();
      if (rows.isNotEmpty) {
        rows.sort(
          (a, b) => _distanceKm(
            lat,
            lng,
            a.lat,
            a.lng,
          ).compareTo(_distanceKm(lat, lng, b.lat, b.lng)),
        );
        return rows.first;
      }
    }
    return null;
  }

  static String _escapeLike(String s) =>
      s.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}');

  static double _distanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }
}
