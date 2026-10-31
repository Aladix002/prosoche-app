@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/features/calendar/calendar_screen.dart';
import 'package:prosoche/features/calendar/hijri_offset.dart';
import 'package:prosoche/ui/theme/prosoche_theme.dart';

import '../../fakes/fake_repositories.dart';
import '../../helpers/golden/golden.dart';
import '../prayer/f05_test_app.dart';

ThemeData _theme(Brightness b) =>
    b == Brightness.dark ? ProsocheTheme.dark() : ProsocheTheme.light();

const _screen = BoxConstraints.tightFor(width: 360, height: 760);

/// Goldeny kalendara A9 a hijri offsetu A10.8 (EN, AR, UR, BN, smoke ID
/// a TR). Texty eventov su placeholdery.
///
///   flutter test --update-goldens test/features/calendar/calendar_golden_test.dart
void main() {
  final fakes = FakeRepositories(
    calendar: FakeCalendarRepository(
      rules: testEventRules,
      texts: testEventTexts,
    ),
  );
  final overrides = fakes.overrides(now: bratislava(2026, 10, 29, 9, 0));

  Widget screen(Widget child) => ProviderScope(
    overrides: overrides,
    retry: (_, _) => null,
    child: Overlay(initialEntries: [OverlayEntry(builder: (_) => child)]),
  );

  goldenAllLocales(
    'CalendarScreen',
    fileName: 'f05_calendar',
    theme: _theme,
    constraints: _screen,
    builder: (_) => screen(const CalendarScreen()),
  );

  goldenAllLocales(
    'HijriOffsetScreen',
    fileName: 'f05_hijri_offset',
    theme: _theme,
    constraints: _screen,
    builder: (_) => screen(const HijriOffsetScreen()),
  );
}
