import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:prosoche/ui/foundation/sk_ui_strings.dart';
import 'package:prosoche/ui/theme/prosoche_typography.dart';
import 'package:prosoche/ui/theme/sk_context.dart';
import 'package:prosoche/ui/tokens/sk_space.dart';

/// Stav riadku modlitby (docs/01 3.2 `SkPrayerRow`).
enum SkPrayerRowState { upcoming, next, current, passed }

/// Stav trackera. Ziadna cervena pre `missed` (docs/01 1.4).
enum SkPrayerStatus { unlogged, onTime, late, missed, qada }

/// Riadok modlitby: nazov, cas (tabularne cislice), relativny cas/stav,
/// ikona notifikacie a tracker (kruh 28 dp v 48 dp targete).
///
/// Pri velkom texte (`context.sk.largeText`) sa cas presunie pod nazov.
class SkPrayerRow extends StatelessWidget {
  const SkPrayerRow({
    required this.name,
    required this.time,
    this.state = SkPrayerRowState.upcoming,
    this.status = SkPrayerStatus.unlogged,
    this.relative,
    this.estimated = false,
    this.notificationOff = false,
    this.adjustedLabel,
    this.onTrackerTap,
    this.customActions = const {},
    super.key,
  });

  final String name;

  /// Naformatovany cas (U-02 lokalizuje cislice).
  final String time;
  final SkPrayerRowState state;
  final SkPrayerStatus status;

  /// Napr. "in 1 h 12 min" pre `next`.
  final String? relative;

  /// High latitude odhad: hviezdicka + `SkUiStrings.estimated` pre SR.
  final bool estimated;
  final bool notificationOff;

  /// Napr. "+2 min".
  final String? adjustedLabel;

  /// Otvori `SkPrayerStatusSheet`.
  final VoidCallback? onTrackerTap;

  /// "Mark on time", "Mark late", ... (docs/01 8.1).
  final Map<CustomSemanticsAction, VoidCallback> customActions;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final c = sk.colors;
    final strings = SkUiStrings.of(context);
    final highlighted = state == SkPrayerRowState.next;
    final passed = state == SkPrayerRowState.passed;
    final fg = highlighted ? c.onPrimaryContainer : c.textPrimary;
    final secondary = highlighted ? c.onPrimaryContainer : c.textSecondary;

    final nameText = Text(
      name,
      style: sk.text.titleMedium!.copyWith(color: fg),
    );
    final timeText = Text(
      estimated ? '$time *' : time,
      style: ProsocheTypography.tabular(
        sk.text.bodyLarge!.copyWith(color: passed ? c.textSecondary : fg),
      ),
    );
    final relativeText = switch (state) {
      SkPrayerRowState.current => strings.now,
      SkPrayerRowState.next => relative,
      _ => null,
    };
    final meta = [?relativeText, ?adjustedLabel].join(' · ');

    final large = sk.largeText;

    final info = large
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              nameText,
              timeText,
              if (meta.isNotEmpty)
                Text(
                  meta,
                  style: sk.text.bodyMedium!.copyWith(color: secondary),
                ),
            ],
          )
        : Row(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 88),
                child: nameText,
              ),
              const SizedBox(width: SkSpace.space8),
              timeText,
              const SizedBox(width: SkSpace.space12),
              Expanded(
                child: Text(
                  meta,
                  style: sk.text.bodyMedium!.copyWith(color: secondary),
                ),
              ),
            ],
          );

    final statusLabel = switch (status) {
      SkPrayerStatus.unlogged => strings.prayerStatusUnlogged,
      SkPrayerStatus.onTime => strings.prayerStatusOnTime,
      SkPrayerStatus.late => strings.prayerStatusLate,
      SkPrayerStatus.missed => strings.prayerStatusMissed,
      SkPrayerStatus.qada => strings.prayerStatusQada,
    };

    final semantics = [
      name,
      time,
      ?relativeText,
      ?adjustedLabel,
      if (estimated) strings.estimated,
      if (notificationOff) strings.notificationsOff,
      statusLabel,
    ].join(', ');

    return Semantics(
      container: true,
      label: semantics,
      button: onTrackerTap != null,
      onTap: onTrackerTap,
      customSemanticsActions: customActions,
      excludeSemantics: true,
      child: Material(
        color: highlighted ? c.primaryContainer : c.surface,
        borderRadius: BorderRadius.circular(SkRadius.md),
        child: Container(
          padding: const EdgeInsetsDirectional.only(
            start: SkSpace.space16,
            end: SkSpace.space4,
          ),
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    vertical: SkSpace.space8,
                  ),
                  child: info,
                ),
              ),
              if (notificationOff)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: SkSpace.space8,
                  ),
                  child: Icon(
                    Icons.notifications_off_outlined,
                    size: 20,
                    color: secondary,
                  ),
                ),
              SkPrayerTracker(status: status, onTap: onTrackerTap),
            ],
          ),
        ),
      ),
    );
  }
}

/// Status tracker modlitby: kruh 28 dp v 48 dp targete; tvar + ikona,
/// nie len farba (docs/01 8.5).
class SkPrayerTracker extends StatelessWidget {
  const SkPrayerTracker({required this.status, this.onTap, super.key});

  final SkPrayerStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sk.colors;
    final (
      Color ring,
      Color? fill,
      IconData? icon,
      Color iconColor,
    ) = switch (status) {
      SkPrayerStatus.unlogged => (c.outlineStrong, null, null, c.surface),
      SkPrayerStatus.onTime => (c.primary, c.primary, Icons.check, c.onPrimary),
      SkPrayerStatus.late => (c.primary, null, Icons.schedule, c.primary),
      SkPrayerStatus.missed => (c.textTertiary, null, null, c.surface),
      SkPrayerStatus.qada => (c.success, c.success, Icons.history, c.surface),
    };
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: SizedBox.square(
        dimension: SkSpace.minTouchTarget,
        child: Center(
          child: CustomPaint(
            size: const Size.square(28),
            painter: _TrackerPainter(
              ring: ring,
              fill: fill,
              dashed: status == SkPrayerStatus.missed,
              half: status == SkPrayerStatus.late,
            ),
            child: SizedBox.square(
              dimension: 28,
              child: icon == null
                  ? null
                  : Icon(icon, size: 16, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackerPainter extends CustomPainter {
  const _TrackerPainter({
    required this.ring,
    required this.fill,
    required this.dashed,
    required this.half,
  });

  final Color ring;
  final Color? fill;
  final bool dashed;
  final bool half;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 1;
    final stroke = Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    if (fill != null) {
      canvas.drawCircle(center, r, Paint()..color = fill!);
    }
    if (half) {
      // Polovicny kruh (spodna polovica vyplnena, slabo).
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        0,
        math.pi,
        true,
        Paint()..color = ring.withValues(alpha: 0.25),
      );
    }
    if (dashed) {
      const segments = 12;
      const sweep = 2 * math.pi / segments;
      for (var i = 0; i < segments; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: r),
          i * sweep,
          sweep * 0.55,
          false,
          stroke,
        );
      }
    } else {
      canvas.drawCircle(center, r, stroke);
    }
  }

  @override
  bool shouldRepaint(_TrackerPainter old) =>
      old.ring != ring ||
      old.fill != fill ||
      old.dashed != dashed ||
      old.half != half;
}
