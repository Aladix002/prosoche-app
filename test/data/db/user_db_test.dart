import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prosoche/data/db/converters.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

final _t0 = DateTime.utc(2026, 10, 29, 8);
final _d = LocalDate(2026, 10, 29);

void main() {
  // Kazdy test otvara novu DB nad vlastnym spojenim.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  group('file database', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('user_db'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test(
      'runs in WAL with busy_timeout and foreign keys (docs/02 D14)',
      () async {
        final db = UserDb.open(File(p.join(tmp.path, 'user.db')));
        addTearDown(db.close);
        Future<Object?> pragma(String name) async =>
            (await db.customSelect('PRAGMA $name').getSingle())
                .data
                .values
                .single;

        expect(await pragma('journal_mode'), 'wal');
        expect(await pragma('busy_timeout'), userDbBusyTimeoutMs);
        expect(await pragma('foreign_keys'), 1);
        expect(await pragma('user_version'), UserDb.currentSchemaVersion);
      },
    );

    test('second connection (gate engine) sees committed writes', () async {
      final file = File(p.join(tmp.path, 'user.db'));
      final a = UserDb.open(file);
      final b = UserDb.open(file);
      addTearDown(a.close);
      addTearDown(b.close);
      await a.settingsDao.write('k', '1');
      expect(await b.settingsDao.read('k'), '1');
      await b.settingsDao.write('k', '2');
      expect(await a.settingsDao.read('k'), '2');
    });
  });

  group('schema v1', () {
    late UserDb db;
    setUp(() => db = UserDb.memory());
    tearDown(() => db.close());

    test('has partial unique index for seen (docs/02 D1)', () async {
      final sql =
          (await db
                  .customSelect(
                    'SELECT sql FROM sqlite_master WHERE name = ?',
                    variables: [Variable.withString(cardEventSeenIndex)],
                  )
                  .getSingle())
              .read<String>('sql');
      expect(sql, contains('UNIQUE'));
      expect(sql, contains('WHERE "action" = \'seen\''));
    });

    test('has query indexes on card_event', () async {
      final names = [
        for (final r
            in await db
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type = 'index' "
                  "AND tbl_name = 'card_event' AND name NOT LIKE 'sqlite_%' "
                  'ORDER BY name',
                )
                .get())
          r.read<String>('name'),
      ];
      expect(names, [
        'card_event_card_id',
        'card_event_date',
        cardEventSeenIndex,
        'card_event_type_action',
      ]);
    });

    test('CHECK rejects bad enum and second singleton', () async {
      await expectLater(
        db.customStatement(
          "INSERT INTO prayer_log VALUES ('2026-10-29', 'witr', 'on_time', 0)",
        ),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        db.customStatement(
          'INSERT INTO streak_state (id, current, longest, grace_left) '
          'VALUES (2, 0, 0, 0)',
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('deleteAllData empties every table', () async {
      await db.settingsDao.write('k', '"v"');
      final app = await db.blockerDao.addApp(platformRef: 'x', now: _t0);
      await db.blockerDao.logUnlock(
        blockedAppId: app.id,
        source: UnlockSource.cards,
        minutes: 10,
        ts: _t0,
      );
      await db.cardEventDao.log(
        date: _d,
        card: CardId.parse('ayah:1001'),
        context: CardContext.feed,
        action: CardAction.seen,
        ts: _t0,
      );
      await db.deleteAllData();
      for (final t in db.allTables) {
        final c = await db
            .customSelect('SELECT COUNT(*) AS c FROM "${t.actualTableName}"')
            .getSingle();
        expect(c.read<int>('c'), 0, reason: t.actualTableName);
      }
    });
  });

  group('converters', () {
    test('wire enums round trip and reject unknown values', () {
      const c = WireEnumConverter(PrayerStatus.values);
      for (final v in PrayerStatus.values) {
        expect(c.fromSql(c.toSql(v)), v);
      }
      expect(c.toSql(PrayerStatus.onTime), 'on_time');
      expect(() => c.fromSql('bogus'), throwsStateError);
    });

    test('every enum has a unique snake_case wire', () {
      final all = <List<WireEnum>>[
        CardContext.values,
        CardAction.values,
        DayPhase.values,
        QuestSlotKind.values,
        QuestStatus.values,
        SrsState.values,
        SrsSource.values,
        PrayerKind.values,
        PrayerStatus.values,
        FastType.values,
        DayStatus.values,
        GateResult.values,
        UnlockSource.values,
      ];
      for (final values in all) {
        final wires = [for (final v in values) v.wire];
        expect(wires.toSet(), hasLength(wires.length));
        for (final w in wires) {
          expect(w, matches(RegExp(r'^[a-z]+(_[a-z]+)*$')));
        }
      }
      expect(SrsState.fresh.wire, 'new');
    });

    test('row JSON uses wire values, ISO dates and UTC millis', () {
      final row = PrayerLogRow(
        date: _d,
        prayer: PrayerKind.asr,
        status: PrayerStatus.onTime,
        ts: _t0,
      );
      final json = row.toJson();
      expect(json, {
        'date': '2026-10-29',
        'prayer': 'asr',
        'status': 'on_time',
        'ts': _t0.millisecondsSinceEpoch,
      });
      expect(PrayerLogRow.fromJson(json), row);
    });

    test('card type, date and timestamp', () {
      const t = CardTypeConverter();
      expect(t.fromSql(t.toSql(CardType.reflection)), CardType.reflection);
      expect(() => t.fromSql('bogus'), throwsStateError);
      const d = LocalDateConverter();
      expect(d.toSql(_d), '2026-10-29');
      expect(d.fromSql('2026-10-29'), _d);
      const ts = UtcMillisConverter();
      expect(ts.fromSql(ts.toSql(_t0)), _t0);
      expect(ts.fromSql(0).isUtc, isTrue);
    });
  });
}
