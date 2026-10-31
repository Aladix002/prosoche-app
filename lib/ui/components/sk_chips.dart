import 'package:flutter/material.dart';
import 'package:sakina/ui/theme/sk_context.dart';
import 'package:sakina/ui/tokens/sk_space.dart';

/// Stav chipu dalsej modlitby (docs/01 3.2 `SkNextPrayerChip`).
enum SkNextPrayerState { normal, now, unavailable }

/// Kompaktny "Asr in 1 h 12 min" na Today a v brane. Text doda volajuci
/// (lokalizovany relativny cas); `unavailable` = "Set location for prayer
/// times" s akciou.
class SkNextPrayerChip extends StatelessWidget {
  const SkNextPrayerChip({
    required this.label,
    this.state = SkNextPrayerState.normal,
    this.onTap,
    super.key,
  });

  final String label;
  final SkNextPrayerState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final c = sk.colors;
    final (bg, fg, icon) = switch (state) {
      SkNextPrayerState.normal => (c.surfaceAlt, c.textPrimary, Icons.schedule),
      SkNextPrayerState.now => (
        c.primaryContainer,
        c.onPrimaryContainer,
        Icons.mosque_outlined,
      ),
      SkNextPrayerState.unavailable => (
        c.surfaceAlt,
        c.textSecondary,
        Icons.location_off_outlined,
      ),
    };
    return Semantics(
      button: onTap != null,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(SkRadius.full),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: SkSpace.space16,
                vertical: SkSpace.space8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(child: Icon(icon, size: 20, color: fg)),
                  const SizedBox(width: SkSpace.space8),
                  Flexible(
                    child: Text(
                      label,
                      style: sk.text.labelLarge!.copyWith(
                        color: fg,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
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

/// Hlavicka s hijri datumom: "14 Jumada al-Ula 1448 · Friday" v
/// `accentText`, volitelny event chip a `offsetAdjusted` label ("+1 day").
/// Tap -> kalendar.
class SkHijriHeader extends StatelessWidget {
  const SkHijriHeader({
    required this.date,
    this.eventLabel,
    this.offsetLabel,
    this.onTap,
    super.key,
  });

  /// Uz naformatovany hijri datum a den v tyzdni.
  final String date;

  /// Napr. "Jumu'ah", "White days".
  final String? eventLabel;

  /// Napr. "+1 day", ked pouzivatel pouziva hijri offset.
  final String? offsetLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final c = sk.colors;
    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SkRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: SkSpace.space8,
            ),
            child: Wrap(
              spacing: SkSpace.space8,
              runSpacing: SkSpace.space4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  date,
                  style: sk.text.titleMedium!.copyWith(color: c.accentText),
                ),
                if (offsetLabel != null)
                  Text(
                    offsetLabel!,
                    style: sk.text.labelSmall!.copyWith(color: c.textSecondary),
                  ),
                if (eventLabel != null) SkTag(label: eventLabel!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Maly tag (event, oznacenie). `radiusXs`, `surfaceAlt`.
class SkTag extends StatelessWidget {
  const SkTag({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: SkSpace.space8,
        vertical: SkSpace.space2,
      ),
      decoration: BoxDecoration(
        color: sk.colors.surfaceAlt,
        borderRadius: BorderRadius.circular(SkRadius.xs),
      ),
      child: Text(
        label,
        style: sk.text.labelSmall!.copyWith(color: sk.colors.accentText),
      ),
    );
  }
}
