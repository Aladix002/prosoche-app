import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:sakina/core/clock/clock_provider.dart';
import 'package:sakina/core/flags/feature_flags.dart';
import 'package:sakina/core/logging/logger_provider.dart';
import 'package:sakina/data/repositories/calendar/calendar_repository.dart';
import 'package:sakina/data/repositories/cards/card_actions_repository.dart';
import 'package:sakina/data/repositories/cards/card_content_repository.dart';
import 'package:sakina/data/repositories/catalog/content_catalog.dart';
import 'package:sakina/data/repositories/infra/databases.dart';
import 'package:sakina/data/repositories/infra/time_providers.dart';
import 'package:sakina/data/repositories/prayer/city_repository.dart';
import 'package:sakina/data/repositories/prayer/prayer_repository.dart';
import 'package:sakina/data/repositories/quran/quran_repository.dart';
import 'package:sakina/data/repositories/settings/drift_settings_repository.dart';
import 'package:sakina/data/repositories/settings/settings_providers.dart';
import 'package:sakina/data/repositories/today/daily_set_repository.dart';
import 'package:sakina/data/repositories/today/quest_repository.dart';
import 'package:sakina/data/repositories/today/streak_repository.dart';
import 'package:sakina/domain/calendar/calendar.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/prayer/prayer.dart';
import 'package:sakina/domain/prayer/prayer_schedule.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/domain/streak/streak.dart';

// ---------------------------------------------------------------- repozitare
// Kazdy repozitar je override point: widget testy obrazoviek ho prepisu
// fake implementaciou z `test/fakes/` (`fakeRepositoryOverrides`).

/// Kuratovany obsah pre enginy (interne, nie pre obrazovky).
final Provider<ContentCatalog> contentCatalogProvider =
    Provider<ContentCatalog>(
      (ref) => ContentCatalog(
        ref.watch(contentDbProvider.future),
        logger: ref.watch(appLoggerProvider),
      ),
      name: 'contentCatalogProvider',
    );

final Provider<CalendarRepository> calendarRepositoryProvider =
    Provider<CalendarRepository>(
      (ref) => ContentCalendarRepository(
        catalog: ref.watch(contentCatalogProvider),
        settings: ref.watch(settingsRepositoryProvider),
      ),
      name: 'calendarRepositoryProvider',
    );

/// Po zmene polohy/nastaveni modlitieb (P-02 prepise na
/// `NotificationPlanner.reschedule`). Default nic.
final Provider<PrayerSettingsChanged> prayerSettingsChangedProvider =
    Provider<PrayerSettingsChanged>(
      (ref) => () async {},
      name: 'prayerSettingsChangedProvider',
    );

final Provider<PrayerRepository> prayerRepositoryProvider =
    Provider<PrayerRepository>(
      (ref) => DriftPrayerRepository(
        db: ref.watch(userDbProvider),
        settings: ref.watch(settingsRepositoryProvider),
        clock: ref.watch(appClockProvider),
        onChanged: ref.watch(prayerSettingsChangedProvider),
      ),
      name: 'prayerRepositoryProvider',
    );

final Provider<CityRepository> cityRepositoryProvider =
    Provider<CityRepository>(
      (ref) => ContentCityRepository(ref.watch(contentDbProvider.future)),
      name: 'cityRepositoryProvider',
    );

final Provider<QuranRepository> quranRepositoryProvider =
    Provider<QuranRepository>(
      (ref) => DriftQuranRepository(
        content: ref.watch(contentDbProvider.future),
        userDb: ref.watch(userDbProvider),
        settings: ref.watch(settingsRepositoryProvider),
        clock: ref.watch(appClockProvider),
      ),
      name: 'quranRepositoryProvider',
    );

final Provider<QuestRepository> questRepositoryProvider =
    Provider<QuestRepository>(
      (ref) => DriftQuestRepository(
        userDb: ref.watch(userDbProvider),
        catalog: ref.watch(contentCatalogProvider),
        calendar: ref.watch(calendarRepositoryProvider),
        installId: () => ensureInstallId(ref.read(settingsRepositoryProvider)),
        language: () => currentContentLanguage(
          ref.read(settingsRepositoryProvider),
          ref.read(deviceLanguageProvider),
        ),
        clock: ref.watch(appClockProvider),
        wordsEnabled: ref.watch(featureFlagsProvider).words,
        // Lenivo: dailySetRepositoryProvider zavisi od tohto providera.
        ensureSet: (date) => ref.read(dailySetRepositoryProvider).ensure(date),
      ),
      name: 'questRepositoryProvider',
    );

final Provider<StreakRepository> streakRepositoryProvider =
    Provider<StreakRepository>(
      (ref) => DriftStreakRepository(
        userDb: ref.watch(userDbProvider),
        clock: ref.watch(appClockProvider),
        timeZone: () => ref.read(deviceTimeZoneProvider.future),
      ),
      name: 'streakRepositoryProvider',
    );

