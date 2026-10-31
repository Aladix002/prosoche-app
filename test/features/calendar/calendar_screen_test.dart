import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/calendar/calendar.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/calendar/calendar_routes.dart';
import 'package:sakina/features/calendar/calendar_screen.dart';
import 'package:sakina/features/prayer/prayer_paths.dart';
import 'package:sakina/ui/i18n/i18n.dart';
import 'package:sakina/ui/ui.dart';

import '../../fakes/fake_repositories.dart';
import '../../fakes/in_memory_settings_repository.dart';
import '../prayer/f05_test_app.dart';

/// Kalendar, ktory hadze chybu (E-CAL-1).
class _BrokenCalendar extends FakeCalendarRepository {
  @override
  Future<CalendarMonth> month(int year, int month) async =>
      throw StateError('db');
}

/// Fake s offsetom z nastaveni (ako `ContentCalendarRepository`).
class _SettingsCalendar extends FakeCalendarRepository {
  _SettingsCalendar(this.settings, {super.rules, super.texts});

  final SettingsRepository settings;

  Future<void> _sync() async =>
      offset = await settings.get(SettingsKeys.hijriOffset);

  @override
  Future<HijriDate> hijriDate(LocalDate date) async {
    await _sync();
    return await super.hijriDate(date);
  }

  @override
  Future<CalendarMonth> month(int year, int month) async {
    await _sync();
    return await super.month(year, month);
  }
}

