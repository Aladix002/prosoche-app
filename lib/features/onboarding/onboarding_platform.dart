import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/data/notifications/notifications.dart';
import 'package:url_launcher/url_launcher.dart';

// Tenke rozhrania nad platformou pre onboarding (notifikacie). Widget testy
// ich prepisu fake implementaciou.

/// Otvori systemove nastavenia appky: Android kanal v `MainActivity`,
/// iOS `app-settings:`.
Future<void> openSystemAppSettings() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    await const MethodChannel('app.prosoche/system')
        .invokeMethod<bool>('openAppSettings');
  } else {
    await launchUrl(Uri.parse('app-settings:'));
  }
}

/// Stav povoleni notifikacii (O4).
@immutable
final class NotificationAccess {
  const NotificationAccess({required this.enabled});

  /// Notifikacie appky su zapnute (Android < 13 vzdy).
  final bool enabled;

  @override
  bool operator ==(Object other) =>
      other is NotificationAccess && other.enabled == enabled;

  @override
  int get hashCode => enabled.hashCode;
}

/// Povolenia notifikacii pre O4 nad [NotificationPlatform] (P-02).
abstract interface class OnboardingNotifications {
  Future<NotificationAccess> access();

  /// `POST_NOTIFICATIONS` (Android 13+). Vrati, ci su povolene.
  Future<bool> requestPermission();

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

    return NotificationAccess(enabled: await safe(_platform.areEnabled));
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
  Future<void> openAppSettings() async {
    try {
      await openSystemAppSettings();
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
