@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/flags/feature_flags.dart';
import 'package:sakina/data/blocker/blocker_gateway.dart';
import 'package:sakina/data/blocker/fake_blocker_gateway.dart';
import 'package:sakina/features/onboarding/onboarding_steps.dart';
import 'package:sakina/ui/theme/sakina_theme.dart';

import '../../fakes/fake_repositories.dart';
import '../../helpers/golden/golden.dart';
import 'onboarding_test_helpers.dart';

/// Goldeny krokov onboardingu lite (PLAN_VYVOJA 4.2 bod 3): EN, AR, UR,
/// BN x svetla/tmava x textScale 1.0/2.0, ID a TR smoke.
///
///   flutter test --update-goldens test/features/onboarding/onboarding_golden_test.dart
void main() {
  ThemeData theme(Brightness b) =>
      b == Brightness.dark ? SakinaTheme.dark() : SakinaTheme.light();

  for (final step in const OnboardingFlow(gate: false).steps) {
    goldenAllLocales(
      'onboarding ${step.key}',
      fileName: 'onboarding_${step.key}',
      theme: theme,
      builder: (context) => SizedBox(
        height: 640,
        child: OnboardingHarness(
          repos: FakeRepositories(
            prayer: FakePrayerRepository(location: bratislava),
          ),
        ).step(step),
      ),
    );
  }

  // Kroky brany O5 a O6 (len FEATURE_GATE, B-03).
  for (final step in [OnboardingStep.gateApps, OnboardingStep.permissions]) {
    goldenAllLocales(
      'onboarding ${step.key}',
      fileName: 'onboarding_${step.key}',
      theme: theme,
      builder: (context) => SizedBox(
        height: 640,
        child: OnboardingHarness(
          flags: const FeatureFlags(gate: true),
          blocker: FakeBlockerGateway(
            manufacturer: 'xiaomi',
            permissionsState: const BlockerPermissions(
              usageAccess: true,
              overlay: false,
              notifications: true,
              exactAlarm: true,
              batteryOptimized: true,
            ),
            apps: const [
              LaunchableApp(ref: 'com.instagram.android', label: 'Instagram'),
              LaunchableApp(ref: 'com.example.notes', label: 'Notes'),
            ],
          ),
        ).step(step),
      ),
    );
  }
}
