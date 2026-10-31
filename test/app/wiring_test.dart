import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/app/background.dart';
import 'package:sakina/app/content_wiring.dart';
import 'package:sakina/app/gate_wiring.dart';
import 'package:sakina/app/location_wiring.dart';
import 'package:sakina/app/notification_wiring.dart';
import 'package:sakina/core/flags/feature_flags.dart';
import 'package:sakina/core/result.dart';
import 'package:sakina/data/content/hadith_extra_pack_service.dart';
import 'package:sakina/data/content/sem_ver.dart';
import 'package:sakina/data/db/hadith_extra_repository.dart' as db;
import 'package:sakina/data/notifications/notifications.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/ramadan/ramadan.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/domain/streak/streak.dart';
import 'package:sakina/features/cards/hadith_explanations_pack.dart';
import 'package:sakina/features/onboarding/onboarding_platform.dart';
import 'package:sakina/features/prayer/prayer_providers.dart';
import 'package:sakina/features/ramadan/ramadan_providers.dart';

import '../data/notifications/fake_notification_platform.dart';
import '../fakes/fake_repositories.dart';
import '../fakes/in_memory_settings_repository.dart';

class _FakeExtra implements db.HadithExtraRepository {
  _FakeExtra(this.result);

  final db.HadithExplanation? result;

  @override
  Future<db.HadithExplanation?> explanationFor(
    int hadithId,
    String lang,
  ) async => result;
}

/// Len cast [HadithExtraPackService], ktoru pouziva adapter karty.
class _FakePackService implements HadithExtraPackService {
  _FakePackService(this._status);

  HadithExtraPackStatus _status;
  final _changes = StreamController<HadithExtraPackStatus>.broadcast();
  int downloads = 0;

  void emit(HadithExtraPackStatus s) {
    _status = s;
    _changes.add(s);
  }

  @override
  Stream<HadithExtraPackStatus> get changes => _changes.stream;

  @override
  HadithExtraPackStatus? get current => _status;

  @override
  Future<HadithExtraPackStatus> status() async => _status;

