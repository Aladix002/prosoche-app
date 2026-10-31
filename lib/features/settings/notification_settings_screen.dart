import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/onboarding/onboarding_platform.dart';
import 'package:prosoche/features/settings/settings_widgets.dart';
import 'package:prosoche/ui/ui.dart';

/// Stav systemoveho povolenia notifikacii. Obnovi sa pri navrate do appky
/// (napr. zo systemovych nastaveni).
final FutureProvider<NotificationAccess> notificationAccessProvider =
    FutureProvider.autoDispose<NotificationAccess>(
      (ref) => ref.watch(onboardingNotificationsProvider).access(),
      name: 'notificationAccessProvider',
    );

/// `HH:mm` -> [TimeOfDay]; neplatne = [fallback] (07:30, default kluca).
TimeOfDay parseMorningTime(
  String value, {
  TimeOfDay fallback = const TimeOfDay(hour: 7, minute: 30),
}) {
  final m = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
  if (m == null) return fallback;
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

  Future<void> _pickTime(SettingKey<String> key, String current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: parseMorningTime(current),
    );
    if (picked == null) return;
    await ref
        .read(settingsRepositoryProvider)
        .set(key, formatMorningTime(picked));
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
    final eveningTime =
        ref.watch(settingOf(SettingsKeys.notifEveningTime)).value ??
        SettingsKeys.notifEveningTime.defaultValue;
    final eveningOn = value(SettingsKeys.notifEveningEnabled);
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
          onTap: () =>
              unawaited(_pickTime(SettingsKeys.notifMorningTime, morningTime)),
        ),
        SettingsSection(l10n.setEvening),
        toggle(
          'notif:evening',
          SettingsKeys.notifEveningEnabled,
          l10n.setEveningToggle,
          l10n.setEveningHelp,
        ),
        ListTile(
          key: const ValueKey('notif:evening_time'),
          enabled: eveningOn,
          title: Text(l10n.setEveningTime),
          trailing: Text(
            MaterialLocalizations.of(context).formatTimeOfDay(
              parseMorningTime(
                eveningTime,
                fallback: const TimeOfDay(hour: 21, minute: 0),
              ),
            ),
          ),
          onTap: () =>
              unawaited(_pickTime(SettingsKeys.notifEveningTime, eveningTime)),
        ),
        SettingsSection(l10n.setLockScreen),
        toggle(
          'notif:private',
          SettingsKeys.notifPrivateLockscreen,
          l10n.setPrivateText,
          l10n.setPrivateTextHelp,
        ),
        SettingsNote(l10n.setOsDelayNote),
      ],
    );
  }
}
