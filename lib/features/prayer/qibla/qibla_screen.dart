import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/features/prayer/prayer_paths.dart';
import 'package:prosoche/features/prayer/prayer_providers.dart';
import 'package:prosoche/features/prayer/prayer_texts.dart';
import 'package:prosoche/features/prayer/qibla/compass.dart';
import 'package:prosoche/features/prayer/qibla/compass_math.dart';
import 'package:prosoche/features/prayer/qibla/qibla_dial.dart';
import 'package:prosoche/ui/ui.dart';

/// Odchylka, pri ktorej telefon "smeruje na qiblu" (A7.2).
const qiblaAlignedDegrees = 5.0;

/// Stav kompasu na obrazovke qibly (docs/01 3.2 `SkQiblaDial`).
enum QiblaCompassState { calibrating, pointing, aligned, noSensor }

/// Qibla (docs/02 A7.2). Route `/prayer/qibla`.
class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  bool _wasAligned = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bearing = ref.watch(qiblaBearingProvider);
    final Widget body;
    if (bearing.hasError) {
      body = SkErrorState(
        title: l10n.prayerErrorTitle,
        body: l10n.prayerErrorBody,
        onRetry: () => ref.invalidate(prayerConfigProvider),
      );
    } else if (!bearing.hasValue) {
      body = const Center(child: SkLoadingView());
    } else if (bearing.requireValue == null) {
      body = Center(
        child: SkEmptyState(
          title: l10n.prayerLocationTitle,
          body: l10n.prayerLocationBody,
          actionLabel: l10n.prayerChooseCity,
          onAction: () => unawaited(context.push(PrayerPaths.citySearch)),
        ),
      );
    } else {
      body = _QiblaCompass(
        bearing: bearing.requireValue!,
        onAligned: (aligned) {
          if (aligned && !_wasAligned) {
            unawaited(HapticFeedback.lightImpact());
          }
          _wasAligned = aligned;
        },
      );
    }
    return Scaffold(
      appBar: skAppBar(context, title: l10n.qiblaTitle),
      body: body,
    );
  }
}

class _QiblaCompass extends ConsumerWidget {
  const _QiblaCompass({required this.bearing, required this.onAligned});

  final double bearing;
  final ValueChanged<bool> onAligned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final compass = ref.watch(compassProvider);
    final city = ref.watch(prayerConfigProvider).value?.location.city;
    final reading = compass.hasError ? null : compass.value;
    final delta = reading == null ? null : turnDelta(reading.heading, bearing);
    final state = compass.hasError
        ? QiblaCompassState.noSensor
        : reading == null || reading.lowAccuracy
        ? QiblaCompassState.calibrating
        : delta!.abs() < qiblaAlignedDegrees
        ? QiblaCompassState.aligned
        : QiblaCompassState.pointing;
    onAligned(state == QiblaCompassState.aligned);

    final degrees = context.formats.number(bearing.round());
    final (String title, String? body) = switch (state) {
      QiblaCompassState.noSensor => (
        l10n.qiblaNoSensorTitle,
        l10n.qiblaNoSensorBody(degrees),
      ),
      QiblaCompassState.calibrating => (
        l10n.qiblaCalibrateTitle,
        l10n.qiblaCalibrateBody,
      ),
      QiblaCompassState.aligned => (l10n.qiblaFacing, null),
      QiblaCompassState.pointing => (
        delta! > 0
            ? l10n.qiblaTurnRight(context.formats.number(delta.round()))
            : l10n.qiblaTurnLeft(context.formats.number(-delta.round())),
        null,
      ),
    };
    final gutter = SkSpace.gutterFor(MediaQuery.sizeOf(context).width);
    return ListView(
      key: ValueKey('qibla:${state.name}'),
      padding: EdgeInsetsDirectional.fromSTEB(
        gutter,
        SkSpace.space16,
        gutter,
        SkSpace.space24,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: QiblaDial(
              bearing: bearing,
              heading: state == QiblaCompassState.noSensor
                  ? null
                  : reading?.heading ?? 0,
              aligned: state == QiblaCompassState.aligned,
              northLabel: l10n.qiblaNorth,
              semanticLabel: l10n.qiblaDialSemantics(degrees),
            ),
          ),
        ),
        const SizedBox(height: SkSpace.space24),
        Semantics(
          liveRegion: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: sk.text.titleLarge!.copyWith(
              color: state == QiblaCompassState.aligned
                  ? sk.colors.success
                  : sk.colors.textPrimary,
            ),
          ),
        ),
        if (body != null) ...[
          const SizedBox(height: SkSpace.space8),
          Text(body, textAlign: TextAlign.center, style: sk.text.bodyLarge),
        ],
        const SizedBox(height: SkSpace.space16),
        if (state != QiblaCompassState.noSensor)
          Text(
            l10n.qiblaBearing(degrees),
            textAlign: TextAlign.center,
            style: sk.text.bodyLarge,
          ),
        if (city != null)
          Text(
            l10n.qiblaFrom(city),
            textAlign: TextAlign.center,
            style: sk.text.bodyMedium!.copyWith(color: sk.colors.textSecondary),
          ),
        if (state != QiblaCompassState.noSensor) ...[
          const SizedBox(height: SkSpace.space16),
          Text(
            l10n.qiblaHint,
            textAlign: TextAlign.center,
            style: sk.text.bodyMedium!.copyWith(color: sk.colors.textSecondary),
          ),
        ],
      ],
    );
  }
}
