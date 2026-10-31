import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/prayer/prayer.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/prayer/prayer_providers.dart';
import 'package:sakina/features/prayer/prayer_screen.dart';
import 'package:sakina/features/prayer/settings/prayer_settings_screen.dart';
import 'package:sakina/ui/ui.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../fakes/fake_repositories.dart';
import 'f05_test_app.dart';

final date = LocalDate(2026, 10, 29);

Finder rowOf(String name) => find.widgetWithText(SkPrayerRow, name);

Finder trackerOf(String name) =>
    find.descendant(of: rowOf(name), matching: find.byType(SkPrayerTracker));

SkPrayerRow rowWidget(WidgetTester tester, String name) =>
    tester.widget<SkPrayerRow>(rowOf(name));

Future<Map<Prayer, PrayerStatus>> logOf(FakeRepositories f, LocalDate d) =>
    f.prayer.watchLog(d).first;

void main() {
  late FakeRepositories fakes;

  setUp(() {
    fakes = FakeRepositories(
      prayer: FakePrayerRepository(location: fakeBratislava),
    );
  });

  group('states', () {
    testWidgets('loading shows a skeleton after 300 ms', (tester) async {
      final never = StreamController<PrayerConfig?>();
      addTearDown(never.close);
      await pumpF05(
        tester,
        fakes: fakes,
        now: bratislava(2026, 10, 29, 9, 0),
        overrides: [prayerConfigProvider.overrideWith((ref) => never.stream)],
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SkSkeleton), findsOneWidget);
      expect(find.byType(SkPrayerRow), findsNothing);
    });

    testWidgets('error shows E-PRAYER-1 with retry', (tester) async {
      await pumpF05(
        tester,
        fakes: fakes,
        now: bratislava(2026, 10, 29, 9, 0),
        overrides: [
          prayerConfigProvider.overrideWith(
            (ref) => Stream.error(StateError('tz')),
          ),
        ],
      );
      expect(find.text("Prayer times couldn't be calculated"), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      await tester.tap(find.text('Prayer settings'));
      await tester.pumpAndSettle();
      expect(find.byType(PrayerSettingsScreen), findsOneWidget);
    });

    testWidgets('without location: empty state and tracker without times', (
      tester,
    ) async {
      fakes = FakeRepositories();
      await pumpF05(tester, fakes: fakes, now: bratislava(2026, 10, 29, 9, 0));
      expect(find.text('Set your location'), findsOneWidget);
      expect(find.byType(SkPrayerRow), findsNWidgets(5));
      expect(find.text('Sunrise'), findsNothing);
      expect(find.byType(PrayerScreen), findsOneWidget);

      // Bez polohy: tap = on_time (A7.1).
      await tester.tap(trackerOf('Isha'));
      await tester.pumpAndSettle();
      expect((await logOf(fakes, date))[Prayer.isha], PrayerStatus.onTime);
    });

    testWidgets('data: 6 rows, next prayer highlighted with countdown', (
      tester,
    ) async {
      final day = bratislavaDay(date);
      final now = day[Prayer.asr].subtract(const Duration(minutes: 72));
      await pumpF05(tester, fakes: fakes, now: now);
      expect(find.byType(SkPrayerRow), findsNWidgets(5));
      expect(find.text('Sunrise'), findsOneWidget);
      expect(find.text('Bratislava'), findsOneWidget);
      expect(rowWidget(tester, 'Asr').state, SkPrayerRowState.next);
      expect(rowWidget(tester, 'Asr').relative, 'in 1 h 12 min');
      expect(rowWidget(tester, 'Dhuhr').state, SkPrayerRowState.current);
      expect(rowWidget(tester, 'Fajr').state, SkPrayerRowState.passed);
      expect(rowWidget(tester, 'Isha').state, SkPrayerRowState.upcoming);
      expect(
        find.textContaining('Muslim World League · Asr Shafi'),
        findsOneWidget,
      );
      expect(find.text('Thursday, October 29'), findsOneWidget);
      expect(find.text('18 Jumada al-Ula 1448'), findsOneWidget);
    });
  });

  group('tracker (A7.1 AC)', () {
    testWidgets('tap Asr 9 min after it began -> on_time', (tester) async {
      final now = bratislavaDay(
        date,
      )[Prayer.asr].add(const Duration(minutes: 9));
      await pumpF05(tester, fakes: fakes, now: now);
      await tester.tap(trackerOf('Asr'));
      await tester.pumpAndSettle();
      expect((await logOf(fakes, date))[Prayer.asr], PrayerStatus.onTime);
      expect(rowWidget(tester, 'Asr').status, SkPrayerStatus.onTime);
    });

    testWidgets('tap Asr after Maghrib began -> late', (tester) async {
      final now = bratislavaDay(
        date,
      )[Prayer.maghrib].add(const Duration(minutes: 20));
      await pumpF05(tester, fakes: fakes, now: now);
      await tester.tap(trackerOf('Asr'));
      await tester.pumpAndSettle();
      expect((await logOf(fakes, date))[Prayer.asr], PrayerStatus.late);
    });

    testWidgets('01:00: shows yesterday, Isha is logged to yesterday', (
      tester,
    ) async {
      await pumpF05(tester, fakes: fakes, now: bratislava(2026, 10, 30, 1, 0));
      expect(find.text('Thursday, October 29'), findsOneWidget);
      expect(find.text('Isha time continues until Fajr'), findsOneWidget);
      expect(rowWidget(tester, 'Isha').state, SkPrayerRowState.current);
      await tester.tap(trackerOf('Isha'));
      await tester.pumpAndSettle();
      expect((await logOf(fakes, date))[Prayer.isha], PrayerStatus.onTime);
      expect(await logOf(fakes, date.addDays(1)), isEmpty);

      // Dopredu sa da ist na dnesok (casy este nezacali).
      await tester.tap(find.byTooltip('Next day'));
      await tester.pumpAndSettle();
      expect(find.text('Friday, October 30'), findsOneWidget);
      expect(rowWidget(tester, 'Fajr').onTrackerTap, isNull);
    });

    testWidgets('a future prayer cannot be logged', (tester) async {
      final now = bratislavaDay(
        date,
      )[Prayer.asr].add(const Duration(minutes: 9));
      await pumpF05(tester, fakes: fakes, now: now);
      expect(rowWidget(tester, 'Isha').onTrackerTap, isNull);
      await tester.tap(trackerOf('Isha'));
      await tester.pumpAndSettle();
      expect(await logOf(fakes, date), isEmpty);
    });

    testWidgets('tap on a logged prayer clears it, Undo restores', (
      tester,
    ) async {
      final now = bratislavaDay(
        date,
      )[Prayer.isha].add(const Duration(minutes: 5));
      await fakes.prayer.setStatus(date, Prayer.dhuhr, PrayerStatus.late);
      await pumpF05(tester, fakes: fakes, now: now);
      expect(rowWidget(tester, 'Dhuhr').status, SkPrayerStatus.late);

      await tester.tap(trackerOf('Dhuhr'));
      await tester.pumpAndSettle();
      expect(await logOf(fakes, date), isEmpty);
      expect(find.text('Dhuhr log cleared.'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect((await logOf(fakes, date))[Prayer.dhuhr], PrayerStatus.late);
    });

    testWidgets('long press opens the status sheet', (tester) async {
      final now = bratislavaDay(
        date,
      )[Prayer.isha].add(const Duration(minutes: 5));
      await pumpF05(tester, fakes: fakes, now: now);
      await tester.longPress(rowOf('Fajr'));
      await tester.pumpAndSettle();
      for (final option in ['Mark on time', 'Mark late', 'Mark missed']) {
        expect(find.text(option), findsOneWidget);
      }
      await tester.tap(find.text('Made up (qada)'));
      await tester.pumpAndSettle();
      expect((await logOf(fakes, date))[Prayer.fajr], PrayerStatus.qada);
      expect(rowWidget(tester, 'Fajr').status, SkPrayerStatus.qada);

      await tester.longPress(rowOf('Fajr'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(await logOf(fakes, date), isEmpty);
    });

    testWidgets('missed is not red (docs/01 1.4)', (tester) async {
      await fakes.prayer.setStatus(date, Prayer.fajr, PrayerStatus.missed);
      await pumpF05(tester, fakes: fakes, now: bratislava(2026, 10, 29, 20, 0));
      expect(rowWidget(tester, 'Fajr').status, SkPrayerStatus.missed);
    });

    testWidgets('day arrows: back max 30 days, forward max today', (
      tester,
    ) async {
      await pumpF05(tester, fakes: fakes, now: bratislava(2026, 10, 29, 20, 0));
      final next = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );
      expect(next.onPressed, isNull);
      await tester.tap(find.byTooltip('Previous day'));
      await tester.pumpAndSettle();
      expect(find.text('Wednesday, October 28'), findsOneWidget);
      await tester.tap(trackerOf('Asr'));
      await tester.pumpAndSettle();
      expect(
        (await logOf(fakes, date.addDays(-1)))[Prayer.asr],
        PrayerStatus.late,
      );
      for (var i = 0; i < PrayerScreen.maxDaysBack + 3; i++) {
        await tester.tap(find.byTooltip('Previous day'));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.text('Tuesday, September 29'), findsOneWidget);
    });
  });

  group('banners and modifiers', () {
    testWidgets('reminders off and exact alarms banners', (tester) async {
      await pumpF05(
        tester,
        fakes: fakes,
        now: bratislava(2026, 10, 29, 9, 0),
        overrides: [
          prayerReminderHealthProvider.overrideWith(
            (ref) async => const PrayerReminderHealth(
              notificationsEnabled: false,
              exactAlarms: false,
            ),
          ),
        ],
      );
      expect(find.text('Prayer reminders are off'), findsOneWidget);
      expect(
        find.text('Reminders may arrive up to 10 minutes late or more.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Turn on'));
      await tester.pumpAndSettle();
      expect(find.text('stub:notifications'), findsOneWidget);
    });

    testWidgets('different time zone banner opens city search', (tester) async {
      await pumpF05(
        tester,
        fakes: fakes,
        now: bratislava(2026, 10, 29, 9, 0),
        timeZone: 'Europe/Istanbul',
      );
      expect(find.text('New time zone detected'), findsOneWidget);
    });

    testWidgets('same offset, other zone name: no banner', (tester) async {
      await pumpF05(
        tester,
        fakes: fakes,
        now: bratislava(2026, 10, 29, 9, 0),
        timeZone: 'Europe/Vienna',
      );
      expect(find.text('New time zone detected'), findsNothing);
    });

    testWidgets('notification off and manual adjustment in the row', (
      tester,
    ) async {
      await fakes.settings.set(SettingsKeys.notifPrayer('maghrib'), false);
      await fakes.prayer.setAdjust(Prayer.fajr, 2);
      await pumpF05(tester, fakes: fakes, now: bratislava(2026, 10, 29, 9, 0));
      expect(rowWidget(tester, 'Maghrib').notificationOff, isTrue);
      expect(rowWidget(tester, 'Fajr').adjustedLabel, '+2 min');
      expect(find.textContaining('1 time adjusted'), findsOneWidget);
    });

    testWidgets('high latitude estimate in summer (Oslo)', (tester) async {
      fakes = FakeRepositories(
        prayer: FakePrayerRepository(
          location: PrayerLocation(
            lat: 59.91,
            lng: 10.75,
            country: 'NO',
            tz: 'Europe/Oslo',
            city: 'Oslo',
          ),
        ),
      );
      ensureTimeZoneData();
      await pumpF05(
        tester,
        fakes: fakes,
        now: tz.TZDateTime(tz.getLocation('Europe/Oslo'), 2026, 6, 20, 12),
      );
      expect(rowWidget(tester, 'Isha').estimated, isTrue);
      await tester.tap(find.text('* Why is this estimated?'));
      await tester.pumpAndSettle();
      expect(find.text('Estimated time'), findsOneWidget);
      expect(find.textContaining('Middle of the night'), findsOneWidget);
    });

    testWidgets('winter in Bratislava is not estimated', (tester) async {
      await pumpF05(tester, fakes: fakes, now: bratislava(2026, 12, 20, 12, 0));
      expect(rowWidget(tester, 'Isha').estimated, isFalse);
      expect(rowWidget(tester, 'Fajr').estimated, isFalse);
    });
  });

  group('accessibility', () {
    testWidgets('row semantics, custom actions and tap targets', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final now = bratislavaDay(
        date,
      )[Prayer.asr].add(const Duration(minutes: 9));
      await pumpF05(tester, fakes: fakes, now: now);
      final data = tester.getSemantics(rowOf('Asr')).getSemanticsData();
      expect(data.label, contains('Asr'));
      expect(data.label, contains('Now'));
      expect(data.label, contains('Not logged'));
      expect(data.customSemanticsActionIds, hasLength(4));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('app bar opens qibla, calendar and settings', (tester) async {
      final router = await pumpF05(
        tester,
        fakes: fakes,
        now: bratislava(2026, 10, 29, 9, 0),
      );
      await tester.tap(find.byTooltip('Qibla direction'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/prayer/qibla');
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Islamic calendar'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/calendar');
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Muslim World League'));
      await tester.pumpAndSettle();
      expect(find.byType(PrayerSettingsScreen), findsOneWidget);
    });
  });
}
