import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/library/library_routes.dart';
import 'package:prosoche/features/library/widgets/reader_page.dart';
import 'package:prosoche/ui/ui.dart';

import '../../fakes/fake_repositories.dart';
import '../../helpers/golden/golden.dart';
import 'f01_harness.dart';

void main() {
  group('readerParagraphs', () {
    test('marks the quote inside its paragraph and across paragraphs', () {
      const text = 'aa bb.\n\ncc dd ee.\n\nff';
      final one = readerParagraphs(text, 'dd');
      expect(one.map((p) => p.start), [null, 3, null]);
      expect(one[1].end, 5);
      final across = readerParagraphs(text, 'bb.\n\ncc');
      expect(
        [for (final p in across) (p.start, p.end)],
        [(3, 6), (0, 2), (null, null)],
      );
      expect(readerParagraphs(text, 'zz').every((p) => p.start == null), true);
      expect(readerParagraphs(text, null), hasLength(3));
    });

    test('workIdOfSection and reader path', () {
      expect(workIdOfSection('meditations.2.1'), 'meditations');
      expect(workIdOfSection('on-anger.3.36'), 'on-anger');
      expect(workIdOfSection('x'), 'x');
      expect(
        LibraryRoutes.reader('meditations', section: 'meditations.2.1'),
        '/reader/meditations?section=meditations.2.1',
      );
    });
  });

  testWidgets('library: authors, works with translator, open reader', (
    tester,
  ) async {
    final repos = FakeRepositories();
    await pumpF01(tester, location: '/library', repos: repos);
    expect(find.text('AUTHOR A  AD 1-2'), findsOneWidget);
    expect(find.text('[PLACEHOLDER] Work With Books'), findsOneWidget);
    expect(
      find.text('2 books · Translated by [PLACEHOLDER] Translator (1862)'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('library:continue')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('work:fake-books')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader:section:fake-books.1.1')),
      findsOneWidget,
    );
    expect(find.text('Book 1'), findsOneWidget);
    expect(
      repos.library.positions.value['fake-books']!.sectionKey,
      'fake-books.1.1',
    );
    expectNoTextClipping(tester);
  });

  testWidgets('reader: next, contents, bookmark, position', (tester) async {
    final repos = FakeRepositories();
    await pumpF01(
      tester,
      location: '/reader/fake-books?section=fake-books.1.2',
      repos: repos,
    );
    expect(find.text('2 / 4'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reader:next')));
    await tester.pumpAndSettle();
    expect(find.text('3 / 4'), findsOneWidget);
    expect(
      repos.library.positions.value['fake-books']!.sectionKey,
      'fake-books.2.1',
    );
    await tester.tap(find.byKey(const ValueKey('reader:bookmark')));
    await tester.pumpAndSettle();
    expect(repos.library.bookmarks.value.single.sectionKey, 'fake-books.2.1');
    expect(find.text('Bookmarked'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reader:bookmark')));
    await tester.pumpAndSettle();
    expect(repos.library.bookmarks.value, isEmpty);
    await tester.tap(find.byKey(const ValueKey('reader:contents')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('contents:fake-books.1.1')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 4'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reader:previous')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 4'), findsOneWidget);
  });

  testWidgets('reader: reading size S-XL is saved and applied', (tester) async {
    final repos = FakeRepositories();
    await pumpF01(
      tester,
      location: '/reader/fake-books?section=fake-books.1.2',
      repos: repos,
    );
    double size() => tester
        .widget<SkReaderText>(find.byType(SkReaderText).first)
        .size
        .factor;
    expect(size(), 1);
    await tester.tap(find.byKey(const ValueKey('reader:text_size')));
    await tester.pumpAndSettle();
    expect(find.text('Extra large'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reader_scale:xl')));
    await tester.pumpAndSettle();
    expect(await repos.settings.get(SettingsKeys.readerScale), 'xl');
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(size(), 1.3);
    expect(readerSizeOf('s'), SkReaderSize.s);
    expect(readerSizeOf('l'), SkReaderSize.l);
    expect(readerSizeOf(null), SkReaderSize.m);
  });

  testWidgets('reader highlights the quote from a card', (tester) async {
    final router = await pumpF01(tester, location: '/library');
    unawaited(
      router.push<void>(
        LibraryRoutes.reader('fake-books', section: 'fake-books.1.2'),
        extra: 'quoted line 1.2',
      ),
    );
    await tester.pumpAndSettle();
    final rich = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((r) => r.text.toPlainText())
        .where((t) => t.contains('quoted line 1.2'));
    expect(rich, isNotEmpty);
  });

  testWidgets('reader: unknown work and error states', (tester) async {
    await pumpF01(tester, location: '/reader/nope');
    expect(find.text('This work is not available'), findsOneWidget);
    await pumpF01(
      tester,
      location: '/reader/fake-books',
      repos: FakeRepositories(library: FakeLibraryRepository(fail: true)),
    );
    expect(find.byType(SkErrorState), findsOneWidget);
  });

  testWidgets('library: empty and error states', (tester) async {
    await pumpF01(
      tester,
      location: '/library',
      repos: FakeRepositories(library: FakeLibraryRepository(empty: true)),
    );
    expect(find.text('No works'), findsOneWidget);
    await pumpF01(
      tester,
      location: '/library',
      repos: FakeRepositories(library: FakeLibraryRepository(fail: true)),
    );
    expect(find.byType(SkErrorState), findsOneWidget);
  });

  testWidgets('continue reading tile opens the last position', (tester) async {
    final repos = FakeRepositories();
    await repos.library.savePosition('fake-flat', 'fake-flat.2');
    await pumpF01(tester, location: '/library', repos: repos);
    expect(find.text('Continue at Flat 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('library:continue')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader:section:fake-flat.2')),
      findsOneWidget,
    );
  });

  testWidgets('search: hint, results with highlight, empty, open', (
    tester,
  ) async {
    final repos = FakeRepositories();
    await pumpF01(tester, location: '/library/search', repos: repos);
    expect(find.text('Search all works'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('search:field')), 'none');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Nothing found'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('search:field')), 'word');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Books 1.2'), findsOneWidget);
    expect(repos.library.searches, containsAll(['none', 'word']));
    await tester.tap(find.byKey(const ValueKey('hit:fake-books.1.2')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader:section:fake-books.1.2')),
      findsOneWidget,
    );
  });

  testWidgets('bookmarks: empty, list, remove, open', (tester) async {
    final repos = FakeRepositories();
    await pumpF01(tester, location: '/library/bookmarks', repos: repos);
    expect(find.text('No bookmarks yet'), findsOneWidget);
    await repos.library.setBookmark('fake-flat.1', 'fake-flat', on: true);
    await tester.pumpAndSettle();
    expect(find.text('Flat 1'), findsOneWidget);
    await tester.tap(find.text('Flat 1'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader:section:fake-flat.1')),
      findsOneWidget,
    );
    expect(find.text('[PLACEHOLDER] Chapter 1'), findsOneWidget);
  });

  testWidgets('library at text scale 2.0 without clipping', (tester) async {
    await pumpF01(tester, location: '/library', textScale: 2);
    expectNoTextClipping(tester);
  });
}
