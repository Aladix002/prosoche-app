import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/flags/feature_flags.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/quests/quests.dart' show CardAction, CardContext;
import 'package:sakina/features/cards/cards.dart' show CardView;
import 'package:sakina/features/cards/translator_notes.dart';
import 'package:sakina/features/journey/card_pager.dart';
import 'package:sakina/features/journey/saved_screen.dart';
import 'package:sakina/ui/ui.dart';

import '../../fakes/fake_repositories.dart';
import '../../helpers/pump_app.dart';
import 'journey_fixtures.dart';

void main() {
  test('parseSavedType accepts only saveable types', () {
    expect(parseSavedType('hadith'), CardType.hadith);
    expect(parseSavedType('intro'), isNull);
    expect(parseSavedType('evil'), isNull);
    expect(parseSavedType(null), isNull);
  });

  Future<FakeRepositories> pump(
    WidgetTester tester, {
    FakeRepositories? repos,
    String location = '/journey/saved',
    List<CardId> saved = const [],
  }) async {
    phoneView(tester);
    final r = repos ?? FakeRepositories();
    for (final id in saved) {
      await r.actions.save(journeyToday, id, context: CardContext.feed);
    }
    await tester.pumpSakina(
      location: location,
      flags: FeatureFlags.none,
      fakes: r,
    );
    return r;
  }

  final ayah = AyahCardId(AyahId(2, 255));
  final hadith = HadithCardId(13);
  final dua = DuaCardId(77);
  final name = NameCardId(7);
  final reflection = ReflectionCardId(31);

  testWidgets('empty state (EMPTY-SAVED)', (tester) async {
    await pump(tester);
    expect(find.text('Saved cards'), findsOneWidget);
    expect(find.text('Nothing saved yet'), findsOneWidget);
    expect(
      find.text('Tap the bookmark on any card to keep it here.'),
      findsOneWidget,
    );
  });

  testWidgets('loading shows a skeleton', (tester) async {
    phoneView(tester);
    await tester.pumpSakina(
      location: '/journey/saved',
      flags: FeatureFlags.none,
      fakes: FakeRepositories(actions: StuckActionsRepository()),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SkSkeleton), findsOneWidget);
  });

  testWidgets('error shows E-DB-1', (tester) async {
    phoneView(tester);
    await tester.pumpSakina(
      location: '/journey/saved',
      flags: FeatureFlags.none,
      fakes: FakeRepositories(actions: StuckActionsRepository(error: 'db')),
    );
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('data: newest first, previews without Arabic', (tester) async {
    await pump(tester, saved: [hadith, dua, name, reflection, ayah]);
    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => (t.title! as Text).data)
        .toList();
    expect(titles.first, 'Placeholder 2 \u20682:255\u2069');
    expect(titles, hasLength(5));
    expect(find.text('[PLACEHOLDER translation 2:255]'), findsOneWidget);
    expect(find.text('[PLACEHOLDER hadith]'), findsOneWidget);
    expect(find.text('[PLACEHOLDER meaning]'), findsOneWidget);
    expect(find.textContaining('PLACEHOLDER hadith ar'), findsNothing);
  });

  // BF-02: znacky `[n]` v nahlade ako horny index bez tapu (rovnaky
  // renderer ako karta), text nahladu sa nemeni.
  testWidgets('verse preview: note markers as superscript, not tappable', (
    tester,
  ) async {
    const text =
        '(1) [PLACEHOLDER] one,[2] [PLACEHOLDER] two, [PLACEHOLDER] three, '
        '[PLACEHOLDER] four, [PLACEHOLDER] five, [PLACEHOLDER] six.[3]';
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      repos: FakeRepositories(
        cards: NotesCardContentRepository({
          AyahId(2, 255): (text, '[2]- [PLACEHOLDER]\n[3]- [PLACEHOLDER]'),
        }),
      ),
      saved: [ayah],
    );
    final markers = find.byType(TranslatorNoteMarker);
    expect(markers, findsNWidgets(2));
    for (final m in tester.widgetList<TranslatorNoteMarker>(markers)) {
      expect(m.interactive, isFalse);
    }
    expect(find.bySemanticsLabel(RegExp("Translator's note")), findsNothing);
    final subtitle = tester.widget<ListTile>(find.byType(ListTile)).subtitle!;
    expect(subtitle, isA<Text>());
    final rich = subtitle as Text;
    expect(rich.maxLines, 2);
    expect(rich.overflow, TextOverflow.ellipsis);
    // Text nahladu je doslovne preklad (znacky su WidgetSpan s `[n]`).
    final plain = StringBuffer();
    rich.textSpan!.visitChildren((span) {
      if (span is TextSpan && span.text != null) plain.write(span.text);
      if (span is WidgetSpan) {
        plain.write((span.child as TranslatorNoteMarker).marker);
      }
      return true;
    });
    expect(plain.toString(), text);

    // Tap na znacku nic neotvori, otvori sa karta (ako tap na riadok).
    await tester.tap(find.text('[2]'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text("Translator's note"), findsNothing);
    handle.dispose();
  });

  testWidgets('filters by type, also from ?type=', (tester) async {
    await pump(tester, saved: [hadith, ayah, dua]);
    await tester.tap(find.byKey(const ValueKey('saved-filter:hadith')));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('[PLACEHOLDER hadith]'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('saved-filter:name')));
    await tester.pumpAndSettle();
    expect(find.text('Nothing saved yet'), findsOneWidget);

    await pump(
      tester,
      location: '/journey/saved?type=dua',
      saved: [hadith, ayah, dua],
    );
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('[PLACEHOLDER dua]'), findsOneWidget);
    final chip = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('saved-filter:dua')),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('tap opens the card fullscreen, swipe between saved', (
    tester,
  ) async {
    await pump(tester, saved: [hadith, ayah]);
    await tester.tap(find.text('[PLACEHOLDER translation 2:255]'));
    await tester.pumpAndSettle();
    expect(find.byType(JourneyCardPager), findsOneWidget);
    expect(find.text('1 of 2'), findsOneWidget);
    expect(tester.widget<CardView>(find.byType(CardView)).cardId, ayah);

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 of 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(JourneyCardPager), findsNothing);
    expect(find.byType(SavedCardsScreen), findsOneWidget);
  });

  testWidgets('swipe removes with undo', (tester) async {
    final repos = await pump(tester, saved: [hadith, ayah]);
    await tester.drag(
      find.text('[PLACEHOLDER translation 2:255]'),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('[PLACEHOLDER translation 2:255]'), findsNothing);
    expect(find.text('Removed from saved'), findsOneWidget);
    expect(repos.actions.logged.last, (
      ayah,
      CardAction.unsaved,
      CardContext.saved,
    ));

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('[PLACEHOLDER translation 2:255]'), findsOneWidget);
    expect(repos.actions.logged.last, (
      ayah,
      CardAction.saved,
      CardContext.saved,
    ));
  });

  testWidgets('screen reader remove action', (tester) async {
    final handle = tester.ensureSemantics();
    final repos = await pump(tester, saved: [hadith]);
    final node = tester.getSemantics(
      find.descendant(
        of: find.byType(Dismissible),
        matching: find.byType(ListTile),
      ),
    );
    expect(node.getSemanticsData().customSemanticsActionIds, isNotEmpty);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(repos.actions.logged.last.$2, CardAction.saved);
    handle.dispose();
  });
}
