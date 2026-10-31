import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meta/meta.dart';
import 'package:prosoche/data/notifications/notifications.dart';

// Tenke rozhrania nad platformou pre onboarding (O3 poloha, O4 notifikacie).
// Widget testy ich prepisu fake implementaciou.

/// Vysledok jednorazoveho zistenia polohy (O3).
sealed class LocationResult {
  const LocationResult();
}

@immutable
final class LocationFound extends LocationResult {
  const LocationFound(this.lat, this.lng);

  final double lat;
  final double lng;
}

/// Povolenie zamietnute (aj "don't ask again") alebo poloha vypnuta.
final class LocationDenied extends LocationResult {
  const LocationDenied();
}

/// GPS timeout (10 s) alebo chyba pluginu.
final class LocationFailed extends LocationResult {
  const LocationFailed();
}

abstract interface class DeviceLocation {
  /// Poziada o povolenie (ak treba) a raz zisti polohu s nizkou presnostou.
  Future<LocationResult> locateOnce();
}

/// [DeviceLocation] nad `geolocator` (`LocationAccuracy.low`, timeout 10 s).
/// Systemove nastavenia sa automaticky neotvaraju (docs/02 O3).
final class GeolocatorDeviceLocation implements DeviceLocation {
  const GeolocatorDeviceLocation({this.timeout = const Duration(seconds: 10)});

  final Duration timeout;

  @override
  Future<LocationResult> locateOnce() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationDenied();
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const LocationDenied();
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: timeout,
        ),
      );
      return LocationFound(p.latitude, p.longitude);
    } on Object {
      return const LocationFailed();
    }
  }
}

final Provider<DeviceLocation> deviceLocationProvider =
    Provider<DeviceLocation>(
      (ref) => const GeolocatorDeviceLocation(),
      name: 'deviceLocationProvider',
    );

/// Stav povoleni notifikacii (O4).
@immutable
final class NotificationAccess {
  const NotificationAccess({required this.enabled, required this.exact});

  /// Notifikacie appky su zapnute (Android < 13 vzdy).
  final bool enabled;

  /// Smie planovat presne alarmy (`canScheduleExactAlarms`).
  final bool exact;

  @override
  bool operator ==(Object other) =>
      other is NotificationAccess &&
      other.enabled == enabled &&
      other.exact == exact;

  @override
  int get hashCode => Object.hash(enabled, exact);
}

/// Povolenia notifikacii pre O4 nad [NotificationPlatform] (P-02).
abstract interface class OnboardingNotifications {
  Future<NotificationAccess> access();

  /// `POST_NOTIFICATIONS` (Android 13+). Vrati, ci su povolene.
  Future<bool> requestPermission();

  /// Otvori `ACTION_REQUEST_SCHEDULE_EXACT_ALARM`.
  Future<void> requestExactAlarms();

  /// Otvori systemove nastavenia appky (zamietnute notifikacie).
  Future<void> openAppSettings();
}

final class PlatformOnboardingNotifications implements OnboardingNotifications {
  PlatformOnboardingNotifications(this._platform);

  final NotificationPlatform _platform;

  @override
  Future<NotificationAccess> access() async {
    Future<bool> safe(Future<bool> Function() f) async {
      try {
        return await f();
      } on Object {
        return false;
      }
    }

    return NotificationAccess(
      enabled: await safe(_platform.areEnabled),
      exact: await safe(_platform.canScheduleExact),
    );
  }

  @override
  Future<bool> requestPermission() async {
    try {
      return await _platform.requestPermission();
    } on Object {
      return false;
    }
  }

  @override
  Future<void> requestExactAlarms() async {
    try {
      await _platform.requestExactAlarms();
    } on Object {
      // Stav sa znova nacita po navrate do appky.
    }
  }

  @override
  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } on Object {
      // Bez nastaveni pokracuje onboarding normalne.
    }
  }
}

final Provider<OnboardingNotifications> onboardingNotificationsProvider =
    Provider<OnboardingNotifications>(
      (ref) => PlatformOnboardingNotifications(LocalNotificationsPlatform()),
      name: 'onboardingNotificationsProvider',
    );

/// Preplanovanie notifikacii po onboardingu
/// (`NotificationService.reschedule`, P-02). Integracia prepise; default
/// nic (NotificationTriggers aj tak reaguje na zmenu nastaveni).
final Provider<Future<void> Function()> onboardingRescheduleProvider =
    Provider<Future<void> Function()>(
      (ref) => () async {},
      name: 'onboardingRescheduleProvider',
    );
