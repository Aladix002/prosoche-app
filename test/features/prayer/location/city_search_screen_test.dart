import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/prayer/calc_settings.dart';
import 'package:sakina/domain/prayer/prayer.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/prayer/prayer_paths.dart';
import 'package:sakina/features/prayer/prayer_providers.dart';
import 'package:sakina/features/prayer/prayer_routes.dart';
import 'package:sakina/ui/i18n/i18n.dart';
import 'package:sakina/ui/ui.dart';

import '../../../fakes/fake_repositories.dart';
import '../f05_test_app.dart';

class _Locator implements DeviceLocator {
  _Locator(this.fix);

  final ({double lat, double lng})? fix;

  @override
  Future<({double lat, double lng})?> locate() async => fix;
}

Finder resultTitles() =>
    find.descendant(of: find.byType(ListView), matching: find.byType(ListTile));

Future<void> search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(CitySearchScreen.debounce);
  await tester.pumpAndSettle();
}

void main() {
  late FakeRepositories fakes;
  final now = bratislava(2026, 10, 29, 9, 0);

  setUp(() {
    fakes = FakeRepositories(
      prayer: FakePrayerRepository(location: fakeBratislava),
      cities: FakeCityRepository(testCities),
    );
  });

  testWidgets('before typing: tips and current city', (tester) async {
    await pumpF05(
      tester,
      fakes: fakes,
      now: now,
      location: PrayerPaths.citySearch,
    );
    expect(
      find.text('Type the first letters of your city. The list works offline.'),
      findsOneWidget,
    );
    expect(find.text('Current: Bratislava'), findsOneWidget);
    expect(find.text('Use my location'), findsNothing);
  });

  testWidgets('"Sara" -> Sarajevo first (A7.3 AC)', (tester) async {
    await pumpF05(
      tester,
      fakes: fakes,
      now: now,
      location: PrayerPaths.citySearch,
    );
    await search(tester, 'Sara');
    final tiles = tester.widgetList<ListTile>(resultTitles()).toList();
    expect(tiles, hasLength(2));
    expect((tiles.first.title! as Text).data, 'Sarajevo');
    expect((tiles.first.subtitle! as Text).data, 'Bosnia and Herzegovina');
  });

  testWidgets('no results', (tester) async {
    await pumpF05(
      tester,
      fakes: fakes,
      now: now,
      location: PrayerPaths.citySearch,
    );
    await search(tester, 'Xyz');
    expect(find.text('No cities found for "Xyz"'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Type the first letters'), findsOneWidget);
  });

  testWidgets('search error shows retry', (tester) async {
    await pumpF05(
      tester,
      fakes: fakes,
      now: now,
      location: PrayerPaths.citySearch,
      overrides: [
        citySearchProvider.overrideWith(
          (ref, q) => Future.error(StateError('db')),
        ),
      ],
    );
    await search(tester, 'Sa');
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('choosing a city recalculates times and reschedules (DoD)', (
    tester,
  ) async {
    final router = await pumpF05(tester, fakes: fakes, now: now);
    final date = LocalDate(2026, 10, 29);
    final before = (await fakes.prayer.config())!.schedule.day(date);
    String fajrText() => tester
        .widget<SkPrayerRow>(find.widgetWithText(SkPrayerRow, 'Fajr'))
        .time;
    final en = SakinaFormats(const Locale('en'));
    expect(fajrText(), en.time(before[Prayer.fajr]));

    await tester.tap(find.text('Bratislava'));
    await tester.pumpAndSettle();
    expect(find.byType(CitySearchScreen), findsOneWidget);
    await search(tester, 'Ista');
    await tester.tap(find.text('Istanbul'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, PrayerRoutes.root);
    expect(fakes.prayer.changes, 1);
    final config = (await fakes.prayer.config())!;
    expect(config.location.city, 'Istanbul');
    expect(config.location.tz, 'Europe/Istanbul');
    final after = config.schedule.day(date);
    expect(after[Prayer.fajr], isNot(before[Prayer.fajr]));
    expect(fajrText(), en.time(after[Prayer.fajr]));
    expect(find.text('Prayer times updated for Istanbul.'), findsOneWidget);
    expect(find.text('Istanbul'), findsOneWidget);
  });

  testWidgets('manual method + new country suggests the usual method', (
    tester,
  ) async {
    await fakes.settings.set(
      SettingsKeys.prayerMethod,
      PrayerMethod.muslimWorldLeague.key,
    );
    await pumpF05(
      tester,
      fakes: fakes,
      now: now,
      location: PrayerPaths.citySearch,
    );
    await search(tester, 'Ista');
    await tester.tap(find.text('Istanbul'));
    await tester.pumpAndSettle();
    expect(find.text('Diyanet (Türkiye) is common in Turkey'), findsOneWidget);
    await tester.tap(find.text('Switch'));
    await tester.pumpAndSettle();
    expect(fakes.prayer.changes, 2);
    expect(
      (await fakes.prayer.config())!.settings.method,
      PrayerMethod.turkiye,
    );
  });

  testWidgets('manual method: Keep leaves the method', (tester) async {
    await fakes.settings.set(
      SettingsKeys.prayerMethod,
      PrayerMethod.muslimWorldLeague.key,
    );
    await pumpF05(
      tester,
      fakes: fakes,
      now: now,
      location: PrayerPaths.citySearch,
    );
    await search(tester, 'Ista');
    await tester.tap(find.text('Istanbul'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep Muslim World League'));
    await tester.pumpAndSettle();
    expect(fakes.prayer.changes, 1);
    expect(
      (await fakes.prayer.config())!.settings.method,
      PrayerMethod.muslimWorldLeague,
    );
  });

  testWidgets('use my location picks the nearest city', (tester) async {
    fakes = FakeRepositories(cities: FakeCityRepository(testCities.sublist(1)));
    await pumpF05(
      tester,
      fakes: fakes,
      now: now,
      location: PrayerPaths.citySearch,
      overrides: [
        deviceLocatorProvider.overrideWithValue(
          _Locator((lat: 43.8563, lng: 18.4131)),
        ),
      ],
    );
    await tester.tap(find.text('Use my location'));
    await tester.pumpAndSettle();
    final config = (await fakes.prayer.config())!;
    expect(config.location.city, 'Sarajevo');
    expect(config.settings.method, PrayerMethod.muslimWorldLeague);
    expect(fakes.prayer.changes, 1);
  });

  testWidgets('location unavailable: E-LOC-1 and manual search', (
    tester,
  ) async {
    await pumpF05(
      tester,
      fakes: fakes,
      now: now,
      location: PrayerPaths.citySearch,
      overrides: [deviceLocatorProvider.overrideWithValue(_Locator(null))],
    );
    await tester.tap(find.text('Use my location'));
    await tester.pumpAndSettle();
    expect(find.textContaining("We couldn't find your location"), findsOne);
    expect(fakes.prayer.changes, 0);
  });

  testWidgets('onboarding mode returns the city without saving', (
    tester,
  ) async {
    City? picked;
    await pumpF05Widget(
      tester,
      CitySearchScreen(onPicked: (c) => picked = c),
      fakes: fakes,
      now: now,
    );
    await search(tester, 'Sara');
    await tester.tap(find.text('Sarajevo'));
    await tester.pumpAndSettle();
    expect(picked?.name, 'Sarajevo');
    expect(fakes.prayer.changes, 0);
  });

  testWidgets('tap targets and labels', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpF05(
      tester,
      fakes: fakes,
      now: now,
      location: PrayerPaths.citySearch,
    );
    await search(tester, 'Sara');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
