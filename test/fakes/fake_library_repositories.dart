// Fake Library a Practice repozitare (F-01) pre widget testy obrazoviek.
// Obsah je len placeholder (PLAN_VYVOJA 5.5), ziadny text filozofov.
import 'dart:async';

import 'package:prosoche/data/db/user_enums.dart' show JournalKind;
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/practice/practice.dart';

class _Watched<T> {
  _Watched(this._value);

  T _value;
  final _changes = StreamController<T>.broadcast(sync: true);

  T get value => _value;
  set value(T v) {
    _value = v;
    _changes.add(v);
  }

  Stream<T> watch() async* {
    yield _value;
    yield* _changes.stream;
  }
}

/// Dve placeholder diela: `fake-books` (2 knihy) a `fake-flat`.
class FakeLibraryRepository implements LibraryRepository {
  FakeLibraryRepository({this.empty = false, this.fail = false});

  final bool empty;
  final bool fail;
  final searches = <String>[];

  static const books = LibraryWork(
    id: 'fake-books',
    authorId: 'a',
    author: '[PLACEHOLDER] Author A',
    title: '[PLACEHOLDER] Work With Books',
    shortRef: 'Books',
    translator: '[PLACEHOLDER] Translator',
    editionYear: 1862,
    bookCount: 2,
    sectionCount: 4,
  );
  static const flat = LibraryWork(
    id: 'fake-flat',
    authorId: 'b',
    author: '[PLACEHOLDER] Author B',
    title: '[PLACEHOLDER] Flat Work',
    shortRef: 'Flat',
    translator: '[PLACEHOLDER] Translator',
    bookCount: 0,
    sectionCount: 2,
  );

  static LibrarySection makeSection(
    String workId,
    String ref, {
    String? title,
  }) {
    final short = workId == books.id ? books.shortRef : flat.shortRef;
    return LibrarySection(
      key: '$workId.$ref',
      workId: workId,
      book: ref.contains('.') ? int.parse(ref.split('.').first) : null,
      ref: ref,
      title: title,
      text:
          '[PLACEHOLDER section $workId.$ref] first paragraph.\n\n'
          '[PLACEHOLDER] quoted line $ref.',
      reference: '$short $ref',
    );
  }

  static final Map<String, LibrarySection> sections = {
    for (final s in [
      makeSection(books.id, '1.1'),
      makeSection(books.id, '1.2'),
      makeSection(books.id, '2.1'),
      makeSection(books.id, '2.2'),
      makeSection(flat.id, '1', title: '[PLACEHOLDER] Chapter 1'),
      makeSection(flat.id, '2'),
    ])
      s.key: s,
  };

  final positions = _Watched<Map<String, ReadingPosition>>(const {});
  final bookmarks = _Watched<List<SectionBookmark>>(const []);

  void _check() {
    if (fail) throw StateError('fake library failure');
  }

  @override
  Future<List<LibraryAuthor>> authors() async {
    _check();
    if (empty) return const [];
    return const [
      LibraryAuthor(
        id: 'a',
        name: 'Author A',
        lifespan: 'AD 1-2',
        works: [books],
      ),
      LibraryAuthor(
        id: 'b',
        name: 'Author B',
        lifespan: 'AD 3-4',
        works: [flat],
      ),
    ];
  }

  @override
  Future<WorkText?> work(String workId) async {
    _check();
    final work = switch (workId) {
      'fake-books' => books,
      'fake-flat' => flat,
      _ => null,
    };
    if (work == null) return null;
    final list = sections.values.where((s) => s.workId == workId).toList();
    final byBook = <int?, List<LibrarySection>>{};
    for (final s in list) {
      (byBook[s.book] ??= []).add(s);
    }
    return WorkText(
      work: work,
      books: [
        for (final e in byBook.entries)
          LibraryBook(
            number: e.key,
            title: e.key == null ? null : 'Book ${e.key}',
            sections: e.value,
          ),
      ],
    );
  }

  @override
  Future<LibrarySection?> section(String key) async => sections[key];

  @override
  Future<List<SearchHit>> search(String query) async {
    searches.add(query);
    if (query.contains('none')) return const [];
    return [
      const SearchHit(
        sectionKey: 'fake-books.1.2',
        workId: 'fake-books',
        reference: 'Books 1.2',
        snippet: '...the [PLACEHOLDER] [word] here...',
      ),
    ];
  }

  @override
  Stream<Map<String, ReadingPosition>> watchPositions() => positions.watch();

  @override
  Stream<ReadingPosition?> watchLastPosition() => positions.watch().map((m) {
    final all = m.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all.firstOrNull;
  });

  @override
  Future<void> savePosition(
    String workId,
    String sectionKey, {
    double offset = 0,
  }) async {
    positions.value = {
      ...positions.value,
      workId: ReadingPosition(
        workId: workId,
        sectionKey: sectionKey,
        offset: offset,
        updatedAt: DateTime(2026, 10, 29, 9, positions.value.length),
      ),
    };
  }

