import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/data/repositories/catalog/content_catalog.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/practice/practice.dart';

import '../../db/fixtures/content_fixture.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late ContentDb content;
  late UserDb user;
  late DriftLibraryRepository library;
  late DriftPracticeRepository practice;
  final day = LocalDate(2026, 10, 31);
  final clock = Clock.fixed(DateTime.utc(2026, 10, 31, 20));

  setUp(() {
    content = openContentFixture();
    user = UserDb.memory();
    library = DriftLibraryRepository(
      content: Future.value(content),
      userDb: user,
      clock: clock,
    );
    practice = DriftPracticeRepository(
      content: Future.value(content),
      userDb: user,
      library: library,
      clock: clock,
    );
  });
  tearDown(() async {
    await content.close();
    await user.close();
  });

  group('LibraryRepository', () {
    test('authors with works, translator and edition year', () async {
      final authors = await library.authors();
      expect(authors.map((a) => a.name), ['Author A', 'Author B']);
      final w = authors.first.works.single;
      expect(w.id, 'work-books');
      expect(w.author, 'Author A');
      expect(w.translator, 'Fixture Translator');
      expect(w.editionYear, 1880);
      expect(w.bookCount, 2);
    });

    test('work text by books, sections with references', () async {
      final text = (await library.work('work-books'))!;
      expect(text.books.map((b) => b.title), ['Book 1', 'Book 2']);
      expect(text.sections.map((s) => s.reference).first, 'Books 1.1');
      expect(text.sections.first.number, '1');
      expect(text.sections.first.paragraphs, hasLength(2));
      final flat = (await library.work('work-flat'))!;
      expect(flat.books.single.number, isNull);
      expect(flat.sections.first.title, 'Chapter 1');
      expect(await library.work('nope'), isNull);
      expect((await library.section('work-flat.2'))!.reference, 'Flat 2');
      expect(await library.section('nope'), isNull);
    });

    test('FTS5 search with escaped query and references', () async {
      final hits = await library.search('rive');
      expect(hits, isNotEmpty);
      expect(hits.first.reference, matches(RegExp('^(Books|Flat) ')));
      expect(hits.first.snippet, contains('['));
      expect(await library.search('  '), isEmpty);
      expect(await library.search('"OR'), isEmpty);
    });

    test('reading position and last read work', () async {
      expect(await library.watchLastPosition().first, isNull);
      await library.savePosition('work-books', 'work-books.2.1', offset: 2);
      final pos = await library.watchPositions().first;
      expect(pos['work-books']!.sectionKey, 'work-books.2.1');
      expect(pos['work-books']!.offset, 1);
      expect((await library.watchLastPosition().first)!.workId, 'work-books');
    });

    test('bookmarks on and off', () async {
      await library.setBookmark('work-flat.1', 'work-flat', on: true);
      await library.setBookmark('work-flat.1', 'work-flat', on: true);
      expect((await library.watchBookmarks().first).single.workId, 'work-flat');
      await library.setBookmark('work-flat.1', 'work-flat', on: false);
      expect(await library.watchBookmarks().first, isEmpty);
    });
  });

  group('PracticeRepository', () {
    test('evening routine: questions from the practice text first', () async {
      final r = await practice.routine(RoutineKind.evening, day);
      expect(r.practice!.title, 'Evening review');
      expect(r.section!.key, 'work-flat.3');
      expect(r.questions.map((q) => q.text).take(2), [
        'Question one?',
        'Question two?',
      ]);
      expect(r.questions.first.id, 'practice:evening-review#1');
      expect(r.questions, hasLength(3));
      expect(r.questions.last.id, startsWith('prompt:evening'));
    });

    test('morning routine: prompts tagged morning, stable per day', () async {
      final a = await practice.routine(RoutineKind.morning, day);
      final b = await practice.routine(RoutineKind.morning, day);
      expect(a.questions, b.questions);
      expect(
        a.questions.map((q) => q.id),
        everyElement(startsWith('prompt:morning')),
      );
      expect(a.section!.reference, 'Books 1.1');
    });

    test('practices list', () async {
      final all = await practice.practices();
      expect(all, hasLength(5));
      expect(all.first.steps, hasLength(2));
    });

    test('answers: save, update, clear; notes; export; delete', () async {
      final r = await practice.routine(RoutineKind.evening, day);
      final q = r.questions.first;
      await practice.saveAnswer(day, RoutineKind.evening, q, '  ');
      expect(await practice.answer(day, RoutineKind.evening, q), isNull);
      await practice.saveAnswer(day, RoutineKind.evening, q, 'first');
      await practice.saveAnswer(day, RoutineKind.evening, q, 'first');
      await practice.saveAnswer(day, RoutineKind.evening, q, 'second');
      final e = (await practice.answer(day, RoutineKind.evening, q))!;
      expect(e.body, 'second');
      expect(e.prompt, 'Question one?');
      expect(e.kind, JournalKind.evening);
      await practice.addNote(day, 'note', promptId: 'prompt:x', prompt: 'P?');
      await practice.addNote(day, '   ');
      expect(await practice.watchJournal().first, hasLength(2));
      final text = await practice.exportJournal(title: 'Journal');
      expect(text, startsWith('Journal\n\n2026-10-31'));
      expect(text, contains('Question one?\nsecond'));
      expect(text, contains('P?\nnote'));
      await practice.saveAnswer(day, RoutineKind.evening, q, '');
      expect(await practice.watchJournal().first, hasLength(1));
      final note = (await practice.watchJournal().first).single;
      await practice.deleteEntry(note.id);
      expect(await practice.watchJournal().first, isEmpty);
      await practice.addNote(day, 'again');
      await practice.deleteJournal();
      expect(await practice.watchJournal().first, isEmpty);
    });

    test('done routines per day', () async {
      await practice.setDone(day, RoutineKind.morning, done: true);
      await practice.setDone(day, RoutineKind.morning, done: true);
      expect(await practice.watchDone(day).first, {RoutineKind.morning});
      await practice.setDone(day, RoutineKind.morning, done: false);
      expect(await practice.watchDone(day).first, isEmpty);
    });

    test('journal is part of delete all my data', () async {
      await practice.addNote(day, 'private');
      await library.savePosition('work-flat', 'work-flat.1');
      await user.deleteAllData();
      expect(await practice.watchJournal().first, isEmpty);
      expect(await library.watchPositions().first, isEmpty);
    });
  });

  test('card content of every type from content.db', () async {
    final repo = ContentCardRepository(
      catalog: ContentCatalog(Future.value(content)),
    );
    final quote =
        (await repo.load(ContentCardId.quote(fixtureQuoteId(1)), lang: 'en'))!
            as QuoteContent;
    expect(quote.reference, 'Books 1.1');
    expect(
      quote.translation,
      const Translation(translator: 'Fixture Translator', year: 1880),
    );
    expect(quote.author, 'Author A');
    expect(quote.sectionKey, 'work-books.1.1');
    final passage =
        (await repo.load(ContentCardId(CardType.passage, 'p1'), lang: 'en'))!
            as QuoteContent;
    expect(passage.isPassage, isTrue);
    final practiceCard =
        (await repo.load(
              ContentCardId(CardType.practice, 'morning-preparation'),
              lang: 'en',
            ))!
            as PracticeContent;
    expect(practiceCard.reference, 'Books 1.1');
    expect(practiceCard.shareText, startsWith('Morning preparation'));
    expect(
      await repo.load(ContentCardId(CardType.prompt, 'free-5'), lang: 'en'),
      isA<PromptContent>(),
    );
    final concept =
        (await repo.load(ContentCardId(CardType.concept, 'c1'), lang: 'en'))!
            as ConceptContent;
    expect(concept.reference, 'Flat 1');
    final author =
        (await repo.load(
              ContentCardId(CardType.author, 'author-b'),
              lang: 'en',
            ))!
            as AuthorContent;
    expect(author.firstWorkId, 'work-flat');
    expect(author.lifespan, 'AD 3-4');
    expect(await repo.load(ContentCardId.quote('nope'), lang: 'en'), isNull);
    expect(await repo.load(DoneCardId(day), lang: 'en'), isNull);
    expect(paragraphs('a\n\n \n\nb'), ['a', 'b']);
  });

  test('catalog pools every card type with time of day from tags', () async {
    final pools = await ContentCatalog(Future.value(content)).feedPools();
    expect(pools.of(CardType.quote), hasLength(fixtureQuoteCount));
    expect(pools.of(CardType.author), hasLength(2));
    final morning = pools
        .of(CardType.practice)
        .firstWhere((c) => c.id.key == 'morning-preparation');
    expect(morning.timeOfDay.wire, 'morning');
    expect(
      await ContentCatalog(Future.value(content)).questTemplates(),
      isEmpty,
    );
  });
}
