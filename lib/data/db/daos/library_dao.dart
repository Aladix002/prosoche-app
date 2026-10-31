import 'package:drift/drift.dart';
import 'package:prosoche/data/db/content_db.dart';

part 'library_dao.g.dart';

/// Vysledok fulltextu (kontrakt kap. 7): sekcia a uryvok so zvyraznenim
/// v hranatych zatvorkach `[slovo]`.
typedef SectionHit = ({String key, String workId, String ref, String snippet});

/// Library: autori, diela, knihy, sekcie a FTS5 (kontrakt kap. 3, 7).
@DriftAccessor(tables: [Authors, Works, Books, Sections])
class LibraryDao extends DatabaseAccessor<ContentDb> with _$LibraryDaoMixin {
  LibraryDao(super.attachedDatabase);

  Future<List<AuthorRow>> allAuthors() =>
      (select(authors)..orderBy([(t) => OrderingTerm.asc(t.ord)])).get();

  Future<List<WorkRow>> allWorks() =>
      (select(works)..orderBy([(t) => OrderingTerm.asc(t.ord)])).get();

  Future<WorkRow?> workById(String id) =>
      (select(works)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<BookRow>> booksOf(String workId) =>
      (select(books)
            ..where((t) => t.workId.equals(workId))
            ..orderBy([(t) => OrderingTerm.asc(t.number)]))
          .get();

  /// Sekcie diela (s textom) v poradi `section.id`.
  Future<List<SectionRow>> sectionsOf(String workId) =>
      (select(sections)
            ..where((t) => t.workId.equals(workId))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  Future<SectionRow?> sectionByKey(String key) =>
      (select(sections)..where((t) => t.key.equals(key))).getSingleOrNull();

  /// Fulltext nad `section_fts`. [match] je uz escapovany FTS5 vyraz.
  Future<List<SectionHit>> search(String match, {int limit = 50}) async {
    final rows = await customSelect(
      'SELECT s.key AS key, s.work_id AS work_id, s.ref AS ref, '
      "snippet(section_fts, 1, '[', ']', '...', 12) AS snip "
      'FROM section_fts JOIN section s ON s.id = section_fts.rowid '
      'WHERE section_fts MATCH ? ORDER BY rank LIMIT ?',
      variables: [Variable.withString(match), Variable.withInt(limit)],
      readsFrom: {sections},
    ).get();
    return [
      for (final r in rows)
        (
          key: r.read<String>('key'),
          workId: r.read<String>('work_id'),
          ref: r.read<String>('ref'),
          snippet: r.read<String>('snip'),
        ),
    ];
  }
}
