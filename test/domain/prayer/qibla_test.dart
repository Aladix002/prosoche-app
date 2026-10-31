import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/domain/prayer/qibla.dart';

/// Referencne azimuty: AlAdhan Qibla API
/// (`https://api.aladhan.com/v1/qibla/{lat}/{lng}`), stiahnute 2026-10-29.
const _reference = <String, (double, double, double)>{
  'Bratislava': (48.15, 17.11, 137.76391155948053),
  'London': (51.51, -0.13, 118.98724106300966),
  'Jakarta': (-6.21, 106.85, 295.15100649012027),
  'Karachi': (24.86, 67.01, 267.74695629726574),
  'New York': (40.71, -74.01, 58.47914069179555),
  'Kuala Lumpur': (3.14, 101.69, 292.5368038832188),
};

void main() {
  for (final MapEntry(key: city, value: (lat, lng, want))
      in _reference.entries) {
    test('qibla $city within 0.5 degree', () {
      expect(qiblaBearing(lat, lng), closeTo(want, 0.5));
    });
  }

  test('range is 0..360', () {
    for (final (lat, lng) in [(0.0, 0.0), (-33.87, 151.21), (64.15, -21.94)]) {
      final b = qiblaBearing(lat, lng);
      expect(b, inInclusiveRange(0, 360));
    }
  });
}
