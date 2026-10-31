import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/settings/prayer_location.dart';

void main() {
  test('rounds coordinates to 2 decimals', () {
    final loc = PrayerLocation(
      lat: 48.14816,
      lng: -17.10674,
      country: 'SK',
      tz: 'Europe/Bratislava',
    );
    expect((loc.lat, loc.lng), (48.15, -17.11));
    expect(loc.city, isNull);
    expect(loc.toString(), contains('48.15'));
  });

  test('json round trip', () {
    final loc = PrayerLocation(
      lat: 21.4225,
      lng: 39.8262,
      city: 'Mecca',
      country: 'SA',
      tz: 'Asia/Riyadh',
    );
    final json = loc.toJson();
    expect(json, {
      'lat': 21.42,
      'lng': 39.83,
      'city': 'Mecca',
      'country': 'SA',
      'tz': 'Asia/Riyadh',
    });
    expect(PrayerLocation.fromJson(json), loc);
    expect(PrayerLocation.fromJson(json).hashCode, loc.hashCode);
  });

  test('validates', () {
    expect(
      () => PrayerLocation(lat: 91, lng: 0, country: 'SK', tz: 'UTC'),
      throwsArgumentError,
    );
    expect(
      () => PrayerLocation(lat: 0, lng: 181, country: 'SK', tz: 'UTC'),
      throwsArgumentError,
    );
    expect(
      () => PrayerLocation(lat: 0, lng: 0, country: 'svk', tz: 'UTC'),
      throwsArgumentError,
    );
    expect(
      () => PrayerLocation(lat: 0, lng: 0, country: 'SK', tz: ''),
      throwsArgumentError,
    );
    for (final json in <Object>[
      'x',
      {'lat': 1, 'lng': 2, 'country': 'SK'},
      {'lat': 1, 'lng': 2, 'country': 'SK', 'tz': 'UTC', 'city': 5},
      {'lat': 100, 'lng': 2, 'country': 'SK', 'tz': 'UTC'},
    ]) {
      expect(() => PrayerLocation.fromJson(json), throwsFormatException);
    }
  });
}