  @override
  Future<Result<void>> download() async {
    downloads++;
    emit(const HadithExtraDownloading(receivedBytes: 1, totalBytes: 10));
    emit(const HadithExtraDownloading(receivedBytes: 5, totalBytes: 10));
    await Future<void>.delayed(Duration.zero);
    emit(const HadithExtraFailed(Offline()));
    return const Err(Offline());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocation implements DeviceLocation {
  _FakeLocation(this.result);

  final LocationResult result;

  @override
  Future<LocationResult> locateOnce() async => result;
}

ProviderContainer _container({
  FakeNotificationPlatform? platform,
  SettingsRepository? settings,
  StreakRepository? streak,
  bool ramadan = false,
}) {
  final c = ProviderContainer(
    overrides: [
      featureFlagsProvider.overrideWithValue(
        FeatureFlags(ramadanLight: ramadan),
      ),
      notificationPlatformProvider.overrideWithValue(
        platform ?? FakeNotificationPlatform(),
      ),
      settingsRepositoryProvider.overrideWithValue(
        settings ?? InMemorySettingsRepository(),
      ),
      streakRepositoryProvider.overrideWithValue(
        streak ?? FakeStreakRepository(),
      ),
      ...notificationOverrides(),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

Future<InMemorySettingsRepository> _onboarded() async {
  final s = InMemorySettingsRepository();
  await s.set(SettingsKeys.onboardingCompleted, true);
  return s;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('content', () {
    test('disabled ids keep only valid card ids', () {
      expect(disabledCardIds({'ayah:2255', 'nonsense', ''}), {
        CardId.parse('ayah:2255'),
      });
    });

    test('app version from build name, fallback to define', () {
      expect(appVersionOf('1.2.3'), SemVer.parse('1.2.3'));
      expect(appVersionOf('garbage'), SemVer.parse('0.1.0'));
      expect(appVersionOf(null), SemVer.parse('0.1.0'));
    });

    test('hadith_extra.db lives next to content.db', () {
      expect(
        hadithExtraFile(Directory('/support')).path,
        '/support/content/hadith_extra.db',
      );
    });

    test('hadith extra adapter maps hints and missing pack', () async {
      const e = db.HadithExplanation(
        hadithId: 7,
        lang: 'en',
        explanation: 'x',
        hints: ['a', 'b'],
        sourceId: 's',
      );
      expect(
        await FileHadithExtraAdapter(_FakeExtra(null)).explanation(7, 'en'),
        isNull,
      );
      final mapped = await FileHadithExtraAdapter(_FakeExtra(e))
          .explanation(7, 'en');
      expect(mapped!.hints, 'a\nb');
      expect(mapped.explanation, 'x');
      final noHints = await FileHadithExtraAdapter(
        _FakeExtra(
          const db.HadithExplanation(
            hadithId: 7,
            lang: 'en',
            explanation: null,
            hints: [],
            sourceId: 's',
          ),
        ),
      ).explanation(7, 'en');
      expect(noHints!.hints, isNull);
    });

    test('pack status maps to hadith card states', () {
      expect(
        explanationsStatusOf(const HadithExtraUnavailable()),
        HadithExplanationsPackStatus.notAvailable,
      );
      expect(
        explanationsStatusOf(const HadithExtraNotDownloaded()),
        HadithExplanationsPackStatus.notDownloaded,
      );
      expect(
        explanationsStatusOf(const HadithExtraStale()),
        HadithExplanationsPackStatus.notDownloaded,
      );
      expect(
        explanationsStatusOf(const HadithExtraDownloading()),
        HadithExplanationsPackStatus.downloading,
      );
      expect(
        explanationsStatusOf(const HadithExtraReady(sizeBytes: 1)),
        HadithExplanationsPackStatus.ready,
      );
      expect(
        explanationsStatusOf(const HadithExtraFailed(Offline())),
        HadithExplanationsPackStatus.failed,
      );
    });

    test('explanations pack watches status and downloads to the end', () async {
      final service = _FakePackService(const HadithExtraNotDownloaded());
      final pack = ServiceHadithExplanationsPack(service);
      final seen = <HadithExplanationsPackStatus>[];
      final sub = pack.watchStatus().listen(seen.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();
      expect(seen, [HadithExplanationsPackStatus.notDownloaded]);

      await pack.download();
      await pumpEventQueue();
      expect(service.downloads, 1);
      expect(seen, [
        HadithExplanationsPackStatus.notDownloaded,
        HadithExplanationsPackStatus.downloading,
        HadithExplanationsPackStatus.failed,
      ]);
    });

    test('content overrides provide the explanations pack', () {
      final c = ProviderContainer(
        overrides: contentOverrides(supportDir: Directory.systemTemp),
      );
      addTearDown(c.dispose);
      expect(
        c.read(hadithExplanationsPackProvider),
        isA<ServiceHadithExplanationsPack>(),
      );
    });

    test('missing pack file gives no explanation', () async {
      final repo = FileHadithExtraAdapter(
        db.FileHadithExtraRepository(
          hadithExtraFile(Directory.systemTemp.createTempSync('he')),
        ),
      );
      expect(await repo.explanation(1, 'en'), isNull);
    });
  });

  group('location', () {
    test('found, denied and failed', () async {
      expect(
        await DeviceLocationLocator(
          _FakeLocation(const LocationFound(48.1, 17.1)),
        ).locate(),
        (lat: 48.1, lng: 17.1),
      );
      expect(
        await DeviceLocationLocator(_FakeLocation(const LocationDenied()))
            .locate(),
        isNull,
      );
      expect(
        await DeviceLocationLocator(_FakeLocation(const LocationFailed()))
            .locate(),
        isNull,
      );
    });

    test('override uses onboarding device location', () {
      final c = ProviderContainer(
        overrides: [
          deviceLocationProvider.overrideWithValue(
            _FakeLocation(const LocationDenied()),
          ),
          ...locationOverrides(),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(deviceLocatorProvider), isA<DeviceLocationLocator>());
    });
  });

  group('notifications', () {
    test('tap target maps payload deep link, default Today', () {
      expect(notificationTarget('{"link":"mursa://prayer?p=fajr"}'), '/prayer');
      expect(notificationTarget('{"link":"mursa://today"}'), '/today');
      expect(notificationTarget(null), '/today');
      expect(notificationTarget('not json'), '/today');
    });

    test('confirmed zone is stored in settings', () async {
      final settings = InMemorySettingsRepository();
      final store = SettingsTimeZoneStore(settings);
      expect(await store.confirmedZone(), isNull);
      await store.setConfirmedZone('Europe/Bratislava');
      expect(
        await settings.get(SettingsKeys.notifConfirmedTz),
        'Europe/Bratislava',
      );
      expect(await store.confirmedZone(), 'Europe/Bratislava');
    });

    test('excused days come from day_log', () async {
      final today = LocalDate(2026, 10, 29);
      final streak = FakeStreakRepository(
        days: [
          DayLogEntry(date: today, status: DayStatus.done),
          DayLogEntry(date: today.addDays(1), status: DayStatus.excused),
          DayLogEntry(date: today.addDays(30), status: DayStatus.excused),
        ],
      );
      expect(await excusedDaysAhead(streak, today), {today.addDays(1)});
    });

    test('reminder health reflects platform state', () async {
      final platform = FakeNotificationPlatform()
        ..enabled = false
        ..exactAllowed = false;
      final c = _container(platform: platform);
      final health = await c.read(prayerReminderHealthProvider.future);
      expect(health.notificationsEnabled, isFalse);
      expect(health.exactAlarms, isFalse);
    });

    test('feature hooks reschedule through the service', () async {
      final platform = FakeNotificationPlatform();
      final c = _container(platform: platform, settings: await _onboarded());
      await c.read(prayerSettingsChangedProvider)();
      await c.read(onboardingRescheduleProvider)();
      // Morning reminder is on by default, so the plan is not empty.
      expect(platform.scheduled, isNotEmpty);
      expect(
        c.read(onboardingNotificationsProvider),
        isA<PlatformOnboardingNotifications>(),
      );
    });

    test(
      'before onboarding nothing is planned and pending is cancelled',
      () async {
        final settings = await _onboarded();
        final platform = FakeNotificationPlatform();
        final c = _container(platform: platform, settings: settings);
        await c.read(prayerSettingsChangedProvider)();
        expect(platform.scheduled, isNotEmpty);

        // Ako po "Delete all my data": nastavenia su prazdne.
        await settings.set(SettingsKeys.onboardingCompleted, false);
        await c.read(prayerSettingsChangedProvider)();
        expect(platform.scheduled, isEmpty);
        expect(
          await runBackgroundTask(
            NotificationBackground.taskName,
            null,
            createContainer: () => ProviderContainer(parent: c),
          ),
          isTrue,
        );
        expect(platform.scheduled, isEmpty);
      },
    );

    test('cancelAll removes every pending notification', () async {
      final platform = FakeNotificationPlatform();
      final c = _container(platform: platform, settings: await _onboarded());
      final scheduler = c.read(notificationSchedulerProvider);
      await scheduler.reschedule();
      expect(platform.scheduled, isNotEmpty);
      await scheduler.cancelAll();
      expect(platform.scheduled, isEmpty);
    });

    test('ramadan season change reschedules', () async {
      final platform = FakeNotificationPlatform();
      final c = _container(platform: platform, settings: await _onboarded());
      await c.read(ramadanSeasonChangedProvider)();
      expect(platform.scheduled, isNotEmpty);
    });

    test(
      'fasting days come from the confirmed season with ramadanLight',
      () async {
        final settings = await _onboarded();
        final start = LocalDate(2027, 2, 8);
        await settings.set(
          SettingsKeys.ramadanSeason,
          RamadanConfirmation(
            hijriYear: 1448,
            startDate: start,
            source: SeasonSource.userConfirmed,
          ),
        );
        final days = await ramadanFastingDaysAhead(settings, start, days: 3);
        expect(days, {start, start.addDays(1), start.addDays(2)});
        final c = _container(settings: settings, ramadan: true);
        expect(c.read(notificationServiceProvider), isA<NotificationService>());
      },
    );

    test('background task reschedules, unknown task succeeds', () async {
      final platform = FakeNotificationPlatform();
      final c = _container(platform: platform, settings: await _onboarded());
      // Uloha svoj kontajner zlikviduje; preto potomok testovacieho.
      expect(
        await runBackgroundTask(
          NotificationBackground.taskName,
          null,
          createContainer: () => ProviderContainer(parent: c),
        ),
        isTrue,
      );
      expect(platform.scheduled, isNotEmpty);
      expect(
        await runBackgroundTask(
          'other',
          null,
          createContainer: () => ProviderContainer(parent: c),
        ),
        isTrue,
      );
    });
  });

  group('gate', () {
    test('resume refresh only with the gate flag', () {
      final lite = ProviderContainer();
      addTearDown(lite.dispose);
      expect(startGateSync(lite), isNull);

      final full = ProviderContainer(
        overrides: [
          featureFlagsProvider.overrideWithValue(FeatureFlags.all),
          // startGateSync hned overi branu (I-03): bez user.db.
          settingsRepositoryProvider.overrideWithValue(
            InMemorySettingsRepository(),
          ),
        ],
      );
      addTearDown(full.dispose);
      final listener = startGateSync(full);
      expect(listener, isNotNull);
      listener!.dispose();
    });

    test('refresh after gate re-reads the daily set', () async {
      var builds = 0;
      final date = LocalDate(2026, 10, 29);
      final c = ProviderContainer(
        overrides: [
          dailySetProvider.overrideWith((ref, d) {
            builds++;
            return const Stream.empty();
          }),
          questsProvider.overrideWith((ref, d) => const Stream.empty()),
          streakProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );
      addTearDown(c.dispose);
      final sub = c.listen(dailySetProvider(date), (_, _) {});
      addTearDown(sub.close);
      expect(builds, 1);
      refreshAfterGate(c);
      c.read(dailySetProvider(date));
      expect(builds, 2);
    });
  });
}
