import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/flags/feature_flags.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/prayer/prayer_texts.dart';
import 'package:sakina/features/settings/blocking/blocking_providers.dart';
import 'package:sakina/features/settings/settings_paths.dart';
import 'package:sakina/features/settings/settings_widgets.dart';

/// Koren nastaveni (docs/02 A10.0). Route `/settings`.
///
/// Kazdy riadok ukazuje aktualnu hodnotu. Brana len pri `FEATURE_GATE`,
/// audio len pri `FEATURE_AUDIO`; zaloha (F-09) zatial skryta.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final flags = ref.watch(featureFlagsProvider);
    void open(String path) => unawaited(context.push(path));

    final method = ref.watch(prayerConfigProvider).value?.settings.method;
    final offset = ref.watch(settingOf(SettingsKeys.hijriOffset)).value;
    final language = Localizations.localeOf(context).languageCode;
    final blocker = flags.gate
        ? ref.watch(settingOf(SettingsKeys.blockerEnabled)).value
        : null;
    // Brana zapnuta, ale chyba povolenie (I-03).
    final gateWarning =
        flags.gate && (ref.watch(gateNeedsAttentionProvider).value ?? false);

    return SettingsScaffold(
      title: l10n.setTitle,
      children: [
        if (flags.gate)
          SettingsNavTile(
            icon: Icons.shield_outlined,
            title: l10n.setGate,
            value: gateWarning
                ? l10n.setGateNeedsAttention
                : blocker == null
                ? null
                : l10n.setOnOff(blocker.toString()),
            warning: gateWarning,
            onTap: () => open(SettingsPaths.blocking),
          ),
        SettingsNavTile(
          icon: Icons.access_time,
          title: l10n.setPrayerTimes,
          value: method == null ? null : context.methodName(method),
          onTap: () => open(SettingsPaths.prayer),
        ),
        SettingsNavTile(
          icon: Icons.notifications_outlined,
          title: l10n.setNotifications,
          onTap: () => open(SettingsPaths.notifications),
        ),
        SettingsNavTile(
          icon: Icons.translate,
          title: l10n.setLanguage,
          value: l10n.onbLanguageName(language),
          onTap: () => open(SettingsPaths.language),
        ),
        SettingsNavTile(
          icon: Icons.text_fields,
          title: l10n.setDisplay,
          onTap: () => open(SettingsPaths.display),
        ),
        if (flags.audio)
          SettingsNavTile(
            icon: Icons.headphones_outlined,
            title: l10n.setAudio,
            onTap: () => open(SettingsPaths.audio),
          ),
        SettingsNavTile(
          icon: Icons.calendar_month_outlined,
          title: l10n.setHijriCalendar,
          value: offset == null ? null : context.hijriOffsetLabel(offset),
          onTap: () => open(SettingsPaths.calendar),
        ),
        SettingsNavTile(
          icon: Icons.lock_outline,
          title: l10n.setPrivacy,
          onTap: () => open(SettingsPaths.privacy),
        ),
        SettingsNavTile(
          icon: Icons.menu_book_outlined,
          title: l10n.setSources,
          onTap: () => open(SettingsPaths.sources),
        ),
        SettingsNavTile(
          icon: Icons.info_outline,
          title: l10n.setAbout,
          onTap: () => open(SettingsPaths.about),
        ),
      ],
    );
  }
}
