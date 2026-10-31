import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/onboarding/steps/niyyah_step.dart'
    show
        encodeNiyyahPresets,
        niyyahMaxLength,
        niyyahPresets,
        parseNiyyahPresets;
import 'package:prosoche/ui/ui.dart';

/// Text umyslu na Moja cesta: vlastny text, inak zvolene predvolby, inak
/// null (A8.1). Len z nastaveni, nic nove.
String? niyyahDisplay(AppLocalizations l10n, String? text, String? preset) {
  if (text != null && text.trim().isNotEmpty) {
    return l10n.todayNiyyah(text.trim());
  }
  final presets = parseNiyyahPresets(preset);
  if (presets.isEmpty) return null;
  return [
    for (final p in niyyahPresets)
      if (presets.contains(p)) l10n.onbNiyyahOption(p),
  ].join(' · ');
}

/// Uprava umyslu (A8.1 "edit niyyah -> dialog ako O2"). Zapise
/// `niyyah.preset` a `niyyah.text`; nic neodchadza z telefonu.
Future<void> showNiyyahDialog(BuildContext context, WidgetRef ref) async {
  final settings = ref.read(settingsRepositoryProvider);
  final preset = await settings.get(SettingsKeys.niyyahPreset);
  final text = await settings.get(SettingsKeys.niyyahText);
  if (!context.mounted) return;
  final result = await showDialog<(String?, String?)>(
    context: context,
    builder: (_) =>
        NiyyahDialog(presets: parseNiyyahPresets(preset), text: text ?? ''),
  );
  if (result == null) return;
  await settings.set(SettingsKeys.niyyahPreset, result.$1);
  await settings.set(SettingsKeys.niyyahText, result.$2);
}

/// Dialog s predvolbami a vlastnym textom. Vrati `(preset, text)`.
class NiyyahDialog extends StatefulWidget {
  const NiyyahDialog({required this.presets, required this.text, super.key});

  final Set<String> presets;
  final String text;

  @override
  State<NiyyahDialog> createState() => _NiyyahDialogState();
}

class _NiyyahDialogState extends State<NiyyahDialog> {
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
        .pop((encodeNiyyahPresets(_selected), text.isEmpty ? null : text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.journeyNiyyahDialogTitle),
      scrollable: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: SkSpace.space8,
            runSpacing: SkSpace.space8,
            children: [
              for (final id in niyyahPresets)
                FilterChip(
                  key: ValueKey('journey-niyyah:$id'),
                  label: Text(l10n.onbNiyyahOption(id)),
                  selected: _selected.contains(id),
                  onSelected: (on) => setState(
                    () => on ? _selected.add(id) : _selected.remove(id),
                  ),
                ),
              FilterChip(
                key: const ValueKey('journey-niyyah:own'),
                label: Text(l10n.onbNiyyahOption('own')),
                selected: _own,
                onSelected: (on) => setState(() => _own = on),
              ),
            ],
          ),
          if (_own) ...[
            const SizedBox(height: SkSpace.space16),
            TextField(
              key: const ValueKey('journey-niyyah:text'),
              controller: _text,
              maxLength: niyyahMaxLength,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.onbNiyyahOwnHint,
                labelText: l10n.onbNiyyahOption('own'),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.journeyNiyyahCancel),
        ),
        TextButton(onPressed: _save, child: Text(l10n.journeyNiyyahSave)),
      ],
    );
  }
}

/// Riadok umyslu s tlacidlom upravy.
class JourneyNiyyah extends ConsumerWidget {
  const JourneyNiyyah({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final text = ref.watch(settingOf(SettingsKeys.niyyahText)).value;
    final preset = ref.watch(settingOf(SettingsKeys.niyyahPreset)).value;
    final shown = niyyahDisplay(l10n, text, preset);
    return Row(
      children: [
        Expanded(
          child: Text(
            shown ?? l10n.journeyNiyyahEmpty,
            style: sk.text.bodyLarge!.copyWith(
              color: shown == null ? sk.colors.textSecondary : null,
            ),
          ),
        ),
        SkIconButton(
          icon: Icons.edit_outlined,
          tooltip: l10n.journeyNiyyahEdit,
          onPressed: () => unawaited(showNiyyahDialog(context, ref)),
        ),
      ],
    );
  }
}
