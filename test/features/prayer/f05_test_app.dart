import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/calendar/calendar.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/prayer/calc_settings.dart';
import 'package:prosoche/domain/prayer/prayer_schedule.dart';
import 'package:prosoche/features/calendar/calendar_routes.dart';
import 'package:prosoche/features/prayer/prayer_paths.dart';
import 'package:prosoche/features/prayer/prayer_routes.dart';
import 'package:prosoche/ui/theme/prosoche_theme.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../fakes/fake_repositories.dart';

PrayerDay bratislavaDay(LocalDate d) {
  ensureTimeZoneData();
  return PrayerConfig(
    fakeBratislava,
    CalcSettings.resolve(lat: fakeBratislava.lat, country: 'SK'),
  ).schedule.day(d);
}

tz.TZDateTime bratislava(int y, int m, int d, int h, int min) {
  ensureTimeZoneData();
  return tz.TZDateTime(tz.getLocation('Europe/Bratislava'), y, m, d, h, min);
}

/// Poradie ako z content.db (populacia): Saratov (845 tis.) pred Sarajevom.
const testCities = [
  City(
    id: 498677,
    name: 'Saratov',
    countryCode: 'RU',
    countryName: 'Russia',
    lat: 51.54,
    lng: 46.01,
    tz: 'Europe/Saratov',
  ),
  City(
    id: 3191281,
    name: 'Sarajevo',
    countryCode: 'BA',
    countryName: 'Bosnia and Herzegovina',
    lat: 43.85,
    lng: 18.36,
    tz: 'Europe/Sarajevo',
  ),
  City(
    id: 745044,
    name: 'Istanbul',
    countryCode: 'TR',
    countryName: 'Turkey',
    lat: 41.01,
    lng: 28.95,
    tz: 'Europe/Istanbul',
  ),
  City(
    id: 3060972,
    name: 'Bratislava',
    countryCode: 'SK',
    countryName: 'Slovakia',
    lat: 48.15,
    lng: 17.11,
    tz: 'Europe/Bratislava',
  ),
];

/// Placeholder pravidla eventov pre testy kalendara (nie produkcne eventy).
final List<EventRule> testEventRules = [
  EventRuleParser.parse({
    'id': 'white_days',
    'when': {
      'hijri_day': [13, 14, 15],
    },
  }),
  EventRuleParser.parse({
    'id': 'month_start',
    'when': {
      'hijri_month_day': [
        [9, 1],
      ],
    },
  }),
];

/// Placeholder texty eventov (len `en`).
const testEventTexts = {
  'white_days': '[PLACEHOLDER event white_days]',
  'month_start': '[PLACEHOLDER event month_start]',
};

/// Router len s routami F-05 a zastupkami cielov mimo F-05.
GoRouter f05Router(String location) => GoRouter(
  initialLocation: location,
  routes: [
    ...prayerRoutes(),
    ...calendarRoutes(),
    GoRoute(
      path: PrayerPaths.settings,
      builder: PrayerSettingsBuilders.settings,
      routes: [
        GoRoute(
          path: 'location',
          builder: PrayerSettingsBuilders.location,
          routes: [
            GoRoute(path: 'search', builder: PrayerSettingsBuilders.location),
          ],
        ),
      ],
    ),
    GoRoute(
      path: PrayerPaths.calendarSettings,
      builder: CalendarSettingsBuilders.offset,
    ),
    GoRoute(
      path: PrayerPaths.notifications,
      builder: (context, state) => const Text('stub:notifications'),
    ),
  ],
);

/// Spusti [location] s fakes D-02 v case [now] a vrati router.
Future<GoRouter> pumpF05(
  WidgetTester tester, {
  required FakeRepositories fakes,
  required DateTime now,
  String location = PrayerRoutes.root,
  List<Override> overrides = const [],
  Locale locale = const Locale('en'),
  String timeZone = 'Europe/Bratislava',
  String deviceLanguage = 'en',
  bool settle = true,
  Size size = const Size(412, 1400),
}) async {
  tester.view
    ..physicalSize = size * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = f05Router(location);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...fakes.overrides(
          now: now,
          timeZone: timeZone,
          deviceLanguage: deviceLanguage,
        ),
        ...overrides,
      ],
      retry: (_, _) => null,
      child: MaterialApp.router(
        theme: ProsocheTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return router;
}

/// Jedna obrazovka bez routera (napr. onboarding rezim vyhladavania).
Future<void> pumpF05Widget(
  WidgetTester tester,
  Widget child, {
  required FakeRepositories fakes,
  required DateTime now,
  List<Override> overrides = const [],
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...fakes.overrides(now: now),
        ...overrides,
      ],
      retry: (_, _) => null,
      child: MaterialApp(
        theme: ProsocheTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
