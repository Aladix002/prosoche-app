import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/data/db/content_db.dart';
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

  test('contract defines FTS5 tables and its user_version', () {
    final fts = [
      for (final r in contract.select(
        "SELECT name FROM sqlite_master WHERE sql LIKE '%USING fts5%' "
        'ORDER BY name',
      ))
        r['name'],
    ];
    expect(fts, ['ayah_fts', 'translation_fts']);
    expect(
      contract.select('PRAGMA user_version').single.values.single,
      ContentDb.contractVersion,
    );
  });

  test('local contract copy equals sakina-content (when available)', () {
    final upstream = findUpstreamContract('content_schema.sql');
    if (upstream == null) {
      markTestSkipped('sakina-content not found next to sakina-app');
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
