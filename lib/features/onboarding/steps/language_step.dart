import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/infra/time_providers.dart';
import 'package:prosoche/data/repositories/providers.dart';
import 'package:prosoche/data/repositories/quran/quran_repository.dart';
import 'package:prosoche/data/repositories/settings/settings_providers.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/onboarding/onboarding_screen.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

/// Jazyky skryte vo vybere, kym nie su aktivne v obsahu (BN do potvrdenia
/// `bengali_zakaria`, docs/02 O1, docs/10 cut list 2).
const onboardingHiddenLanguages = {'bn'};

/// Jazyky na vyber v O1 (poradie [ProsocheLocales.all]).
List<String> get onboardingLanguages => [
  for (final l in ProsocheLocales.all)
    if (!onboardingHiddenLanguages.contains(l.languageCode)) l.languageCode,
];

/// Predvolba: ulozena volba, inak jazyk systemu, inak `en`.
String defaultOnboardingLanguage({required String device, String? stored}) {
  final languages = onboardingLanguages;
  if (stored != null && languages.contains(stored)) return stored;
  return languages.contains(device) ? device : 'en';
}

/// Preklady Koranu pre jazyk a aktualne zvoleny (O1 dropdown).
typedef TranslationChoice = ({
  List<TranslationSource> sources,
  TranslationSource? selected,
});

final FutureProviderFamily<TranslationChoice, String>
onboardingTranslationsProvider = FutureProvider.autoDispose
    .family<TranslationChoice, String>((ref, lang) async {
      final repo = ref.watch(quranRepositoryProvider);
      final sources = await repo.translationSources(lang);
      final selected = await repo.selectedTranslation(lang);
      return (sources: sources, selected: selected ?? sources.firstOrNull);
    }, name: 'onboardingTranslationsProvider');

/// O1 Jazyk s uvitanim (docs/02 A1). Vyber jazyka hned zapise `ui.locale`,
/// takze UI a smer textu sa prepnu okamzite (AR, UR = RTL).
class LanguageStep extends ConsumerStatefulWidget {
  const LanguageStep({required this.onNext, super.key});

  final OnboardingNext onNext;

  @override
  ConsumerState<LanguageStep> createState() => _LanguageStepState();
}

class _LanguageStepState extends ConsumerState<LanguageStep> {
  String? _picked;
  TranslationSource? _source;
  bool _busy = false;

  String get _language =>
      _picked ??
      defaultOnboardingLanguage(
        stored: ref.watch(settingOf(SettingsKeys.uiLocale)).value,
        device: ref.watch(deviceLanguageProvider),
      );

  Future<void> _pick(String? lang) async {
    if (lang == null || lang == _language) return;
    setState(() {
      _picked = lang;
      _source = null;
    });
    await ref.read(settingsRepositoryProvider).set(SettingsKeys.uiLocale, lang);
  }

  Future<void> _continue(TranslationSource? source) async {
    setState(() => _busy = true);
    try {
      final lang = _language;
      await ref
          .read(settingsRepositoryProvider)
          .set(SettingsKeys.uiLocale, lang);
      if (source != null) {
        await ref.read(quranRepositoryProvider).selectTranslation(lang, source);
      }
      await widget.onNext();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = _language;
    // AR je bez prekladu Koranu (dropdown sa nezobrazi).
    final translations = lang == 'ar'
        ? null
        : ref.watch(onboardingTranslationsProvider(lang));
    if (translations case AsyncError()) {
      return SkErrorState(title: l10n.onbFatalTitle, body: l10n.onbFatalBody);
    }
    final source = _source ?? translations?.value?.selected;
    final loading = translations?.isLoading ?? false;
    final text = context.sk.text;
    return OnboardingStepBody(
      leading: [
        // D-05: uvitanie s medailonom motivu (pomaly sa dokresli).
        const Center(child: SkMotifBadge(size: 112, animate: true)),
        const SizedBox(height: SkSpace.space16),
        Semantics(
          header: true,
          child: Text(l10n.appTitle, style: text.headlineMedium),
        ),
        const SizedBox(height: SkSpace.space8),
        Text(l10n.onbWelcomeBody, style: text.bodyLarge),
        const SizedBox(height: SkSpace.space4),
        Text(l10n.onbWelcomeNote, style: text.bodyMedium),
        const SizedBox(height: SkSpace.space24),
      ],
      title: l10n.onbLanguageTitle,
      body: l10n.onbLanguageBody,
      primaryLabel: l10n.onbContinue,
      busy: _busy,
      onPrimary: loading ? null : () => _continue(source),
      children: [
        RadioGroup<String>(
          groupValue: lang,
          onChanged: _pick,
          child: Column(
            children: [
              for (final code in onboardingLanguages)
                RadioListTile<String>(
                  key: ValueKey('language:$code'),
                  value: code,
                  contentPadding: EdgeInsetsDirectional.zero,
                  title: Text(
                    l10n.onbLanguageName(code),
                    // Endonym v smere svojho jazyka (aj v LTR UI).
                    textDirection: textDirectionForLanguage(code),
                  ),
                ),
            ],
          ),
        ),
        if (translations != null) ...[
          const SizedBox(height: SkSpace.space16),
          _TranslationPicker(
            choice: translations.value,
            selected: source,
            onChanged: (s) => setState(() => _source = s),
          ),
        ],
      ],
    );
  }
}

class _TranslationPicker extends StatelessWidget {
  const _TranslationPicker({
    required this.choice,
    required this.selected,
    required this.onChanged,
  });

  /// null = nacitava sa.
  final TranslationChoice? choice;
  final TranslationSource? selected;
  final ValueChanged<TranslationSource?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.sk.text;
    final sources = choice?.sources;
    final Widget picker;
    if (sources == null) {
      picker = const SkSkeletonBox(height: SkSpace.minTouchTarget);
    } else if (sources.isEmpty) {
      picker = Text(l10n.onbTranslationNone, style: text.bodyMedium);
    } else if (sources.length == 1) {
      picker = Text(sources.single.name, style: text.bodyLarge);
    } else {
      picker = DropdownButtonFormField<String>(
        key: const ValueKey('translation'),
        initialValue: selected?.id,
        isExpanded: true,
        decoration: InputDecoration(labelText: l10n.onbTranslationLabel),
        items: [
          for (final s in sources)
            DropdownMenuItem(
              value: s.id,
              child: Text(s.name, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (id) => onChanged(sources.firstWhere((s) => s.id == id)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sources == null || sources.length < 2)
          Text(l10n.onbTranslationLabel, style: text.titleSmall),
        const SizedBox(height: SkSpace.space4),
        picker,
      ],
    );
  }
}
