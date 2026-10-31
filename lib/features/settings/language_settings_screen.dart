import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/onboarding/steps/language_step.dart'
    show onboardingLanguages;
import 'package:sakina/features/quran/quran_providers.dart';
import 'package:sakina/features/settings/settings_providers.dart';
import 'package:sakina/features/settings/settings_widgets.dart';
import 'package:sakina/ui/i18n/i18n.dart';
import 'package:sakina/ui/ui.dart';

/// Jazyk a preklad (docs/02 A10.5). Route `/settings/language`.
///
/// Jazyk UI zapise `ui.locale` (null = jazyk systemu); jazyk obsahu sa
/// riadi rovnakym klucom. Zmena prekladu ide cez
/// [SettingsActions.selectTranslation], takze karty vo feede sa hned
/// nacitaju s novym prekladom a atribuciou.
class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  /// Hodnota volby "jazyk systemu" v [RadioGroup].
  static const deviceValue = '';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.read(settingsRepositoryProvider);
    final stored = ref.watch(settingOf(SettingsKeys.uiLocale));
    final translit =
        ref.watch(settingOf(SettingsKeys.displayTranslit)).value ?? false;
    final contentLang = ref.watch(contentLanguageProvider).value;

    Future<void> pick(String? code) async {
      if (code == null) return;
      if (code == deviceValue) {
        await settings.reset(SettingsKeys.uiLocale);
      } else {
        await settings.set(SettingsKeys.uiLocale, code);
      }
    }

    return SettingsScaffold(
      title: l10n.setLanguage,
      children: [
        SettingsSection(l10n.setAppLanguage),
        if (stored.hasValue)
          RadioGroup<String>(
            groupValue: stored.value ?? deviceValue,
            onChanged: (v) => unawaited(pick(v)),
            child: Column(
              children: [
                RadioListTile<String>(
                  key: const ValueKey('language:device'),
                  value: deviceValue,
                  title: Text(l10n.setDeviceLanguage),
                ),
                for (final code in onboardingLanguages)
                  RadioListTile<String>(
                    key: ValueKey('language:$code'),
                    value: code,
                    title: Text(
                      l10n.onbLanguageName(code),
                      // Endonym v smere svojho jazyka (aj v LTR UI).
                      textDirection: textDirectionForLanguage(code),
                    ),
                  ),
              ],
            ),
          )
        else
          const Padding(
            padding: EdgeInsetsDirectional.all(SkSpace.space16),
            child: SkSkeleton.list(lines: 4),
          ),
        SettingsSection(l10n.setTranslation),
        if (contentLang == null)
          const Padding(
            padding: EdgeInsetsDirectional.all(SkSpace.space16),
            child: SkSkeleton.list(lines: 2),
          )
        else
          _TranslationChoice(lang: contentLang),
        SettingsSection(l10n.setDisplayOptions),
        SwitchListTile(
          key: const ValueKey('translit'),
          title: Text(l10n.setTranslit),
          subtitle: Text(l10n.setTranslitHelp),
          value: translit,
          onChanged: (v) =>
              unawaited(settings.set(SettingsKeys.displayTranslit, v)),
        ),
      ],
    );
  }
}

class _TranslationChoice extends ConsumerWidget {
  const _TranslationChoice({required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (lang == 'ar') return SettingsNote(l10n.setTranslationArabic);
    final sources = ref.watch(translationSourcesProvider(lang));
    final selected = ref.watch(selectedTranslationProvider).value;
    if (sources.hasError) {
      return SkErrorState(
        title: l10n.setLoadErrorTitle,
        body: l10n.setLoadErrorBody,
        onRetry: () => ref.invalidate(translationSourcesProvider(lang)),
      );
    }
    final list = sources.value;
    if (list == null) {
      return const Padding(
        padding: EdgeInsetsDirectional.all(SkSpace.space16),
        child: SkSkeleton.list(lines: 2),
      );
    }
    if (list.isEmpty) return SettingsNote(l10n.setTranslationNone);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RadioGroup<String>(
          groupValue: selected?.id ?? list.first.id,
          onChanged: (id) {
            final source = list.where((s) => s.id == id).firstOrNull;
            if (source == null) return;
            unawaited(
              ref.read(settingsActionsProvider).selectTranslation(lang, source),
            );
          },
          child: Column(
            children: [
              for (final s in list)
                RadioListTile<String>(
                  key: ValueKey('translation:${s.id}'),
                  value: s.id,
                  title: Text(s.name),
                  subtitle: Text(
                    l10n.setSourceVersionLicense(s.version, s.license),
                  ),
                ),
            ],
          ),
        ),
        SettingsNote(l10n.setTranslationDisclaimer),
      ],
    );
  }
}
