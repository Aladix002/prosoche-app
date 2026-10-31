// Maly content.db v1 pre testy: schema z kontraktu
// `drift_schemas/content/content_schema.sql` + placeholder autori, diela,
// sekcie a karty vsetkych typov. Ziadny skutocny text filozofov
// (PLAN_VYVOJA 5.5): texty su `[PLACEHOLDER ...]`.
//
// Ako skript zapise fixture do suboru:
//   dart run test/data/db/fixtures/content_fixture.dart /tmp/content.db
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:sqlite3/sqlite3.dart';

/// Cesta ku kopii kontraktu (testy bezia z korena balika).
const contractPath = 'drift_schemas/content/content_schema.sql';

/// Pocet citatov vo fixture (`quote:q_0001` az `quote:q_0020`).
const fixtureQuoteCount = 20;

/// Kluc citatu vo fixture (cast za `quote:`).
String fixtureQuoteId(int n) => 'q_${n.toString().padLeft(4, '0')}';

/// Pocet vsetkych kariet fixture (20 citatov, 4 uryvky, 5 cviceni,
/// 5 otazok, 3 pojmy, 2 autori).
const fixtureCardCount = 39;

/// Diela fixture: `work-books` (2 knihy po 3 sekcie), `work-flat`
/// (4 sekcie bez knih).
const fixtureWorks = ['work-books', 'work-flat'];

/// Kluce sekcii v poradi `section.id`.
const fixtureSectionKeys = [
  'work-books.1.1',
  'work-books.1.2',
  'work-books.1.3',
  'work-books.2.1',
  'work-books.2.2',
  'work-books.2.3',
  'work-flat.1',
  'work-flat.2',
  'work-flat.3',
  'work-flat.4',
];

/// Text sekcie: dva odstavce, druhy obsahuje citaty, ktore k nej patria.
String fixtureSectionText(String key) {
  final i = fixtureSectionKeys.indexOf(key);
  final quotes = [
    for (var n = 1; n <= fixtureQuoteCount; n++)
      if ((n - 1) % fixtureSectionKeys.length == i) '[PLACEHOLDER quote $n]',
  ];
  final word = i.isEven ? 'attention' : 'river';
  return '[PLACEHOLDER section $key] $word.\n\n${quotes.join(' ')}';
}

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

String _sha(String s) => sha256.convert(utf8.encode(s)).toString();

