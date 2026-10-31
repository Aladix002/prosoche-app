import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/domain/library/library.dart';

/// Autor a jeho diela (zoznam Library).
@immutable
final class LibraryAuthor {
  const LibraryAuthor({
    required this.id,
    required this.name,
    required this.lifespan,
    required this.works,
  });

  final String id;
  final String name;
  final String lifespan;
  final List<LibraryWork> works;
}

/// Dielo v zozname Library.
@immutable
final class LibraryWork {
  const LibraryWork({
    required this.id,
    required this.authorId,
    required this.author,
    required this.title,
    required this.shortRef,
    required this.translator,
    required this.bookCount,
    required this.sectionCount,
    this.editionYear,
  });

  final String id;
  final String authorId;

  /// Meno autora ("Marcus Aurelius").
  final String author;

  /// Nazov diela ("On Anger", "To Marcia, On Consolation").
  final String title;

  /// Kratky nazov pre referencie ("On Anger", "To Marcia").
  final String shortRef;
  final String translator;
  final int? editionYear;
  final int bookCount;
  final int sectionCount;
}

/// Sekcia diela s textom (citacka).
@immutable
final class LibrarySection {
  const LibrarySection({
    required this.key,
    required this.workId,
    required this.ref,
    required this.text,
    required this.reference,
    this.book,
    this.title,
  });

  /// Stabilny `section.key`.
  final String key;
  final String workId;
  final int? book;

  /// "2.1" (bez nazvu diela).
  final String ref;

  /// Nadpis kapitoly (Discourses), ak je.
  final String? title;
  final String text;

  /// "Meditations 2.1".
  final String reference;

  /// Cislo sekcie v knihe ("1" z "2.1").
  String get number => ref.split('.').last;

  /// Odstavce (oddelene `\n\n`).
  List<String> get paragraphs => [
    for (final p in text.split('\n\n'))
      if (p.trim().isNotEmpty) p,
  ];
}

/// Kniha diela so sekciami (dielo bez knih ma jednu "knihu" s [number]
/// null).
@immutable
final class LibraryBook {
  const LibraryBook({
    required this.number,
    required this.title,
    required this.sections,
  });

  final int? number;
  final String? title;
  final List<LibrarySection> sections;
}

/// Cele dielo pre citacku.
@immutable
final class WorkText {
  const WorkText({required this.work, required this.books});

  final LibraryWork work;
  final List<LibraryBook> books;

  List<LibrarySection> get sections => [for (final b in books) ...b.sections];
}

/// Vysledok vyhladavania.
@immutable
final class SearchHit {
  const SearchHit({
    required this.sectionKey,
    required this.workId,
    required this.reference,
    required this.snippet,
  });

  final String sectionKey;
  final String workId;
  final String reference;

  /// Uryvok so zvyraznenim `[slovo]` ([snippetParts]).
  final String snippet;
}

/// Pozicia citania v diele.
@immutable
final class ReadingPosition {
  const ReadingPosition({
    required this.workId,
    required this.sectionKey,
    required this.updatedAt,
    this.offset = 0,
  });

  final String workId;
  final String sectionKey;
  final double offset;
  final DateTime updatedAt;
}

/// Zalozka na sekciu.
@immutable
final class SectionBookmark {
  const SectionBookmark({
    required this.sectionKey,
    required this.workId,
    required this.createdAt,
  });

  final String sectionKey;
  final String workId;
  final DateTime createdAt;
}

/// Library (F-01): diela z content.db v1, pozicia citania a zalozky
/// v user.db.
abstract interface class LibraryRepository {
  Future<List<LibraryAuthor>> authors();

  /// Dielo s textom, alebo null (dielo zaniklo).
  Future<WorkText?> work(String workId);

  /// Sekcia podla stabilneho kluca, alebo null.
  Future<LibrarySection?> section(String key);

  /// Fulltext (FTS5). Prazdny dotaz = prazdny vysledok.
  Future<List<SearchHit>> search(String query);

  Stream<Map<String, ReadingPosition>> watchPositions();

  /// Naposledy citane dielo (Today "Keep reading").
  Stream<ReadingPosition?> watchLastPosition();

  Future<void> savePosition(String workId, String sectionKey, {double offset});

  Stream<List<SectionBookmark>> watchBookmarks();

  Future<void> setBookmark(
    String sectionKey,
    String workId, {
    required bool on,
  });
}

/// [LibraryRepository] nad content.db a user.db.
class DriftLibraryRepository implements LibraryRepository {
  DriftLibraryRepository({
    required this._content,
    required UserDb userDb,
    this._clock = const Clock(),
  }) : _user = userDb;

