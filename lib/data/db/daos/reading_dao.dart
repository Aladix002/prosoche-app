import 'package:drift/drift.dart';
import 'package:prosoche/data/db/user_db.dart';

part 'reading_dao.g.dart';

/// Pozicia citania a zalozky sekcii (Library, F-01). Kluce su stabilne
/// `work.id` a `section.key` z content.db.
@DriftAccessor(tables: [ReadingPositions, SectionBookmarks])
class ReadingDao extends DatabaseAccessor<UserDb> with _$ReadingDaoMixin {
  ReadingDao(super.attachedDatabase);

  /// Ulozi poziciu citania v diele [workId].
  Future<void> savePosition(
    String workId,
    String sectionKey,
    DateTime now, {
    double offset = 0,
  }) => into(readingPositions).insertOnConflictUpdate(
    ReadingPositionsCompanion.insert(
      workId: workId,
      sectionKey: sectionKey,
      offset: Value(offset.clamp(0, 1).toDouble()),
      updatedAt: now,
    ),
  );

  Future<ReadingPositionRow?> position(String workId) => (select(
    readingPositions,
  )..where((t) => t.workId.equals(workId))).getSingleOrNull();

  /// Pozicie vo vsetkych dielach, posledne citane prve.
  Stream<List<ReadingPositionRow>> watchPositions() => (select(
    readingPositions,
  )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  /// Naposledy citane dielo (Today "Keep reading").
  Stream<ReadingPositionRow?> watchLast() =>
      (select(readingPositions)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
            ..limit(1))
          .watchSingleOrNull();

  // ------------------------------------------------------------ zalozky

  Future<void> addBookmark(String sectionKey, String workId, DateTime now) =>
      into(sectionBookmarks).insert(
        SectionBookmarksCompanion.insert(
          sectionKey: sectionKey,
          workId: workId,
          createdAt: now,
        ),
        onConflict: DoNothing(),
      );

  Future<void> removeBookmark(String sectionKey) => (delete(
    sectionBookmarks,
  )..where((t) => t.sectionKey.equals(sectionKey))).go();

  /// Zalozky, najnovsie prve.
  Stream<List<SectionBookmarkRow>> watchBookmarks() => (select(
    sectionBookmarks,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
}
