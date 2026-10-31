import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/prayer/qibla/compass.dart';
import 'package:sakina/features/prayer/qibla/compass_math.dart';

const _accel = EventChannel('dev.fluttercommunity.plus/sensors/accelerometer');
const _magnet = EventChannel('dev.fluttercommunity.plus/sensors/magnetometer');
const _method = MethodChannel('dev.fluttercommunity.plus/sensors/method');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('headingFromSensors (phone flat, screen up)', () {
    // Gravitacia +z, pole Zeme: horizontalna zlozka na sever, vertikalna dole.
    double? heading(double mx, double my) =>
        headingFromSensors(ax: 0, ay: 0, az: 9.81, mx: mx, my: my, mz: -40);

    test('top edge to the north = 0', () {
      expect(heading(0, 20), closeTo(0, 1e-9));
    });

    test('top edge to the east = 90 (north on the left)', () {
      expect(heading(-20, 0), closeTo(90, 1e-9));
    });

    test('south = 180, west = 270', () {
      expect(heading(0, -20), closeTo(180, 1e-9));
      expect(heading(20, 0), closeTo(270, 1e-9));
    });

    test('free fall or field along gravity has no heading', () {
      expect(
        headingFromSensors(ax: 0, ay: 0, az: 0, mx: 0, my: 20, mz: -40),
        isNull,
      );
      expect(
        headingFromSensors(ax: 0, ay: 0, az: 9.81, mx: 0, my: 0, mz: -40),
        isNull,
      );
    });
  });

  test('angles', () {
    expect(normalizeDegrees(-10), 350);
    expect(normalizeDegrees(370), 10);
    expect(turnDelta(350, 10), 20);
    expect(turnDelta(10, 350), -20);
    expect(turnDelta(0, 180), 180);
    expect(smoothHeading(null, 42), 42);
    expect(smoothHeading(350, 10, alpha: 0.5), closeTo(0, 1e-9));
    expect(magneticFieldPlausible(0, 20, -40), isTrue);
    expect(magneticFieldPlausible(0, 200, -40), isFalse);
  });

  group('SensorsCompassSource', () {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    void mockSensors({
      required List<double> accel,
      required List<double>? magnet,
    }) {
      messenger
        ..setMockMethodCallHandler(_method, (call) async => null)
        ..setMockStreamHandler(
          _accel,
          MockStreamHandler.inline(
            onListen: (args, sink) => sink.success([...accel, 0.0]),
          ),
        )
        ..setMockStreamHandler(
          _magnet,
          MockStreamHandler.inline(
            onListen: (args, sink) => magnet == null
                ? sink.error(code: 'NO_SENSOR', message: 'Sensor not found')
                : sink.success([...magnet, 0.0]),
          ),
        );
    }

    tearDown(() {
      messenger
        ..setMockMethodCallHandler(_method, null)
        ..setMockStreamHandler(_accel, null)
        ..setMockStreamHandler(_magnet, null);
    });

    test('combines accelerometer and magnetometer into a heading', () async {
      mockSensors(accel: [0, 0, 9.81], magnet: [-20, 0, -40]);
      final r = await const SensorsCompassSource().readings().first;
      expect(r.heading, closeTo(90, 1e-6));
      expect(r.lowAccuracy, isFalse);
    });

    test('disturbed field = low accuracy', () async {
      mockSensors(accel: [0, 0, 9.81], magnet: [0, 300, -40]);
      final r = await const SensorsCompassSource().readings().first;
      expect(r.lowAccuracy, isTrue);
    });

    test('missing magnetometer -> NoCompassException', () async {
      mockSensors(accel: [0, 0, 9.81], magnet: null);
      await expectLater(
        const SensorsCompassSource().readings(),
        emitsError(isA<NoCompassException>()),
      );
    });

    test('no data before the timeout -> NoCompassException', () async {
      messenger
        ..setMockMethodCallHandler(_method, (call) async => null)
        ..setMockStreamHandler(
          _accel,
          MockStreamHandler.inline(onListen: (args, sink) {}),
        )
        ..setMockStreamHandler(
          _magnet,
          MockStreamHandler.inline(onListen: (args, sink) {}),
        );
      await expectLater(
        const SensorsCompassSource(timeout: Duration(milliseconds: 20))
            .readings(),
        emitsError(isA<NoCompassException>()),
      );
    });
  });
}
