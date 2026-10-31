import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:sqlite3/sqlite3.dart';

import 'fixtures/content_fixture.dart';
import 'fixtures/schema_compare.dart';

class _CreatableContentDb extends ContentDb {
  _CreatableContentDb(super.e);

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) => m.createAll());
}

void main() {
  // Kazdy test otvara novu DB nad vlastnym spojenim.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Database contract;
  late Database fromDrift;

  setUpAll(() async {
    contract = sqlite3.openInMemory()
      ..execute(File(contractPath).readAsStringSync());
    fromDrift = sqlite3.openInMemory();
    // ContentDb sama schemu nevytvara; v teste ju vytvori createAll().
    final db = _CreatableContentDb(
      NativeDatabase.opened(fromDrift, closeUnderlyingOnClose: false),
    );
    await db.customSelect('SELECT 1').get();
    await db.close();
  });

  tearDownAll(() {
    contract.close();
    fromDrift.close();
  });

  test('drift has exactly the tables of the contract', () {
    expect(plainTables(fromDrift), plainTables(contract));
    expect(plainTables(contract), hasLength(contentTables.length));
  });

  test('every table matches the contract (columns, PK, FK, UNIQUE)', () {
    for (final table in plainTables(contract)) {
      final expected = describeTable(contract, table);
      expect(expected['columns'], isNotEmpty, reason: table);
      expect(describeTable(fromDrift, table), expected, reason: 'table $table');
    }
  });

  test('contract declares the schema_version of the app', () {
    // user_version nastavuje pipeline (build_db), schema ju deklaruje
    // v hlavicke a v `meta.schema_version`.
    expect(
      File(contractPath).readAsStringSync(),
      contains('schema_version: ${ContentDb.contractVersion}'),
    );
  });

  test('FTS5 table is part of the contract', () {
    expect(
      contract
          .select("SELECT name FROM sqlite_master WHERE name = 'section_fts'")
          .single['name'],
      'section_fts',
    );
  });

  test('local contract copy equals prosoche-content (when available)', () {
    final upstream = findUpstreamContract('content_schema.sql');
    if (upstream == null) {
      markTestSkipped('prosoche-content not found next to prosoche-app');
      return;
    }
    expect(
      File(contractPath).readAsStringSync(),
      upstream.readAsStringSync(),
      reason:
          'Kontrakt sa zmenil: skopiruj ${upstream.path} do $contractPath '
          'a uprav content_tables.dart.',
    );
  });
}
