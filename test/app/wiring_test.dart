import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/app/background.dart';
import 'package:prosoche/app/content_wiring.dart';
import 'package:prosoche/app/gate_wiring.dart';
import 'package:prosoche/app/notification_wiring.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/data/content/sem_ver.dart';
import 'package:prosoche/data/notifications/notifications.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/onboarding/onboarding_platform.dart';

import '../data/notifications/fake_notification_platform.dart';
import '../fakes/in_memory_settings_repository.dart';

ProviderContainer _container({
  FakeNotificationPlatform? platform,
  SettingsRepository? settings,
}) {
  final c = ProviderContainer(
    overrides: [
      featureFlagsProvider.overrideWithValue(FeatureFlags.none),
      notificationPlatformProvider.overrideWithValue(
        platform ?? FakeNotificationPlatform(),
      ),
      settingsRepositoryProvider.overrideWithValue(
        settings ?? InMemorySettingsRepository(),
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
      expect(disabledCardIds({'quote:q_0001', 'nonsense', ''}), {
        CardId.parse('quote:q_0001'),
      });
    });

    test('app version from build name, fallback to define', () {
      expect(appVersionOf('1.2.3'), SemVer.parse('1.2.3'));
      expect(appVersionOf('garbage'), SemVer.parse('0.1.0'));
      expect(appVersionOf(null), SemVer.parse('0.1.0'));
    });
  });

  group('notifications', () {
    test('tap target maps payload deep link, default Today', () {
      expect(notificationTarget('{"link":"prosoche://journey"}'), '/journey');
      expect(notificationTarget('{"link":"prosoche://today"}'), '/today');
      expect(notificationTarget(null), '/today');
      expect(notificationTarget('not json'), '/today');
    });

    test('feature hooks reschedule through the service', () async {
      final platform = FakeNotificationPlatform();
      final c = _container(platform: platform, settings: await _onboarded());
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
        await c.read(onboardingRescheduleProvider)();
        expect(platform.scheduled, isNotEmpty);

        // Ako po "Delete all my data": nastavenia su prazdne.
        await settings.set(SettingsKeys.onboardingCompleted, false);
        await c.read(onboardingRescheduleProvider)();
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
      expect(c.read(notificationServiceProvider), isA<NotificationService>());
    });

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
