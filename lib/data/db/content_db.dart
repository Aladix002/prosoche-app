import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:prosoche/data/db/content_tables.dart';
import 'package:prosoche/data/db/daos/content_meta_dao.dart';
import 'package:prosoche/data/db/daos/curated_dao.dart';
import 'package:sqlite3/sqlite3.dart';

export 'package:prosoche/data/db/content_tables.dart';

part 'content_db.g.dart';

/// content.db: obsah iba na citanie (plan 3.3, 07 ADR-04).
///
/// Subor vytvara pipeline `prosoche-content`; appka ho nikdy nevytvara ani
/// nemigruje. Verzia schemy = `PRAGMA user_version` kontraktu.
@DriftDatabase(tables: contentTables, daos: [ContentMetaDao, CuratedDao])
class ContentDb extends _$ContentDb {
  ContentDb(super.e);

  /// Otvori [file] v read-only rezime (zapis skonci chybou SQLite).
  ///
  /// SQLite bezi na pozadovom izolate (P-01): otvorenie suboru ani dotazy
  /// neblokuju UI izolat. Spojenie je `OpenMode.readOnly` a navyse
  /// `PRAGMA query_only = ON`. Chyby z izolatu sa rozbalia z
  /// [DriftRemoteException], takze volajuci vidia rovnake vynimky ako pri
  /// spojeni na UI izolate (napr. `SqliteException` pri zapise).
  factory ContentDb.openReadOnly(File file) => ContentDb(
    _readOnlyInBackground(file.absolute.path)
        .interceptWith(_UnwrapRemoteErrors()),
  );

  /// Spojenie na pozadovom izolate; izolat skonci pri [close].
  static DatabaseConnection _readOnlyInBackground(String path) =>
      DatabaseConnection.delayed(
        Future.sync(() async {
          // Subor sa otvori lenivo az pri ensureOpen v izolate: chyba
          // otvorenia (chybajuci/poskodeny subor) sa vrati dotazu. Chyba
          // priamo v openeri by spojenie nikdy nedokoncila.
          final isolate = await DriftIsolate.spawn(
            () => DatabaseConnection(
              _LazyReadOnly(() => NativeDatabase.opened(_openRaw(path))),
            ),
          );
          return await isolate.connect(singleClientMode: true);
        }),
      );

  /// Bezi v pozadovom izolate.
  static Database _openRaw(String path) =>
      sqlite3.open(path, mode: OpenMode.readOnly)
        ..execute('PRAGMA query_only = ON');

  /// Verzia kontraktu `content_schema.sql` (`schema_version` v `meta`).
  static const contractVersion = 1;

  @override
  int get schemaVersion => contractVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => throw StateError(
      'content.db is created by the content pipeline, not by the app',
    ),
    onUpgrade: (m, from, to) async => throw StateError(
      'content.db schema $from is not supported (app expects $to)',
    ),
  );
}

/// [LazyDatabase], ktora po neuspesnom otvoreni zavrie bez chyby. Inak by
/// `close` pri ukonceni izolatu znova vyhodil chybu otvorenia (unhandled),
/// izolat by spadol a klient by na `close` cakal navzdy.
final class _LazyReadOnly extends LazyDatabase {
  _LazyReadOnly(super.opener);

  @override
  Future<void> close() async {
    try {
      await super.close();
    } on Object {
      // Nic nebolo otvorene, niet co zatvarat.
    }
  }
}

/// Vrati povodnu chybu z pozadoveho izolatu namiesto [DriftRemoteException].
final class _UnwrapRemoteErrors extends QueryInterceptor {
  _UnwrapRemoteErrors();

  Future<T> _unwrap<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DriftRemoteException catch (e) {
      // Chyba migracie ide klient -> izolat -> klient: obalena dvakrat.
      var cause = e;
      for (
        var c = e.remoteCause;
        c is DriftRemoteException;
        c = c.remoteCause
      ) {
        cause = c;
      }
      Error.throwWithStackTrace(
        cause.remoteCause,
        cause.remoteStackTrace ?? StackTrace.current,
      );
    }
  }

  @override
  Future<bool> ensureOpen(QueryExecutor executor, QueryExecutorUser user) =>
      _unwrap(() => super.ensureOpen(executor, user));

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _unwrap(() => super.runSelect(executor, statement, args));

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _unwrap(() => super.runCustom(executor, statement, args));

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _unwrap(() => super.runInsert(executor, statement, args));

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _unwrap(() => super.runUpdate(executor, statement, args));

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _unwrap(() => super.runDelete(executor, statement, args));

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) => _unwrap(() => super.runBatched(executor, statements));
}
