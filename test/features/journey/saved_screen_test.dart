import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/quests.dart'
    show CardAction, CardContext;
import 'package:prosoche/features/cards/cards.dart' show CardView;
import 'package:prosoche/features/journey/card_pager.dart';
import 'package:prosoche/features/journey/saved_screen.dart';
import 'package:prosoche/ui/ui.dart';

import '../../fakes/fake_repositories.dart';
import '../../helpers/pump_app.dart';
import 'journey_fixtures.dart';

void main() {
  test('parseSavedType accepts only saveable types', () {
    expect(parseSavedType('quote'), CardType.quote);
    expect(parseSavedType('concept'), CardType.concept);
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
    await tester.pumpProsoche(
      location: location,
      flags: FeatureFlags.none,
      fakes: r,
    );
    return r;
  }

  final first = fakeQuoteId(1);
  final second = fakeQuoteId(2);
  final idea = ContentCardId(CardType.concept, 'logos');

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
    await tester.pumpProsoche(
      location: '/journey/saved',
      flags: FeatureFlags.none,
      fakes: FakeRepositories(actions: StuckActionsRepository()),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SkSkeleton), findsOneWidget);
  });

  testWidgets('error shows E-DB-1', (tester) async {
    phoneView(tester);
    await tester.pumpProsoche(
      location: '/journey/saved',
      flags: FeatureFlags.none,
      fakes: FakeRepositories(actions: StuckActionsRepository(error: 'db')),
    );
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('data: newest first with reference and preview', (tester) async {
    await pump(tester, saved: [idea, second, first]);
    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => (t.title! as Text).data)
        .toList();
    expect(titles.first, '[PLACEHOLDER work] 1.1');
    expect(titles.last, '[PLACEHOLDER concept logos]');
    expect(titles, hasLength(3));
    expect(find.text('[PLACEHOLDER quote q_0001]'), findsOneWidget);
    expect(find.text('[PLACEHOLDER quote q_0002]'), findsOneWidget);
  });

  testWidgets('filters by type, also from ?type=', (tester) async {
    await pump(tester, saved: [idea, first]);
    await tester.tap(find.byKey(const ValueKey('saved-filter:quote')));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('[PLACEHOLDER quote q_0001]'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('saved-filter:practice')));
    await tester.pumpAndSettle();
    expect(find.text('Nothing saved yet'), findsOneWidget);

    await pump(
      tester,
      location: '/journey/saved?type=concept',
      saved: [idea, first],
    );
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('[PLACEHOLDER concept logos]'), findsWidgets);
    final chip = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('saved-filter:concept')),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('tap opens the card fullscreen, swipe between saved', (
    tester,
  ) async {
    await pump(tester, saved: [second, first]);
    await tester.tap(find.text('[PLACEHOLDER quote q_0001]'));
    await tester.pumpAndSettle();
    expect(find.byType(JourneyCardPager), findsOneWidget);
    expect(find.text('1 of 2'), findsOneWidget);
    expect(tester.widget<CardView>(find.byType(CardView)).cardId, first);

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 of 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(JourneyCardPager), findsNothing);
    expect(find.byType(SavedCardsScreen), findsOneWidget);
  });

  testWidgets('swipe removes with undo', (tester) async {
    final repos = await pump(tester, saved: [second, first]);
    await tester.drag(
      find.text('[PLACEHOLDER quote q_0001]'),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('[PLACEHOLDER quote q_0001]'), findsNothing);
    expect(find.text('Removed from saved'), findsOneWidget);
    expect(repos.actions.logged.last, (
      first,
      CardAction.unsaved,
      CardContext.saved,
    ));

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('[PLACEHOLDER quote q_0001]'), findsOneWidget);
    expect(repos.actions.logged.last, (
      first,
      CardAction.saved,
      CardContext.saved,
    ));
  });

  testWidgets('screen reader remove action', (tester) async {
    final handle = tester.ensureSemantics();
    final repos = await pump(tester, saved: [first]);
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