  @override
  Stream<List<SectionBookmark>> watchBookmarks() => bookmarks.watch();

  @override
  Future<void> setBookmark(
    String sectionKey,
    String workId, {
    required bool on,
  }) async {
    final rest = bookmarks.value.where((b) => b.sectionKey != sectionKey);
    bookmarks.value = [
      if (on)
        SectionBookmark(
          sectionKey: sectionKey,
          workId: workId,
          createdAt: DateTime(2026, 10, 29),
        ),
      ...rest,
    ];
  }
}

class FakePracticeRepository implements PracticeRepository {
  FakePracticeRepository({this.fail = false});

  final bool fail;
  final journal = _Watched<List<JournalEntry>>(const []);
  final done = _Watched<Set<RoutineKind>>(const {});
  final exported = <String>[];
  var _id = 0;

  static final morningPractice = PracticeContent(
    ContentCardId(CardType.practice, 'morning-preparation'),
    title: '[PLACEHOLDER] Morning preparation',
    subtitle: '[PLACEHOLDER] subtitle',
    text: '[PLACEHOLDER] step one\n\n[PLACEHOLDER] step two',
    ref: 'Books 1.1',
    sectionKey: 'fake-books.1.1',
  );
  static final eveningPractice = PracticeContent(
    ContentCardId(CardType.practice, 'evening-review'),
    title: '[PLACEHOLDER] Evening review',
    text: '[PLACEHOLDER] Question one? Question two?',
  );
  static final memento = PracticeContent(
    ContentCardId(CardType.practice, 'memento-mori'),
    title: '[PLACEHOLDER] Memento mori',
    text: '[PLACEHOLDER] memento text',
  );

  @override
  Future<PracticeRoutine> routine(RoutineKind kind, LocalDate date) async {
    if (fail) throw StateError('fake practice failure');
    final p = kind == RoutineKind.morning ? morningPractice : eveningPractice;
    return PracticeRoutine(
      kind: kind,
      date: date,
      practice: p,
      section: kind == RoutineKind.morning
          ? FakeLibraryRepository.sections['fake-books.1.1']
          : null,
      questions: [
        RoutineQuestion(id: '${p.id}#1', text: '[PLACEHOLDER] Question one?'),
        const RoutineQuestion(id: 'prompt:x', text: '[PLACEHOLDER] Prompt?'),
      ],
    );
  }

  @override
  Future<List<PracticeContent>> practices() async {
    if (fail) throw StateError('fake practice failure');
    return [morningPractice, eveningPractice, memento];
  }

  @override
  Stream<List<JournalEntry>> watchJournal() => journal.watch();

  JournalEntry _entry(
    LocalDate date,
    JournalKind kind,
    String body, {
    String? promptId,
    String? prompt,
  }) => JournalEntry(
    id: ++_id,
    date: date,
    kind: kind,
    body: body,
    promptId: promptId,
    prompt: prompt,
    createdAt: DateTime(2026, 10, 29),
    updatedAt: DateTime(2026, 10, 29),
  );

  static JournalKind _kind(RoutineKind k) =>
      k == RoutineKind.morning ? JournalKind.morning : JournalKind.evening;

  @override
  Future<JournalEntry?> answer(
    LocalDate date,
    RoutineKind kind,
    RoutineQuestion question,
  ) async => journal.value
      .where((e) => e.date == date && e.promptId == question.id)
      .firstOrNull;

  @override
  Future<void> saveAnswer(
    LocalDate date,
    RoutineKind kind,
    RoutineQuestion question,
    String body,
  ) async {
    final rest = journal.value.where(
      (e) => !(e.date == date && e.promptId == question.id),
    );
    journal.value = [
      if (body.trim().isNotEmpty)
        _entry(
          date,
          _kind(kind),
          body.trim(),
          promptId: question.id,
          prompt: question.text,
        ),
      ...rest,
    ];
  }

  @override
  Future<void> addNote(
    LocalDate date,
    String body, {
    String? promptId,
    String? prompt,
  }) async {
    journal.value = [
      _entry(date, JournalKind.note, body, promptId: promptId, prompt: prompt),
      ...journal.value,
    ];
  }

  @override
  Future<void> deleteEntry(int id) async =>
      journal.value = [...journal.value.where((e) => e.id != id)];

  @override
  Future<void> deleteJournal() async => journal.value = const [];

  @override
  Future<String> exportJournal({required String title}) async {
    final text = [title, for (final e in journal.value) e.body].join('\n\n');
    exported.add(text);
    return text;
  }

  @override
  Stream<Set<RoutineKind>> watchDone(LocalDate date) => done.watch();

  @override
  Future<void> setDone(
    LocalDate date,
    RoutineKind kind, {
    required bool done,
  }) async {
    this.done.value = {
      ...this.done.value.where((k) => k != kind),
      if (done) kind,
    };
  }
}
