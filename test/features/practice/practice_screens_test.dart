import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/practice/practice.dart';
import 'package:prosoche/domain/quests/quests.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/practice/memento_mori_screen.dart';
import 'package:prosoche/features/practice/practice_routes.dart';
import 'package:prosoche/ui/ui.dart';

import '../../fakes/fake_repositories.dart';
import '../../helpers/golden/golden.dart';
import '../library/f01_harness.dart';

void main() {
  test('routine paths', () {
    expect(
      PracticeRoutes.routine(RoutineKind.evening),
      '/practice/routine/evening',
    );
    expect(PracticeRoutes.parseRoutine('morning'), RoutineKind.morning);
    expect(PracticeRoutes.parseRoutine('noon'), isNull);
  });

  testWidgets('hub: routines, journal, memento, exercises', (tester) async {
    await pumpF01(tester, location: '/practice');
    expect(find.text('[PLACEHOLDER] Morning preparation'), findsWidgets);
    expect(find.text('MORNING'), findsOneWidget);
    expect(find.text('EVENING'), findsOneWidget);
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Memento mori'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('exercise:memento-mori')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('exercise:memento-mori')), findsOneWidget);
    // Ranna priprava je hore ako karta, v zozname cviceni sa neopakuje.
    expect(find.text('Other exercises'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('exercise:morning-preparation')),
      findsNothing,
    );
    expectNoTextClipping(tester);
  });

  testWidgets('morning routine: section, steps, journal answer, done', (
    tester,
  ) async {
    final repos = FakeRepositories();
    await pumpF01(tester, location: '/practice/routine/morning', repos: repos);
    expect(find.text('Books 1.1'), findsWidgets);
    await tester.scrollUntilVisible(
      find.textContaining('[PLACEHOLDER] step one', findRichText: true),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final answer = find.byKey(
      const ValueKey('answer:practice:morning-preparation#1'),
    );
    await tester.scrollUntilVisible(
      answer,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final field = find.descendant(of: answer, matching: find.byType(TextField));
    await tester.enterText(field, 'my answer');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(repos.practice.journal.value.single.body, 'my answer');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('routine:done')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('routine:done')));
    await tester.pumpAndSettle();
    expect(repos.practice.done.value, {RoutineKind.morning});
    expect(repos.quests.actChanges.last, QuestStatus.done);
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('routine:undo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('routine:undo')));
    await tester.pumpAndSettle();
    expect(repos.practice.done.value, isEmpty);
  });

  testWidgets('routine error state', (tester) async {
    await pumpF01(
      tester,
      location: '/practice/routine/evening',
      repos: FakeRepositories(practice: FakePracticeRepository(fail: true)),
    );
    expect(find.byType(SkErrorState), findsOneWidget);
  });

  testWidgets('journal: empty, add note, export, delete', (tester) async {
    final repos = FakeRepositories();
    await pumpF01(tester, location: '/practice/journal', repos: repos);
    expect(find.text('No entries yet'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('journal:add')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('journal:noteField')),
      'a note',
    );
    await tester.tap(find.byKey(const ValueKey('journal:noteSave')));
    await tester.pumpAndSettle();
    expect(find.text('a note'), findsOneWidget);
    expect(find.text('Note'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('journal:deleteAll')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('journal:deleteConfirm')));
    await tester.pumpAndSettle();
    expect(repos.practice.journal.value, isEmpty);
  });

  testWidgets('memento mori: add year, weeks, clear', (tester) async {
    final repos = FakeRepositories();
    await pumpF01(tester, location: '/practice/memento', repos: repos);
    expect(
      find.textContaining('[PLACEHOLDER] memento text', findRichText: true),
      findsWidgets,
    );
    await tester.tap(find.byKey(const ValueKey('memento:setYear')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('memento:yearField')),
      '1990',
    );
    await tester.tap(find.byKey(const ValueKey('memento:yearSave')));
    await tester.pumpAndSettle();
    expect(await repos.settings.get(SettingsKeys.practiceBirthYear), 1990);
    expect(find.textContaining('of 4,160 weeks'), findsOneWidget);
    expect(find.byType(LifeGrid), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('memento:clearYear')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('memento:clearYear')));
    await tester.pumpAndSettle();
    expect(await repos.settings.get(SettingsKeys.practiceBirthYear), isNull);
  });

  testWidgets('exercise: steps, read in context, I did this', (tester) async {
    final repos = FakeRepositories();
    await pumpF01(
      tester,
      location: '/practice/exercise/morning-preparation',
      repos: repos,
    );
    expect(find.text('Read Books 1.1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('exercise:done')));
    await tester.pumpAndSettle();
    expect(repos.quests.actChanges.last, QuestStatus.done);
    await tester.tap(find.text('Read Books 1.1'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader:section:fake-books.1.1')),
      findsOneWidget,
    );
    await pumpF01(tester, location: '/practice/exercise/unknown');
    expect(find.text('This exercise is not available'), findsOneWidget);
  });
}
