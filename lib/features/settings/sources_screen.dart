import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/features/settings/settings_providers.dart';
import 'package:prosoche/features/settings/settings_widgets.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

/// Zdroje a licencie (docs/02 A11, docs/09 4). Route `/settings/sources`.
///
/// Generuje sa z tabulky `source` v content.db (nazov, verzia, licencia,
/// atribucia, URL), nic nie je natvrdo. URL (napr. tanzil.net, podmienka
/// Tanzilu) je klikatelny odkaz. Na konci verzia obsahu a open-source
/// licencie (`showLicensePage`, OFL fontov cez `LicenseRegistry`).
class SourcesScreen extends ConsumerWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final info = ref.watch(sourcesInfoProvider);
    final Widget body;
    if (info.hasError) {
      body = SkErrorState(
        title: l10n.setLoadErrorTitle,
        body: l10n.setLoadErrorBody,
        onRetry: () => retrySourcesInfo(ref),
      );
    } else if (!info.hasValue) {
      body = const Center(
        child: SkLoadingView(skeleton: SkSkeleton.list(lines: 6)),
      );
    } else if (info.requireValue.sources.isEmpty) {
      body = SettingsList(
        children: [
          SkEmptyState(title: l10n.setSourcesEmpty),
          const _OpenSourceButton(),
        ],
      );
    } else {
      final data = info.requireValue;
      body = SettingsList(
        children: [
          SettingsNote(l10n.setSourcesIntro, secondary: false),
          for (final group in groupSources(data.sources)) ...[
            SettingsSection(l10n.setSourceKind(group.kind)),
            for (final s in group.sources) SourceTile(source: s),
            if (group.kind == 'translation')
              SettingsNote(l10n.setTranslationDisclaimer),
          ],
          if (data.contentVersion != null)
            SettingsNote(l10n.setContentVersion(data.contentVersion!)),
          SettingsNote(l10n.setSourcesReport),
          const _OpenSourceButton(),
        ],
      );
    }
    return Scaffold(
      appBar: skAppBar(context, title: l10n.setSources),
      body: body,
    );
  }
}

/// Znova nacita zdroje; content.db len ak sa ju nepodarilo otvorit.
void retrySourcesInfo(WidgetRef ref) {
  if (ref.read(contentDbProvider).hasError) ref.invalidate(contentDbProvider);
  ref.invalidate(sourcesInfoProvider);
}

/// Jeden zdroj: nazov, verzia a licencia, atribucia a odkaz. Tap otvori
/// detail s plnym textom.
class SourceTile extends ConsumerWidget {
  const SourceTile({required this.source, super.key});

  final ContentSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final s = source;
    return InkWell(
      key: ValueKey('source:${s.id}'),
      onTap: () => unawaited(_showDetail(context, ref)),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: SkSpace.space16,
          vertical: SkSpace.space8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.lang == null ? s.name : '${s.name} (${s.lang})',
              style: sk.text.titleMedium,
            ),
            const SizedBox(height: SkSpace.space2),
            Text(
              l10n.setSourceVersionLicense(s.version, s.license),
              style: sk.text.bodyMedium,
            ),
            if (s.attribution.isNotEmpty) ...[
              const SizedBox(height: SkSpace.space4),
              Text(
                s.attribution,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: sk.text.bodySmall!.copyWith(
                  color: sk.colors.textSecondary,
                ),
              ),
            ],
            if (s.url.isNotEmpty) SourceLink(url: s.url),
          ],
        ),
      ),
    );
  }

  Future<void> _showDetail(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = source;
    return showSkInfoSheet<void>(
      context,
      title: s.name,
      closeLabel: MaterialLocalizations.of(context).closeButtonTooltip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.setSourceVersionLicense(s.version, s.license)),
          if (s.attribution.isNotEmpty) ...[
            const SizedBox(height: SkSpace.space12),
            SelectableText(s.attribution),
          ],
          if (s.url.isNotEmpty) SourceLink(url: s.url),
          if (s.licenseUrl case final url? when url.isNotEmpty)
            SourceLink(url: url, label: l10n.setLicenseLink),
          if (s.licenseText.isNotEmpty) ...[
            const SizedBox(height: SkSpace.space12),
            SelectableText(s.licenseText),
          ],
        ],
      ),
    );
  }
}

/// Klikatelny odkaz; otvori prehliadac, pri chybe snackbar.
class SourceLink extends ConsumerWidget {
  const SourceLink({required this.url, this.label, super.key});

  final String url;
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uri = Uri.tryParse(url);
    final text = label ?? _display(url);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          padding: EdgeInsetsDirectional.zero,
          minimumSize: const Size(0, SkSpace.minTouchTarget),
        ),
        icon: const Icon(Icons.open_in_new, size: 18),
        label: Text(text, textDirection: textDirectionForLanguage('en')),
        onPressed: uri == null
            ? null
            : () async {
                final ok = await ref.read(linkOpenerProvider)(uri);
                if (!ok && context.mounted) {
                  showSkSnackbar(
                    context,
                    message: context.l10n.setLinkFailed(url),
                  );
                }
              },
      ),
    );
  }

  /// `https://example.org/a` -> `example.org/a`.
  static String _display(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;
    final path = uri.path == '/' ? '' : uri.path;
    return '${uri.host}$path';
  }
}

class _OpenSourceButton extends StatelessWidget {
  const _OpenSourceButton();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.all(SkSpace.space16),
    child: SkButton.outlined(
      key: const ValueKey('sources:oss'),
      label: context.l10n.setOpenSourceLicenses,
      onPressed: () => showOpenSourceLicenses(context),
    ),
  );
}

/// Open-source licencie (Flutter balicky a OFL fontov z `LicenseRegistry`).
void showOpenSourceLicenses(BuildContext context, {String? version}) =>
    showLicensePage(
      context: context,
      applicationName: context.l10n.appTitle,
      applicationVersion: version,
    );
