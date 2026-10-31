import 'package:flutter/material.dart';
import 'package:prosoche/ui/foundation/sk_ui_strings.dart';
import 'package:prosoche/ui/i18n/bidi.dart';
import 'package:prosoche/ui/theme/sk_context.dart';
import 'package:prosoche/ui/tokens/sk_space.dart';

/// Varianta progresu (docs/01 3.2 `SkDailyProgress`).
enum SkDailyProgressVariant { feed, gate, todaySummary }

/// Segmentovy progres dennej sady: `▮▮▮▮▮▯▯▯ 5 / 12`.
///
/// Stavy: notStarted (`done == 0`), inProgress, completed
/// (`done == total`, ikona check), extended (volne citanie - progres sa
/// skryje, zobrazi sa "Free reading"). V RTL sa plni sprava (Row).
class SkDailyProgress extends StatelessWidget {
  const SkDailyProgress({
    required this.done,
    required this.total,
    this.variant = SkDailyProgressVariant.feed,
    this.extended = false,
    this.summaryLabel,
    super.key,
  }) : assert(total > 0, 'total > 0'),
       assert(done >= 0 && done <= total, '0 <= done <= total');

  final int done;
  final int total;
  final SkDailyProgressVariant variant;

  /// Volne citanie po dokonceni.
  final bool extended;

  /// Text pre `todaySummary`, napr. "5 of 12 cards" (lokalizuje volajuci).
  final String? summaryLabel;

  bool get completed => done == total;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final c = sk.colors;
    final strings = SkUiStrings.of(context);
    final caption = sk.text.bodySmall!.copyWith(color: c.textSecondary);

    if (extended) {
      return Semantics(
        label: strings.dailyCards,
        value: strings.freeReading,
        child: ExcludeSemantics(
          child: Text(strings.freeReading, style: caption),
        ),
      );
    }

    final motion = sk.motion.medium;
    final current = completed ? -1 : done;
    final bar = Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: SkSpace.space4),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: motion.duration,
                  curve: motion.curve,
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < done
                        ? c.primary
                        : i == current
                        ? c.primary.withValues(alpha: 0.5)
                        : c.outlineStrong,
                    borderRadius: BorderRadius.circular(SkRadius.full),
                  ),
                ),
                const SizedBox(height: 2),
                // Aktualny segment: 2 dp podciarknutie (nie len farba).
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: i == current ? c.primary : null,
                    borderRadius: BorderRadius.circular(SkRadius.full),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    final valueText = variant == SkDailyProgressVariant.todaySummary
        ? (summaryLabel ?? strings.progressOf(done, total))
        : Bidi.isolateLtr('$done / $total'); // v RTL inak "10 / 7"

    return Semantics(
      label: strings.dailyCards,
      value: strings.progressOf(done, total),
      liveRegion: completed,
      child: ExcludeSemantics(
        child: Row(
          children: [
            Expanded(child: bar),
            const SizedBox(width: SkSpace.space12),
            if (completed) ...[
              Icon(Icons.check, size: 16, color: c.primary),
              const SizedBox(width: SkSpace.space4),
            ],
            Text(
              valueText,
              style: caption.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
