import 'package:flutter/material.dart';
import 'package:prosoche/ui/components/sk_button.dart';
import 'package:prosoche/ui/foundation/sk_ui_strings.dart';
import 'package:prosoche/ui/theme/sk_context.dart';
import 'package:prosoche/ui/tokens/sk_space.dart';

/// Varianta potvrdzovacieho dialogu (docs/01 3.2 Dialogy a sheety).
enum SkConfirmVariant { neutral, destructive }

/// Potvrdzovaci dialog. Poradie: Cancel na zaciatku, potvrdenie na konci
/// (v RTL zrkadlene). Text potvrdenia je sloveso ("Delete").
class SkConfirmDialog extends StatelessWidget {
  const SkConfirmDialog({
    required this.title,
    required this.confirmLabel,
    this.body,
    this.cancelLabel,
    this.variant = SkConfirmVariant.neutral,
    super.key,
  });

  final String title;
  final String? body;
  final String confirmLabel;

  /// Default `SkUiStrings.cancel`.
  final String? cancelLabel;
  final SkConfirmVariant variant;

  @override
  Widget build(BuildContext context) {
    final strings = SkUiStrings.of(context);
    return AlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body!),
      actionsOverflowButtonSpacing: SkSpace.space8,
      actions: [
        SkButton.tertiary(
          label: cancelLabel ?? strings.cancel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        if (variant == SkConfirmVariant.destructive)
          SkButton.destructive(
            label: confirmLabel,
            onPressed: () => Navigator.of(context).pop(true),
          )
        else
          SkButton.secondary(
            label: confirmLabel,
            onPressed: () => Navigator.of(context).pop(true),
          ),
      ],
    );
  }
}

/// Zobrazi [SkConfirmDialog]; vrati `true` pri potvrdeni.
Future<bool> showSkConfirmDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? body,
  String? cancelLabel,
  SkConfirmVariant variant = SkConfirmVariant.neutral,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => SkConfirmDialog(
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      variant: variant,
    ),
  );
  return result ?? false;
}

/// Obsah bottom sheetu: titulok, obsah, volitelne akcie. Scrolluje, ak sa
/// nezmesti. Drag ma alternativu (zatvaracie tlacidlo cez [closeLabel]).
class SkSheet extends StatelessWidget {
  const SkSheet({
    required this.title,
    required this.child,
    this.actions = const [],
    this.closeLabel,
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  /// Tooltip zatvaracieho tlacidla (napr. "Close").
  final String? closeLabel;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          SkSpace.space24,
          0,
          SkSpace.space24,
          SkSpace.space24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: sk.text.titleLarge),
                  ),
                ),
                if (closeLabel != null)
                  SkIconButton(
                    icon: Icons.close,
                    tooltip: closeLabel!,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
              ],
            ),
            const SizedBox(height: SkSpace.space16),
            DefaultTextStyle.merge(style: sk.text.bodyLarge, child: child),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: SkSpace.space24),
              for (final (i, a) in actions.indexed) ...[
                if (i > 0) const SizedBox(height: SkSpace.space8),
                a,
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Informacny sheet (zdroj hadisu, legenda tajwidu, high latitude).
Future<T?> showSkInfoSheet<T>(
  BuildContext context, {
  required String title,
  required Widget child,
  List<Widget> actions = const [],
  String? closeLabel,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => SkSheet(
    title: title,
    closeLabel: closeLabel,
    actions: actions,
    child: child,
  ),
);
