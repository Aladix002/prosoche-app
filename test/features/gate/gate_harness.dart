// Harness widget testov brany (B-02): GateScreen s fake repozitarmi D-02,
// FakeBlockerGateway (B-01) a FakeGateRepository.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/app.dart';
import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/blocker/blocker_gateway_provider.dart';
import 'package:prosoche/data/blocker/fake_blocker_gateway.dart';
import 'package:prosoche/data/blocker/gate_repository.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/features/gate/gate_screen.dart';
import 'package:prosoche/ui/foundation/sk_ui_strings.dart';
import 'package:prosoche/ui/theme/prosoche_theme.dart';

import '../../fakes/fake_repositories.dart';

const igRef = 'com.instagram.android';

/// Stvrtok 29. 10. 2026, 9:00.
final gateNow = DateTime(2026, 10, 29, 9);
final gateToday = LocalDate(2026, 10, 29);

/// Pamatovy [GateRepository]: appky, sessions a odomknutia v zoznamoch.
class FakeGateRepository implements GateRepository {
  FakeGateRepository({Map<String, GateTarget>? apps})
    : apps = apps ?? {igRef: instagram()};

  static GateTarget instagram({
    int cardsRequired = 3,
    int unlockMinutes = 10,
    bool enabled = true,
    String? label = 'Instagram',
  }) => GateTarget(
    id: 1,
    ref: igRef,
    label: label,
    cardsRequired: cardsRequired,
    unlockMinutes: unlockMinutes,
    enabled: enabled,
  );

  final Map<String, GateTarget> apps;

  /// Chyba pri citani appky (DB zamknuta a pod.).
  Exception? appError;

  /// Citanie appky sa nikdy nedokonci (timeout).
  bool hang = false;

  final sessions = <int, ({GateResult? result, int cardsSeen})>{};
  final unlocks = <(int?, UnlockSource, int)>[];
  final freeReading = <CardId>[];

  @override
  Future<GateTarget?> app(String ref) async {
    if (hang) return await Completer<GateTarget?>().future;
    if (appError case final e?) throw e;
    return apps[ref];
  }

  @override
  Future<int> openSession(int? appId) async {
    final id = sessions.length + 1;
    sessions[id] = (result: null, cardsSeen: 0);
    return id;
  }

  @override
  Future<void> closeSession(
    int sessionId, {
    required GateResult result,
    required int cardsSeen,
  }) async => sessions[sessionId] = (result: result, cardsSeen: cardsSeen);

  @override
  Future<void> logUnlock(
    int? appId, {
    required UnlockSource source,
    required int minutes,
  }) async => unlocks.add((appId, source, minutes));

  @override
  Future<void> markFreeReading(LocalDate date, CardId card) async =>
      freeReading.add(card);

  GateResult? get lastResult => sessions.values.lastOrNull?.result;
}

/// Hodiny, ktore idu s fake casom testu.
Clock gateClock(WidgetTester tester) {
  final t0 = tester.binding.clock.now();
  return Clock(() => gateNow.add(tester.binding.clock.now().difference(t0)));
}

class GateTest {
  GateTest({
    FakeRepositories? repos,
    FakeGateRepository? gates,
    FakeBlockerGateway? blocker,
    List<CardId>? extra,
  }) : extra = extra ?? [for (var i = 101; i <= 110; i++) fakeQuoteId(i)],
       repos = repos ?? FakeRepositories(),
       gates = gates ?? FakeGateRepository(),
       blocker = blocker ?? FakeBlockerGateway();

  final FakeRepositories repos;
  final FakeGateRepository gates;
  final FakeBlockerGateway blocker;

  /// Karty volneho citania po konci sady.
  final List<CardId> extra;
  int closed = 0;

  List<Override> overrides(
    WidgetTester tester, {
    bool overlayEnabled = true,
    List<Override> extra = const [],
  }) => [
    // Prvy override fakes su hodiny, nahradia ich hodiny testu.
    appClockProvider.overrideWithValue(gateClock(tester)),
    ...repos.overrides(now: gateNow).skip(1),
    blockerGatewayProvider.overrideWithValue(blocker),
    gateRepositoryProvider.overrideWithValue(gates),
    gateOverlayEnabledProvider.overrideWithValue(overlayEnabled),
    gateFreeReadingProvider.overrideWithValue(() async => this.extra),
    ...extra,
  ];

  /// Spusti [child] (default [GateScreen] pre Instagram) na telefone
  /// 360 x 780 dp.
  Future<void> pump(
    WidgetTester tester, {
    Widget? child,
    bool overlayEnabled = true,
    Locale locale = const Locale('en'),
    List<Override> extra = const [],
    bool accessibleNavigation = false,
  }) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: overrides(
          tester,
          overlayEnabled: overlayEnabled,
          extra: extra,
        ),
        child:
            child ??
            MaterialApp(
              locale: locale,
              theme: ProsocheTheme.light(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(accessibleNavigation: accessibleNavigation),
                child: Theme(
                  data: prosocheAppTheme(
                    brightness: Brightness.light,
                    locale: Localizations.localeOf(context),
                  ),
                  child: SkUiStringsScope(
                    strings: skUiStringsOf(context.l10n),
                    child: child!,
                  ),
                ),
              ),
              home: GateScreen(app: igRef, onClosed: () => closed++),
            ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }
}

/// Pocka dwell jednej karty (4 s) a prekresli.
Future<void> passDwell(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

/// Dwell karty a prechod na dalsiu cez "Next".
Future<void> passCard(WidgetTester tester, {bool next = true}) async {
  await passDwell(tester);
  if (!next) return;
  final button = find.text('Next');
  if (button.evaluate().isEmpty) return;
  await tester.tap(button);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}
