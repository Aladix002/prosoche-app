import 'package:meta/meta.dart';

/// Hodnota `settings.prayer.location` (docs/02 0.7).
///
/// Suradnice sa pri vytvoreni zaokruhlia na 2 desatinne miesta (~1 km),
/// presnejsia poloha sa nikdy neuklada.
@immutable
final class PrayerLocation {
  PrayerLocation({
    required double lat,
    required double lng,
    required this.country,
    required this.tz,
    this.city,
  }) : lat = _round2(lat),
       lng = _round2(lng) {
    final problem = _problem(this.lat, this.lng, country, tz);
    if (problem != null) throw ArgumentError(problem);
  }

  /// Z JSON objektu; pri neplatnej hodnote hodi [FormatException].
  factory PrayerLocation.fromJson(Object json) {
    if (json case {
      'lat': final num lat,
      'lng': final num lng,
      'country': final String country,
      'tz': final String tz,
    }) {
      final city = json['city'];
      if (city != null && city is! String) {
        throw const FormatException('prayer.location: city');
      }
      final problem = _problem(lat, lng, country, tz);
      if (problem != null) throw FormatException('prayer.location: $problem');
      return PrayerLocation(
        lat: lat.toDouble(),
        lng: lng.toDouble(),
        country: country,
        tz: tz,
        city: city as String?,
      );
    }
    throw const FormatException('prayer.location: expected object');
  }

  final double lat;
  final double lng;

  /// Nazov mesta na zobrazenie (alebo null pri polohe bez mesta).
  final String? city;

  /// ISO 3166-1 alpha-2, podla neho sa predvoli metoda vypoctu.
  final String country;

  /// IANA casova zona, napr. `Europe/Bratislava`.
  final String tz;

  Map<String, Object?> toJson() => {
    'lat': lat,
    'lng': lng,
    'city': city,
    'country': country,
    'tz': tz,
  };

  @override
  bool operator ==(Object other) =>
      other is PrayerLocation &&
      other.lat == lat &&
      other.lng == lng &&
      other.city == city &&
      other.country == country &&
      other.tz == tz;

  @override
  int get hashCode => Object.hash(lat, lng, city, country, tz);

  @override
  String toString() => 'PrayerLocation($lat, $lng, $country, $tz)';

  static String? _problem(num lat, num lng, String country, String tz) {
    if (lat < -90 || lat > 90) return 'lat must be -90..90';
    if (lng < -180 || lng > 180) return 'lng must be -180..180';
    if (!_country.hasMatch(country)) return 'country must be ISO alpha-2';
    if (tz.isEmpty) return 'tz must be an IANA zone';
    return null;
  }

  static final _country = RegExp(r'^[A-Z]{2}$');

  static double _round2(double v) => (v * 100).roundToDouble() / 100;
}
