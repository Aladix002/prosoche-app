// Maly content.db pre testy: schema z prechodneho kontraktu
// `drift_schemas/content/content_schema.sql` + par placeholder citatov
// a sablon questov. Ziadny skutocny obsah (PLAN_VYVOJA 5.5).
//
// Ako skript zapise fixture do suboru:
//   dart run test/data/db/fixtures/content_fixture.dart /tmp/content.db
import 'dart:io';

import 'package:drift/native.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:sqlite3/sqlite3.dart';

/// Cesta ku kopii kontraktu (testy bezia z korena balika).
const contractPath = 'drift_schemas/content/content_schema.sql';

/// Pocet schvalenych citatov vo fixture (`q_0001` az `q_0020`).
const fixtureQuoteCount = 20;

/// ID citatu vo fixture.
String fixtureQuoteId(int n) => 'q_${n.toString().padLeft(4, '0')}';

/// Vytvori fixture v [path] (`:memory:` = v pamati) a vrati otvorene
/// spojenie.
Database buildContentFixture([String path = ':memory:']) {
  final db = sqlite3.open(path)..execute(File(contractPath).readAsStringSync());
  _fill(db);
  return db;
}

/// Fixture ako [ContentDb] v pamati.
ContentDb openContentFixture() =>
    ContentDb(NativeDatabase.opened(buildContentFixture()));

void _fill(Database db) {
  void insert(String table, List<Map<String, Object?>> rows) {
    for (final row in rows) {
      final cols = row.keys.join(', ');
      final qs = List.filled(row.length, '?').join(', ');
      db.execute(
        'INSERT INTO "$table" ($cols) VALUES ($qs)',
        row.values.toList(),
      );
    }
  }

  db.execute('BEGIN');
  insert('meta', [
    {'key': 'schema_version', 'value': '${ContentDb.contractVersion}'},
    {'key': 'dev_content', 'value': '1'},
    {'key': 'content_version', 'value': 'fixture'},
    {'key': 'langs', 'value': '["en"]'},
  ]);
  insert('source', [
    {
      'id': 'fx-text',
      'kind': 'text',
      'lang': 'en',
      'name': 'Fixture text',
      'version': '1',
      'license': 'test-only',
      'license_text': '[PLACEHOLDER license]',
      'attribution': '[PLACEHOLDER attribution]',
      'url': 'https://example.invalid/fx-text',
      'commercial_status': 'allowed',
    },
    {
      'id': 'fx-curated',
      'kind': 'curated',
      'lang': 'en',
      'name': 'Fixture curated',
      'version': '1',
      'license': 'test-only',
      'license_text': '[PLACEHOLDER license]',
      'attribution': '[PLACEHOLDER curated]',
      'url': 'https://example.invalid/fx-curated',
      'commercial_status': 'allowed',
    },
  ]);
  insert('quote', [
    for (var n = 1; n <= fixtureQuoteCount; n++)
      {
        'id': fixtureQuoteId(n),
        'status': 'approved',
        'origin': 'placeholder',
        'text': '[PLACEHOLDER quote $n]',
        'author': '[PLACEHOLDER author]',
        'work': '[PLACEHOLDER work]',
        'ref': '1.$n',
        'tags': n.isEven ? '["even"]' : '[]',
        'time_of_day': n == 1 ? 'morning' : 'any',
        'weight': 1.0,
        'source_id': 'fx-text',
      },
    // Neschvaleny a vyradeny citat sa do feedu nedostanu.
    {
      'id': 'q_draft',
      'status': 'draft',
      'origin': 'placeholder',
      'text': '[PLACEHOLDER draft]',
      'author': '[PLACEHOLDER author]',
      'work': '[PLACEHOLDER work]',
      'ref': null,
      'tags': 'not json',
      'source_id': 'fx-text',
    },
    {
      'id': 'q_retired',
      'status': 'retired',
      'origin': 'placeholder',
      'text': '[PLACEHOLDER retired]',
      'author': '[PLACEHOLDER author]',
      'work': '[PLACEHOLDER work]',
      'ref': null,
      'tags': '[]',
      'source_id': 'fx-text',
    },
  ]);
  insert('quest_template', [
    {
      'id': 'read.quotes_n',
      'status': 'approved',
      'origin': 'placeholder',
      'slot': 'read',
      'rule_json':
          '{"count": {"type": ["quote", "passage"], "min": {"param": "n"}},'
          ' "params": {"n": [3, 4]}}',
      'tags': '[]',
      'cooldown_days': 7,
    },
    {
      'id': 'learn.idea',
      'status': 'approved',
      'origin': 'placeholder',
      'slot': 'learn',
      'rule_json':
          '{"completion": {"mode": "auto", "metric": "idea_learned",'
          ' "target": 1}}',
      'tags': '[]',
      'facets_json': '{"excused_ok": true}',
    },
    {
      'id': 'act.placeholder',
      'status': 'approved',
      'origin': 'placeholder',
      'slot': 'act',
      'rule_json': '{}',
      'tags': '[]',
    },
    {
      'id': 'act.draft',
      'status': 'draft',
      'origin': 'placeholder',
      'slot': 'act',
      'rule_json': '{}',
      'tags': '[]',
    },
    {
      'id': 'read.broken',
      'status': 'approved',
      'origin': 'placeholder',
      'slot': 'read',
      'rule_json': '{"count": {"type": "unknown_type", "min": 1}}',
      'tags': '[]',
    },
  ]);
  insert('quest_text', [
    for (final id in ['read.quotes_n', 'learn.idea', 'act.placeholder'])
      {
        'quest_id': id,
        'lang': 'en',
        'title': '[PLACEHOLDER quest $id]',
        'body': null,
        'source_id': 'fx-curated',
      },
  ]);
  db.execute('COMMIT');
}

void main(List<String> args) {
  final path = args.isEmpty ? 'content_fixture.db' : args.first;
  final f = File(path);
  if (f.existsSync()) f.deleteSync();
  buildContentFixture(path).close();
  stdout.writeln('content fixture: $path');
}
