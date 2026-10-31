@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/data/blocker/blocker_gateway.dart';
import 'package:prosoche/data/blocker/fake_blocker_gateway.dart';
import 'package:prosoche/features/onboarding/onboarding_steps.dart';
import 'package:prosoche/ui/theme/prosoche_theme.dart';

import '../../helpers/golden/golden.dart';
import 'onboarding_test_helpers.dart';

/// Goldeny krokov onboardingu lite (PLAN_VYVOJA 4.2 bod 3): EN, AR, UR,
/// BN x svetla/tmava x textScale 1.0/2.0, ID a TR smoke.
///
///   flutter test --update-goldens test/features/onboarding/onboarding_golden_test.dart
void main() {
  ThemeData theme(Brightness b) =>
      b == Brightness.dark ? ProsocheTheme.dark() : ProsocheTheme.light();

  for (final step in const OnboardingFlow(gate: false).steps) {
    goldenAllLocales(
      'onboarding ${step.key}',
      fileName: 'onboarding_${step.key}',
      theme: theme,
      builder: (context) =>
          SizedBox(height: 640, child: OnboardingHarness().step(step)),
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
          flags: FeatureFlags.all,
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
