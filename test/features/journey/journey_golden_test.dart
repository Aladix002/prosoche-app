@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:prosoche/domain/quests/quests.dart' show CardContext;
import 'package:prosoche/features/journey/journey_day_screen.dart';
import 'package:prosoche/features/journey/journey_screen.dart';
import 'package:prosoche/features/journey/saved_screen.dart';
import 'package:prosoche/ui/theme/prosoche_theme.dart';

import '../../fakes/fake_repositories.dart';
import '../../helpers/golden/golden.dart';
import 'journey_fixtures.dart';

ThemeData _theme(Brightness b) =>
    b == Brightness.dark ? ProsocheTheme.dark() : ProsocheTheme.light();

const _screen = BoxConstraints.tightFor(width: 360, height: 760);

/// Goldeny Moja cesta A8.1-A8.3 (EN, AR, UR, BN x tema x 1.0/2.0; ID a TR
/// smoke). Obsah kariet je placeholder.
///
///   flutter test --update-goldens test/features/journey/journey_golden_test.dart
void main() {
  final yesterday = journeyToday.addDays(-1);

  Future<FakeRepositories> repos() async {
    final r = FakeRepositories(
      streak: fixtureStreak(),
      quran: JourneyQuranRepository(counts: {1: 7, 2: 143, 18: 30}, khatms: 1),
    );
    r.dailySets.put(
      DailySetState(
        set: fakeDailySet(yesterday),
        cursor: 10,
        completedAt: DateTime(2026, 10, 28, 9, 10),
      ),
    );
    await r.prayer.setStatus(yesterday, Prayer.fajr, PrayerStatus.onTime);
    await r.prayer.setStatus(yesterday, Prayer.asr, PrayerStatus.late);
    for (final id in [
      ReflectionCardId(31),
      HadithCardId(13),
      AyahCardId(AyahId(2, 255)),
    ]) {
      await r.actions.save(journeyToday, id, context: CardContext.feed);
    }
    return r;
  }

  late FakeRepositories fakes;
  late FakeRepositories notesFakes;
  setUpAll(() async {
    fakes = await repos();
    // BF-02: nahlad versa so znackami poznamok prekladatela.
    notesFakes = FakeRepositories(
      cards: NotesCardContentRepository({
        AyahId(2, 255): (
          '(1) [PLACEHOLDER] one,[2] [PLACEHOLDER] two.[3]',
          '[2]- [PLACEHOLDER]\n[3]- [PLACEHOLDER]',
        ),
      }),
    );
    await notesFakes.actions.save(
      journeyToday,
      AyahCardId(AyahId(2, 255)),
      context: CardContext.feed,
    );
  });

  Widget screen(
    BuildContext context,
    Widget child, {
    FakeRepositories? using,
  }) => ProviderScope(
    retry: (_, _) => null,
    overrides: (using ?? fakes).overrides(
      now: journeyNow,
      deviceLanguage: Localizations.localeOf(context).languageCode,
    ),
    child: Overlay(initialEntries: [OverlayEntry(builder: (_) => child)]),
  );

  goldenAllLocales(
    'JourneyScreen',
    fileName: 'f06_journey',
    theme: _theme,
    constraints: _screen,
    builder: (context) => screen(context, const JourneyScreen()),
  );

  goldenAllLocales(
    'JourneyDayScreen',
    fileName: 'f06_journey_day',
    theme: _theme,
    constraints: _screen,
    builder: (context) => screen(context, JourneyDayScreen(date: yesterday)),
  );

  goldenAllLocales(
    'SavedCardsScreen',
    fileName: 'f06_saved',
    theme: _theme,
    constraints: _screen,
    builder: (context) => screen(context, const SavedCardsScreen()),
  );

  goldenAllLocales(
    'SavedCardsScreen translator notes',
    fileName: 'f06_saved_notes',
    theme: _theme,
    constraints: _screen,
    builder: (context) =>
        screen(context, const SavedCardsScreen(), using: notesFakes),
  );
}
