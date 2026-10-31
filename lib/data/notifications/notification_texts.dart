import 'dart:ui';

import 'package:intl/date_symbol_data_local.dart';
import 'package:prosoche/core/l10n/generated/app_localizations.dart';
import 'package:prosoche/domain/notifications/notifications.dart';
import 'package:prosoche/ui/i18n/localized_formats.dart';

/// Texty notifikacii z ARB (docs/01 7.5). Len UI texty, nikdy obsah karty.
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
      ProsocheFormats(resolved),
    );
  }

  final AppLocalizations l10n;
  final ProsocheFormats formats;

  String get localeName => l10n.localeName;

  /// Nazov a text notifikacie.
  (String title, String body) render(
    PlannedNotification n, {
    required bool private,
  }) => private ? _private(n) : _standard(n);

  (String, String) _standard(PlannedNotification n) => switch (n.kind) {
    NotificationKind.morning => (
      l10n.notifMorningTitle,
      l10n.notifMorningBody(n.cardMinutes ?? 10),
    ),
    NotificationKind.openApp => (
      l10n.notifOpenAppTitle,
      l10n.notifOpenAppBody(l10n.appTitle),
    ),
  };

  (String, String) _private(PlannedNotification n) => switch (n.kind) {
    NotificationKind.morning => (l10n.appTitle, l10n.notifMorningPrivateBody),
    NotificationKind.openApp => (l10n.appTitle, l10n.notifOpenAppPrivateBody),
  };

  String channelName(NotificationChannel channel) => switch (channel) {
    NotificationChannel.daily => l10n.notifChannelDaily,
    NotificationChannel.system => l10n.notifChannelSystem,
  };

  String channelDescription(NotificationChannel channel) => switch (channel) {
    NotificationChannel.daily => l10n.notifChannelDailyDescription,
    NotificationChannel.system => l10n.notifChannelSystemDescription,
  };
}
