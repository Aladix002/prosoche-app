// Maly hadith_extra.db pre testy: schema z kontraktu
// `drift_schemas/content/hadith_extra_schema.sql` + vysvetlivky k hadisom
// 11 a 12 z content_fixture.dart s placeholder textom (PLAN_VYVOJA 5.5).
//
// Ako skript zapise fixture do suboru:
//   dart run test/data/db/fixtures/hadith_extra_fixture.dart /tmp/extra.db
import 'dart:io';

import 'package:drift/native.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/data/db/hadith_extra_db.dart';
import 'package:sqlite3/sqlite3.dart';

/// Cesta ku kopii kontraktu (testy bezia z korena balika).
const hadithExtraContractPath = 'drift_schemas/content/hadith_extra_schema.sql';

/// Vytvori fixture v [path] (`:memory:` = v pamati) a vrati otvorene
/// spojenie. [meta] prepise hodnoty v `meta` (kontrola kompatibility).
Database buildHadithExtraFixture([
  String path = ':memory:',
  Map<String, String> meta = const {},
]) {
  final db = sqlite3.open(path)
    ..execute(File(hadithExtraContractPath).readAsStringSync())
    ..execute('BEGIN');
  for (final e in {
    'pack_id': HadithExtraDb.packId,
    'schema_version': '${HadithExtraDb.contractVersion}',
    'base_schema_version': '${ContentDb.contractVersion}',
    'content_version': '7',
    'created_at': '2026-01-01T00:00:00Z',
    'langs': '["en"]',
    'row_count': '2',
    ...meta,
  }.entries) {
    db.execute('INSERT INTO meta (key, value) VALUES (?, ?)', [e.key, e.value]);
  }
  db
    ..execute(
      'INSERT INTO source (id, kind, lang, name, version, license, '
      'license_text, attribution, url, commercial_status) VALUES '
      "('fx-hadith', 'hadith', 'en', 'Fixture fx-hadith', '1', 'test-only', "
      "'[PLACEHOLDER license]', '[PLACEHOLDER attribution]', "
      "'https://example.invalid/fx-hadith', 'allowed')",
    )
    ..execute('INSERT INTO hadith_explanation VALUES (?, ?, ?, ?, ?)', [
      11,
      'en',
      '[PLACEHOLDER explanation 11]',
      r'["[PLACEHOLDER hint 1]\r", "[PLACEHOLDER hint 2]"]',
      'fx-hadith',
    ])
    ..execute('INSERT INTO hadith_explanation VALUES (?, ?, ?, ?, ?)', [
      12,
      'en',
      null,
      '["[PLACEHOLDER hint only]"]',
      'fx-hadith',
    ])
    ..execute('COMMIT');
  return db;
}

/// Fixture ako [HadithExtraDb] v pamati.
HadithExtraDb openHadithExtraFixture() =>
    HadithExtraDb(NativeDatabase.opened(buildHadithExtraFixture()));

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('usage: hadith_extra_fixture.dart <out.db>');
    exitCode = 64;
    return;
  }
  final out = File(args.single);
  if (out.existsSync()) out.deleteSync();
  buildHadithExtraFixture(out.path).close();
  stdout.writeln('wrote ${out.path}');
}
