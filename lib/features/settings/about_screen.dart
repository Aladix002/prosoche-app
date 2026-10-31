import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/data/content/content_providers.dart';
import 'package:sakina/data/content/hadith_extra_pack_providers.dart';
import 'package:sakina/features/settings/problem_report_sheet.dart';
import 'package:sakina/features/settings/settings_paths.dart';
import 'package:sakina/features/settings/settings_providers.dart';
import 'package:sakina/features/settings/settings_widgets.dart';
import 'package:sakina/features/settings/sources_screen.dart';
import 'package:sakina/ui/i18n/i18n.dart';
import 'package:sakina/ui/ui.dart';

/// `X.Y.Z+BUILD` (docs/02 A10.10); bez cisla buildu len `X.Y.Z`.
String appVersionLabel(String version, String? build) =>
    build == null || build.isEmpty ? version : '$version+$build';

/// O appke (docs/02 A10.10). Route `/settings/about`.
///
/// Verzia appky, verzia obsahu, disclaimery (docs/11 12.1-12.3), feedback a
/// privacy policy (ak su URL nastavene), zdroje a open-source licencie.
/// Rucna kontrola aktualizacie obsahu pride s D-05.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final version = appVersionLabel(
      ref.watch(appVersionProvider).toString(),
      ref.watch(appBuildNumberProvider),
    );
    final content = ref.watch(sourcesInfoProvider);
    final links = ref.watch(appLinksProvider);
    final opener = ref.read(linkOpenerProvider);
    final contentVersion = content.hasError
        ? l10n.setUnavailable
        : content.value?.contentVersion ?? (content.hasValue ? '-' : '…');

    return SettingsScaffold(
      title: l10n.setAbout,
      children: [
        ListTile(
          key: const ValueKey('about:version'),
          title: Text(l10n.setAppVersion),
          subtitle: Text(
            version,
            textDirection: textDirectionForLanguage('en'),
          ),
        ),
        ListTile(
          key: const ValueKey('about:content'),
          title: Text(l10n.setContentVersionTitle),
          subtitle: Text(
            contentVersion,
            textDirection: textDirectionForLanguage('en'),
          ),
        ),
        const _HadithExtraPackTile(),
        SettingsSection(l10n.setDisclaimers),
        SettingsNote(l10n.setDisclaimerPrayer),
        SettingsNote(l10n.setDisclaimerQuran),
        SettingsNote(l10n.setDisclaimerRulings),
        SettingsSection(l10n.setMore),
        ListTile(
          key: const ValueKey('about:report'),
          title: Text(l10n.setReportProblem),
          trailing: const Icon(Icons.flag_outlined),
          onTap: () => unawaited(showProblemReportSheet(context)),
        ),
        if (links.feedbackUri case final uri?)
          ListTile(
            key: const ValueKey('about:feedback'),
            title: Text(l10n.setFeedback),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => unawaited(opener(uri)),
          ),
        if (links.privacyPolicyUri case final uri?)
          ListTile(
            key: const ValueKey('about:policy'),
            title: Text(l10n.setPrivacyPolicy),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => unawaited(opener(uri)),
          ),
        ListTile(
          key: const ValueKey('about:sources'),
          title: Text(l10n.setSources),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => unawaited(context.push(SettingsPaths.sources)),
        ),
        ListTile(
          key: const ValueKey('about:oss'),
          title: Text(l10n.setOpenSourceLicenses),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showOpenSourceLicenses(context, version: version),
        ),
      ],
    );
  }
}

/// Stiahnuty balik vysvetliviek hadisov (D-05) s moznostou zmazania.
/// Inak (nestiahnuty, nedostupny, chyba) sa riadok neukaze.
class _HadithExtraPackTile extends ConsumerWidget {
  const _HadithExtraPackTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final status = ref.watch(hadithExtraPackStatusProvider).value;
    if (status is! HadithExtraReady) return const SizedBox.shrink();
    final mb = (status.sizeBytes / (1024 * 1024)).toStringAsFixed(1);
    return ListTile(
      key: const ValueKey('about:hadith_extra'),
      title: Text(l10n.setHadithExtra),
      subtitle: Text(l10n.setSizeMb(mb)),
      trailing: TextButton(
        onPressed: () async {
          final ok = await showSkConfirmDialog(
            context,
            title: l10n.setHadithExtraDeleteTitle,
            body: l10n.setHadithExtraDeleteBody,
            confirmLabel: l10n.setDeleteConfirm,
            variant: SkConfirmVariant.destructive,
          );
          if (ok) await ref.read(hadithExtraPackServiceProvider).delete();
        },
        child: Text(l10n.setDeleteConfirm),
      ),
    );
  }
}
