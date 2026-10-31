import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/settings/settings_providers.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/onboarding/onboarding_screen.dart';
import 'package:prosoche/ui/ui.dart';

/// Predvolby umyslu, hodnoty `intention.preset` (docs/02 O2).
const intentionPresets = ['less_scrolling', 'calm', 'read_daily', 'reflect'];

/// Maximalna dlzka vlastneho textu (`intention.text`).
const intentionMaxLength = 140;

/// `intention.preset` sa uklada ako zoznam id oddelenych ciarkou.
Set<String> parseIntentionPresets(String? stored) => {
  for (final id in (stored ?? '').split(','))
    if (intentionPresets.contains(id.trim())) id.trim(),
};

String? encodeIntentionPresets(Set<String> ids) {
  final ordered = [
    for (final p in intentionPresets)
      if (ids.contains(p)) p,
  ];
  return ordered.isEmpty ? null : ordered.join(',');
}

/// O2 Umysel: multi-select a vlastny text. Neodosiela sa nikam.
class IntentionStep extends ConsumerStatefulWidget {
  const IntentionStep({required this.onNext, super.key});

  final OnboardingNext onNext;

  @override
  ConsumerState<IntentionStep> createState() => _IntentionStepState();
}

class _IntentionStepState extends ConsumerState<IntentionStep> {
  final _text = TextEditingController();
  final _selected = <String>{};
  bool _own = false;
  bool _loaded = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final settings = ref.read(settingsRepositoryProvider);
    final presets = parseIntentionPresets(
      await settings.get(SettingsKeys.intentionPreset),
    );
    final text = await settings.get(SettingsKeys.intentionText);
    if (!mounted) return;
    setState(() {
      _selected.addAll(presets);
      if (text != null && text.isNotEmpty) {
        _own = true;
        _text.text = text;
      }
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    setState(() => _busy = true);
    try {
      final settings = ref.read(settingsRepositoryProvider);
      final text = _own ? _text.text.trim() : '';
      final preset = encodeIntentionPresets(_selected);
      await settings.set(SettingsKeys.intentionPreset, preset);
      await settings.set(
        SettingsKeys.intentionText,
        text.isEmpty ? null : text,
      );
      // Prazdny vyber = ako Skip (docs/02 O2).
      await widget.onNext(skipped: preset == null && text.isEmpty);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OnboardingStepBody(
      icon: Icons.favorite_border,
      title: l10n.onbIntentionTitle,
      body: l10n.onbIntentionBody,
      primaryLabel: l10n.onbContinue,
      busy: _busy,
      onPrimary: _loaded ? _continue : null,
      children: [
        Wrap(
          spacing: SkSpace.space8,
          runSpacing: SkSpace.space8,
          children: [
            for (final id in intentionPresets)
              FilterChip(
                key: ValueKey('intention:$id'),
                label: Text(l10n.onbIntentionOption(id)),
                selected: _selected.contains(id),
                onSelected: (on) => setState(
                  () => on ? _selected.add(id) : _selected.remove(id),
                ),
              ),
            FilterChip(
              key: const ValueKey('intention:own'),
              label: Text(l10n.onbIntentionOption('own')),
              selected: _own,
              onSelected: (on) => setState(() => _own = on),
            ),
          ],
        ),
        if (_own) ...[
          const SizedBox(height: SkSpace.space16),
          TextField(
            key: const ValueKey('intention:text'),
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
    );
  }
}
