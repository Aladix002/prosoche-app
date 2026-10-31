import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sakina/ui/foundation/sk_ui_strings.dart';
import 'package:sakina/ui/theme/sk_context.dart';
import 'package:sakina/ui/tokens/sk_space.dart';

/// Varianty tlacidla (docs/01 3.2 `SkButton`).
enum SkButtonVariant { primary, secondary, tertiary, outlined, destructive }

/// Tlacidlo Sakina. Label sa zalamuje (nikdy ellipsis), min. vyska 52 dp
/// pre `primary`, inak 48 dp. `loading` nahradi label spinnerom 20 dp bez
/// zmeny sirky. Disabled = `onPressed: null`.
class SkButton extends StatelessWidget {
  const SkButton({
    required this.label,
    required this.onPressed,
    this.variant = SkButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = false,
    super.key,
  });

  const SkButton.primary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
    super.key,
  }) : variant = SkButtonVariant.primary;

  const SkButton.secondary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
    super.key,
  }) : variant = SkButtonVariant.secondary;

  const SkButton.tertiary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
    super.key,
  }) : variant = SkButtonVariant.tertiary;

  const SkButton.outlined({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
    super.key,
  }) : variant = SkButtonVariant.outlined;

  const SkButton.destructive({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
    super.key,
  }) : variant = SkButtonVariant.destructive;

  final String label;
  final VoidCallback? onPressed;
  final SkButtonVariant variant;
  final IconData? icon;
  final bool loading;

  /// Roztiahnut na celu sirku (napr. primarna a "Not now" pod sebou).
  final bool expand;

  double get minHeight => variant == SkButtonVariant.primary ? 52 : 48;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final c = sk.colors;
    final strings = SkUiStrings.of(context);

    final text = Text(label, textAlign: TextAlign.center, softWrap: true);
    var content = icon == null
        ? text
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: SkSpace.space8),
              Flexible(child: text),
            ],
          );
    if (loading) {
      // Sirka sa nemeni: label ostava v layoute, len neviditelny.
      content = Stack(
        alignment: Alignment.center,
        children: [
          Visibility.maintain(visible: false, child: content),
          const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      );
    }
    final padded = Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: SkSpace.space12),
      child: content,
    );

    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(expand ? double.infinity : SkSpace.minTouchTarget, minHeight),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsetsDirectional.symmetric(horizontal: SkSpace.space24),
      ),
      foregroundColor: variant == SkButtonVariant.destructive
          ? WidgetStateProperty.resolveWith(
              (s) =>
                  s.contains(WidgetState.disabled) ? c.textDisabled : c.onError,
            )
          : null,
      backgroundColor: variant == SkButtonVariant.destructive
          ? WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.disabled) ? c.surfaceAlt : c.error,
            )
          : null,
    );

    final onTap = loading ? null : onPressed;
    final button = switch (variant) {
      SkButtonVariant.primary || SkButtonVariant.destructive => FilledButton(
        onPressed: onTap,
        style: style,
        child: padded,
      ),
      SkButtonVariant.secondary => FilledButton.tonal(
        onPressed: onTap,
        style: style,
        child: padded,
      ),
      SkButtonVariant.tertiary => TextButton(
        onPressed: onTap,
        style: style,
        child: padded,
      ),
      SkButtonVariant.outlined => OutlinedButton(
        onPressed: onTap,
        style: style,
        child: padded,
      ),
    };
    if (!loading) return button;
    return Semantics(
      label: strings.loading,
      child: ExcludeSemantics(child: button),
    );
  }
}

/// Ikonove tlacidlo s 48x48 targetom; [tooltip] sluzi aj ako label.
class SkIconButton extends StatelessWidget {
  const SkIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selectedIcon,
    this.selected = false,
    super.key,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final bool selected;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.sk.colors;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      isSelected: selected,
      icon: Icon(icon),
      selectedIcon: Icon(selectedIcon ?? icon),
      color: selected ? c.primary : c.textSecondary,
      constraints: const BoxConstraints(
        minWidth: SkSpace.minTouchTarget,
        minHeight: SkSpace.minTouchTarget,
      ),
    );
  }
}

/// Emergency tlacidlo: podrzanie [holdDuration] s kruhovym progresom
/// (docs/01 3.2 `holdToConfirm`, D4). So screen readerom
/// (`MediaQuery.accessibleNavigation`) tap zavola [onAccessibleConfirm],
/// ktory ma otvorit potvrdzovaci dialog.
class SkHoldToConfirmButton extends StatefulWidget {
  const SkHoldToConfirmButton({
    required this.label,
    required this.onConfirmed,
    required this.onAccessibleConfirm,
    this.icon,
    this.holdDuration = const Duration(milliseconds: 1500),
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onConfirmed;
  final VoidCallback onAccessibleConfirm;
  final Duration holdDuration;

  @override
  State<SkHoldToConfirmButton> createState() => _SkHoldToConfirmButtonState();
}

class _SkHoldToConfirmButtonState extends State<SkHoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.holdDuration,
  )..addStatusListener(_onStatus);

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      unawaited(HapticFeedback.mediumImpact());
      widget.onConfirmed();
      _controller.reset();
    }
  }

  void _start() {
    unawaited(HapticFeedback.selectionClick());
    _controller.forward();
  }

  void _cancel() {
    if (!_controller.isCompleted) _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final c = sk.colors;
    final accessible = MediaQuery.maybeAccessibleNavigationOf(context) ?? false;
    final strings = SkUiStrings.of(context);
    return Semantics(
      button: true,
      label: widget.label,
      hint: accessible ? null : strings.holdToConfirm,
      onTap: widget.onAccessibleConfirm,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: accessible ? widget.onAccessibleConfirm : null,
        onLongPressStart: accessible ? null : (_) => _start(),
        onLongPressEnd: accessible ? null : (_) => _cancel(),
        onLongPressCancel: accessible ? null : _cancel,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: c.outlineStrong),
              borderRadius: BorderRadius.circular(SkRadius.md),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: SkSpace.space16,
                vertical: SkSpace.space12,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: 24,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => CircularProgressIndicator(
                        value: _controller.value,
                        strokeWidth: 2.5,
                        color: c.primary,
                        backgroundColor: c.surfaceAlt,
                      ),
                    ),
                  ),
                  const SizedBox(width: SkSpace.space12),
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 20, color: c.textSecondary),
                    const SizedBox(width: SkSpace.space8),
                  ],
                  Flexible(
                    child: Text(widget.label, style: sk.text.labelLarge),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
