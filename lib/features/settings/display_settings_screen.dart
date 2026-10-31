import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/library/reader_screen.dart';
import 'package:prosoche/features/settings/settings_providers.dart';
import 'package:prosoche/features/settings/settings_widgets.dart';

/// Denna sada a zobrazenie (docs/02 A10.6). Route `/settings/display`.
///
/// Vysoky kontrast sa riadi systemom (MaterialApp `highContrastTheme`).
class DisplaySettingsScreen extends ConsumerWidget {
  const DisplaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.read(settingsRepositoryProvider);
    final theme =
        ref.watch(settingOf(SettingsKeys.displayTheme)).value ?? 'system';
    final simple = ref.watch(settingOf(SettingsKeys.simpleMode)).value ?? false;
    final count = ref.watch(settingOf(SettingsKeys.feedCardsCount)).value;

    return SettingsScaffold(
      title: l10n.setDisplay,
      children: [
        SettingsSection(l10n.setTheme, help: l10n.setHighContrastNote),
        RadioGroup<String>(
          groupValue: theme,
          onChanged: (v) {
            if (v != null) {
              unawaited(settings.set(SettingsKeys.displayTheme, v));
            }
          },
          child: Column(
            children: [
              for (final v in themeValues)
                RadioListTile<String>(
                  key: ValueKey('theme:$v'),
                  value: v,
                  title: Text(l10n.setThemeName(v)),
                ),
            ],
          ),
        ),
        SettingsSection(l10n.readerTextSize, help: l10n.setReaderSizeHelp),
        const ReaderSizePicker(showTitle: false),
        SettingsSection(l10n.setDailySet),
        SwitchListTile(
          key: const ValueKey('simple_mode'),
          title: Text(l10n.setSimpleMode),
          subtitle: Text(l10n.setSimpleModeHelp),
          value: simple,
          onChanged: (v) => unawaited(settings.set(SettingsKeys.simpleMode, v)),
        ),
        SettingsSection(l10n.setCardsCount, help: l10n.setCardsCountHelp),
        RadioGroup<int>(
          groupValue: count ?? SettingsKeys.feedCardsCount.defaultValue,
          onChanged: (v) {
            if (v != null) {
              unawaited(settings.set(SettingsKeys.feedCardsCount, v));
            }
          },
          child: Column(
            children: [
              for (final n in const [8, 12, 16])
                RadioListTile<int>(
                  key: ValueKey('cards:$n'),
                  value: n,
                  title: Text(l10n.setCardsCountValue(n)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
