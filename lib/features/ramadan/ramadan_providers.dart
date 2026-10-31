import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/calendar/calendar.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/ramadan/ramadan.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/ramadan/drift_fast_log_repository.dart';
import 'package:timezone/timezone.dart' as tz;

/// Zaznamy postu. V testoch prepisat fake implementaciou.
final Provider<FastLogRepository> fastLogRepositoryProvider =
    Provider<FastLogRepository>(
      (ref) => DriftFastLogRepository(ref.watch(userDbProvider)),
      name: 'fastLogRepositoryProvider',
    );

/// Ulozene potvrdenie sezony (`ramadan.season`).
final StreamProvider<RamadanConfirmation?> ramadanConfirmationProvider =
    StreamProvider<RamadanConfirmation?>(
      (ref) => ref
          .watch(settingsRepositoryProvider)
          .watch(RamadanConfirmation.settingKey),
      name: 'ramadanConfirmationProvider',
    );

/// Stav Ramadanu teraz (prepocet kazdu minutu, pri zmene polohy, offsetu
/// alebo potvrdenia).
final FutureProvider<RamadanState> ramadanStateProvider =
    FutureProvider<RamadanState>((ref) async {
      final now = await ref.watch(minuteTickProvider.future);
      ref.watch(settingProvider(SettingsKeys.hijriOffset));
      final calendar = await ref.watch(calendarRepositoryProvider).calendar();
      final config = await ref.watch(prayerConfigProvider.future);
      final stored = await ref.watch(ramadanConfirmationProvider.future);
      final RamadanDayTimes times;
      if (config != null) {
        times = RamadanDayTimes.forSchedule(config.schedule);
      } else {
        final zone = tryTimeZone(
          await ref.watch(deviceTimeZoneProvider.future),
        );
        times = RamadanDayTimes(zone: zone ?? tz.UTC);
      }
      return RamadanStateMachine(calendar: calendar)
          .resolve(now: now, times: times, stored: stored);
    }, name: 'ramadanStateProvider');

/// Zaznam postu dna.
final StreamProviderFamily<FastEntry?, LocalDate> fastEntryProvider =
    StreamProvider.family<FastEntry?, LocalDate>(
      (ref, date) => ref.watch(fastLogRepositoryProvider).watch(date),
      name: 'fastEntryProvider',
    );

/// Akcie karty Ramadanu na Dnes.
final Provider<RamadanActions> ramadanActionsProvider =
    Provider<RamadanActions>(
      (ref) => RamadanActions(
        settings: ref.watch(settingsRepositoryProvider),
        calendar: ref.watch(calendarRepositoryProvider),
        fastLog: ref.watch(fastLogRepositoryProvider),
        clock: ref.watch(appClockProvider),
        onSeasonChanged: ref.watch(ramadanSeasonChangedProvider),
      ),
      name: 'ramadanActionsProvider',
    );

/// Po zmene sezony (I-01 prepise na preplanovanie notifikacii, rovnako
/// ako `prayerSettingsChangedProvider`). Default nic.
final Provider<Future<void> Function()> ramadanSeasonChangedProvider =
    Provider<Future<void> Function()>(
      (ref) => () async {},
      name: 'ramadanSeasonChangedProvider',
    );

class RamadanActions {
  RamadanActions({
    required this.settings,
    required this.calendar,
    required this.fastLog,
    required this.clock,
    required this.onSeasonChanged,
  });

  final SettingsRepository settings;
  final CalendarRepository calendar;
  final FastLogRepository fastLog;
  final Clock clock;
  final Future<void> Function() onSeasonChanged;

  /// "Zajtra" (1), "Pozajtra" (2) alebo vypocet (null).
  Future<void> confirmStart(RamadanSeason season, int? daysAhead) async {
    final machine = RamadanStateMachine(calendar: await calendar.calendar());
    await settings.set(
      RamadanConfirmation.settingKey,
      machine.confirmStart(
        hijriYear: season.hijriYear,
        answerDay: LocalDate.fromDateTime(clock.now()),
        daysAhead: daysAhead,
      ),
    );
    await onSeasonChanged();
  }

  /// "Je zajtra Eid?": ano, nie alebo vypocet (null).
  Future<void> confirmEnd(
    RamadanSeason season, {
    required bool? eidTomorrow,
  }) async {
    final machine = RamadanStateMachine(calendar: await calendar.calendar());
    await settings.set(
      RamadanConfirmation.settingKey,
      machine.confirmEnd(season: season, eidTomorrow: eidTomorrow),
    );
    await onSeasonChanged();
  }

  Future<void> setFast(LocalDate day, FastEntry? entry) =>
      fastLog.set(day, entry);
}

/// Dni postu od [from] na [days] dni pre `NotificationService.fastingDays`
/// (I-01: `fastingDays: () => ramadanFastingDaysAhead(settings, today)`).
Future<Set<LocalDate>> ramadanFastingDaysAhead(
  SettingsRepository settings,
  LocalDate from, {
  int days = 12,
}) async => ramadanFastingDays(
  calendar: IslamicCalendar(
    offset: await settings.get(SettingsKeys.hijriOffset),
  ),
  from: from,
  days: days,
  stored: await settings.get(RamadanConfirmation.settingKey),
);
