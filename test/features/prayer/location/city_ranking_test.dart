import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/features/prayer/location/city_ranking.dart';

City city(int id, String name, String tz, {String country = 'XX'}) =>
    City(id: id, name: name, countryCode: country, lat: 0, lng: 0, tz: tz);

List<String> names(List<City> l) => [for (final c in l) c.name];

void main() {
  final now = DateTime.utc(2026, 10, 29, 12);

  setUpAll(ensureTimeZoneData);

  test('Sara from Bratislava: Sarajevo before Saratov (A7.3 AC)', () {
    final ranked = rankCities(
      'Sara',
      [
        city(1, 'Saratov', 'Europe/Saratov'),
        city(2, 'Sarajevo', 'Europe/Sarajevo'),
        city(3, 'Saransk', 'Europe/Moscow'),
      ],
      referenceZone: 'Europe/Bratislava',
      now: now,
    );
    expect(names(ranked), ['Sarajevo', 'Saratov', 'Saransk']);
  });

  test('big cities still win over small nearby ones', () {
    final ranked = rankCities(
      'Lon',
      [
        city(1, 'London', 'Europe/London'),
        city(2, 'Londrina', 'America/Sao_Paulo'),
        for (var i = 3; i < 40; i++) city(i, 'Lon$i', 'America/Chicago'),
        city(40, 'Lonato', 'Europe/Rome'),
      ],
      referenceZone: 'Europe/Bratislava',
      now: now,
    );
    expect(ranked.first.name, 'London');
    expect(ranked.indexWhere((c) => c.name == 'Lonato'), greaterThan(3));
  });

  test('exact name match first, case and diacritics ignored', () {
    final ranked = rankCities('sao paulo', [
      city(1, 'São Paulo de Olivença', 'America/Manaus'),
      city(2, 'São Paulo', 'America/Sao_Paulo'),
    ], now: now);
    expect(ranked.first.name, 'São Paulo');
  });

  test('without reference zone keeps population order and the limit', () {
    final ranked = rankCities('Ka', [
      for (var i = 0; i < 50; i++) city(i, 'Ka$i', 'Asia/Karachi'),
    ]);
    expect(ranked, hasLength(cityResultLimit));
    expect(ranked.first.name, 'Ka0');
    expect(ranked[1].name, 'Ka1');
  });

  test('unknown zones are ignored', () {
    final ranked = rankCities(
      'A',
      [city(1, 'A1', 'Nowhere/Zone'), city(2, 'A2', 'Europe/Bratislava')],
      referenceZone: 'Europe/Bratislava',
      now: now,
    );
    expect(names(ranked), ['A2', 'A1']);
    expect(
      names(
        rankCities('A', [
          city(1, 'A1', 'Europe/Vienna'),
        ], referenceZone: 'Bad/Zone'),
      ),
      ['A1'],
    );
  });

  test('foldCityName', () {
    expect(foldCityName('Şanlıurfa'), 'sanliurfa');
    expect(foldCityName('Košice'), 'kosice');
    expect(foldCityName('ŁÓDŹ'), 'lodz');
  });
}
