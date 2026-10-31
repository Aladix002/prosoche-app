import 'package:flutter/material.dart';
import 'package:sakina/ui/foundation/sk_ui_strings.dart';
import 'package:sakina/ui/theme/sk_context.dart';
import 'package:sakina/ui/tokens/sk_space.dart';

/// Varianta inline banneru (docs/01 3.2 Banery a feedback).
enum SkBannerVariant { info, warning, error }

/// Inline banner (nie `MaterialBanner`): chybajuce povolenie, sluzba
/// nebezi, offline. Vzdy s akciou; "Dismiss" okrem kritickych
/// ([onDismiss] == null).
class SkInlineBanner extends StatelessWidget {
  const SkInlineBanner({
    required this.message,
    this.variant = SkBannerVariant.info,
    this.title,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    super.key,
  });

  final SkBannerVariant variant;
  final String? title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Null = kriticky banner bez "Dismiss".
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final c = sk.colors;
    final strings = SkUiStrings.of(context);
    final (bg, fg, icon) = switch (variant) {
      SkBannerVariant.info => (c.surfaceAlt, c.textPrimary, Icons.info_outline),
      SkBannerVariant.warning => (
        c.warningContainer,
        c.onWarningContainer,
        Icons.warning_amber_outlined,
      ),
      SkBannerVariant.error => (
        c.errorContainer,
        c.onErrorContainer,
        Icons.error_outline,
      ),
    };
    final buttonStyle = TextButton.styleFrom(foregroundColor: fg);
    return Semantics(
      container: true,
      liveRegion: variant != SkBannerVariant.info,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(SkRadius.md),
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(
          SkSpace.space16,
          SkSpace.space12,
          SkSpace.space8,
          SkSpace.space4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(child: Icon(icon, size: 20, color: fg)),
                const SizedBox(width: SkSpace.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: sk.text.titleMedium!.copyWith(color: fg),
                        ),
                      Text(
                        message,
                        style: sk.text.bodyMedium!.copyWith(color: fg),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                if (onDismiss != null)
                  TextButton(
                    style: buttonStyle,
                    onPressed: onDismiss,
                    child: Text(strings.dismiss),
                  ),
                if (actionLabel != null)
                  TextButton(
                    style: buttonStyle,
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating snackbar `inverseSurface` s volitelnym Undo. Trva 4 s, pri
/// screen readeri 10 s (docs/01 8.4). Nikdy nad arabskym textom - volajuci
/// zodpoveda za umiestnenie (napr. nad progres barom).
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSkSnackbar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final accessible = MediaQuery.maybeAccessibleNavigationOf(context) ?? false;
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  return messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: Duration(seconds: accessible ? 10 : 4),
      persist: false,
      action: actionLabel == null
          ? null
          : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
    ),
  );
}

/// Inline poznamka, napr. "Audio needs internet" pri audio tlacidle.
class SkOfflineNote extends StatelessWidget {
  const SkOfflineNote({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Icon(
            Icons.cloud_off_outlined,
            size: 16,
            color: sk.colors.textTertiary,
          ),
        ),
        const SizedBox(width: SkSpace.space4),
        Flexible(
          child: Text(
            message,
            style: sk.text.bodySmall!.copyWith(color: sk.colors.textTertiary),
          ),
        ),
      ],
    );
  }
}