final Provider<DailySetRepository> dailySetRepositoryProvider =
    Provider<DailySetRepository>((ref) {
      final prayer = ref.watch(prayerRepositoryProvider);
      return DriftDailySetRepository(
        userDb: ref.watch(userDbProvider),
        catalog: ref.watch(contentCatalogProvider),
        calendar: ref.watch(calendarRepositoryProvider),
        quests: ref.watch(questRepositoryProvider),
        settings: ref.watch(settingsRepositoryProvider),
        clock: ref.watch(appClockProvider),
        installId: () => ensureInstallId(ref.read(settingsRepositoryProvider)),
        language: () => currentContentLanguage(
          ref.read(settingsRepositoryProvider),
          ref.read(deviceLanguageProvider),
        ),
        timeZone: () => ref.read(deviceTimeZoneProvider.future),
        dayBoundaries: (date) async {
          final config = await prayer.config();
          return config == null
              ? null
              : PrayerTracker.dayBoundaries(config.schedule, date);
        },
        disabledIds: () => ref.read(disabledCardIdsProvider),
        wordsEnabled: ref.watch(featureFlagsProvider).words,
        logger: ref.watch(appLoggerProvider),
      );
    }, name: 'dailySetRepositoryProvider');

final Provider<CardContentRepository> cardContentRepositoryProvider =
    Provider<CardContentRepository>(
      (ref) => ContentCardRepository(
        catalog: ref.watch(contentCatalogProvider),
        quran: ref.watch(quranRepositoryProvider),
        calendar: ref.watch(calendarRepositoryProvider),
      ),
      name: 'cardContentRepositoryProvider',
    );

final Provider<CardActionsRepository> cardActionsRepositoryProvider =
    Provider<CardActionsRepository>(
      (ref) => DriftCardActionsRepository(
        userDb: ref.watch(userDbProvider),
        clock: ref.watch(appClockProvider),
      ),
      name: 'cardActionsRepositoryProvider',
    );

// ------------------------------------------------------- Dnes a denna sada

/// `activeSetDate` pre aktualny `localDate` (docs/02 0.1). Feed si ho
/// precita raz pri vstupe (`ref.read(activeSetDateProvider.future)`) a pocas
/// session ho nemeni.
final FutureProvider<LocalDate> activeSetDateProvider =
    FutureProvider<LocalDate>(
      (ref) => ref
          .watch(dailySetRepositoryProvider)
          .activeSetDate(ref.watch(localDateProvider)),
      name: 'activeSetDateProvider',
    );

/// Denna sada dna (vygeneruje ju pri prvom citani) a jej zmeny.
final StreamProviderFamily<DailySetState, LocalDate> dailySetProvider =
    StreamProvider.family<DailySetState, LocalDate>((ref, date) async* {
      final repo = ref.watch(dailySetRepositoryProvider);
      yield await repo.ensure(date);
      await for (final s in repo.watch(date)) {
        if (s != null) yield s;
      }
    }, name: 'dailySetProvider');

/// Questy dna (vyber pri prvom citani) s progresom.
final StreamProviderFamily<List<QuestView>, LocalDate> questsProvider =
    StreamProvider.family<List<QuestView>, LocalDate>(
      (ref, date) => ref.watch(questRepositoryProvider).watch(date),
      name: 'questsProvider',
    );

/// Streak pre dnesok (`localDate`).
final StreamProvider<StreakSummary> streakProvider =
    StreamProvider<StreakSummary>(
      (ref) => ref
          .watch(streakRepositoryProvider)
          .watch(ref.watch(localDateProvider)),
      name: 'streakProvider',
    );

/// `day_log` gregorianskeho mesiaca (Moja cesta A8.1), kluc `(rok, mesiac)`.
final StreamProviderFamily<List<DayLogEntry>, (int, int)> dayLogProvider =
    StreamProvider.family<List<DayLogEntry>, (int, int)>((ref, ym) {
      final first = LocalDate(ym.$1, ym.$2, 1);
      final last =
          (ym.$2 == 12
                  ? LocalDate(ym.$1 + 1, 1, 1)
                  : LocalDate(ym.$1, ym.$2 + 1, 1))
              .addDays(-1);
      return ref.watch(streakRepositoryProvider).watchDayLog(first, last);
    }, name: 'dayLogProvider');

// --------------------------------------------------------------- kalendar

final FutureProviderFamily<HijriDate, LocalDate> hijriDateProvider =
    FutureProvider.family<HijriDate, LocalDate>((ref, date) {
      ref.watch(settingProvider(SettingsKeys.hijriOffset));
      return ref.watch(calendarRepositoryProvider).hijriDate(date);
    }, name: 'hijriDateProvider');

final FutureProviderFamily<EventResolution, LocalDate> eventResolutionProvider =
    FutureProvider.family<EventResolution, LocalDate>((ref, date) {
      ref.watch(settingProvider(SettingsKeys.hijriOffset));
      return ref.watch(calendarRepositoryProvider).resolve(date);
    }, name: 'eventResolutionProvider');