void main() {
  final now = bratislava(2026, 10, 29, 9, 0);
  final en = SakinaFormats(const Locale('en'));
  late FakeRepositories fakes;

  FakeRepositories withCalendar(
    FakeCalendarRepository Function(SettingsRepository settings) build,
  ) {
    final settings = InMemorySettingsRepository();
    return FakeRepositories(settings: settings, calendar: build(settings));
  }

  setUp(() {
    fakes = withCalendar(
      (s) => _SettingsCalendar(s, rules: testEventRules, texts: testEventTexts),
    );
  });

  Future<void> open(WidgetTester tester, {String query = ''}) => pumpF05(
    tester,
    fakes: fakes,
    now: now,
    location: '${CalendarRoutes.root}$query',
  );

  testWidgets('current hijri month with events (A9)', (tester) async {
    await open(tester);
    expect(find.text('Jumada al-Ula 1448'), findsOneWidget);
    expect(find.text('Oct – Nov 2026'), findsOneWidget);
    expect(find.text('Events this month'), findsOneWidget);
    expect(find.text('[PLACEHOLDER event white_days]'), findsOneWidget);
    expect(find.text('13, 14, 15'), findsOneWidget);
    expect(find.text('Hijri date offset: 0 days'), findsOneWidget);
    // Dnes (18. Jumada al-Ula) je oznaceny.
    expect(
      find.bySemanticsLabel(RegExp('^18 Jumada al-Ula 1448, .*Today')),
      findsOneWidget,
    );
  });

  testWidgets('month paging is limited to +-12 months', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('Jumada al-Akhirah 1448'), findsOneWidget);
    for (var i = 0; i < 14; i++) {
      await tester.tap(find.byTooltip('Next month'));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('Jumada al-Ula 1449'), findsOneWidget);
    for (var i = 0; i < 30; i++) {
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('Jumada al-Ula 1447'), findsOneWidget);
  });

  testWidgets('query parameters choose the month', (tester) async {
    await open(tester, query: '?hm=1448-09');
    expect(find.text('Ramadan 1448'), findsOneWidget);
    await open(tester, query: '?month=2026-12');
    expect(find.text('Jumada al-Akhirah 1448'), findsOneWidget);
    // Mimo +-12 mesiacov a neplatne hodnoty = aktualny mesiac (C2).
    await open(tester, query: '?hm=1460-01');
    expect(find.text('Jumada al-Ula 1448'), findsOneWidget);
    await open(tester, query: '?hm=x');
    expect(find.text('Jumada al-Ula 1448'), findsOneWidget);
  });

  testWidgets('offset +1 shows 1 Ramadan one day later (A9 AC)', (
    tester,
  ) async {
    final base = IslamicCalendar().gregorianOf(HijriDate(1448, 9, 1));
    String firstDayLabel() => tester
        .getSemantics(find.bySemanticsLabel(RegExp('^1 Ramadan 1448, ')))
        .label;

    final handle = tester.ensureSemantics();
    await open(tester, query: '?hm=1448-09');
    expect(firstDayLabel(), contains(en.weekdayDate(base.toLocalDateTime())));

    await fakes.settings.set(SettingsKeys.hijriOffset, 1);
    await tester.pumpAndSettle();
    expect(
      firstDayLabel(),
      contains(en.weekdayDate(base.addDays(1).toLocalDateTime())),
    );
    expect(find.text('Hijri date offset: +1 day'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('change offset in the sheet (A10.8)', (tester) async {
    await open(tester);
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    expect(find.text('Today is 18 Jumada al-Ula 1448'), findsOneWidget);
    await tester.tap(find.byTooltip('One day later'));
    await tester.pumpAndSettle();
    expect(await fakes.settings.get(SettingsKeys.hijriOffset), 1);
    expect(find.text('Today is 17 Jumada al-Ula 1448'), findsOneWidget);
    expect(find.text('+1 day'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byTooltip('One day earlier'));
      await tester.pumpAndSettle();
    }
    expect(await fakes.settings.get(SettingsKeys.hijriOffset), -2);
    final minus = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.remove),
    );
    expect(minus.onPressed, isNull);
  });

  testWidgets('tap a day opens its events', (tester) async {
    await open(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('^13 Jumada al-Ula 1448')));
    await tester.pumpAndSettle();
    expect(find.byType(SkSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SkSheet),
        matching: find.text('[PLACEHOLDER event white_days]'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('^20 Jumada al-Ula 1448')));
    await tester.pumpAndSettle();
    expect(find.text('No special events on this day.'), findsOneWidget);
  });

  testWidgets('empty month shows the next event (EMPTY-CAL-MONTH)', (
    tester,
  ) async {
    fakes = withCalendar(
      (s) => _SettingsCalendar(
        s,
        rules: [testEventRules.last],
        texts: testEventTexts,
      ),
    );
    await open(tester);
    expect(find.text('No special days this month'), findsOneWidget);
    final next = IslamicCalendar().gregorianOf(HijriDate(1448, 9, 1));
    expect(
      find.text(
        'Next: [PLACEHOLDER event month_start] on '
        '${en.date(next.toLocalDateTime())}.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('event text in English is tagged EN for other languages', (
    tester,
  ) async {
    await pumpF05(
      tester,
      fakes: fakes,
      now: now,
      location: CalendarRoutes.root,
      locale: const Locale('tr'),
      deviceLanguage: 'tr',
    );
    expect(find.text('[PLACEHOLDER event white_days]'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
  });

  testWidgets('error state E-CAL-1', (tester) async {
    fakes = FakeRepositories(calendar: _BrokenCalendar());
    await open(tester);
    expect(find.text("The calendar couldn't load"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('loading state', (tester) async {
    await pumpF05(
      tester,
      fakes: fakes,
      now: now,
      location: CalendarRoutes.root,
      settle: false,
    );
    expect(find.byType(SkLoadingView), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(SkLoadingView), findsNothing);
  });

  testWidgets('settings screen /settings/calendar', (tester) async {
    await pumpF05(
      tester,
      fakes: fakes,
      now: now,
      location: PrayerPaths.calendarSettings,
    );
    expect(find.byType(HijriOffsetScreen), findsOneWidget);
    expect(find.text('Hijri date'), findsOneWidget);
    await tester.tap(find.byTooltip('One day later'));
    await tester.pumpAndSettle();
    expect(await fakes.settings.get(SettingsKeys.hijriOffset), 1);
  });

  testWidgets('semantics and tap targets', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  test('route helpers', () {
    expect(CalendarRoutes.parseHijri('1448-05'), (1448, 5));
    expect(CalendarRoutes.parseHijri('1448-13'), isNull);
    expect(CalendarRoutes.parseGregorian('2026-10'), (2026, 10));
    expect(CalendarRoutes.parseGregorian(null), isNull);
    expect(shiftHijriMonth((1448, 12), 1), (1449, 1));
    expect(shiftHijriMonth((1448, 1), -1), (1447, 12));
  });
}
