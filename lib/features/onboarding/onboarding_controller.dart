import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/core/logging/logger_provider.dart';
import 'package:prosoche/data/repositories/providers.dart';
import 'package:prosoche/data/repositories/settings/settings_providers.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/onboarding/onboarding_guard.dart';
import 'package:prosoche/features/onboarding/onboarding_platform.dart';
import 'package:prosoche/features/onboarding/onboarding_steps.dart';

/// Anonymny event onboardingu (bez obsahu, polohy a mesta).
@immutable
final class OnboardingEvent {
  const OnboardingEvent(this.name, [this.props = const {}]);

  final String name;
  final Map<String, Object> props;

  @override
  String toString() => 'OnboardingEvent($name, $props)';
}

/// Prijemca eventov po suhlase v O7 (PostHog, D-04). Default zahodi.
final Provider<void Function(List<OnboardingEvent> events)>
onboardingAnalyticsSinkProvider =
    Provider<void Function(List<OnboardingEvent> events)>(
      (ref) => (_) {},
      name: 'onboardingAnalyticsSinkProvider',
    );

/// Kroky, ulozenie `onboarding.step` a dokoncenie (docs/02 A1).
///
/// Analytika sa bufferuje v pamati a odosle sa az po suhlase v O7, inak sa
/// zahodi.
class OnboardingController {
  OnboardingController(this._ref, this.flow);

  final Ref _ref;
  final OnboardingFlow flow;
  final _buffer = <OnboardingEvent>[];

  /// Vysledok ziadosti o notifikacie v O4 (`onboarding_completed`).
  bool notificationsGranted = false;

  SettingsRepository get _settings => _ref.read(settingsRepositoryProvider);
  AppLogger get _logger => _ref.read(appLoggerProvider);

  /// Eventy cakajuce na suhlas (len na kontrolu v testoch).
  List<OnboardingEvent> get buffered => List.unmodifiable(_buffer);

  void track(String name, [Map<String, Object> props = const {}]) =>
      _buffer.add(OnboardingEvent(name, props));

  /// Ukonci krok [step] ("Continue" alebo "Skip"): zapise analytiku a dalsi
  /// krok do `onboarding.step`. Vrati dalsi krok, null za poslednym.
  Future<OnboardingStep?> advance(
    OnboardingStep step, {
    bool skipped = false,
  }) async {
    track('onboarding_step', {'step': step.key, 'skipped': skipped});
    final next = flow.next(step);
    if (next != null) {
      await _settings.set(SettingsKeys.onboardingStep, next.key);
    }
    return next;
  }

  /// Dokoncenie po O7: suhlasy, `onboarding.completed`, prva denna sada,
  /// preplanovanie notifikacii a odoslanie alebo zahodenie analytiky.
  Future<void> finish({
    required bool ageConfirmed,
    required bool analytics,
    required bool crashReports,
  }) async {
    final settings = _settings;
    final share = ageConfirmed && analytics;
    await settings.set(SettingsKeys.ageConfirmed16, ageConfirmed);
    await settings.set(SettingsKeys.analyticsOptIn, share);
    await settings.set(SettingsKeys.crashReports, ageConfirmed && crashReports);
    await advance(OnboardingStep.privacy);
    await settings.set(SettingsKeys.onboardingCompleted, true);
    _ref.read(onboardingGuardProvider).markCompleted();

    track('onboarding_completed', {
      'blocker_enabled':
          flow.gate && await settings.get(SettingsKeys.blockerEnabled),
      'notif_granted': notificationsGranted,
    });
    final events = List.of(_buffer);
    _buffer.clear();
    if (share) _ref.read(onboardingAnalyticsSinkProvider)(events);

    await _quietly('daily set', () async {
      final date = await _ref.read(activeSetDateProvider.future);
      await _ref.read(dailySetRepositoryProvider).ensure(date);
    });
    await _quietly('reschedule', _ref.read(onboardingRescheduleProvider));
  }

  Future<void> _quietly(String what, Future<void> Function() task) async {
    try {
      await task();
    } on Object catch (e, st) {
      // Today si sadu vygeneruje sam, notifikacie preplanuje dalsi start.
      _logger.error('onboarding', '$what failed', error: e, stack: st);
    }
  }
}

final Provider<OnboardingController> onboardingControllerProvider =
    Provider<OnboardingController>(
      (ref) => OnboardingController(
        ref,
        OnboardingFlow(gate: ref.watch(featureFlagsProvider).gate),
      ),
      name: 'onboardingControllerProvider',
    );
