import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:prosoche/features/prayer/qibla/compass_math.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Jedno meranie kompasu.
@immutable
final class CompassReading {
  const CompassReading(this.heading, {this.lowAccuracy = false});

  /// Stupne od severu v smere hodinovych ruciciek, 0..<360.
  final double heading;

  /// Rusene alebo nekalibrovane pole: navod "figure 8" (Q-CALIBRATE).
  final bool lowAccuracy;
}

/// Zariadenie nema kompas (Q-NOSENSOR).
class NoCompassException implements Exception {
  const NoCompassException();

  @override
  String toString() => 'NoCompassException';
}

/// Zdroj kompasu. Stream chyby [NoCompassException], ked senzor chyba.
abstract interface class CompassSource {
  Stream<CompassReading> readings();
}

/// Kompas z akcelerometra a magnetometra (`sensors_plus`). Bez senzora
/// prida plugin chybu `NO_SENSOR`; bez udajov do [timeout] sa kompas
/// povazuje za nedostupny.
class SensorsCompassSource implements CompassSource {
  const SensorsCompassSource({this.timeout = const Duration(seconds: 3)});

  final Duration timeout;

  @override
  Stream<CompassReading> readings() {
    late StreamController<CompassReading> controller;
    final subs = <StreamSubscription<Object?>>[];
    Timer? watchdog;
    (double, double, double)? gravity;
    double? heading;

    void fail(Object _) {
      if (!controller.isClosed) controller.addError(const NoCompassException());
    }

    void onMagnet(MagnetometerEvent m) {
      final g = gravity;
      if (g == null) return;
      final raw = headingFromSensors(
        ax: g.$1,
        ay: g.$2,
        az: g.$3,
        mx: m.x,
        my: m.y,
        mz: m.z,
      );
      if (raw == null) return;
      watchdog?.cancel();
      heading = smoothHeading(heading, raw);
      controller.add(
        CompassReading(
          heading!,
          lowAccuracy: !magneticFieldPlausible(m.x, m.y, m.z),
        ),
      );
    }

    controller = StreamController<CompassReading>(
      onListen: () {
        watchdog = Timer(timeout, () => fail(const NoCompassException()));
        const period = SensorInterval.uiInterval;
        subs
          ..add(
            accelerometerEventStream(samplingPeriod: period).listen(
              (a) => gravity = _lowPass(gravity, (a.x, a.y, a.z)),
              onError: fail,
            ),
          )
          ..add(
            magnetometerEventStream(samplingPeriod: period)
                .listen(onMagnet, onError: fail),
          );
      },
      onCancel: () async {
        watchdog?.cancel();
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return controller.stream;
  }

  static (double, double, double) _lowPass(
    (double, double, double)? prev,
    (double, double, double) next,
  ) {
    if (prev == null) return next;
    const a = 0.2;
    return (
      prev.$1 + a * (next.$1 - prev.$1),
      prev.$2 + a * (next.$2 - prev.$2),
      prev.$3 + a * (next.$3 - prev.$3),
    );
  }
}

/// Override point pre testy (fake kompas).
final Provider<CompassSource> compassSourceProvider = Provider<CompassSource>(
  (ref) => const SensorsCompassSource(),
  name: 'compassSourceProvider',
);

/// Meranie kompasu; error = bez kompasu. Len kym je qibla otvorena.
final StreamProvider<CompassReading> compassProvider =
    StreamProvider.autoDispose<CompassReading>(
      (ref) => ref.watch(compassSourceProvider).readings(),
      name: 'compassProvider',
      // Chybajuci senzor sa opakovanim neopravi.
      retry: (_, _) => null,
    );
