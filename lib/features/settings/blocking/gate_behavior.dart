import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/blocker/blocked_apps_repository.dart';
import 'package:prosoche/data/repositories/settings/settings_providers.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/settings/blocking/blocking_widgets.dart';
import 'package:prosoche/features/settings/notification_settings_screen.dart'
    show formatMorningTime, parseMorningTime;
import 'package:prosoche/features/settings/settings_widgets.dart';
import 'package:prosoche/ui/ui.dart';

/// `gate.practice_first.until` ako [TimeOfDay] (default 10:00).
TimeOfDay practiceFirstUntil(String value) =>
    parseMorningTime(value, fallback: const TimeOfDay(hour: 10, minute: 0));

/// A10.1 "At the gate" (G-01): otazka zameru, rastuci odpor a ranny zamok
/// "Practice first" (podobrazovka [PracticeFirstScreen]).
class GateBehaviorSection extends ConsumerWidget {
  const GateBehaviorSection({required this.onPracticeFirst, super.key});

  final VoidCallback onPracticeFirst;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.read(settingsRepositoryProvider);
    bool value(SettingKey<bool> key) =>
        ref.watch(settingOf(key)).value ?? key.defaultValue;
    final practiceOn = value(SettingsKeys.gatePracticeFirst);
    final until =
        ref.watch(settingOf(SettingsKeys.gatePracticeFirstUntil)).value ??
        SettingsKeys.gatePracticeFirstUntil.defaultValue;
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(practiceFirstUntil(until));

    Widget toggle(String id, SettingKey<bool> key, String title, String sub) =>
        SwitchListTile(
          key: ValueKey(id),
          title: Text(title),
          subtitle: Text(sub),
          value: value(key),
          onChanged: (v) => unawaited(settings.set(key, v)),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSection(l10n.blkGateSection),
        toggle(
          'blocking:intent',
          SettingsKeys.gateAskIntent,
          l10n.blkAskIntent,
          l10n.blkAskIntentHelp,
        ),
        toggle(
          'blocking:friction',
          SettingsKeys.gateRisingFriction,
          l10n.blkFriction,
          l10n.blkFrictionHelp,
        ),
        SettingsNavTile(
          key: const ValueKey('blocking:practice_first'),
          icon: Icons.wb_twilight,
          title: l10n.blkPracticeFirst,
          value: practiceOn
              ? l10n.blkPracticeFirstOn(time)
              : l10n.blkPracticeFirstOff,
          onTap: onPracticeFirst,
        ),
      ],
    );
  }
}

/// `/settings/blocking/practice-first` (G-01): prepinac, cas konca
/// ranneho zamku a appky, na ktore plati (`blocked_app.practice_first`).
class PracticeFirstScreen extends ConsumerWidget {
  const PracticeFirstScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.read(settingsRepositoryProvider);
    final on =
        ref.watch(settingOf(SettingsKeys.gatePracticeFirst)).value ??
        SettingsKeys.gatePracticeFirst.defaultValue;
    final until =
        ref.watch(settingOf(SettingsKeys.gatePracticeFirstUntil)).value ??
        SettingsKeys.gatePracticeFirstUntil.defaultValue;
    final apps = ref.watch(blockedAppsProvider);
    final repo = ref.read(blockedAppsRepositoryProvider);

    Future<void> pickTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: practiceFirstUntil(until),
      );
      if (picked == null) return;
      await settings.set(
        SettingsKeys.gatePracticeFirstUntil,
        formatMorningTime(picked),
      );
    }

    return Scaffold(
      appBar: skAppBar(context, title: l10n.blkPracticeFirst),
      body: SettingsList(
        children: [
          SwitchListTile(
            key: const ValueKey('practice_first:switch'),
            title: Text(l10n.blkPracticeFirst),
            subtitle: Text(l10n.blkPracticeFirstHelp),
            value: on,
            onChanged: (v) =>
                unawaited(settings.set(SettingsKeys.gatePracticeFirst, v)),
          ),
          ListTile(
            key: const ValueKey('practice_first:until'),
            enabled: on,
            title: Text(l10n.blkPracticeFirstUntil),
            trailing: Text(
              MaterialLocalizations.of(context)
                  .formatTimeOfDay(practiceFirstUntil(until)),
            ),
            onTap: () => unawaited(pickTime()),
          ),
          SettingsSection(l10n.blkPracticeFirstApps),
          ...apps.when(
            loading: () => [const SkSkeleton.list()],
            error: (_, _) => [SettingsNote(l10n.blkLoadError)],
            data: (list) => [
              if (list.isEmpty) SettingsNote(l10n.blkPracticeFirstAppsNone),
              for (final app in list)
                CheckboxListTile(
                  key: ValueKey('practice_first:app:${app.id}'),
                  secondary: GateAppIcon(app.ref),
                  title: Text(app.displayName),
                  value: app.practiceFirst,
                  onChanged: on
                      ? (v) => unawaited(
                          repo.update(
                            app.id,
                            BlockedAppPatch(practiceFirst: v ?? true),
                          ),
                        )
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