final FutureProviderFamily<List<ActiveEvent>, LocalDate> activeEventsProvider =
    FutureProvider.family<List<ActiveEvent>, LocalDate>(
      (ref, date) async =>
          (await ref.watch(eventResolutionProvider(date).future)).active,
      name: 'activeEventsProvider',
    );

/// Hijri mesiac (A9), kluc `(rok, mesiac)`.
final FutureProviderFamily<CalendarMonth, (int, int)> hijriMonthProvider =
    FutureProvider.family<CalendarMonth, (int, int)>((ref, ym) {
      ref.watch(settingProvider(SettingsKeys.hijriOffset));
      return ref.watch(calendarRepositoryProvider).month(ym.$1, ym.$2);
    }, name: 'hijriMonthProvider');

// --------------------------------------------------------------- modlitby

final StreamProvider<PrayerConfig?> prayerConfigProvider =
    StreamProvider<PrayerConfig?>(
      (ref) => ref.watch(prayerRepositoryProvider).watchConfig(),
      name: 'prayerConfigProvider',
    );

/// Casy dna; null = poloha nie je nastavena ("Set your location").
final FutureProviderFamily<PrayerDay?, LocalDate> prayerScheduleProvider =
    FutureProvider.family<PrayerDay?, LocalDate>(
      (ref, date) async =>
          (await ref.watch(prayerConfigProvider.future))?.schedule.day(date),
      name: 'prayerScheduleProvider',
    );

/// Dalsia modlitba (odpocet sa prepocita kazdu minutu); null bez polohy.
final FutureProvider<PrayerMoment?> nextPrayerProvider =
    FutureProvider<PrayerMoment?>((ref) async {
      final now = await ref.watch(minuteTickProvider.future);
      final config = await ref.watch(prayerConfigProvider.future);
      return config?.schedule.next(now);
    }, name: 'nextPrayerProvider');

/// Den, ktory ukazuje tracker (po polnoci do fajr vcerajsok, docs/02 E2).
final FutureProvider<LocalDate> prayerTrackerDateProvider =
    FutureProvider<LocalDate>((ref) async {
      final now = await ref.watch(minuteTickProvider.future);
      final config = await ref.watch(prayerConfigProvider.future);
      return PrayerTracker.trackerDate(config?.schedule, now);
    }, name: 'prayerTrackerDateProvider');

final StreamProviderFamily<Map<Prayer, PrayerStatus>, LocalDate>
prayerLogProvider = StreamProvider.family<Map<Prayer, PrayerStatus>, LocalDate>(
  (ref, date) => ref.watch(prayerRepositoryProvider).watchLog(date),
  name: 'prayerLogProvider',
);

// ------------------------------------------------------------------ Koran

final FutureProvider<List<SurahInfo>> surahsProvider =
    FutureProvider<List<SurahInfo>>((ref) async {
      final lang = await ref.watch(contentLanguageProvider.future);
      return await ref.watch(quranRepositoryProvider).surahs(lang);
    }, name: 'surahsProvider');

final FutureProviderFamily<List<AyahView>, int> surahAyahsProvider =
    FutureProvider.family<List<AyahView>, int>((ref, surah) async {
      final lang = await ref.watch(contentLanguageProvider.future);
      ref.watch(settingProvider(SettingsKeys.translation(lang)));
      return await ref
          .watch(quranRepositoryProvider)
          .ayahsOfSurah(surah, lang: lang);
    }, name: 'surahAyahsProvider');

/// Posledny precitany vers (khatm); null = pred 1:1.
final StreamProvider<AyahId?> readingPositionProvider = StreamProvider<AyahId?>(
  (ref) => ref.watch(quranRepositoryProvider).watchReadingPosition(),
  name: 'readingPositionProvider',
);

/// Precitane versy podla sury (progres v zozname sur).
final StreamProvider<Map<int, int>> readCountsProvider =
    StreamProvider<Map<int, int>>(
      (ref) => ref.watch(quranRepositoryProvider).watchReadCounts(),
      name: 'readCountsProvider',
    );

// ------------------------------------------------------------------ karty

/// Obsah karty v jazyku obsahu (null = chyba v content.db). Zmena
/// zvoleneho prekladu (`translation.{lang}`, F-07) kartu nacita znova.
final FutureProviderFamily<CardContent?, CardId> cardContentProvider =
    FutureProvider.family<CardContent?, CardId>((ref, id) async {
      final lang = await ref.watch(contentLanguageProvider.future);
      ref.watch(
        settingProvider(SettingsKeys.translation(lang)).select((v) => v.value),
      );
      return await ref
          .watch(cardContentRepositoryProvider)
          .load(id, lang: lang);
    }, name: 'cardContentProvider');

final StreamProviderFamily<bool, CardId> isSavedProvider =
    StreamProvider.family<bool, CardId>(
      (ref, id) => ref.watch(cardActionsRepositoryProvider).watchIsSaved(id),
      name: 'isSavedProvider',
    );
