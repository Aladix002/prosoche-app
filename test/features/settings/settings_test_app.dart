import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/flags/feature_flags.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/data/content/content_providers.dart';
import 'package:sakina/data/content/sem_ver.dart';
import 'package:sakina/data/db/content_db.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/features/onboarding/onboarding_platform.dart';
import 'package:sakina/features/settings/settings_providers.dart';
import 'package:sakina/features/settings/settings_routes.dart';
import 'package:sakina/ui/theme/sakina_theme.dart';

import '../../data/db/fixtures/content_fixture.dart';
import '../../fakes/fake_repositories.dart';

/// Povolenia notifikacii bez platformy.
class FakeNotificationAccess implements OnboardingNotifications {
  FakeNotificationAccess({this.enabled = true, this.exact = true});

  bool enabled;
  bool exact;
  int exactRequests = 0;
  int settingsOpened = 0;

  @override
  Future<NotificationAccess> access() async =>
      NotificationAccess(enabled: enabled, exact: exact);

  @override
  Future<void> openAppSettings() async => settingsOpened++;

  @override
  Future<bool> requestPermission() async => enabled = true;

  @override
  Future<void> requestExactAlarms() async => exactRequests++;
}

/// Zaznamenane otvorenia odkazov.
class LinkLog {
  final opened = <Uri>[];
  bool result = true;

  Future<bool> call(Uri uri) async {
    opened.add(uri);
    return result;
  }
}

/// Spolocne overrides testov F-07 (fakes D-02, content.db fixture,
/// notifikacie, odkazy, verzia).
List<Override> settingsOverrides({
  required FakeRepositories fakes,
  FeatureFlags flags = FeatureFlags.none,
  ContentDb? content,
  FakeNotificationAccess? notifications,
  LinkLog? links,
  AppLinks appLinks = const AppLinks(),
  String? build = '42',
}) => [
  ...fakes.overrides(now: DateTime(2026, 10, 29, 9)),
  featureFlagsProvider.overrideWithValue(flags),
  if (content != null) contentDbProvider.overrideWith((ref) async => content),
  onboardingNotificationsProvider.overrideWithValue(
    notifications ?? FakeNotificationAccess(),
  ),
  linkOpenerProvider.overrideWithValue((links ?? LinkLog()).call),
  appLinksProvider.overrideWithValue(appLinks),
  appVersionProvider.overrideWithValue(SemVer.parse('1.2.3')),
  appBuildNumberProvider.overrideWithValue(build),
];

/// Fixture content.db; zatvori sa po teste.
ContentDb contentFixture() {
  final db = openContentFixture();
  addTearDown(db.close);
  return db;
}

/// Router s routami nastaveni a zastupkami ostatnych cielov.
GoRouter settingsRouter(String location, {bool gate = false}) => GoRouter(
  initialLocation: location,
  routes: [
    ...settingsRoutes(gate: gate),
    GoRoute(
      path: '/onboarding/:step',
      builder: (context, state) => const Text('stub:onboarding'),
    ),
    GoRoute(
      path: '/today',
      builder: (context, state) => const Text('stub:today'),
    ),
  ],
);

/// Spusti [location] (default koren nastaveni) a vrati router.
Future<GoRouter> pumpSettings(
  WidgetTester tester, {
  required List<Override> overrides,
  String location = SettingsPaths.root,
  bool gate = false,
  Locale locale = const Locale('en'),
  bool settle = true,
  Size size = const Size(412, 2400),
}) async {
  tester.view
    ..physicalSize = size * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = settingsRouter(location, gate: gate);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      retry: (_, _) => null,
      child: MaterialApp.router(
        theme: SakinaTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return router;
}
