import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/quran/quran_format.dart';
import 'package:sakina/features/quran/quran_providers.dart';
import 'package:sakina/ui/ui.dart';

/// "Aa" sheet citatela (docs/02 A5.2): velkost arabciny, prepinac
/// prekladu a vyber zdroja prekladu (A10.5). Transliteracia je skryta,
/// kym nie su data slov (FEATURE_WORDS=false).
Future<void> showReaderSettingsSheet(BuildContext context) {
  final l10n = context.l10n;
  return showSkInfoSheet<void>(
    context,
    title: l10n.quranTextSettings,
    closeLabel: l10n.quranClose,
    child: const ReaderSettingsPanel(),
  );
}

class ReaderSettingsPanel extends ConsumerWidget {
  const ReaderSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final settings = ref.watch(settingsRepositoryProvider);
    final scale = ref.watch(readerArabicScaleProvider);
    final showTranslation = ref.watch(readerShowTranslationProvider);
    final lang = ref.watch(contentLanguageProvider).value;
    final sources = lang == null || lang == 'ar'
        ? const <TranslationSource>[]
        : ref.watch(translationSourcesProvider(lang)).value ?? const [];
    final selected = ref.watch(selectedTranslationProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.quranArabicSize, style: sk.text.titleSmall),
        const SizedBox(height: SkSpace.space8),
        SegmentedButton<SkArabicScale>(
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
        if (lang != 'ar') ...[
          const SizedBox(height: SkSpace.space16),
          SwitchListTile(
            contentPadding: EdgeInsetsDirectional.zero,
            title: Text(l10n.quranShowTranslation),
            value: showTranslation,
            onChanged: (v) =>
                unawaited(settings.set(SettingsKeys.displayTranslation, v)),
          ),
          if (sources.length > 1) ...[
            const SizedBox(height: SkSpace.space8),
            Text(l10n.quranTranslationSource, style: sk.text.titleSmall),
            RadioGroup<String>(
              groupValue: selected?.id,
              onChanged: (id) {
                final source = sources.where((s) => s.id == id).firstOrNull;
                if (source != null && lang != null) {
                  unawaited(
                    ref
                        .read(quranRepositoryProvider)
                        .selectTranslation(lang, source),
                  );
                }
              },
              child: Column(
                children: [
                  for (final s in sources)
                    RadioListTile<String>(
                      contentPadding: EdgeInsetsDirectional.zero,
                      value: s.id,
                      title: Text(s.name),
                      subtitle: Text(translationAttribution(context, s)),
                    ),
                ],
              ),
            ),
          ] else if (selected != null)
            Text(
              [
                l10n.quranTranslationOfMeaning(selected.name),
                translationAttribution(context, selected),
              ].join('\n'),
              style: sk.text.bodySmall,
            ),
        ],
      ],
    );
  }
}

/// Akcie versa (long press alebo tlacidlo "..."), docs/02 A5.2. Share,
/// Play a Report pribudnu s balikmi `share_plus`/`url_launcher` a audiom.
Future<void> showVerseActionsSheet(
  BuildContext context, {
  required bool saved,
  required String copyText,
  required ValueChanged<bool> onSaved,
  required VoidCallback onCopied,
}) {
  final l10n = context.l10n;
  return showSkInfoSheet<void>(
    context,
    title: l10n.quranVerseActions,
    closeLabel: l10n.quranClose,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: EdgeInsetsDirectional.zero,
          leading: const Icon(Icons.copy),
          title: Text(l10n.quranCopy),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: copyText));
            if (context.mounted) await Navigator.of(context).maybePop();
            // Ziadny snackbar nad arabskym textom (docs/01 1.3 bod 3).
            onCopied();
          },
        ),
        ListTile(
          contentPadding: EdgeInsetsDirectional.zero,
          leading: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
          title: Text(saved ? l10n.quranRemoveSaved : l10n.quranSave),
          onTap: () {
            onSaved(!saved);
            Navigator.of(context).maybePop();
          },
        ),
      ],
    ),
  );
}
