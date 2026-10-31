import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/data/repositories/cards/card_content_repository.dart';
import 'package:prosoche/data/repositories/infra/databases.dart';
import 'package:prosoche/data/repositories/infra/time_providers.dart';
import 'package:prosoche/data/repositories/library/library_repository.dart';
import 'package:prosoche/data/repositories/practice/practice_repository.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/practice/practice.dart';

// ------------------------------------------------------------------ Library

final Provider<LibraryRepository> libraryRepositoryProvider =
    Provider<LibraryRepository>(
      (ref) => DriftLibraryRepository(
        content: ref.watch(contentDbProvider.future),
        userDb: ref.watch(userDbProvider),
        clock: ref.watch(appClockProvider),
      ),
      name: 'libraryRepositoryProvider',
    );

/// Autori a diela (zoznam Library).
final FutureProvider<List<LibraryAuthor>> libraryAuthorsProvider =
    FutureProvider<List<LibraryAuthor>>(
      (ref) => ref.watch(libraryRepositoryProvider).authors(),
      name: 'libraryAuthorsProvider',
    );

/// Cele dielo pre citacku (null = dielo nie je v obsahu).
final FutureProviderFamily<WorkText?, String> workTextProvider =
    FutureProvider.family<WorkText?, String>(
      (ref, id) => ref.watch(libraryRepositoryProvider).work(id),
      name: 'workTextProvider',
    );

/// Sekcia podla `section.key`.
final FutureProviderFamily<LibrarySection?, String> sectionProvider =
    FutureProvider.family<LibrarySection?, String>(
      (ref, key) => ref.watch(libraryRepositoryProvider).section(key),
      name: 'sectionProvider',
    );

/// Fulltext (FTS5) pre dotaz.
final FutureProviderFamily<List<SearchHit>, String> librarySearchProvider =
    FutureProvider.family<List<SearchHit>, String>(
      (ref, q) => ref.watch(libraryRepositoryProvider).search(q),
      name: 'librarySearchProvider',
    );

final StreamProvider<Map<String, ReadingPosition>> readingPositionsProvider =
    StreamProvider<Map<String, ReadingPosition>>(
      (ref) => ref.watch(libraryRepositoryProvider).watchPositions(),
      name: 'readingPositionsProvider',
    );

/// Naposledy citane dielo (Today "Keep reading").
final StreamProvider<ReadingPosition?> lastReadingProvider =
    StreamProvider<ReadingPosition?>(
      (ref) => ref.watch(libraryRepositoryProvider).watchLastPosition(),
      name: 'lastReadingProvider',
    );

final StreamProvider<List<SectionBookmark>> sectionBookmarksProvider =
    StreamProvider<List<SectionBookmark>>(
      (ref) => ref.watch(libraryRepositoryProvider).watchBookmarks(),
      name: 'sectionBookmarksProvider',
    );

// ----------------------------------------------------------------- Practice

final Provider<PracticeRepository> practiceRepositoryProvider =
    Provider<PracticeRepository>(
      (ref) => DriftPracticeRepository(
        content: ref.watch(contentDbProvider.future),
        userDb: ref.watch(userDbProvider),
        journalDb: ref.watch(journalDbProvider),
        library: ref.watch(libraryRepositoryProvider),
        clock: ref.watch(appClockProvider),
      ),
      name: 'practiceRepositoryProvider',
    );

/// Rutina dna (ranna/vecerna) pre dnesny `localDate`.
final FutureProviderFamily<PracticeRoutine, RoutineKind>
practiceRoutineProvider = FutureProvider.family<PracticeRoutine, RoutineKind>(
  (ref, kind) => ref
      .watch(practiceRepositoryProvider)
      .routine(kind, ref.watch(localDateProvider)),
  name: 'practiceRoutineProvider',
);

/// Vsetky cvicenia z obsahu.
final FutureProvider<List<PracticeContent>> practicesProvider =
    FutureProvider<List<PracticeContent>>(
      (ref) => ref.watch(practiceRepositoryProvider).practices(),
      name: 'practicesProvider',
    );

final StreamProvider<List<JournalEntry>> journalProvider =
    StreamProvider<List<JournalEntry>>(
      (ref) => ref.watch(practiceRepositoryProvider).watchJournal(),
      name: 'journalProvider',
    );

/// Dokoncene rutiny dna.
final StreamProviderFamily<Set<RoutineKind>, LocalDate> practiceDoneProvider =
    StreamProvider.family<Set<RoutineKind>, LocalDate>(
      (ref, date) => ref.watch(practiceRepositoryProvider).watchDone(date),
      name: 'practiceDoneProvider',
    );
