import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/core/logging/logger_provider.dart';
import 'package:prosoche/data/repositories/cards/card_actions_repository.dart';
import 'package:prosoche/data/repositories/cards/card_content_repository.dart';
import 'package:prosoche/data/repositories/catalog/content_catalog.dart';
import 'package:prosoche/data/repositories/infra/databases.dart';
import 'package:prosoche/data/repositories/infra/time_providers.dart';
import 'package:prosoche/data/repositories/settings/drift_settings_repository.dart';
import 'package:prosoche/data/repositories/settings/settings_providers.dart';
import 'package:prosoche/data/repositories/today/daily_set_repository.dart';
import 'package:prosoche/data/repositories/today/quest_repository.dart';
import 'package:prosoche/data/repositories/today/streak_repository.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/streak/streak.dart';

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

final Provider<QuestRepository> questRepositoryProvider =
    Provider<QuestRepository>(
      (ref) => DriftQuestRepository(
        userDb: ref.watch(userDbProvider),
        catalog: ref.watch(contentCatalogProvider),
        installId: () => ensureInstallId(ref.read(settingsRepositoryProvider)),
        language: () => currentContentLanguage(
          ref.read(settingsRepositoryProvider),
          ref.read(deviceLanguageProvider),
        ),
        clock: ref.watch(appClockProvider),
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
    Provider<DailySetRepository>(
      (ref) => DriftDailySetRepository(
        userDb: ref.watch(userDbProvider),
        catalog: ref.watch(contentCatalogProvider),
        quests: ref.watch(questRepositoryProvider),
        settings: ref.watch(settingsRepositoryProvider),
        clock: ref.watch(appClockProvider),
        installId: () => ensureInstallId(ref.read(settingsRepositoryProvider)),
        timeZone: () => ref.read(deviceTimeZoneProvider.future),
        disabledIds: () => ref.read(disabledCardIdsProvider),
        logger: ref.watch(appLoggerProvider),
      ),
      name: 'dailySetRepositoryProvider',
    );

final Provider<CardContentRepository> cardContentRepositoryProvider =
    Provider<CardContentRepository>(
      (ref) =>
          ContentCardRepository(catalog: ref.watch(contentCatalogProvider)),
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

// ------------------------------------------------------------------ karty

/// Obsah karty v jazyku obsahu (null = chyba v content.db).
final FutureProviderFamily<CardContent?, CardId> cardContentProvider =
    FutureProvider.family<CardContent?, CardId>((ref, id) async {
      final lang = await ref.watch(contentLanguageProvider.future);
      return await ref
          .watch(cardContentRepositoryProvider)
          .load(id, lang: lang);
    }, name: 'cardContentProvider');

final StreamProviderFamily<bool, CardId> isSavedProvider =
    StreamProvider.family<bool, CardId>(
      (ref, id) => ref.watch(cardActionsRepositoryProvider).watchIsSaved(id),
      name: 'isSavedProvider',
    );
