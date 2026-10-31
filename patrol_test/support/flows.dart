import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:prosoche/features/cards/card_view.dart';
import 'package:prosoche/features/cards/types/day_cards.dart';
import 'package:prosoche/ui/ui.dart';

/// Kroky cez UI spolocne pre scenare. Texty su EN (`lib/l10n/app_en.arb`),
/// kluce z obrazoviek (`ValueKey('language:en')` a pod.).

const _short = Duration(milliseconds: 300);

/// Realne cakanie (live binding) a jeden frame.
Future<void> wait(PatrolIntegrationTester $, Duration d) async {
  await Future<void>.delayed(d);
  await $.tester.pump();
}

/// Pocka, kym [finder] nieco najde (bez pumpAndSettle: appka ma
/// nekonecne animacie, napr. skeletony).
Future<void> waitFor(
  PatrolIntegrationTester $,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) {
      throw TestFailure('Timeout ($timeout): $finder\n${visibleTexts()}');
    }
    await wait($, _short);
  }
}

/// Pocka, kym [condition] neplati.
Future<void> waitUntil(
  PatrolIntegrationTester $,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(end)) {
      throw TestFailure('Timeout ($timeout): podmienka neplati');
    }
    await wait($, _short);
  }
}

/// Pocka, kym aspon jeden z [finders] nieco najde.
Future<void> waitForAny(
  PatrolIntegrationTester $,
  List<Finder> finders, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (finders.every((f) => f.evaluate().isEmpty)) {
    if (DateTime.now().isAfter(end)) {
      throw TestFailure('Timeout ($timeout): $finders');
    }
    await wait($, _short);
  }
}

/// Tapne [target] (po naskrolovani) a opakuje, kym sa neobjavi [expected]
/// (tlacidlo moze byt chvilu neaktivne, kym sa nacitaju data).
Future<void> tapUntil(
  PatrolIntegrationTester $,
  Finder target,
  Finder expected, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (expected.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) {
      throw TestFailure(
        'Timeout ($timeout): $target -> $expected\n${visibleTexts()}',
      );
    }
    if (target.evaluate().isNotEmpty) {
      await $.tester.ensureVisible(target.first);
      await $.tester.pump();
      if (target.hitTestable().evaluate().isNotEmpty) {
        await $.tester.tap(target.hitTestable().first);
      }
    }
    await wait($, const Duration(milliseconds: 700));
  }
}

/// Texty na obrazovke (diagnostika pri timeoute).
String visibleTexts() => [
  for (final e in find.byType(Text).hitTestable().evaluate())
    (e.widget as Text).data ?? '',
].where((t) => t.isNotEmpty).join(' | ');

Finder text(String s) => find.text(s);
Finder key(String k) => find.byKey(ValueKey(k));

/// Hlavne tlacidlo kroku onboardingu ("Continue").
Finder get continueButton => find.widgetWithText(SkButton, 'Continue');

/// Vysledok onboardingu pre kontroly v scenari 1.
class OnboardingReport {
  bool locationDialogShown = false;
  bool notificationDialogShown = false;
  bool notificationsOn = false;
}

/// Cely onboarding v `lite` (O1-O4, O7): EN, umysel, poloha (GPS
/// odmietnute v systemovom dialogu, potom rucne Bratislava), povolenie
/// notifikacii v systemovom dialogu, sukromie bez suhlasu, az po Dnes.
///
/// [denyLocationFirst]: tapne "Use my location" a v systemovom dialogu
/// polohu odmietne (emulator nema fix polohy, odmietnutie je
/// deterministicke).
Future<OnboardingReport> completeOnboarding(
  PatrolIntegrationTester $, {
  bool denyLocationFirst = false,
}) async {
  final report = OnboardingReport();

  // O1 Jazyk.
  await waitFor($, text('Choose your language'), timeout: _contentTimeout);
  expect(text('Step 1 of 5'), findsOneWidget);
  await tapUntil($, key('language:en'), text('Quran translation'));
  await tapUntil($, continueButton, text('Why are you here?'));

  // O2 Umysel.
  expect(text('Step 2 of 5'), findsOneWidget);
  await $.tester.tap(key('niyyah:khatm'));
  await $.tester.pump();
  await tapUntil($, continueButton, text('Prayer times for where you are'));

  // O3 Poloha.
  expect(text('Step 3 of 5'), findsOneWidget);
  if (denyLocationFirst) {
    await $.tester.tap(text('Use my location'));
    await $.tester.pump();
    report.locationDialogShown = await $.platform.mobile
        .isPermissionDialogVisible(timeout: const Duration(seconds: 10));
    if (report.locationDialogShown) {
      await $.platform.mobile.denyPermission();
    }
    await waitFor($, text('Location is off. Choose your city instead.'));
  }
  await tapUntil($, text('Choose a city instead'), key('city:search'));
  await $.tester.enterText(key('city:search'), 'Bratislava');
  final city = find.widgetWithText(ListTile, 'Bratislava');
  await waitFor($, city);
  await $.tester.tap(city.first);
  await waitFor(
    $,
    find.byWidgetPredicate(
      (w) =>
          w is Text &&
          w.key == const ValueKey('location:city') &&
          (w.data ?? '').contains('Bratislava'),
    ),
  );
  await tapUntil($, continueButton, text('Gentle reminders'));

  // O4 Notifikacie.
  expect(text('Step 4 of 5'), findsOneWidget);
  final on = text('Notifications are on');
  final allow = text('Allow notifications');
  await waitForAny($, [on, allow]);
  if (allow.evaluate().isNotEmpty) {
    await $.tester.tap(allow);
    await $.tester.pump();
    report.notificationDialogShown = await $.platform.mobile
        .isPermissionDialogVisible(timeout: const Duration(seconds: 10));
    if (report.notificationDialogShown) {
      await $.platform.mobile.grantPermissionWhenInUse();
    }
  }
  await waitFor($, on);
  report.notificationsOn = true;
  await tapUntil($, continueButton, text('Your data stays here'));

  // O7 Sukromie: vek nepotvrdeny, suhlasy ostanu "nie".
  expect(text('Step 5 of 5'), findsOneWidget);
  await tapUntil(
    $,
    find.widgetWithText(SkButton, 'Finish'),
    text("Today's intentions"),
  );
  return report;
}

