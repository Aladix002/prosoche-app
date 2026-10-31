import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/onboarding/steps/intention_step.dart'
    show
        encodeIntentionPresets,
        intentionMaxLength,
        intentionPresets,
        parseIntentionPresets;
import 'package:prosoche/ui/ui.dart';

/// Text umyslu na Moja cesta: vlastny text, inak zvolene predvolby, inak
/// null (A8.1). Len z nastaveni, nic nove.
String? intentionDisplay(AppLocalizations l10n, String? text, String? preset) {
  if (text != null && text.trim().isNotEmpty) {
    return l10n.todayIntention(text.trim());
  }
  final presets = parseIntentionPresets(preset);
  if (presets.isEmpty) return null;
  return [
    for (final p in intentionPresets)
      if (presets.contains(p)) l10n.onbIntentionOption(p),
  ].join(' · ');
}

/// Uprava umyslu (A8.1, dialog ako O2). Zapise
/// `intention.preset` a `intention.text`; nic neodchadza z telefonu.
Future<void> showIntentionDialog(BuildContext context, WidgetRef ref) async {
  final settings = ref.read(settingsRepositoryProvider);
  final preset = await settings.get(SettingsKeys.intentionPreset);
  final text = await settings.get(SettingsKeys.intentionText);
  if (!context.mounted) return;
  final result = await showDialog<(String?, String?)>(
    context: context,
    builder: (_) => IntentionDialog(
      presets: parseIntentionPresets(preset),
      text: text ?? '',
    ),
  );
  if (result == null) return;
  await settings.set(SettingsKeys.intentionPreset, result.$1);
  await settings.set(SettingsKeys.intentionText, result.$2);
}

/// Dialog s predvolbami a vlastnym textom. Vrati `(preset, text)`.
class IntentionDialog extends StatefulWidget {
  const IntentionDialog({required this.presets, required this.text, super.key});

  final Set<String> presets;
  final String text;

  @override
  State<IntentionDialog> createState() => _IntentionDialogState();
}

class _IntentionDialogState extends State<IntentionDialog> {
  late final Set<String> _selected = {...widget.presets};
  late final _text = TextEditingController(text: widget.text);
  late bool _own = widget.text.trim().isNotEmpty;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    final text = _own ? _text.text.trim() : '';
    Navigator.of(context)
        .pop((encodeIntentionPresets(_selected), text.isEmpty ? null : text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.journeyIntentionDialogTitle),
      scrollable: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: SkSpace.space8,
            runSpacing: SkSpace.space8,
            children: [
              for (final id in intentionPresets)
                FilterChip(
                  key: ValueKey('journey-intention:$id'),
                  label: Text(l10n.onbIntentionOption(id)),
                  selected: _selected.contains(id),
                  onSelected: (on) => setState(
                    () => on ? _selected.add(id) : _selected.remove(id),
                  ),
                ),
              FilterChip(
                key: const ValueKey('journey-intention:own'),
                label: Text(l10n.onbIntentionOption('own')),
                selected: _own,
                onSelected: (on) => setState(() => _own = on),
              ),
            ],
          ),
          if (_own) ...[
            const SizedBox(height: SkSpace.space16),
            TextField(
              key: const ValueKey('journey-intention:text'),
              controller: _text,
              maxLength: intentionMaxLength,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.onbIntentionOwnHint,
                labelText: l10n.onbIntentionOption('own'),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.journeyIntentionCancel),
        ),
        TextButton(onPressed: _save, child: Text(l10n.journeyIntentionSave)),
      ],
    );
  }
}

/// Riadok umyslu s tlacidlom upravy.
class JourneyIntention extends ConsumerWidget {
  const JourneyIntention({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final text = ref.watch(settingOf(SettingsKeys.intentionText)).value;
    final preset = ref.watch(settingOf(SettingsKeys.intentionPreset)).value;
    final shown = intentionDisplay(l10n, text, preset);
    return Row(
      children: [
        Expanded(
          child: Text(
            shown ?? l10n.journeyIntentionEmpty,
            style: sk.text.bodyLarge!.copyWith(
              color: shown == null ? sk.colors.textSecondary : null,
            ),
          ),
        ),
        SkIconButton(
          icon: Icons.edit_outlined,
          tooltip: l10n.journeyIntentionEdit,
          onPressed: () => unawaited(showIntentionDialog(context, ref)),
        ),
      ],
    );
  }
}
