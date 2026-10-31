import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/app.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/core/router/app_router.dart';
import 'package:prosoche/data/blocker/blocked_apps_repository.dart';
import 'package:prosoche/data/blocker/blocker_gateway_provider.dart';
import 'package:prosoche/data/blocker/fake_blocked_apps_repository.dart';
import 'package:prosoche/data/blocker/fake_blocker_gateway.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/features/onboarding/onboarding_controller.dart';
import 'package:prosoche/features/onboarding/onboarding_guard.dart';
import 'package:prosoche/features/onboarding/onboarding_platform.dart';
import 'package:prosoche/features/onboarding/onboarding_screen.dart';
import 'package:prosoche/features/onboarding/onboarding_steps.dart';

import '../../fakes/fake_repositories.dart';

/// Datum a cas testov (stvrtok 29. 10. 2026 9:00).
final testNow = DateTime(2026, 10, 29, 9);
final testToday = LocalDate(2026, 10, 29);

class FakeOnboardingNotifications implements OnboardingNotifications {
  FakeOnboardingNotifications({
    this.enabled = false,
    this.exact = false,
    this.grant = true,
    this.grantExact = true,
  });

  bool enabled;
  bool exact;

  /// Vysledok systemoveho dialogu.
  bool grant;
  bool grantExact;
  int requests = 0;
  int exactRequests = 0;
  int settingsOpened = 0;

  @override
  Future<NotificationAccess> access() async =>
      NotificationAccess(enabled: enabled, exact: exact);

  @override
  Future<bool> requestPermission() async {
    requests++;
    enabled = grant;
    return grant;
  }

  @override
  Future<void> requestExactAlarms() async {
    exactRequests++;
    exact = grantExact;
  }

  @override
  Future<void> openAppSettings() async => settingsOpened++;
}

/// Prostredie onboardingu: fakes repozitarov a platformy.
class OnboardingHarness {
  OnboardingHarness({
    FakeRepositories? repos,
    FakeOnboardingNotifications? notifications,
    FakeBlockerGateway? blocker,
    this.flags = FeatureFlags.none,
    this.deviceLanguage = 'en',
  }) : repos = repos ?? FakeRepositories(),
       notifications = notifications ?? FakeOnboardingNotifications(),
       blocker = blocker ?? FakeBlockerGateway() {
    blockedApps = FakeBlockedAppsRepository(gateway: this.blocker);
  }

  final FakeRepositories repos;
  final FakeOnboardingNotifications notifications;

  /// Brana (O5, O6): nativ a `blocked_app`.
  final FakeBlockerGateway blocker;
  late final FakeBlockedAppsRepository blockedApps;
  final FeatureFlags flags;
  final String deviceLanguage;
  final sent = <OnboardingEvent>[];
  int reschedules = 0;

  List<Override> get overrides => [
    ...repos.overrides(now: testNow, deviceLanguage: deviceLanguage),
    featureFlagsProvider.overrideWithValue(flags),
    onboardingNotificationsProvider.overrideWithValue(notifications),
    onboardingAnalyticsSinkProvider.overrideWithValue(sent.addAll),
    onboardingRescheduleProvider.overrideWithValue(() async => reschedules++),
    blockerGatewayProvider.overrideWithValue(blocker),
    blockedAppsRepositoryProvider.overrideWithValue(blockedApps),
  ];

  /// Cela appka s onboarding guardom na [location].
  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    String location = '/today',
  }) async {
    late GoRouter router;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...overrides,
          appRouterProvider.overrideWith((ref) {
            router = buildAppRouter(
              initialLocation: location,
              flags: flags,
              onboarding: ref.watch(onboardingGuardProvider),
            );
            ref.onDispose(router.dispose);
            return router;
          }),
        ],
        retry: (_, _) => null,
        child: const ProsocheApp(),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  /// Samostatny krok bez routera (goldeny, stavy krokov).
  Widget step(OnboardingStep step) => ProviderScope(
    overrides: overrides,
    retry: (_, _) => null,
    child: OnboardingScreen(
      step: step,
      flow: OnboardingFlow(gate: flags.gate),
    ),
  );
}

Finder textOf(String text) => find.text(text);

/// Hlavne tlacidlo kroku (Continue / Finish).
Future<void> tapPrimary(WidgetTester tester, String label) async {
  final button = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

bool isPrimaryEnabled(WidgetTester tester, String label) =>
    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, label))
        .onPressed !=
    null;

/// Tap na prvok v scrollovanom obsahu kroku.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
