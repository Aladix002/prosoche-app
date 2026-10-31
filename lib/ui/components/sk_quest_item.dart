import 'package:flutter/material.dart';
import 'package:sakina/ui/foundation/sk_ui_strings.dart';
import 'package:sakina/ui/i18n/bidi.dart';
import 'package:sakina/ui/theme/sk_context.dart';
import 'package:sakina/ui/tokens/sk_space.dart';

/// Slot questu (docs/01 3.2 `SkQuestItem`).
enum SkQuestSlot {
  /// Auto-splnenie s progresom x/y.
  read,

  /// Auto-splnenie s progresom x/y.
  learn,

  /// Self-report tlacidlom "I did it".
  act,
}

/// Stav questu.
enum SkQuestState { open, inProgress, done, skipped }

/// Polozka "Today's intentions". Ziadny `Checkbox` (nie task list),
/// done = ikona + text, nie len farba.
class SkQuestItem extends StatelessWidget {
  const SkQuestItem({
    required this.title,
    required this.slot,
    this.state = SkQuestState.open,
    this.progress = 0,
    this.target = 0,
    this.subtitle,
    this.eventLabel,
    this.onTap,
    this.onAction,
    this.onUndo,
    this.onLongPress,
    super.key,
  });

  final String title;
  final SkQuestSlot slot;
  final SkQuestState state;

  /// Pre read/learn: aktualny progres a ciel (x / y).
  final int progress;
  final int target;

  /// Napr. kratky zdroj (bez nabozenskeho textu v galerii).
  final String? subtitle;

  /// Event override, napr. "Jumu'ah" (accentText).
  final String? eventLabel;

  /// Detail (bottom sheet so zdrojom).
  final VoidCallback? onTap;

  /// "I did it" pri slote `act`.
  final VoidCallback? onAction;

  /// "Undo" pri stave `skipped`.
  final VoidCallback? onUndo;

  /// Menu ("Skip for today", "Undo"); alternativa long-pressu je v detaile.
  final VoidCallback? onLongPress;

  bool get _auto => slot != SkQuestSlot.act;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final c = sk.colors;
    final strings = SkUiStrings.of(context);
    final done = state == SkQuestState.done;
    final skipped = state == SkQuestState.skipped;

    final leading = _QuestLeading(slot: slot, state: state);

    final trailing = switch (state) {
      SkQuestState.done => Text(
        strings.done,
        style: sk.text.labelLarge!.copyWith(color: c.success),
      ),
      SkQuestState.skipped => TextButton(
        onPressed: onUndo,
        child: Text(strings.undo),
      ),
      _ when _auto && target > 0 => Text(
        // Vzdy LTR: v RTL by medzery okolo "/" prehodili poradie ("10 / 7").
        Bidi.isolateLtr('$progress / $target'),
        style: sk.text.bodyMedium!.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      _ when slot == SkQuestSlot.act => FilledButton.tonal(
        onPressed: onAction,
        child: Text(strings.iDidIt),
      ),
      _ => const SizedBox.shrink(),
    };

    final titleStyle = sk.text.titleMedium!.copyWith(
      color: skipped ? c.textTertiary : c.textPrimary,
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eventLabel != null)
          Text(
            eventLabel!,
            style: sk.text.labelSmall!.copyWith(color: c.accentText),
          ),
        Text(title, style: titleStyle),
        if (skipped)
          Text(
            strings.skippedForToday,
            style: sk.text.bodyMedium!.copyWith(color: c.textTertiary),
          )
        else if (subtitle != null)
          Text(subtitle!, style: sk.text.bodyMedium),
        if (_auto &&
            target > 0 &&
            state == SkQuestState.inProgress &&
            progress < target) ...[
          const SizedBox(height: SkSpace.space8),
          ClipRRect(
            borderRadius: BorderRadius.circular(SkRadius.full),
            child: LinearProgressIndicator(
              value: progress / target,
              minHeight: 4,
              color: c.primary,
              backgroundColor: c.outlineStrong,
            ),
          ),
        ],
      ],
    );

    // Pri velkom texte tlacidlo pod text, nie vedla.
    final large = sk.largeText;
    final actionBelow = large && slot == SkQuestSlot.act && !done && !skipped;

    final content = Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: SkSpace.space16,
        vertical: SkSpace.space12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExcludeSemantics(child: leading),
              const SizedBox(width: SkSpace.space12),
              Expanded(child: body),
              if (!actionBelow) ...[
                const SizedBox(width: SkSpace.space8),
                trailing,
              ],
            ],
          ),
          if (actionBelow) ...[
            const SizedBox(height: SkSpace.space8),
            Align(alignment: AlignmentDirectional.centerEnd, child: trailing),
          ],
        ],
      ),
    );

    final status = switch (state) {
      SkQuestState.done => strings.done,
      SkQuestState.skipped => strings.skippedForToday,
      _ when _auto && target > 0 => strings.progressOf(progress, target),
      _ => null,
    };

    return Semantics(
      container: true,
      value: status,
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(SkRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Ikona slotu v tonalnom kruhu; pri splneni sa pokojne prelnie na
/// `check_circle` a raz sa rozplynie jemny kruh (D-05, ziadne konfety).
/// Pri reduce motion bez animacie.
class _QuestLeading extends StatefulWidget {
  const _QuestLeading({required this.slot, required this.state});

  final SkQuestSlot slot;
  final SkQuestState state;

  @override
  State<_QuestLeading> createState() => _QuestLeadingState();
}

class _QuestLeadingState extends State<_QuestLeading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bloom = AnimationController(vsync: this);

  @override
  void didUpdateWidget(_QuestLeading old) {
    super.didUpdateWidget(old);
    final motion = context.sk.motion;
    if (old.state != SkQuestState.done &&
        widget.state == SkQuestState.done &&
        !motion.reduced) {
      _bloom
        ..duration = motion.calm.duration
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bloom.dispose();
    super.dispose();
  }

  IconData get _slotIcon => switch (widget.slot) {
    SkQuestSlot.read => Icons.menu_book_outlined,
    SkQuestSlot.learn => Icons.lightbulb_outline,
    SkQuestSlot.act => Icons.eco_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final c = sk.colors;
    final done = widget.state == SkQuestState.done;
    final skipped = widget.state == SkQuestState.skipped;
    final (bg, fg) = done
        ? (c.success.withValues(alpha: 0.14), c.success)
        : skipped
        ? (c.surfaceAlt, c.textTertiary)
        : (c.primaryContainer, c.onPrimaryContainer);
    final motion = sk.motion.medium;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 40,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: motion.duration,
              curve: motion.curve,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            ),
            AnimatedSwitcher(
              duration: motion.duration,
              switchInCurve: motion.curve,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1).animate(a),
                  child: child,
                ),
              ),
              child: Icon(
                done ? Icons.check_circle : _slotIcon,
                key: ValueKey(done),
                color: fg,
                size: done ? 26 : 20,
              ),
            ),
            AnimatedBuilder(
              animation: _bloom,
              builder: (context, _) {
                final t = _bloom.value;
                if (t == 0 || t == 1) return const SizedBox.shrink();
                return IgnorePointer(
                  child: Container(
                    width: 40 + 24 * t,
                    height: 40 + 24 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c.goldDeco.withValues(alpha: 0.6 * (1 - t)),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
