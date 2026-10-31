import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/data/db/user_db.dart';
import 'package:prosoche/domain/common/common.dart';

import 'fixtures/content_fixture.dart';

/// Dotaz dennej sady (A3 Feed): `daily_set` z user.db a obsah vsetkych
/// kariet z content.db.
Future<int> loadDailySet(UserDb user, ContentDb content, LocalDate date) async {
  final set = (await user.dailySetDao.byDate(date))!;
  final cards = [
    for (final c
        in (jsonDecode(set.cardsJson) as Map<String, Object?>)['cards']!
            as List<Object?>)
      CardId.parse((c! as Map<String, Object?>)['card_id']! as String),
  ];
  var loaded = 0;
  for (final c in cards) {
    if (c is ContentCardId && await content.cardDao.card(c.format()) != null) {
      loaded++;
    }
  }
  return loaded;
}

void main() {
  // Kazdy test otvara novu DB nad vlastnym spojenim.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  test('daily set query < 16 ms on the fixture (DoD D-01)', () async {
    final content = openContentFixture();
    final user = UserDb.memory();
    addTearDown(content.close);
    addTearDown(user.close);

    final date = LocalDate(2026, 10, 29);
    final ids = [
      'intro:2026-10-29',
      for (var i = 1; i <= 11; i++) 'quote:${fixtureQuoteId(i)}',
    ];
    await user.dailySetDao.insertIfAbsent(
      date: date,
      seed: 42,
      cardsJson: jsonEncode({
        'v': 1,
        'cards': [
          for (final (i, id) in ids.indexed) {'pos': i + 1, 'card_id': id},
        ],
      }),
      generatorVersion: 1,
      contentVersion: 'fixture',
      tz: 'UTC',
      phase: DayPhase.morning,
    );

    // zahriatie (prepared statements, JIT)
    for (var i = 0; i < 5; i++) {
      expect(await loadDailySet(user, content, date), 11);
    }
    final times = <int>[];
    for (var i = 0; i < 30; i++) {
      final sw = Stopwatch()..start();
      await loadDailySet(user, content, date);
      times.add(sw.elapsedMicroseconds);
    }
    times.sort();
    final median = times[times.length ~/ 2];
    expect(median, lessThan(16000), reason: 'median $median us');
  });
}
