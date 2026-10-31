@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:prosoche/features/prayer/location/city_search_screen.dart';
import 'package:prosoche/features/prayer/prayer_screen.dart';
import 'package:prosoche/features/prayer/qibla/compass.dart';
import 'package:prosoche/features/prayer/qibla/qibla_screen.dart';
import 'package:prosoche/features/prayer/settings/prayer_settings_screen.dart';
import 'package:prosoche/ui/theme/prosoche_theme.dart';

import '../../fakes/fake_repositories.dart';
import '../../helpers/golden/golden.dart';
import 'f05_test_app.dart';

ThemeData _theme(Brightness b) =>
    b == Brightness.dark ? ProsocheTheme.dark() : ProsocheTheme.light();

const _screen = BoxConstraints.tightFor(width: 360, height: 760);

class _StillCompass implements CompassSource {
  const _StillCompass(this.heading);

  final double heading;

  @override
  Stream<CompassReading> readings() => Stream.value(CompassReading(heading));
}

/// Obrazovka s fakes D-02 bez routera (Overlay pre tooltipy).
Widget _screenWith(Widget child, List<Override> overrides) => ProviderScope(
  overrides: overrides,
  retry: (_, _) => null,
  child: Overlay(initialEntries: [OverlayEntry(builder: (_) => child)]),
);

/// Goldeny obrazoviek F-05 (PLAN_VYVOJA 4.2 bod 3): EN, AR, UR, BN x
/// svetla/tmava x textScale 1.0/2.0, ID a TR smoke.
///
///   flutter test --update-goldens test/features/prayer/prayer_golden_test.dart
void main() {
  final now = bratislava(2026, 10, 29, 14, 0);
  final date = LocalDate(2026, 10, 29);

  List<Override> overrides(FakeRepositories f) => f.overrides(now: now);

  final prayer = FakePrayerRepository(location: fakeBratislava);
  unawaited(prayer.setStatus(date, Prayer.fajr, PrayerStatus.onTime));
  unawaited(prayer.setStatus(date, Prayer.dhuhr, PrayerStatus.late));
  final withLocation = FakeRepositories(
    prayer: prayer,
    cities: FakeCityRepository(testCities),
  );

  goldenAllLocales(
    'PrayerScreen',
    fileName: 'f05_prayer_screen',
    theme: _theme,
    constraints: _screen,
    builder: (_) => _screenWith(const PrayerScreen(), overrides(withLocation)),
  );

  goldenAllLocales(
    'PrayerScreen without location',
    fileName: 'f05_prayer_no_location',
    theme: _theme,
    constraints: _screen,
    builder: (_) =>
        _screenWith(const PrayerScreen(), overrides(FakeRepositories())),
  );

  goldenAllLocales(
    'QiblaScreen',
    fileName: 'f05_qibla',
    theme: _theme,
    constraints: _screen,
    builder: (_) => _screenWith(const QiblaScreen(), [
      ...overrides(withLocation),
      compassSourceProvider.overrideWithValue(const _StillCompass(100)),
    ]),
  );

  goldenAllLocales(
    'PrayerSettingsScreen',
    fileName: 'f05_prayer_settings',
    theme: _theme,
    constraints: _screen,
    builder: (_) =>
        _screenWith(const PrayerSettingsScreen(), overrides(withLocation)),
  );

  goldenAllLocales(
    'CitySearchScreen',
    fileName: 'f05_city_search',
    theme: _theme,
    constraints: _screen,
    builder: (_) =>
        _screenWith(const CitySearchScreen(), overrides(withLocation)),
  );
}
