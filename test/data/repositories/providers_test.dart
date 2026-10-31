import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/clock/clock_provider.dart';
import 'package:sakina/data/db/content_db.dart';
import 'package:sakina/data/db/user_db.dart' show UserDb;
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/prayer/prayer.dart';
import 'package:sakina/domain/quests/quests.dart';
import 'package:sakina/domain/settings/settings_repository.dart';

import '../../fakes/in_memory_settings_repository.dart';
import '../db/fixtures/content_fixture.dart';
import 'harness.dart';

class _FixtureSource implements ContentDbSource {
  _FixtureSource(this.db);

  final ContentDb db;

  @override
  Future<ContentDb> open() async => db;
}

void main() {
  late ProviderContainer c;
  late UserDb user;
  late TestClock clock;
  final thu = LocalDate(2026, 10, 29);

  /// Precita async provider s posluchacom (bez neho je pozastaveny).
  Future<T> get<T>(ProviderListenable<Future<T>> f) async {
    final sub = c.listen(f, (_, _) {});
    try {
      return await sub.read();
    } finally {
      sub.close();
    }
  }

  setUp(() async {
    final content = openContentFixture();
    await addCuratedRules(content);
    user = UserDb.memory();
    clock = TestClock(DateTime(2026, 10, 29, 9));
    c = ProviderContainer(
      overrides: [
        userDbProvider.overrideWithValue(user),
        contentDbSourceProvider.overrideWithValue(_FixtureSource(content)),
        appClockProvider.overrideWithValue(clock),
        deviceTimeZoneProvider.overrideWith((ref) async => 'Europe/Bratislava'),
        deviceLanguageProvider.overrideWithValue('de'),
      ],
      retry: (_, _) => null,
    );
  });

  tearDown(() async {
    c.dispose();
    await user.close();
  });

  test('settings, install id and content language', () async {
    expect(await get(contentLanguageProvider.future), 'en');
    final id = await get(installIdProvider.future);
    expect(id, matches(RegExp('^[0-9a-f]{8}-[0-9a-f]{4}-4')));
    final repo = c.read(settingsRepositoryProvider);
    expect(await ensureInstallId(repo), id);
    final sub = c.listen(settingOf(SettingsKeys.simpleMode), (_, _) {});
    await get(settingProvider(SettingsKeys.simpleMode).future);
    expect(sub.read().value, isFalse);
    await repo.set(SettingsKeys.uiLocale, 'ur');
    await repo.reset(SettingsKeys.niyyahText);
    c.invalidate(contentLanguageProvider);
    expect(await get(contentLanguageProvider.future), 'ur');
    expect(resolveContentLanguage(null, 'bn'), 'bn');
    expect(resolveContentLanguage('xx', 'de'), 'en');
    expect(uuidV4(Random(1)), hasLength(36));
  });

  test('today providers', () async {
    expect(await get(activeSetDateProvider.future), thu);
    final set = await get(dailySetProvider(thu).future);
    expect(set.n, 10);
    final quests = await get(questsProvider(thu).future);
    expect(quests.first.slot, QuestSlot.read);
    final streak = await get(streakProvider.future);
    expect(streak.current, 0);
    expect(await get(dayLogProvider((2026, 10)).future), isEmpty);
    expect(await get(dayLogProvider((2026, 12)).future), isEmpty);
    final content = await c.read(
      cardContentProvider(set.set.cards.first.cardId).future,
    );
    expect(content, isA<IntroContent>());
    expect(await get(isSavedProvider(set.set.cards[1].cardId).future), isFalse);
  });

  test('calendar providers', () async {
    final fri = thu.addDays(1);
    final hijri = await get(hijriDateProvider(fri).future);
    expect((await get(eventResolutionProvider(fri).future)).hijri, hijri);
    expect(
      (await get(activeEventsProvider(fri).future)).single.id,
      'fx_friday',
    );
    final month = await c.read(
      hijriMonthProvider((hijri.year, hijri.month)).future,
    );
    expect(month.eventIds, ['fx_friday']);
  });

  test('prayer providers without and with location', () async {
    expect(await get(prayerConfigProvider.future), isNull);
    expect(await get(prayerScheduleProvider(thu).future), isNull);
    expect(await get(nextPrayerProvider.future), isNull);
    expect(await get(prayerTrackerDateProvider.future), thu);
    await c
        .read(prayerRepositoryProvider)
        .saveLocation(
          PrayerLocation(
            lat: 48.15,
            lng: 17.11,
            country: 'SK',
            tz: 'Europe/Bratislava',
          ),
        );
    final sub = c.listen(prayerConfigProvider, (_, _) {});
    final config =
        await get(prayerConfigProvider.future) ??
        await c
            .read(prayerRepositoryProvider)
            .watchConfig()
            .firstWhere((x) => x != null);
    expect(config, isNotNull);
    sub.close();
    c.invalidate(prayerConfigProvider);
    final day = await get(prayerScheduleProvider(thu).future);
    expect(day![Prayer.fajr].isBefore(day[Prayer.dhuhr]), isTrue);
    expect(await get(nextPrayerProvider.future), isNotNull);
    await c
        .read(prayerRepositoryProvider)
        .setStatus(thu, Prayer.fajr, PrayerStatus.onTime);
    expect(await get(prayerLogProvider(thu).future), {
      Prayer.fajr: PrayerStatus.onTime,
    });
    expect(
      (await c.read(cityRepositoryProvider).search('Brno')).single.name,
      'Brno',
    );
  });

  test('quran providers', () async {
    expect((await get(surahsProvider.future)).length, 2);
    expect((await get(surahAyahsProvider(1).future)).length, 7);
    expect(await get(readingPositionProvider.future), isNull);
    expect(await get(readCountsProvider.future), isEmpty);
    await c
        .read(cardActionsRepositoryProvider)
        .save(thu, AyahCardId(AyahId(1, 1)), context: CardContext.feed);
    expect(
      await c.read(cardActionsRepositoryProvider).watchSaved().first,
      hasLength(1),
    );
  });

  test('local date refreshes from the clock', () {
    expect(c.read(localDateProvider), thu);
    clock.time = DateTime(2026, 10, 30, 0, 1);
    c.read(localDateProvider.notifier).refresh();
    expect(c.read(localDateProvider), thu.addDays(1));
  });

  test('defaults: no content source, no disabled ids', () {
    final bare = ProviderContainer(retry: (_, _) => null);
    addTearDown(bare.dispose);
    expect(() => bare.read(contentDbSourceProvider), throwsA(anything));
    expect(bare.read(disabledCardIdsProvider), isEmpty);
    expect(bare.read(hadithExtraRepositoryProvider), isNotNull);
    expect(
      bare.read(prayerSettingsChangedProvider),
      isA<PrayerSettingsChanged>(),
    );
    expect(InMemorySettingsRepository(), isA<SettingsRepository>());
  });
}
