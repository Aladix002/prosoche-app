import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/onboarding/onboarding_guard.dart';
import 'package:prosoche/features/onboarding/onboarding_steps.dart';

import '../../fakes/in_memory_settings_repository.dart';

class _BrokenSettings extends InMemorySettingsRepository {
  @override
  Future<T> get<T>(SettingKey<T> key) => Future.error(StateError('db'));
}

void main() {
  const lite = OnboardingFlow(gate: false);
  const pending = OnboardingStatus(completed: false, step: 'location');
  const done = OnboardingStatus(completed: true);

  group('onboardingRedirect (docs/02 C3)', () {
    test('unfinished onboarding goes to the stored step', () {
      expect(
        onboardingRedirect('/today', pending, lite),
        '/onboarding/location',
      );
      expect(
        onboardingRedirect('/settings/privacy', pending, lite),
        '/onboarding/location',
      );
      expect(
        onboardingRedirect(
          '/today',
          const OnboardingStatus(completed: false),
          lite,
        ),
        '/onboarding/language',
      );
    });

    test('onboarding routes and the gate stay', () {
      expect(onboardingRedirect('/onboarding/niyyah', pending, lite), isNull);
      expect(onboardingRedirect('/gate', pending, lite), isNull);
    });

    test('finished onboarding leaves onboarding for Today', () {
      expect(onboardingRedirect('/onboarding/privacy', done, lite), '/today');
      expect(onboardingRedirect('/onboarding', done, lite), '/today');
      expect(onboardingRedirect('/quran', done, lite), isNull);
    });
  });

  group('OnboardingGuard', () {
    test(
      'first redirect waits for settings, then answers synchronously',
      () async {
        final settings = InMemorySettingsRepository();
        await settings.set(SettingsKeys.onboardingStep, 'notifications');
        final guard = OnboardingGuard(settings: settings, flow: lite);
        addTearDown(guard.dispose);

        final first = guard.redirect(Uri.parse('/today'), null);
        expect(first, isA<Future<String?>>());
        expect(await first, '/onboarding/notifications');
        // Upstream (deep link) sa prepise guardom.
        expect(
          guard.redirect(Uri.parse('prosoche://prayer'), '/prayer'),
          '/onboarding/notifications',
        );

        await settings.set(SettingsKeys.onboardingStep, 'privacy');
        await pumpEventQueue();
        expect(
          guard.redirect(Uri.parse('/today'), null),
          '/onboarding/privacy',
        );
      },
    );

    test('completion notifies the router once', () async {
      final settings = InMemorySettingsRepository();
      final guard = OnboardingGuard(settings: settings, flow: lite);
      addTearDown(guard.dispose);
      await guard.redirect(Uri.parse('/today'), null);
      var notified = 0;
      guard.addListener(() => notified++);

      await settings.set(SettingsKeys.onboardingCompleted, true);
      guard.markCompleted();
      expect(notified, 1);
      expect(guard.status!.completed, isTrue);
      expect(guard.redirect(Uri.parse('/today'), null), isNull);
      expect(guard.redirect(Uri.parse('/x'), '/today'), '/today');
    });

    test('unreadable settings do not redirect', () async {
      final guard = OnboardingGuard(settings: _BrokenSettings(), flow: lite);
      addTearDown(guard.dispose);
      expect(await guard.redirect(Uri.parse('/today'), null), isNull);
      expect(guard.status, isNull);
    });
  });
}
