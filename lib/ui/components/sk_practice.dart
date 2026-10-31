import 'package:flutter/material.dart';
import 'package:prosoche/ui/motif/sk_atmosphere.dart';
import 'package:prosoche/ui/motif/sk_greek_motif.dart';
import 'package:prosoche/ui/theme/sk_context.dart';
import 'package:prosoche/ui/tokens/sk_space.dart';

/// Cast dna praxe (docs/DESIGN.md 7.4).
enum SkPracticeTime {
  /// Ranna priprava: bod oblúka vysoko (vychod).
  morning,

  /// Vecerna reflexia: bod nizko (zapad).
  evening,
}

/// Hlavicka Practice: atmosfera podla casti dna, eyebrow, nadpis
/// (Cormorant), podnadpis a oblúk s bodom.
class SkPracticeHeader extends StatelessWidget {
  const SkPracticeHeader({
    required this.time,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final SkPracticeTime time;

  /// "Morning" / "Evening" (lokalizovane); zobrazi sa verzalkami.
  final String eyebrow;

  /// Napr. "Morning preparation".
  final String title;

  /// Napr. "Marcus Aurelius, Meditations 2.1".
  final String? subtitle;

  /// Napr. tlacidlo historie dennika.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final morning = time == SkPracticeTime.morning;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(eyebrow.toUpperCase(), style: sk.type.eyebrow),
        const SizedBox(height: SkSpace.space4),
        Semantics(
          header: true,
          child: Text(title, style: sk.text.headlineSmall),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: SkSpace.space8),
          Text(subtitle!, style: sk.type.attribution),
        ],
      ],
    );
    return SkAtmospherePanel(
      phase: morning ? SkDayPhase.morning : SkDayPhase.dusk,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: text),
          if (!sk.largeText) ...[
            const SizedBox(width: SkSpace.space16),
            SkArch(size: 56, dot: morning ? 0.25 : 0.8),
          ],
          ?trailing,
        ],
      ),
    );
  }
}

/// Pole dennika (vecerna reflexia). Dennik nikdy neopusti zariadenie;
/// [privacyNote] to pripomenie s ikonou zamku.
class SkJournalField extends StatelessWidget {
  const SkJournalField({
    required this.controller,
    required this.label,
    this.privacyNote,
    this.minLines = 4,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;

  /// Otazka, napr. "What did I do well today?".
  final String label;

  /// Napr. "Your journal stays on this device."
  final String? privacyNote;
  final int minLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final c = sk.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: sk.type.prompt.copyWith(fontSize: 19, height: 28 / 19),
        ),
        const SizedBox(height: SkSpace.space8),
        // Otazka nad polom je aj jeho label pre screen reader.
        MergeSemantics(
          child: Semantics(
            label: label,
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                semanticCounterText: '',
                contentPadding: const EdgeInsetsDirectional.all(
                  SkSpace.space16,
                ),
                fillColor: c.surface,
              ),
              onChanged: onChanged,
              minLines: minLines,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: sk.type.passage.copyWith(color: c.textPrimary),
            ),
          ),
        ),
        if (privacyNote != null) ...[
          const SizedBox(height: SkSpace.space8),
          Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: c.textSecondary),
              const SizedBox(width: SkSpace.space4),
              Expanded(
                child: Text(
                  privacyNote!,
                  style: sk.text.bodySmall!.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
