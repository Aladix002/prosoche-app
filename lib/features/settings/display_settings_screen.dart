import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/quran/quran_providers.dart';
import 'package:prosoche/features/settings/settings_providers.dart';
import 'package:prosoche/features/settings/settings_widgets.dart';
import 'package:prosoche/ui/ui.dart';

/// Prvy vers (1:1) ako nahlad velkosti arabciny; text z content.db.
final FutureProvider<AyahView?> arabicPreviewProvider =
    FutureProvider<AyahView?>(
      (ref) async => (await ref.watch(quranRepositoryProvider).ayahs([
        AyahId.first,
      ], lang: 'ar')).firstOrNull,
      name: 'arabicPreviewProvider',
    );

/// Denna sada a zobrazenie (docs/02 A10.6). Route `/settings/display`.
///
/// Pocet kariet len pri `FEATURE_WORDS` (inak N = 10, docs/02 0.3).
/// Vysoky kontrast sa riadi systemom (MaterialApp `highContrastTheme`).
class DisplaySettingsScreen extends ConsumerWidget {
  const DisplaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.read(settingsRepositoryProvider);
    final theme =
        ref.watch(settingOf(SettingsKeys.displayTheme)).value ?? 'system';
    final scale = ref.watch(readerArabicScaleProvider);
    final simple = ref.watch(settingOf(SettingsKeys.simpleMode)).value ?? false;
    final words = ref.watch(featureFlagsProvider).words;
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
        SettingsSection(l10n.setArabicSize),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: SkSpace.space16,
          ),
          child: SegmentedButton<SkArabicScale>(
            key: const ValueKey('arabic_scale'),
            showSelectedIcon: false,
            segments: [
              for (final (s, label) in [
                (SkArabicScale.s, l10n.quranArabicSizeS),
                (SkArabicScale.m, l10n.quranArabicSizeM),
                (SkArabicScale.l, l10n.quranArabicSizeL),
                (SkArabicScale.xl, l10n.quranArabicSizeXL),
              ])
                ButtonSegment(value: s, label: Text(label)),
            ],
            selected: {scale},
            onSelectionChanged: (s) => unawaited(
              settings.set(SettingsKeys.displayArabicScale, s.first.factor),
            ),
          ),
        ),
        _ArabicPreview(scale: scale),
        SettingsSection(l10n.setDailySet),
        SwitchListTile(
          key: const ValueKey('simple_mode'),
          title: Text(l10n.setSimpleMode),
          subtitle: Text(l10n.setSimpleModeHelp),
          value: simple,
          onChanged: (v) => unawaited(settings.set(SettingsKeys.simpleMode, v)),
        ),
        if (words) ...[
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
      ],
    );
  }
}

class _ArabicPreview extends ConsumerWidget {
  const _ArabicPreview({required this.scale});

  final SkArabicScale scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ayah = ref.watch(arabicPreviewProvider).value;
    final theme = Theme.of(context);
    final typography = context.sk.type.copyWith(arabicScale: scale);
    return Padding(
      padding: const EdgeInsetsDirectional.all(SkSpace.space16),
      child: Card(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(SkSpace.space16),
          child: ayah == null
              ? const SkSkeletonBox(height: SkSpace.space48)
              : Theme(
                  data: theme.copyWith(
                    extensions: [
                      ...theme.extensions.values.where(
                        (e) => e is! ProsocheTypography,
                      ),
                      typography,
                    ],
                  ),
                  child: SkArabicText.quran([
                    SkArabicSegment(ayah.textUthmani),
                  ], textSimple: ayah.textUthmani),
                ),
        ),
      ),
    );
  }
}
