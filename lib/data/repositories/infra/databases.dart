import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/data/db/journal_db.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/domain/common/common.dart';

/// Odkial sa berie otvorena content.db (dohoda D-02 / D-03).
///
/// D-03 (`lib/data/content/`) dodá implementaciu: instalacia pribalenej db,
/// kontrola integrity (plan 17.3), aktualizacia a atomicky rename. Repozitare
/// D-02 poznaju len toto rozhranie. Vlastnictvo vratenej [ContentDb]
/// prechadza na [contentDbProvider], ktory ju pri dispose zavrie; po
/// aktualizacii obsahu staci `ref.invalidate(contentDbProvider)`.
abstract interface class ContentDbSource {
  /// Otvori aktualnu content.db (iba citanie). Pri zlyhani integrity aj
  /// pribalenej db hodi chybu, obrazovky ukazu fatalny stav (O1).
  Future<ContentDb> open();
}

/// Override point pre D-03 (bootstrap):
/// `contentDbSourceProvider.overrideWithValue(ContentPackDbSource(...))`.
final Provider<ContentDbSource> contentDbSourceProvider =
    Provider<ContentDbSource>(
      (ref) => throw UnimplementedError(
        'contentDbSourceProvider: override with the D-03 ContentDbSource',
      ),
      name: 'contentDbSourceProvider',
    );

/// Otvorena content.db. Repozitare drzia `Future<ContentDb>`, takze
/// providery repozitarov su synchronne.
final FutureProvider<ContentDb> contentDbProvider = FutureProvider<ContentDb>((
  ref,
) async {
  final db = await ref.watch(contentDbSourceProvider).open();
  ref.onDispose(db.close);
  return db;
}, name: 'contentDbProvider');

/// `disabled_ids` z manifestu obsahu (plan 5.1, docs/03 7.4). Default
/// prazdne; D-03 prepise providerom nad svojim stavom.
final Provider<Set<CardId>> disabledCardIdsProvider = Provider<Set<CardId>>(
  (ref) => const {},
  name: 'disabledCardIdsProvider',
);

/// user.db v `getApplicationSupportDirectory()/user.db` (WAL, docs/02 D14).
///
/// Otvara sa lenivo (`LazyDatabase`), provider je synchronny. V testoch
/// `userDbProvider.overrideWithValue(UserDb.memory())`.
final Provider<UserDb> userDbProvider = Provider<UserDb>((ref) {
  final db = UserDb(
    LazyDatabase(() async {
      final dir = await getApplicationSupportDirectory();
      return NativeDatabase.createInBackground(
        File(p.join(dir.path, userDbFileName)),
        setup: configureUserDbConnection,
      );
    }),
    // Migracia v2 -> v3 (C-02): dennik zo starej user.db do journal.db.
    legacyJournal: (rows) async {
      final dir = await getApplicationSupportDirectory();
      await importLegacyJournal(
        File(p.join(dir.path, journalDbFileName)),
        rows,
      );
    },
  );
  ref.onDispose(db.close);
  return db;
}, name: 'userDbProvider');

/// Nazov suboru user.db (export F-09 a "Delete all my data" ho potrebuju).
const userDbFileName = 'user.db';

/// journal.db (dennik, C-02) v `getApplicationSupportDirectory()`. Android
/// zaloha ju nezahrna (zalohuje sa len user.db). V testoch
/// `journalDbProvider.overrideWithValue(JournalDb.memory())`.
///
/// Pred prvym dotazom pocka na otvorenie user.db, aby migracia v2 -> v3
/// stihla presunut stary dennik.
final Provider<JournalDb> journalDbProvider = Provider<JournalDb>((ref) {
  final user = ref.watch(userDbProvider);
  final db = JournalDb(
    LazyDatabase(() async {
      await user.customSelect('SELECT 1').get();
      final dir = await getApplicationSupportDirectory();
      return NativeDatabase.createInBackground(
        File(p.join(dir.path, journalDbFileName)),
        setup: configureJournalDbConnection,
      );
    }),
  );
  ref.onDispose(db.close);
  return db;
}, name: 'journalDbProvider');
