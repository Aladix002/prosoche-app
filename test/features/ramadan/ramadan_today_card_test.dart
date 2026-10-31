import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/domain/common/local_date.dart';
import 'package:prosoche/domain/ramadan/ramadan.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/ramadan/ramadan_providers.dart';
import 'package:prosoche/features/ramadan/ramadan_today_card.dart';
import 'package:prosoche/ui/theme/prosoche_theme.dart';
import 'package:prosoche/ui/ui.dart';

import '../../fakes/fake_repositories.dart';
import '../../fakes/in_memory_settings_repository.dart';
import '../../helpers/golden/golden.dart';
import '../prayer/f05_test_app.dart';
import 'ramadan_test_helpers.dart';

/// Karta Ramadanu na Dnes: stavy loading, empty, data, error a akcie.
/// Umm al-Qura 1448: 29. Shaban = 6. 2. 2027, start 8. 2., Eid 9. 3.
void main() {
  late InMemorySettingsRepository settings;
  late FakeFastLogRepository fastLog;
  late int seasonChanges;

  setUp(() {
    settings = InMemorySettingsRepository();
    fastLog = FakeFastLogRepository();
    seasonChanges = 0;
  });

  Future<void> pump(
    WidgetTester tester, {
    required DateTime now,
    FeatureFlags flags = FeatureFlags.all,
    bool location = true,
    List<Object> extra = const [],
  }) async {
    final fakes = FakeRepositories(
      settings: settings,
      prayer: FakePrayerRepository(location: location ? fakeBratislava : null),
    );
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          ...fakes.overrides(now: now),
          featureFlagsProvider.overrideWithValue(flags),
          fastLogRepositoryProvider.overrideWithValue(fastLog),
          ramadanSeasonChangedProvider.overrideWithValue(
            () async => seasonChanges++,
          ),
          ...extra.cast(),
        ],
        child: LocalizedTestApp(
          locale: const Locale('en'),
          theme: (b) => b == Brightness.dark
              ? ProsocheTheme.dark()
              : ProsocheTheme.light(),
          child: const SingleChildScrollView(child: RamadanTodayCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Size cardSize(WidgetTester tester) =>
      tester.getSize(find.byType(RamadanTodayCard));

  group('hidden', () {
    testWidgets('flag off', (tester) async {
      await pump(
        tester,
        now: bratislava(2027, 2, 10, 12, 0),
        flags: FeatureFlags.none,
      );
      expect(cardSize(tester).height, 0);
    });

    testWidgets('empty: outside the season', (tester) async {
      await pump(tester, now: bratislava(2026, 10, 29, 9, 0));
      expect(cardSize(tester).height, 0);
    });

    testWidgets('loading takes no space', (tester) async {
      await pump(
        tester,
        now: bratislava(2027, 2, 10, 12, 0),
        extra: [
          ramadanStateProvider.overrideWith(
            (ref) => Completer<RamadanState>().future,
          ),
        ],
      );
      expect(cardSize(tester).height, 0);
    });
  });

  testWidgets('error: banner with retry', (tester) async {
    var calls = 0;
    await pump(
      tester,
      now: bratislava(2027, 2, 10, 12, 0),
      extra: [
        ramadanStateProvider.overrideWith((ref) async {
          calls++;
          throw StateError('calendar');
        }),
      ],
    );
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.errorGeneric), findsOneWidget);
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  group('data', () {
    testWidgets('upcoming: expected start', (tester) async {
      await pump(tester, now: bratislava(2027, 2, 3, 9, 0));
      expect(find.textContaining('expected to start'), findsOneWidget);
      expect(find.textContaining('Feb 8, 2027'), findsOneWidget);
    });

    testWidgets('29 Shaban: "Tomorrow" stores the confirmation', (
      tester,
    ) async {
      await pump(tester, now: bratislava(2027, 2, 6, 15, 30));
      expect(
        find.text('When does Ramadan start in your community?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Tomorrow'));
      await tester.pumpAndSettle();
      final stored = await settings.get(RamadanConfirmation.settingKey);
      expect(stored!.startDate, LocalDate(2027, 2, 7));
      expect(stored.source, SeasonSource.userConfirmed);
      expect(seasonChanges, 1);
      expect(find.textContaining('Ramadan starts on'), findsOneWidget);
      expect(find.textContaining('Feb 7, 2027'), findsOneWidget);
    });

    testWidgets('"Use the calculation" stores the calculated start', (
      tester,
    ) async {
      await pump(tester, now: bratislava(2027, 2, 6, 15, 30));
      await tester.tap(find.text("I don't know, use the calculation"));
      await tester.pumpAndSettle();
      final stored = await settings.get(RamadanConfirmation.settingKey);
      expect(stored!.startDate, LocalDate(2027, 2, 8));
      expect(stored.source, SeasonSource.calc);
    });

    testWidgets('"Day after tomorrow"', (tester) async {
      await pump(tester, now: bratislava(2027, 2, 6, 15, 30));
      await tester.tap(find.text('Day after tomorrow'));
      await tester.pumpAndSettle();
      final stored = await settings.get(RamadanConfirmation.settingKey);
      expect(stored!.startDate, LocalDate(2027, 2, 8));
    });

    testWidgets('active day: iftar countdown and fast log', (tester) async {
      await pump(tester, now: bratislava(2027, 2, 10, 12, 0));
      expect(find.text('Ramadan · day 3'), findsOneWidget);
      expect(find.textContaining('Iftar at '), findsOneWidget);
      expect(find.textContaining(RegExp(r'^in \d+ h \d+ min$')), findsOne);
      expect(find.text('Your fast on day 2'), findsOneWidget);

      await tester.tap(find.text('Fasted'));
      await tester.pumpAndSettle();
      expect(fastLog.entries[LocalDate(2027, 2, 9)], FastEntry.fasted);
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Fasted'),
      );
      expect(chip.selected, isTrue);

      // Opatovny tap zaznam zmaze.
      await tester.tap(find.text('Fasted'));
      await tester.pumpAndSettle();
      expect(fastLog.entries, isEmpty);

      await tester.tap(find.text('Excused'));
      await tester.pumpAndSettle();
      expect(fastLog.entries[LocalDate(2027, 2, 9)], FastEntry.excused);
    });

    testWidgets('night: suhur countdown', (tester) async {
      await pump(tester, now: bratislava(2027, 2, 10, 2, 30));
      expect(find.text('Ramadan · night 3'), findsOneWidget);
      expect(find.textContaining('Suhur ends at '), findsOneWidget);
    });

    testWidgets('without location: prompt instead of times', (tester) async {
      await pump(tester, now: bratislava(2027, 2, 10, 12, 0), location: false);
      expect(
        find.text('Set your location to see suhur and iftar times.'),
        findsOneWidget,
      );
      expect(find.text('Set location'), findsOneWidget);
    });

    testWidgets('day 29: "No" keeps Ramadan 30 days', (tester) async {
      await pump(tester, now: bratislava(2027, 3, 8, 16, 30));
      expect(find.text('Is Eid tomorrow in your community?'), findsOneWidget);
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
      final stored = await settings.get(RamadanConfirmation.settingKey);
      expect(stored!.lengthDays, 30);
      expect(find.text('Is Eid tomorrow in your community?'), findsNothing);
    });

    testWidgets('day 29: "Yes" ends after 29 days', (tester) async {
      await pump(tester, now: bratislava(2027, 3, 8, 16, 30));
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      final stored = await settings.get(RamadanConfirmation.settingKey);
      expect(stored!.lengthDays, 29);
    });

    testWidgets('Eid evening: only the last fast log', (tester) async {
      await pump(tester, now: bratislava(2027, 3, 8, 21, 0));
      expect(find.textContaining('Iftar'), findsNothing);
      expect(find.textContaining('Suhur'), findsNothing);
      expect(find.text('Your fast on day 29'), findsOneWidget);
    });
  });

  test('ramadanFastingDaysAhead reads offset and confirmation', () async {
    final s = InMemorySettingsRepository();
    final calc = await ramadanFastingDaysAhead(s, LocalDate(2027, 2, 6));
    expect(calc.first, LocalDate(2027, 2, 8));
    expect(calc, hasLength(10));
    await s.set(SettingsKeys.hijriOffset, 1);
    expect(
      (await ramadanFastingDaysAhead(s, LocalDate(2027, 2, 6))).first,
      LocalDate(2027, 2, 9),
    );
    await s.set(
      RamadanConfirmation.settingKey,
      RamadanConfirmation(
        hijriYear: 1448,
        startDate: LocalDate(2027, 2, 7),
        source: SeasonSource.userConfirmed,
      ),
    );
    expect(await ramadanFastingDaysAhead(s, LocalDate(2027, 2, 6), days: 3), {
      LocalDate(2027, 2, 7),
      LocalDate(2027, 2, 8),
    });
  });
}
