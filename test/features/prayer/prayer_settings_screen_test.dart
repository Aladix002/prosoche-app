import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/prayer/calc_settings.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:prosoche/features/prayer/location/city_search_screen.dart';
import 'package:prosoche/features/prayer/prayer_paths.dart';
import 'package:prosoche/ui/i18n/i18n.dart';

import '../../fakes/fake_repositories.dart';
import 'f05_test_app.dart';

final today = LocalDate(2026, 10, 29);

Future<PrayerConfig> currentConfig(FakeRepositories f) async =>
    (await f.prayer.config())!;

void main() {
  late FakeRepositories fakes;

  setUp(() {
    fakes = FakeRepositories(
      prayer: FakePrayerRepository(location: fakeBratislava),
    );
  });

  Future<void> open(WidgetTester tester) => pumpF05(
    tester,
    fakes: fakes,
    now: bratislava(2026, 10, 29, 9, 0),
    location: PrayerPaths.settings,
  );

  testWidgets('shows current settings and today preview', (tester) async {
    await open(tester);
    expect(find.text('Prayer times'), findsOneWidget);
    expect(find.text('Bratislava'), findsOneWidget);
    expect(find.text('Muslim World League'), findsOneWidget);
    expect(find.textContaining('Fajr 18°, Isha 17°'), findsOneWidget);
    final fajr = (await currentConfig(fakes)).schedule.day(today)[Prayer.fajr];
    expect(find.text(ProsocheFormatsTest.hm(fajr)), findsOneWidget);
  });

  testWidgets('changing the method recalculates and reschedules', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Muslim World League'));
    await tester.pumpAndSettle();
    expect(find.text('Automatic'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Diyanet (Türkiye)'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Diyanet (Türkiye)'));
    await tester.pumpAndSettle();
    expect(fakes.prayer.changes, 1);
    expect((await currentConfig(fakes)).settings.method, PrayerMethod.turkiye);
    expect(find.text('Diyanet (Türkiye)'), findsOneWidget);
  });

  testWidgets('asr and high latitude rule', (tester) async {
    await open(tester);
    await tester.tap(find.text('Hanafi'));
    await tester.pumpAndSettle();
    expect((await currentConfig(fakes)).settings.asr, AsrMadhab.hanafi);
    await tester.scrollUntilVisible(find.text('One seventh of the night'), 100);
    await tester.tap(find.text('One seventh of the night'));
    await tester.pumpAndSettle();
    expect(
      (await currentConfig(fakes)).settings.highLatRule,
      HighLatRule.seventhOfNight,
    );
    expect(fakes.prayer.changes, 2);
  });

  testWidgets('Fajr +2 moves the preview and reschedules (A10.3 AC)', (
    tester,
  ) async {
    await open(tester);
    final before = (await currentConfig(fakes)).schedule
        .day(today)[Prayer.fajr];
    final plus = find.byTooltip('Later by 1 minute').first;
    await tester.scrollUntilVisible(plus, 100);
    await tester.tap(plus);
    await tester.pumpAndSettle();
    await tester.tap(plus);
    await tester.pumpAndSettle();
    final after = (await currentConfig(fakes)).schedule.day(today)[Prayer.fajr];
    expect(after.difference(before), const Duration(minutes: 2));
    expect(fakes.prayer.changes, 2);
    expect(find.text('+2 min'), findsOneWidget);
    expect(find.text(ProsocheFormatsTest.hm(after)), findsOneWidget);
  });

  testWidgets('adjust stepper stops at +30', (tester) async {
    await fakes.prayer.setAdjust(Prayer.isha, 30);
    await open(tester);
    final row = find.ancestor(
      of: find.text('+30 min'),
      matching: find.byType(Row),
    );
    final plus = tester.widget<IconButton>(
      find.descendant(
        of: row.first,
        matching: find.widgetWithIcon(IconButton, Icons.add),
      ),
    );
    expect(plus.onPressed, isNull);
  });

  testWidgets('without location shows location empty state', (tester) async {
    fakes = FakeRepositories();
    await open(tester);
    expect(find.text('Set your location'), findsWidgets);
    await tester.tap(find.text('Choose a city'));
    await tester.pumpAndSettle();
    expect(find.byType(CitySearchScreen), findsOneWidget);
  });

  testWidgets('semantics and tap targets', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}

/// Cas modlitby tak, ako ho ukaze EN UI.
abstract final class ProsocheFormatsTest {
  static String hm(DateTime t) => ProsocheFormats(const Locale('en')).time(t);
}
