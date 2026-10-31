import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/domain/prayer/qibla.dart';
import 'package:sakina/features/prayer/prayer_routes.dart';
import 'package:sakina/features/prayer/qibla/compass.dart';
import 'package:sakina/features/prayer/qibla/qibla_dial.dart';

import '../../../fakes/fake_repositories.dart';
import '../f05_test_app.dart';

/// Fake kompas: test posiela merania a chyby rucne.
class FakeCompass implements CompassSource {
  final controller = StreamController<CompassReading>.broadcast();

  @override
  Stream<CompassReading> readings() => controller.stream;
}

void main() {
  late FakeRepositories fakes;
  late FakeCompass compass;
  final now = bratislava(2026, 10, 29, 9, 0);
  final bearing = qiblaBearing(fakeBratislava.lat, fakeBratislava.lng);

  setUp(() {
    fakes = FakeRepositories(
      prayer: FakePrayerRepository(location: fakeBratislava),
    );
    compass = FakeCompass();
  });

  tearDown(() => compass.controller.close());

  Future<void> open(WidgetTester tester) async {
    await pumpF05(
      tester,
      fakes: fakes,
      now: now,
      location: PrayerRoutes.qibla,
      overrides: [compassSourceProvider.overrideWithValue(compass)],
      settle: false,
    );
    // Poloha a azimut sa nacitaju, kompas sa zacne pocuvat.
    for (var i = 0; i < 3; i++) {
      await tester.pump();
    }
  }

  Future<void> emit(WidgetTester tester, CompassReading r) async {
    compass.controller.add(r);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Bratislava qibla is 138 degrees (great circle)', (tester) async {
    // docs/02 A7.2 AC uvadza 136 [OVERIT]; adhan_dart dava 137,8.
    expect(bearing, closeTo(137.8, 0.1));
    await open(tester);
    await tester.pump();
    expect(find.text('Qibla 138° from north'), findsOneWidget);
    expect(find.text('From Bratislava'), findsOneWidget);
  });

  testWidgets('before the first reading: calibrating', (tester) async {
    await open(tester);
    await tester.pump();
    expect(find.text('Calibrating…'), findsOneWidget);
    expect(find.text('Move your phone in a figure 8.'), findsOneWidget);
  });

  testWidgets('low accuracy: calibrating', (tester) async {
    await open(tester);
    await emit(tester, CompassReading(bearing, lowAccuracy: true));
    expect(find.text('Calibrating…'), findsOneWidget);
  });

  testWidgets('turn right / left and facing with one haptic', (tester) async {
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add('$call');
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await open(tester);
    await emit(tester, CompassReading(bearing - 30));
    expect(find.text('Turn right 30°'), findsOneWidget);
    await emit(tester, CompassReading(bearing + 45));
    expect(find.text('Turn left 45°'), findsOneWidget);
    expect(haptics, isEmpty);
    await emit(tester, CompassReading(bearing + 2));
    expect(find.text('Facing the Qibla'), findsOneWidget);
    await emit(tester, CompassReading(bearing - 1));
    expect(haptics, hasLength(1));
    final dial = tester.widget<QiblaDial>(find.byType(QiblaDial));
    expect(dial.aligned, isTrue);
    expect(dial.heading, closeTo(bearing - 1, 0.001));
  });

  testWidgets('no sensor: static bearing (Q-NOSENSOR)', (tester) async {
    await open(tester);
    compass.controller.addError(const NoCompassException());
    await tester.pump();
    await tester.pump();
    expect(find.text('Compass not available'), findsOneWidget);
    expect(find.text('The Qibla is 138° from north.'), findsOneWidget);
    expect(tester.widget<QiblaDial>(find.byType(QiblaDial)).heading, isNull);
  });

  testWidgets('no location: set your location', (tester) async {
    fakes = FakeRepositories();
    await open(tester);
    await tester.pump();
    expect(find.text('Set your location'), findsOneWidget);
    expect(find.byType(QiblaDial), findsNothing);
  });

  testWidgets('dial has a semantic label', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    await emit(tester, CompassReading(bearing));
    expect(
      find.bySemanticsLabel('Compass. Qibla is 138° from north.'),
      findsOneWidget,
    );
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
