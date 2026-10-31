// Plna content.db z pipeline `sakina-content` pre testy F-04, ktore
// potrebuju skutocny text (bajtova zhoda, vykon vyhladavania, goldeny).
// Subor sa necommituje; testy sa bez neho preskocia.
//
//   SAKINA_CONTENT_DB=../sakina-content/dist/content.db flutter test \
//     test/features/quran/full_db
//
// Default: ../sakina-content/dist/content.db vedla repa.
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sakina/data/db/content_db.dart';
import 'package:sakina/data/db/user_db.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../fakes/in_memory_settings_repository.dart';

/// Cesta k plnej content.db alebo null (testy sa preskocia).
String? fullContentDbPath() {
  final candidates = [
    Platform.environment['SAKINA_CONTENT_DB'],
    '../sakina-content/dist/content.db',
  ];
  for (final c in candidates) {
    if (c != null && c.isNotEmpty && File(c).existsSync()) return c;
  }
  return null;
}

/// Dovod preskocenia pre `skip:`.
String? get fullDbSkip => fullContentDbPath() == null
    ? 'Plna content.db nie je dostupna (SAKINA_CONTENT_DB)'
    : null;

/// [ContentDb] nad plnou db iba na citanie. Verzia schemy sa berie zo
/// suboru (`PRAGMA user_version`), aby drift nemigroval: pipeline uz
/// vydava schemu v3, app kontrakt je zatial v2 (D-06).
class FullContentDb extends ContentDb {
  FullContentDb._(super.e, this._version);

  factory FullContentDb.open(String path) {
    final raw = sqlite3.open(path, mode: OpenMode.readOnly);
    final version = raw.select('PRAGMA user_version').first.values.first;
    return FullContentDb._(NativeDatabase.opened(raw), version! as int);
  }

  final int _version;

  @override
  int get schemaVersion => _version;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) async => throw StateError('read only'));
}

/// Skutocny [DriftQuranRepository] nad plnou content.db a in-memory
/// user.db (ako v appke).
({DriftQuranRepository repo, ContentDb content, UserDb user}) openFullQuran(
  String path,
) {
  final content = FullContentDb.open(path);
  final user = UserDb.memory();
  final repo = DriftQuranRepository(
    content: Future.value(content),
    userDb: user,
    settings: InMemorySettingsRepository(),
    clock: Clock.fixed(DateTime(2026, 10, 29, 9)),
  );
  return (repo: repo, content: content, user: user);
}
