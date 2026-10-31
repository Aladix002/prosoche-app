import 'package:flutter_riverpod/misc.dart';
import 'package:sakina/features/onboarding/onboarding_platform.dart';
import 'package:sakina/features/prayer/prayer_providers.dart';

/// F-05 "Use my location" pouziva tu istu geolocator implementaciu ako
/// onboarding O3 (F-01).
List<Override> locationOverrides() => [
  deviceLocatorProvider.overrideWith(
    (ref) => DeviceLocationLocator(ref.watch(deviceLocationProvider)),
  ),
];

/// [DeviceLocator] (F-05) nad [DeviceLocation] (F-01).
final class DeviceLocationLocator implements DeviceLocator {
  const DeviceLocationLocator(this._location);

  final DeviceLocation _location;

  @override
  Future<({double lat, double lng})?> locate() async =>
      switch (await _location.locateOnce()) {
        LocationFound(:final lat, :final lng) => (lat: lat, lng: lng),
        LocationDenied() || LocationFailed() => null,
      };
}
