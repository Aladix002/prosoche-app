// Maly content.db pre testy: schema z kontraktu
// `drift_schemas/content/content_schema.sql` + 2 sury (1 a 2) s placeholder
// textom. Ziadny skutocny obsah (PLAN_VYVOJA 5.5).
//
// Ako skript zapise fixture do suboru:
//   dart run test/data/db/fixtures/content_fixture.dart /tmp/content.db
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:sakina/data/db/content_db.dart';
import 'package:sqlite3/sqlite3.dart';

/// Cesta ku kopii kontraktu (testy bezia z korena balika).
const contractPath = 'drift_schemas/content/content_schema.sql';

/// Pocet versov vo fixture (sura 1: 7, sura 2: 286).
const fixtureAyahCount = 293;

/// Slovo, ktore je len v `text_simple` versa 2:255 (test FTS).
const fixtureArabicToken = 'alphaword';

/// Slovo, ktore je len v anglickom preklade versa 2:255 (test FTS).
const fixtureTranslationToken = 'zephyrword';

String uthmaniOf(int surah, int ayah) => '[PLACEHOLDER uthmani $surah:$ayah]';

/// sha256 Uthmani textu fixture (algoritmus `meta.surah_hash_algo`).
String fixtureUthmaniSha256() => sha256
    .convert(
      utf8.encode(
        [
          for (var a = 1; a <= 7; a++) uthmaniOf(1, a),
          for (var a = 1; a <= 286; a++) uthmaniOf(2, a),
        ].join('\n'),
      ),
    )
    .toString();

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

  Map<String, Object?> src(String id, String kind, [String? lang]) => {
    'id': id,
    'kind': kind,
    'lang': lang,
    'name': 'Fixture $id',
    'version': '1',
    'license': 'test-only',
    'license_text': '[PLACEHOLDER license]',
    'attribution': '[PLACEHOLDER attribution]',
    'url': 'https://example.invalid/$id',
    'commercial_status': 'allowed',
  };

  db.execute('BEGIN');
  insert('meta', [
    {'key': 'schema_version', 'value': '${ContentDb.contractVersion}'},
    {'key': 'dev_content', 'value': '1'},
    {'key': 'content_version', 'value': 'fixture'},
    {'key': 'langs', 'value': '["ar", "en", "id"]'},
    {'key': 'words_enabled', 'value': '1'},
    {'key': 'uthmani_sha256', 'value': fixtureUthmaniSha256()},
    {'key': 'hadith_extra_sha256', 'value': '0' * 64},
    {'key': 'hadith_extra_size', 'value': '0'},
    {'key': 'hadith_extra_schema_version', 'value': '1'},
  ]);
  insert('source', [
    src('fx-uthmani', 'quran_text'),
    src('fx-simple', 'quran_text_search'),
    src('fx-meta', 'quran_metadata'),
    src('fx-en-a', 'translation', 'en'),
    src('fx-en-b', 'translation', 'en'),
    src('fx-id', 'translation', 'id'),
    src('fx-hadith', 'hadith'),
    src('fx-curated', 'curated'),
    src('fx-words', 'word'),
    src('fx-city', 'city'),
  ]);
  insert('surah', [
    for (final (id, count, pre) in [(1, 7, 0), (2, 286, 1)])
      {
        'id': id,
        'name_ar': '[PLACEHOLDER name_ar $id]',
        'name_translit': 'Placeholder $id',
        'revelation_place': id == 1 ? 'meccan' : 'medinan',
        'revelation_order': id == 1 ? 5 : 87,
        'ayah_count': count,
        'bismillah_pre': pre,
        'bismillah_uthmani': pre == 1 ? '[PLACEHOLDER bismillah]' : null,
        'source_id': 'fx-meta',
      },
  ]);
  insert('surah_text', [
    for (final id in [1, 2])
      {
        'surah_id': id,
        'lang': 'en',
        'name_meaning': '[PLACEHOLDER meaning $id]',
        'source_id': 'fx-meta',
      },
  ]);

  var page = 1;
  final ayahs = <Map<String, Object?>>[];
  final translations = <Map<String, Object?>>[];
  for (final (s, count) in [(1, 7), (2, 286)]) {
    for (var a = 1; a <= count; a++) {
      final id = s * 1000 + a;
      final juz = s == 1 || a <= 141 ? 1 : (a <= 252 ? 2 : 3);
      if (a % 10 == 0) page++;
      ayahs.add({
        'id': id,
        'surah_id': s,
        'number': a,
        'text_uthmani': uthmaniOf(s, a),
        'text_simple':
            'placeholder simple s$s a$a'
            '${id == 2255 ? ' $fixtureArabicToken' : ''}',
        'juz': juz,
        'hizb_quarter': juz * 8 - 7,
        'page': page,
        'sajda': null,
        'source_id': 'fx-uthmani',
        'simple_source_id': 'fx-simple',
      });
      translations.add({
        'ayah_id': id,
        'lang': 'en',
        'source_id': 'fx-en-a',
        'text':
            'Placeholder translation $s:$a'
            '${id == 2255 ? ' $fixtureTranslationToken' : ''}',
        'footnotes': a == 1 ? '[PLACEHOLDER footnote]' : null,
      });
      if (s == 1) {
        translations.add({
          'ayah_id': id,
          'lang': 'id',
          'source_id': 'fx-id',
          'text': 'Placeholder terjemahan $s:$a $fixtureTranslationToken',
        });
      }
    }
  }
  insert('ayah', ayahs);
  insert('translation', translations);

  insert('lemma', [
    for (final (id, freq) in [(1, 100), (2, 50), (3, 10)])
      {
        'id': id,
        'text_ar': '[PLACEHOLDER lemma $id]',
        'translit': 'lemma$id',
        'root': null,
        'frequency': freq,
        'rank': id,
        'source_id': 'fx-words',
      },
  ]);
  insert('lemma_meaning', [
    for (final id in [1, 2])
      {
        'lemma_id': id,
        'lang': 'en',
        'meaning': '[PLACEHOLDER lemma meaning $id]',
        'source_id': 'fx-words',
      },
  ]);
  insert('word', [
    for (var p = 1; p <= 3; p++)
      {
        'id': p,
        'ayah_id': 1001,
        'position': p,
        'text_ar': '[PLACEHOLDER word $p]',
        'translit': 'w$p',
        'lemma_id': p == 3 ? null : p,
        'source_id': 'fx-words',
      },
    {
      'id': 4,
      'ayah_id': 2255,
      'position': 1,
      'text_ar': '[PLACEHOLDER word 4]',
      'lemma_id': 1,
      'source_id': 'fx-words',
    },
  ]);
  insert('word_meaning', [
    {
      'word_id': 1,
      'lang': 'en',
      'meaning': '[PLACEHOLDER word meaning 1]',
      'source_id': 'fx-words',
    },
  ]);

  insert('hadith', [
    for (final id in [11, 12, 13])
      {
        'id': id,
        'collection': '[PLACEHOLDER collection]',
        'text_ar': '[PLACEHOLDER hadith $id]',
        'grade': id == 13 ? 'hasan' : 'sahih',
        'grade_ar': '[PLACEHOLDER grade]',
        'tags': id == 11 ? '["jumuah", "patience"]' : null,
        'categories': '[1]',
        'source_id': 'fx-hadith',
      },
  ]);
  insert('hadith_text', [
    for (final id in [11, 12, 13])
      {
        'hadith_id': id,
        'lang': 'en',
        'title': '[PLACEHOLDER title $id]',
        'text': '[PLACEHOLDER hadith text $id]',
        'attribution': '[PLACEHOLDER attribution]',
        'grade_label': '[PLACEHOLDER grade]',
        'source_id': 'fx-hadith',
      },
  ]);
  insert('dua', [
    for (final (id, tod) in [
      ('dua_morning', 'morning'),
      ('dua_evening', 'evening'),
      ('dua_any', 'any'),
    ])
      {
        'id': id,
        'category': 'example',
        'text_ar': '[PLACEHOLDER dua $id]',
        'time_of_day': tod,
        'source_ref': 'example:$id',
        'source_id': 'fx-curated',
      },
  ]);
  insert('dua_text', [
    {
      'dua_id': 'dua_morning',
      'lang': 'en',
      'text': '[PLACEHOLDER dua text]',
      'source_id': 'fx-curated',
    },
  ]);
  insert('name_of_allah', [
    for (final id in [1, 2])
      {
        'id': id,
        'text_ar': '[PLACEHOLDER name $id]',
        'ref_ayah_id': id == 1 ? 1001 : null,
        'source_id': 'fx-curated',
      },
  ]);
  insert('name_text', [
    {
      'name_id': 1,
      'lang': 'en',
      'meaning': '[PLACEHOLDER name meaning]',
      'source_id': 'fx-curated',
    },
  ]);
  insert('reflection', [
    for (final (id, status) in [
      ('refl_a', 'approved'),
      ('refl_b', 'draft'),
      ('refl_old', 'retired'),
    ])
      {'id': id, 'status': status, 'origin': 'example', 'tags': '[]'},
  ]);
  insert('reflection_text', [
    {
      'reflection_id': 'refl_a',
      'lang': 'en',
      'text': '[PLACEHOLDER reflection]',
      'source_id': 'fx-curated',
    },
  ]);
  insert('quest_template', [
    for (final (id, slot, status) in [
      ('q_read', 'read', 'approved'),
      ('q_learn', 'learn', 'approved'),
      ('q_act', 'act', 'approved'),
      ('q_act_old', 'act', 'retired'),
    ])
      {
        'id': id,
        'status': status,
        'origin': 'example',
        'slot': slot,
        'rule_json': '{}',
        'tags': '[]',
      },
  ]);
  insert('quest_text', [
    for (final id in ['q_read', 'q_act'])
      {
        'quest_id': id,
        'lang': 'en',
        'title': '[PLACEHOLDER quest $id]',
        'source_id': 'fx-curated',
      },
  ]);
  insert('islamic_event', [
    for (final (id, prio, status) in [
      ('ev_low', 1, 'approved'),
      ('ev_high', 9, 'approved'),
      ('ev_old', 5, 'retired'),
    ])
      {
        'id': id,
        'status': status,
        'origin': 'example',
        'category': 'core',
        'priority': prio,
        'rule_json': '{}',
      },
  ]);
  insert('islamic_event_text', [
    {
      'event_id': 'ev_high',
      'lang': 'en',
      'title': '[PLACEHOLDER event]',
      'source_id': 'fx-curated',
    },
  ]);
  insert('intro_card', [
    {'id': 'intro_a', 'status': 'approved', 'origin': 'example'},
    {
      'id': 'intro_ev',
      'status': 'approved',
      'origin': 'example',
      'event_id': 'ev_high',
    },
  ]);
  insert('intro_card_text', [
    {
      'intro_id': 'intro_a',
      'lang': 'en',
      'title': '[PLACEHOLDER intro]',
      'source_id': 'fx-curated',
    },
  ]);
  insert('country', [
    {'iso2': 'SK', 'name': 'Slovakia', 'source_id': 'fx-city'},
    {'iso2': 'CZ', 'name': 'Czechia', 'source_id': 'fx-city'},
    {'iso2': 'XX', 'name': 'Placeholder', 'source_id': 'fx-city'},
  ]);
  insert('city', [
    for (final (id, name, ascii, cc, lat, lng, pop) in [
      (1, 'Bratislava', 'Bratislava', 'SK', 48.15, 17.11, 475000),
      (2, 'Brno', 'Brno', 'CZ', 49.20, 16.61, 380000),
      (3, 'Banská Bystrica', 'Banska Bystrica', 'SK', 48.74, 19.15, 76000),
      (4, '100%_town', '100%_town', 'XX', 10.0, 10.0, null),
    ])
      {
        'id': id,
        'name': name,
        'ascii_name': ascii,
        'country_code': cc,
        'lat': lat,
        'lng': lng,
        'tz': 'Europe/Bratislava',
        'population': pop,
        'source_id': 'fx-city',
      },
  ]);
  db
    ..execute("INSERT INTO ayah_fts(ayah_fts) VALUES('rebuild')")
    ..execute("INSERT INTO translation_fts(translation_fts) VALUES('rebuild')")
    ..execute('COMMIT');
}

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('usage: content_fixture.dart <out.db>');
    exitCode = 64;
    return;
  }
  final out = File(args.single);
  if (out.existsSync()) out.deleteSync();
  buildContentFixture(out.path).close();
  stdout.writeln('wrote ${out.path}');
}
