import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/settings/settings_providers.dart';
import 'package:sakina/features/settings/settings_widgets.dart';
import 'package:sakina/ui/ui.dart';

/// Slovo, ktore treba napisat pri mazani dat (docs/02 A10.9).
const deleteConfirmWord = 'DELETE';

/// Sukromie (docs/02 A10.9, plan 13). Route `/settings/privacy`.
///
/// Analytika a hlasenie chyb su opt-in a dostupne len po potvrdeni veku
/// 16+ (`age_confirmed_16`). Vypnutie veku vypne oboje. Spustenie a reset
/// PostHog/Sentry robi D-04 podla tychto klucov.
class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.read(settingsRepositoryProvider);
    bool value(SettingKey<bool> key) =>
        ref.watch(settingOf(key)).value ?? false;
    final age = value(SettingsKeys.ageConfirmed16);
    final analytics = age && value(SettingsKeys.analyticsOptIn);
    final crash = age && value(SettingsKeys.crashReports);
    final policy = ref.watch(appLinksProvider).privacyPolicyUri;

    Future<void> setAge({required bool v}) async {
      await settings.set(SettingsKeys.ageConfirmed16, v);
      if (!v) {
        await settings.set(SettingsKeys.analyticsOptIn, false);
        await settings.set(SettingsKeys.crashReports, false);
      }
    }

    return SettingsScaffold(
      title: l10n.setPrivacy,
      children: [
        SettingsNote(l10n.setPrivacyIntro, secondary: false),
        SettingsSection(l10n.setSharing, help: l10n.setSharingHelp),
        CheckboxListTile(
          key: const ValueKey('privacy:age'),
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(l10n.onbAgeConfirm),
          subtitle: age ? null : Text(l10n.onbAgeNote),
          value: age,
          onChanged: (v) => unawaited(setAge(v: v ?? false)),
        ),
        SwitchListTile(
          key: const ValueKey('privacy:analytics'),
          title: Text(l10n.setAnalytics),
          subtitle: Text(l10n.onbAnalyticsBody),
          value: analytics,
          onChanged: age
              ? (v) => unawaited(settings.set(SettingsKeys.analyticsOptIn, v))
              : null,
        ),
        SwitchListTile(
          key: const ValueKey('privacy:crash'),
          title: Text(l10n.setCrashReports),
          subtitle: Text(l10n.onbCrashBody),
          value: crash,
          onChanged: age
              ? (v) => unawaited(settings.set(SettingsKeys.crashReports, v))
              : null,
        ),
        ListTile(
          key: const ValueKey('privacy:collect'),
          title: Text(l10n.onbWhatWeCollect),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => unawaited(
            showSkInfoSheet<void>(
              context,
              title: l10n.onbWhatWeCollect,
              closeLabel: MaterialLocalizations.of(context).closeButtonTooltip,
              child: Text(l10n.onbWhatWeCollectBody),
            ),
          ),
        ),
        if (policy != null)
          ListTile(
            key: const ValueKey('privacy:policy'),
            title: Text(l10n.setPrivacyPolicy),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => unawaited(ref.read(linkOpenerProvider)(policy)),
          ),
        SettingsSection(l10n.setYourData, help: l10n.setYourDataHelp),
        Padding(
          padding: const EdgeInsetsDirectional.all(SkSpace.space16),
          child: SkButton.destructive(
            key: const ValueKey('privacy:delete'),
            label: l10n.setDeleteAll,
            icon: Icons.delete_outline,
            onPressed: () => unawaited(_delete(context, ref)),
          ),
        ),
      ],
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteAllDataDialog(),
    );
    if (confirmed != true) return;
    await ref.read(settingsActionsProvider).deleteAllData();
  }
}

/// Potvrdenie mazania: vysvetlenie a napisat [deleteConfirmWord]
/// (dvojite potvrdenie, docs/02 A10.9). Vrati `true` pri potvrdeni.
class DeleteAllDataDialog extends StatefulWidget {
  const DeleteAllDataDialog({super.key});

  @override
  State<DeleteAllDataDialog> createState() => _DeleteAllDataDialogState();
}

class _DeleteAllDataDialogState extends State<DeleteAllDataDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    return AlertDialog(
      title: Text(l10n.setDeleteTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.setDeleteBody),
            const SizedBox(height: SkSpace.space16),
            TextField(
              key: const ValueKey('delete:confirm'),
              controller: _controller,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l10n.setDeleteTypeLabel(deleteConfirmWord),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          key: const ValueKey('delete:go'),
          style: TextButton.styleFrom(foregroundColor: sk.colors.error),
          onPressed: _controller.text.trim() == deleteConfirmWord
              ? () => Navigator.of(context).pop(true)
              : null,
          child: Text(l10n.setDeleteConfirm),
        ),
      ],
    );
  }
}