/// Prepocita `meta.sections_sha256` (po zmene sekcii v teste).
void refreshSectionsSha(Database db) {
  final buf = StringBuffer();
  for (final r in db.select('SELECT key, sha256 FROM section ORDER BY id')) {
    buf.write('${r['key']}\t${r['sha256']}\n');
  }
  db.execute("UPDATE meta SET value = ? WHERE key = 'sections_sha256'", [
    _sha('$buf'),
  ]);
}

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
    {'key': 'normalization', 'value': 'ws1'},
    {'key': 'section_hash_algo', 'value': 'sha256-utf8'},
    {'key': 'sections_sha256', 'value': ''},
  ]);
  insert('source', [
    {
      'id': 'fx-text',
      'kind': 'text',
      'name': '[PLACEHOLDER edition]',
      'translator': 'Fixture Translator',
      'translator_died': 1900,
      'edition_year': 1880,
      'version': 'fx1',
      'license': 'public-domain',
      'license_note': '[PLACEHOLDER license note]',
      'attribution': '[PLACEHOLDER attribution]',
      'url': 'https://example.invalid/fx-text',
    },
    {
      'id': 'prosoche-curated',
      'kind': 'curated',
      'name': '[PLACEHOLDER curated]',
      'version': '1',
      'license': 'proprietary-own',
      'license_note': '[PLACEHOLDER own]',
      'attribution': '[PLACEHOLDER curated attribution]',
    },
  ]);
  insert('author', [
    {
      'id': 'author-a',
      'name': 'Author A',
      'full_name': 'Author A Full',
      'lifespan': 'AD 1-2',
      'ord': 1,
    },
    {
      'id': 'author-b',
      'name': 'Author B',
      'full_name': 'Author B Full',
      'lifespan': 'AD 3-4',
      'ord': 2,
    },
  ]);
  insert('work', [
    {
      'id': 'work-books',
      'author_id': 'author-a',
      'source_id': 'fx-text',
      'title': 'Work With Books',
      'original_title': 'Opus',
      'translator': 'Fixture Translator',
      'short_ref': 'Books',
      'book_count': 2,
      'section_count': 6,
      'ord': 1,
    },
    {
      'id': 'work-flat',
      'author_id': 'author-b',
      'source_id': 'fx-text',
      'title': 'Of Flat Work',
      'original_title': 'Planum',
      'translator': 'Fixture Translator',
      'short_ref': 'Flat',
      'book_count': 0,
      'section_count': 4,
      'ord': 2,
    },
  ]);
  insert('book', [
    for (final n in [1, 2])
      {
        'work_id': 'work-books',
        'number': n,
        'title': 'Book $n',
        'section_count': 3,
      },
  ]);
  for (final (i, key) in fixtureSectionKeys.indexed) {
    final parts = key.split('.');
    final text = fixtureSectionText(key);
    insert('section', [
      {
        'id': i + 1,
        'key': key,
        'work_id': parts.first,
        'book': parts.length == 3 ? int.parse(parts[1]) : null,
        'number': int.parse(parts.last),
        'ref': parts.skip(1).join('.'),
        'title': parts.first == 'work-flat' ? 'Chapter ${parts.last}' : null,
        'text': text,
        'char_count': text.length,
        'sha256': _sha(text),
      },
    ]);
  }
  db.execute("INSERT INTO section_fts(section_fts) VALUES ('rebuild')");

  Map<String, Object?> card(
    String id,
    String type,
    int ord, {
    String? text,
    String? sectionKey,
    String? title,
    String? subtitle,
    String? authorId,
    String tags = '[]',
  }) {
    final key = sectionKey;
    final work = key?.split('.').first;
    final textual = type == 'quote' || type == 'passage';
    return {
      'id': id,
      'type': type,
      'author_id':
          authorId ??
          (textual ? (work == 'work-books' ? 'author-a' : 'author-b') : null),
      'work_id': textual ? work : null,
      'section_key': key,
      'ref': key == null
          ? null
          : '${work == 'work-books' ? 'Books' : 'Flat'} '
                '${key.split('.').skip(1).join('.')}',
      'title': title,
      'subtitle': subtitle,
      'text': text ?? '[PLACEHOLDER $id]',
      'tags': tags,
      'status': 'draft',
      'source_id': textual ? 'fx-text' : 'prosoche-curated',
      'ord': ord,
    };
  }

  insert('card', [
    for (var n = 1; n <= fixtureQuoteCount; n++)
      card(
        'quote:${fixtureQuoteId(n)}',
        'quote',
        n,
        text: '[PLACEHOLDER quote $n]',
        sectionKey: fixtureSectionKeys[(n - 1) % fixtureSectionKeys.length],
        tags: n.isEven ? '["time"]' : '[]',
      ),
    for (var n = 1; n <= 4; n++)
      card(
        'passage:p$n',
        'passage',
        n,
        text: fixtureSectionText(fixtureSectionKeys[n]),
        sectionKey: fixtureSectionKeys[n],
      ),
    card(
      'practice:morning-preparation',
      'practice',
      1,
      title: 'Morning preparation',
      subtitle: '[PLACEHOLDER subtitle]',
      text: '[PLACEHOLDER morning step one]\n\n[PLACEHOLDER morning step two]',
      sectionKey: 'work-books.1.1',
      tags: '["morning"]',
    ),
    card(
      'practice:evening-review',
      'practice',
      2,
      title: 'Evening review',
      subtitle: '[PLACEHOLDER subtitle]',
      text:
          '[PLACEHOLDER evening intro]. Question one? Question two?\n\n'
          '[PLACEHOLDER evening outro]',
      sectionKey: 'work-flat.3',
      tags: '["evening"]',
    ),
    for (var n = 3; n <= 5; n++)
      card(
        'practice:x$n',
        'practice',
        n,
        title: 'Practice $n',
        subtitle: '[PLACEHOLDER subtitle $n]',
      ),
    for (final (i, t) in [
      'morning',
      'morning',
      'evening',
      'evening',
      '-',
    ].indexed)
      card(
        'prompt:${t == '-' ? 'free' : t}-${i + 1}',
        'prompt',
        i + 1,
        text: '[PLACEHOLDER question ${i + 1}]?',
        tags: t == '-' ? '[]' : '["$t"]',
      ),
    for (var n = 1; n <= 3; n++)
      card(
        'concept:c$n',
        'concept',
        n,
        title: 'Concept $n',
        subtitle: 'term$n - gloss $n',
        sectionKey: n == 1 ? 'work-flat.1' : null,
      ),
    card(
      'author:author-a',
      'author',
      1,
      title: 'Author A',
      authorId: 'author-a',
    ),
    card(
      'author:author-b',
      'author',
      2,
      title: 'Author B',
      authorId: 'author-b',
    ),
  ]);
  final cards = db.select('SELECT count(*) AS n FROM card').single['n'];
  insert('meta', [
    {'key': 'section_count', 'value': '${fixtureSectionKeys.length}'},
    {'key': 'card_count', 'value': '$cards'},
  ]);
  refreshSectionsSha(db);
  db
    ..execute('COMMIT')
    ..execute('PRAGMA user_version = ${ContentDb.contractVersion}');
}

void main(List<String> args) {
  final path = args.isEmpty ? 'content_fixture.db' : args.first;
  final f = File(path);
  if (f.existsSync()) f.deleteSync();
  buildContentFixture(path).close();
  stdout.writeln('content fixture: $path');
}
