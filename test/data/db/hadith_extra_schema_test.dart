import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/db/hadith_extra_db.dart';
import 'package:sqlite3/sqlite3.dart';

import 'fixtures/hadith_extra_fixture.dart';
import 'fixtures/schema_compare.dart';

class _CreatableHadithExtraDb extends HadithExtraDb {
  _CreatableHadithExtraDb(super.e);

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) => m.createAll());
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Database contract;
  late Database fromDrift;

  setUpAll(() async {
    contract = sqlite3.openInMemory()
      ..execute(File(hadithExtraContractPath).readAsStringSync());
    fromDrift = sqlite3.openInMemory();
    final db = _CreatableHadithExtraDb(
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
    expect(plainTables(contract), hasLength(hadithExtraTables.length));
  });

  test('every table matches the contract (columns, PK, FK, UNIQUE)', () {
    for (final table in plainTables(contract)) {
      final expected = describeTable(contract, table);
      expect(expected['columns'], isNotEmpty, reason: table);
      expect(describeTable(fromDrift, table), expected, reason: 'table $table');
    }
  });

  test('contract user_version is the supported pack schema', () {
    expect(
      contract.select('PRAGMA user_version').single.values.single,
      HadithExtraDb.contractVersion,
    );
  });

  test('local contract copy equals prosoche-content (when available)', () {
    final upstream = findUpstreamContract('hadith_extra_schema.sql');
    if (upstream == null) {
      markTestSkipped('prosoche-content not found next to prosoche-app');
      return;
    }
    expect(
      File(hadithExtraContractPath).readAsStringSync(),
      upstream.readAsStringSync(),
      reason:
          'Kontrakt sa zmenil: skopiruj ${upstream.path} do '
          '$hadithExtraContractPath a uprav hadith_extra_tables.dart.',
    );
  });
}
