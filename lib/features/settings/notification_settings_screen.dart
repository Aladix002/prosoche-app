import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/prayer/prayer.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/onboarding/onboarding_platform.dart';
import 'package:sakina/features/prayer/prayer_texts.dart';
import 'package:sakina/features/settings/settings_widgets.dart';
import 'package:sakina/ui/ui.dart';

/// Stav systemoveho povolenia notifikacii a presnych alarmov. Obnovi sa
/// pri navrate do appky (napr. zo systemovych nastaveni).
final FutureProvider<NotificationAccess> notificationAccessProvider =
    FutureProvider.autoDispose<NotificationAccess>(
      (ref) => ref.watch(onboardingNotificationsProvider).access(),
      name: 'notificationAccessProvider',
    );

/// `HH:mm` -> [TimeOfDay]; neplatne = 07:30 (default kluca).
TimeOfDay parseMorningTime(String value) {
  final m = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
  if (m == null) return const TimeOfDay(hour: 7, minute: 30);
  return TimeOfDay(hour: int.parse(m[1]!), minute: int.parse(m[2]!));
}

/// [TimeOfDay] -> `HH:mm` pre `notif.morning.time`.
String formatMorningTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:'
    '${t.minute.toString().padLeft(2, '0')}';

/// Notifikacie (docs/02 A10.4). Route `/settings/notifications`.
///
/// Prepinace zapisuju kluce `notif.*`; preplanovanie spusti
/// `NotificationTriggers` (P-02), ktory tieto kluce sleduje.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(notificationAccessProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _pickMorningTime(String current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: parseMorningTime(current),
    );
    if (picked == null) return;
    await ref
        .read(settingsRepositoryProvider)
        .set(SettingsKeys.notifMorningTime, formatMorningTime(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.read(settingsRepositoryProvider);
    final platform = ref.read(onboardingNotificationsProvider);
    bool value(SettingKey<bool> key) =>
        ref.watch(settingOf(key)).value ?? key.defaultValue;
    final morningTime =
        ref.watch(settingOf(SettingsKeys.notifMorningTime)).value ??
        SettingsKeys.notifMorningTime.defaultValue;
    final morningOn = value(SettingsKeys.notifMorningEnabled);
    final access = ref.watch(notificationAccessProvider).value;

    Widget toggle(
      String id,
      SettingKey<bool> key,
      String title, [
      String? sub,
    ]) => SwitchListTile(
      key: ValueKey(id),
      title: Text(title),
      subtitle: sub == null ? null : Text(sub),
      value: value(key),
      onChanged: (v) => unawaited(settings.set(key, v)),
    );

    return SettingsScaffold(
      title: l10n.setNotifications,
      children: [
        if (access != null && !access.enabled)
          Padding(
            padding: const EdgeInsetsDirectional.all(SkSpace.space16),
            child: SkInlineBanner(
              key: const ValueKey('notif:blocked'),
              variant: SkBannerVariant.warning,
              message: l10n.setNotifBlocked,
              actionLabel: l10n.setOpenSettings,
              onAction: () => unawaited(platform.openAppSettings()),
            ),
          ),
        SettingsSection(l10n.setPrayerReminders),
        for (final p in Prayer.salah)
          toggle(
            'notif:${p.name}',
            SettingsKeys.notifPrayer(p.name),
            context.prayerName(p),
          ),
        SettingsSection(l10n.setMorning),
        toggle(
          'notif:morning',
          SettingsKeys.notifMorningEnabled,
          l10n.setMorningToggle,
          l10n.setMorningHelp,
        ),
        ListTile(
          key: const ValueKey('notif:morning_time'),
          enabled: morningOn,
          title: Text(l10n.setMorningTime),
          trailing: Text(
            MaterialLocalizations.of(context)
                .formatTimeOfDay(parseMorningTime(morningTime)),
          ),
          onTap: () => unawaited(_pickMorningTime(morningTime)),
        ),
        SettingsSection(l10n.setLockScreen),
        toggle(
          'notif:private',
          SettingsKeys.notifPrivateLockscreen,
          l10n.setPrivateText,
          l10n.setPrivateTextHelp,
        ),
        SettingsSection(l10n.setExactAlarms),
        ListTile(
          key: const ValueKey('notif:exact'),
          title: Text(
            access == null
                ? l10n.setStatusUnknown
                : access.exact
                ? l10n.setExactOn
                : l10n.setExactOff,
          ),
          subtitle: Text(l10n.setExactHelp),
          trailing: access == null || access.exact
              ? null
              : TextButton(
                  onPressed: () => unawaited(platform.requestExactAlarms()),
                  child: Text(l10n.setAllow),
                ),
        ),
        SettingsNote(l10n.setOsDelayNote),
      ],
    );
  }
}