/// Prva instalacia rozbaluje ~45 MB content.db.
const _contentTimeout = Duration(seconds: 90);

/// Pozicia (1-based) karty, ktora je prave na obrazovke; null = ziadna
/// (nacitava sa alebo je zobrazena karta "done").
int? currentCardPos(PatrolIntegrationTester $) {
  final f = find.byType(CardView).hitTestable();
  if (f.evaluate().isEmpty) return null;
  return $.tester.widget<CardView>(f.first).pos;
}

bool doneCardVisible() =>
    find.byType(DoneCard).hitTestable().evaluate().isNotEmpty;

/// Otvori dennu sadu z Dnes a pocka na prvu kartu.
Future<void> openFeed(PatrolIntegrationTester $, Finder cta) async {
  await tapUntil($, cta, find.byType(CardView));
  await waitFor($, find.byType(CardView).hitTestable());
}

/// Posunie feed na dalsiu kartu: tah nahor sa opakuje, kym karta nie je
/// `seen` (dwell 2,5 s, dlha karta az 15 s) a feed sa neposunie.
/// Vrati poziciu novej karty, null = karta "done".
Future<int?> nextCard(PatrolIntegrationTester $) async {
  final before = currentCardPos($);
  final height = $.tester.getSize(find.byType(PageView)).height;
  final end = DateTime.now().add(const Duration(seconds: 40));
  var drags = 0;
  // Tahy pred dwell feed zamerne zablokuje a ukaze hint "Take a moment"
  // (docs/02 0.4); pocet zobrazenych hintov ide do logu (I-03).
  var hints = 0;
  while (DateTime.now().isBefore(end)) {
    // Pomaly tah cez 60 % vysky (ako prst), nie fling.
    await $.tester.timedDrag(
      find.byType(PageView),
      Offset(0, -height * 0.6),
      const Duration(milliseconds: 700),
      warnIfMissed: false,
    );
    drags++;
    await wait($, const Duration(milliseconds: 800));
    if (doneCardVisible()) {
      debugPrint('E2E: karta $before -> done ($drags tahov, hint $hints)');
      return null;
    }
    final now = currentCardPos($);
    if (now != null && now != before) {
      debugPrint('E2E: karta $before -> $now ($drags tahov, hint $hints)');
      return now;
    }
    if (text('Take a moment').evaluate().isNotEmpty) hints++;
  }
  throw TestFailure('Feed sa neposunul z karty $before');
}

/// Prejde vsetky karty az po kartu "Dnes si hotovy".
Future<void> finishFeed(PatrolIntegrationTester $) async {
  for (var i = 0; i < 40; i++) {
    if (await nextCard($) == null) return;
  }
  throw TestFailure('Sada nema koniec');
}

/// Taby spodnej navigacie (poradie docs/01 D1), nezavisle od jazyka.
enum AppTab { today, quran, prayer, journey }

/// Prepne tab v spodnej navigacii.
Future<void> openTab(PatrolIntegrationTester $, AppTab tab) async {
  final destinations = find.descendant(
    of: find.byType(NavigationBar),
    matching: find.byType(NavigationDestination),
  );
  await waitFor($, destinations);
  await $.tester.tap(destinations.at(tab.index));
  await wait($, const Duration(seconds: 1));
}

/// Nastavenia z hlavicky Dnes (EN).
Future<void> openSettingsFromToday(PatrolIntegrationTester $) async {
  await openTab($, AppTab.today);
  await tapUntil($, find.byTooltip('Settings'), text('Privacy'));
}
