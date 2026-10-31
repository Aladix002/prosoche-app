// Porovnanie drift schemy s SQL kontraktom zo prosoche-content (D-01, D-06).
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Strukturny popis tabulky z PRAGMA (CHECK obmedzenia su len v kontrakte).
Map<String, Object?> describeTable(Database db, String table) {
  List<String> rows(String sql) => [
    for (final r in db.select(sql)) r.values.map((v) => '$v').join('|'),
  ];
  final uniques = <String>[];
  for (final idx in db.select('PRAGMA index_list("$table")')) {
    if (idx['origin'] == 'c') continue;
    final cols = [
      for (final c in db.select('PRAGMA index_info("${idx['name']}")'))
        c['name'],
    ];
    uniques.add('${idx['origin']}:${idx['unique']}:${cols.join(',')}');
  }
  uniques.sort();
  return {
    'columns': rows(
      'SELECT name, upper(type), "notnull", dflt_value, pk '
      "FROM pragma_table_info('$table') ORDER BY cid",
    ),
    'foreign_keys': rows(
      'SELECT "table", "from", "to" '
      "FROM pragma_foreign_key_list('$table') "
      'ORDER BY "from"',
    )..sort(),
    'unique': uniques,
  };
}

/// Bezne tabulky (bez FTS5 a ich tienovych tabuliek).
List<String> plainTables(Database db) => [
  for (final r in db.select(
    "SELECT name, sql FROM sqlite_master WHERE type = 'table' "
    "AND name NOT LIKE 'sqlite_%' ORDER BY name",
  ))
    if (!(r['sql'] as String).contains('VIRTUAL TABLE') &&
        !(r['name'] as String).contains('_fts'))
      r['name'] as String,
];

/// Najde `prosoche-content/schema/<name>` v nadradenych adresaroch (lokalne
/// vedla prosoche-app; v CI nie je).
File? findUpstreamContract(String name) =>
    findProsocheContentFile(['schema', name]);

/// Najde subor `prosoche-content/<parts>` v nadradenych adresaroch.
File? findProsocheContentFile(List<String> parts) {
  var dir = Directory.current.absolute;
  while (true) {
    final f = File(p.joinAll([dir.path, 'prosoche-content', ...parts]));
    if (f.existsSync()) return f;
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}