  final Future<ContentDb> _content;
  final UserDb _user;
  final Clock _clock;

  Future<List<LibraryWork>>? _works;

  Future<List<LibraryWork>> _allWorks() => _works ??= () async {
    final db = await _content;
    final authors = {
      for (final a in await db.libraryDao.allAuthors()) a.id: a.name,
    };
    final years = {
      for (final s in await db.contentMetaDao.allSources()) s.id: s.editionYear,
    };
    return [
      for (final w in await db.libraryDao.allWorks())
        LibraryWork(
          id: w.id,
          authorId: w.authorId,
          author: authors[w.authorId] ?? '',
          title: w.title,
          shortRef: w.shortRef,
          translator: w.translator,
          editionYear: years[w.sourceId],
          bookCount: w.bookCount,
          sectionCount: w.sectionCount,
        ),
    ];
  }();

  @override
  Future<List<LibraryAuthor>> authors() async {
    final db = await _content;
    final works = await _allWorks();
    return [
      for (final a in await db.libraryDao.allAuthors())
        LibraryAuthor(
          id: a.id,
          name: a.name,
          lifespan: a.lifespan,
          works: [
            for (final w in works)
              if (w.authorId == a.id) w,
          ],
        ),
    ];
  }

  @override
  Future<WorkText?> work(String workId) async {
    final db = await _content;
    final work = (await _allWorks()).where((w) => w.id == workId).firstOrNull;
    if (work == null) return null;
    final titles = {
      for (final b in await db.libraryDao.booksOf(workId)) b.number: b.title,
    };
    final byBook = <int?, List<LibrarySection>>{};
    for (final s in await db.libraryDao.sectionsOf(workId)) {
      (byBook[s.book] ??= []).add(_section(s, work.shortRef));
    }
    return WorkText(
      work: work,
      books: [
        for (final e in byBook.entries)
          LibraryBook(number: e.key, title: titles[e.key], sections: e.value),
      ],
    );
  }

  @override
  Future<LibrarySection?> section(String key) async {
    final db = await _content;
    final s = await db.libraryDao.sectionByKey(key);
    if (s == null) return null;
    final work = (await _allWorks()).where((w) => w.id == s.workId).firstOrNull;
    return _section(s, work?.shortRef ?? s.workId);
  }

  static LibrarySection _section(SectionRow s, String shortRef) =>
      LibrarySection(
        key: s.key,
        workId: s.workId,
        book: s.book,
        ref: s.ref,
        title: s.title,
        text: s.textContent,
        reference: displayReference(shortRef, s.ref),
      );

  @override
  Future<List<SearchHit>> search(String query) async {
    final match = ftsQuery(query);
    if (match == null) return const [];
    final db = await _content;
    final refs = {for (final w in await _allWorks()) w.id: w.shortRef};
    return [
      for (final h in await db.libraryDao.search(match))
        SearchHit(
          sectionKey: h.key,
          workId: h.workId,
          reference: displayReference(refs[h.workId] ?? h.workId, h.ref),
          snippet: h.snippet,
        ),
    ];
  }

  @override
  Stream<Map<String, ReadingPosition>> watchPositions() => _user.readingDao
      .watchPositions()
      .map((rows) => {for (final r in rows) r.workId: _position(r)});

  @override
  Stream<ReadingPosition?> watchLastPosition() =>
      _user.readingDao.watchLast().map((r) => r == null ? null : _position(r));

  static ReadingPosition _position(ReadingPositionRow r) => ReadingPosition(
    workId: r.workId,
    sectionKey: r.sectionKey,
    offset: r.offset,
    updatedAt: r.updatedAt,
  );

  @override
  Future<void> savePosition(
    String workId,
    String sectionKey, {
    double offset = 0,
  }) => _user.readingDao.savePosition(
    workId,
    sectionKey,
    _clock.now(),
    offset: offset,
  );

  @override
  Stream<List<SectionBookmark>> watchBookmarks() =>
      _user.readingDao.watchBookmarks().map(
        (rows) => [
          for (final r in rows)
            SectionBookmark(
              sectionKey: r.sectionKey,
              workId: r.workId,
              createdAt: r.createdAt,
            ),
        ],
      );

  @override
  Future<void> setBookmark(
    String sectionKey,
    String workId, {
    required bool on,
  }) => on
      ? _user.readingDao.addBookmark(sectionKey, workId, _clock.now())
      : _user.readingDao.removeBookmark(sectionKey);
}
