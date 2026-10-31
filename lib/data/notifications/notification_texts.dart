import 'dart:ui';

import 'package:intl/date_symbol_data_local.dart';
import 'package:sakina/core/l10n/generated/app_localizations.dart';
import 'package:sakina/domain/notifications/notifications.dart';
import 'package:sakina/domain/prayer/prayer.dart';
import 'package:sakina/ui/i18n/localized_formats.dart';

/// Texty notifikacii z ARB (docs/01 7.5). Len UI texty, ziadny vers,
/// meno Allaha ani hadis; text, ktory by pravidlo porusil (napr. nazov
/// eventu), sa nahradi sukromnou verziou.
final class NotificationTexts {
  NotificationTexts(this.l10n, this.formats);

  /// Texty pre [locale]; nepodporovany jazyk = EN. Nacita aj symboly
  /// datumov `intl` (v background isolate nie su nacitane).
  static Future<NotificationTexts> load(Locale locale) async {
    final supported = AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    );
    final resolved = supported
        ? Locale(locale.languageCode)
        : const Locale('en');
    await initializeDateFormatting(resolved.toLanguageTag());
    return NotificationTexts(
      lookupAppLocalizations(resolved),
      SakinaFormats(resolved),
    );
  }

  final AppLocalizations l10n;
  final SakinaFormats formats;

  String get localeName => l10n.localeName;

  /// Nazov a text notifikacie.
  (String title, String body) render(
    PlannedNotification n, {
    required bool private,
  }) {
    if (!private) {
      final standard = _standard(n);
      if (NotificationContentPolicy.allows(standard.$1) &&
          NotificationContentPolicy.allows(standard.$2)) {
        return standard;
      }
    }
    return _private(n);
  }

  (String, String) _standard(PlannedNotification n) {
    switch (n.kind) {
      case NotificationKind.prayer:
      case NotificationKind.jumuah:
        final name = l10n.notifPrayerName(
          n.kind == NotificationKind.jumuah ? 'jumuah' : n.prayer!.name,
        );
        return (
          l10n.notifPrayerTitle(name, formats.time(n.at)),
          l10n.notifPrayerBody(name),
        );
      case NotificationKind.morning:
        return (
          l10n.notifMorningTitle,
          l10n.notifMorningBody(n.cardMinutes ?? 10),
        );
      case NotificationKind.morningEvent:
        return (n.eventName!, l10n.notifMorningEventBody(n.eventName!));
      case NotificationKind.openApp:
        return (l10n.notifOpenAppTitle, l10n.notifOpenAppBody(l10n.appTitle));
      case NotificationKind.suhur:
        return (
          l10n.ramadanNotifSuhurTitle(formats.time(n.at)),
          l10n.ramadanNotifSuhurBody(n.cardMinutes ?? 0),
        );
      case NotificationKind.iftar:
        return (
          l10n.ramadanNotifIftarTitle(formats.time(n.at)),
          l10n.notifPrayerBody(l10n.notifPrayerName(Prayer.maghrib.name)),
        );
    }
  }

  (String, String) _private(PlannedNotification n) => switch (n.kind) {
    NotificationKind.prayer ||
    NotificationKind.jumuah ||
    NotificationKind.iftar => (
      l10n.notifPrivateTitle(l10n.appTitle, formats.time(n.at)),
      l10n.notifPrivateBody,
    ),
    NotificationKind.morning ||
    NotificationKind.morningEvent ||
    NotificationKind.suhur => (l10n.appTitle, l10n.notifMorningPrivateBody),
    NotificationKind.openApp => (l10n.appTitle, l10n.notifOpenAppPrivateBody),
  };

  String channelName(NotificationChannel channel) => switch (channel) {
    NotificationChannel.prayer => l10n.notifChannelPrayer,
    NotificationChannel.daily => l10n.notifChannelDaily,
    NotificationChannel.system => l10n.notifChannelSystem,
  };

  String channelDescription(NotificationChannel channel) => switch (channel) {
    NotificationChannel.prayer => l10n.notifChannelPrayerDescription,
    NotificationChannel.daily => l10n.notifChannelDailyDescription,
    NotificationChannel.system => l10n.notifChannelSystemDescription,
  };
}
