import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/quests/quests.dart';

// Sablony su testovacie fixtures (len ID, bez textov), nie produkcny obsah.
const _engine = QuestEngine();
final _day = LocalDate(2026, 10, 29);
const _all = {'en', 'ar', 'id', 'ur', 'bn', 'tr'};

QuestRule _ayahRule([Object min = 10]) => QuestRule.fromJson({
  'count': {'type': 'ayah', 'min': min},
});

QuestTemplate _read(
  String id, {
  Set<String> langs = _all,
  bool excusedOk = false,
  Set<String> season = const {},
  int? cooldownDays,
}) => QuestTemplate(
  id: id,
  slot: QuestSlot.read,
  langs: langs,
  rule: _ayahRule(const {'param': 'n'}),
  params: const {
    'n': [10, 15, 20],
  },
  excusedOk: excusedOk,
  season: season,
  cooldownDays: cooldownDays,
);

QuestTemplate _learn(String id, {String type = 'word', Set<String>? langs}) =>
    QuestTemplate(
      id: id,
      slot: QuestSlot.learn,
      langs: langs ?? _all,
      rule: QuestRule.fromJson({
        'count': {'type': type, 'min': 3},
      }),
    );

QuestTemplate _act(
  String id, {
  Set<String> langs = _all,
  bool excusedOk = false,
  double weight = 1,
  Set<String> season = const {},
}) => QuestTemplate(
  id: id,
  slot: QuestSlot.act,
  langs: langs,
  excusedOk: excusedOk,
  weight: weight,
  season: season,
);

ActiveEvent _event(String id, Map<QuestSlot, String> quests, {int prio = 0}) =>
    ActiveEvent(
      id: id,
      priority: prio,
      effect: EventEffect(quests: quests),
    );

QuestSelectionInput _input({
  List<QuestTemplate>? templates,
  List<ActiveEvent> events = const [],
  List<QuestLogEntry> history = const [],
  LocalDate? date,
  int seed = 42,
  String lang = 'en',
  bool excused = false,
  bool wordsEnabled = true,
}) => QuestSelectionInput(
  date: date ?? _day,
  seed: seed,
  lang: lang,
  templates:
      templates ??
      [
        _read('read.a'),
        _read('read.b'),
        _learn('learn.a'),
        _act('act.a'),
        _act('act.b'),
        _act('act.c'),
      ],
  activeEvents: events,
  history: history,
  excused: excused,
  wordsEnabled: wordsEnabled,
);

DailyQuest _slot(List<DailyQuest> qs, QuestSlot slot) =>
    qs.singleWhere((q) => q.slot == slot);

void main() {
  test('one quest per slot in order read, learn, act', () {
    final qs = _engine.select(_input());
    expect(qs.map((q) => q.slot), QuestSlot.values);
    expect(qs.every((q) => q.date == _day), isTrue);
    expect(_slot(qs, QuestSlot.act).isSelfReport, isTrue);
    expect(_slot(qs, QuestSlot.read).params['n'], isIn([10, 15, 20]));
    expect(_slot(qs, QuestSlot.read).target, isIn([10, 15, 20]));
    expect(_slot(qs, QuestSlot.act).target, isNull);
  });

  test('same input gives same quests; seeds spread over the pool', () {
    final picks = <String>{};
    for (var seed = 0; seed < 300; seed++) {
      final a = _engine.select(_input(seed: seed));
      expect(_engine.select(_input(seed: seed)), a);
      picks.add(_slot(a, QuestSlot.act).questId);
    }
    expect(picks, {'act.a', 'act.b', 'act.c'});
  });

  test('daySeed is stable and depends on install id and date', () {
    final s = QuestEngine.daySeed('install-1', _day);
    expect(QuestEngine.daySeed('install-1', _day), s);
    expect(QuestEngine.daySeed('install-1', _day.addDays(1)), isNot(s));
    expect(QuestEngine.daySeed('install-2', _day), isNot(s));
    expect(s, inInclusiveRange(0, 0xFFFFFFFF));
  });

  test('weight biases the weighted pick', () {
    final templates = [
      _read('read.a'),
      _learn('learn.a'),
      _act('act.heavy', weight: 20),
      _act('act.light'),
    ];
    var heavy = 0;
    for (var seed = 0; seed < 200; seed++) {
      final qs = _engine.select(_input(templates: templates, seed: seed));
      if (_slot(qs, QuestSlot.act).questId == 'act.heavy') heavy++;
    }
    expect(heavy, greaterThan(170));
  });

  group('cooldown', () {
    test('act LRU with minimum 21 days', () {
      final templates = [_read('read.a'), _learn('learn.a'), _act('act.a')];
      // act.b pouzite pred 20 dnami je stale v cooldowne, takze 100 seedov
      // nikdy nevyberie act.b.
      for (var seed = 0; seed < 100; seed++) {
        final qs = _engine.select(
          _input(
            seed: seed,
            templates: [...templates, _act('act.b')],
            history: [
              QuestLogEntry(
                date: _day.addDays(-20),
                slot: QuestSlot.act,
                questId: 'act.b',
              ),
            ],
          ),
        );
        expect(_slot(qs, QuestSlot.act).questId, 'act.a');
      }

      // Po 21 dnoch je act.b znova v poole.
      final picks = {
        for (var seed = 0; seed < 100; seed++)
          _slot(
            _engine.select(
              _input(
                seed: seed,
                templates: [...templates, _act('act.b')],
                history: [
                  QuestLogEntry(
                    date: _day.addDays(-21),
                    slot: QuestSlot.act,
                    questId: 'act.b',
                  ),
                ],
              ),
            ),
            QuestSlot.act,
          ).questId,
      };
      expect(picks, {'act.a', 'act.b'});
    });

    test('read/learn 7 days, template cooldown can only extend it', () {
      expect(_read('r').effectiveCooldownDays, 7);
      expect(_read('r', cooldownDays: 3).effectiveCooldownDays, 7);
      expect(_read('r', cooldownDays: 30).effectiveCooldownDays, 30);
      expect(_act('a').effectiveCooldownDays, 21);
      expect(QuestCooldown.minDays(QuestSlot.learn), 7);

      Set<String> readPicks(int daysAgo) => {
        for (var seed = 0; seed < 100; seed++)
          _slot(
            _engine.select(
              _input(
                seed: seed,
                history: [
                  QuestLogEntry(
                    date: _day.addDays(-daysAgo),
                    slot: QuestSlot.read,
                    questId: 'read.b',
                    status: QuestStatus.done,
                  ),
                ],
              ),
            ),
            QuestSlot.read,
          ).questId,
      };
      expect(readPicks(6), {'read.a'});
      expect(readPicks(7), {'read.a', 'read.b'});
    });

    test('all in cooldown: least recently used template', () {
      final qs = _engine.select(
        _input(
          history: [
            for (final (id, ago) in [('act.a', 3), ('act.b', 10), ('act.c', 5)])
              QuestLogEntry(
                date: _day.addDays(-ago),
                slot: QuestSlot.act,
                questId: id,
              ),
          ],
        ),
      );
      final act = _slot(qs, QuestSlot.act);
      expect(act.questId, 'act.b');
      expect(act.origin, QuestOrigin.leastRecentlyUsed);
    });

    test('history from the selected day or later is ignored', () {
      final base = _engine.select(_input());
      final withToday = _engine.select(
        _input(
          history: [
            for (final q in base)
              QuestLogEntry(date: _day, slot: q.slot, questId: q.questId),
            QuestLogEntry(
              date: _day.addDays(1),
              slot: QuestSlot.act,
              questId: 'act.a',
            ),
          ],
        ),
      );
      expect(withToday, base);
    });
  });

  group('event override', () {
    test('override wins over the pool and ignores cooldown', () {
      final qs = _engine.select(
        _input(
          templates: [
            _read('read.a'),
            _read('read.kahf', season: const {'jumuah'}),
            _learn('learn.a'),
            _act('act.a'),
            _act('act.white_day'),
          ],
          events: [
            _event('white_days', {QuestSlot.act: 'act.white_day'}, prio: 40),
            _event('jumuah', {QuestSlot.read: 'read.kahf'}, prio: 50),
          ],
          history: [
            QuestLogEntry(
              date: _day.addDays(-1),
              slot: QuestSlot.act,
              questId: 'act.white_day',
            ),
          ],
        ),
      );
      final read = _slot(qs, QuestSlot.read);
      expect(read.questId, 'read.kahf');
      expect(read.origin, QuestOrigin.eventOverride);
      expect(read.eventId, 'jumuah');
      final act = _slot(qs, QuestSlot.act);
      expect(act.questId, 'act.white_day');
      expect(act.eventId, 'white_days');
      expect(_slot(qs, QuestSlot.learn).origin, QuestOrigin.weighted);
    });

    test('higher priority wins, equal priority sorts by id', () {
      final templates = [
        _read('read.a'),
        _learn('learn.a'),
        _act('act.x'),
        _act('act.y'),
        _act('act.z'),
      ];
      String actWith(List<ActiveEvent> events) => _slot(
        _engine.select(_input(templates: templates, events: events)),
        QuestSlot.act,
      ).questId;

      expect(
        actWith([
          _event('ramadan', {QuestSlot.act: 'act.x'}, prio: 100),
          _event('jumuah', {QuestSlot.act: 'act.y'}, prio: 50),
        ]),
        'act.x',
      );
      expect(
        actWith([
          _event('b_event', {QuestSlot.act: 'act.y'}, prio: 10),
          _event('a_event', {QuestSlot.act: 'act.z'}, prio: 10),
        ]),
        'act.z',
      );
    });

    test('unknown override template falls back to the pool', () {
      final qs = _engine.select(
        _input(
          events: [
            _event('jumuah', {QuestSlot.act: 'act.missing'}),
          ],
        ),
      );
      expect(_slot(qs, QuestSlot.act).origin, QuestOrigin.weighted);
    });

    test('season templates only while their event is active', () {
      final templates = [
        _read('read.a'),
        _learn('learn.a'),
        _act('act.ramadan', season: const {'ramadan'}),
        _act('act.any'),
      ];
      final off = {
        for (var seed = 0; seed < 50; seed++)
          _slot(
            _engine.select(_input(templates: templates, seed: seed)),
            QuestSlot.act,
          ).questId,
      };
      expect(off, {'act.any'});
      final on = {
        for (var seed = 0; seed < 50; seed++)
          _slot(
            _engine.select(
              _input(
                templates: templates,
                seed: seed,
                events: [_event('ramadan', const {})],
              ),
            ),
            QuestSlot.act,
          ).questId,
      };
      expect(on, {'act.any', 'act.ramadan'});
    });
  });

  group('excused days', () {
    final templates = [
      _read('read.a'),
      _read('read.excused', excusedOk: true),
      _learn('learn.a'),
      _act('act.fast'),
      _act('act.dhikr', excusedOk: true),
    ];

    test('only excused_ok templates', () {
      for (var seed = 0; seed < 50; seed++) {
        final qs = _engine.select(
          _input(templates: templates, seed: seed, excused: true),
        );
        expect(_slot(qs, QuestSlot.read).questId, 'read.excused');
        expect(_slot(qs, QuestSlot.act).questId, 'act.dhikr');
        // learn.a nie je excused_ok: genericky quest.
        expect(_slot(qs, QuestSlot.learn).origin, QuestOrigin.generic);
      }
    });

    test('event override without excused_ok is replaced by the pool', () {
      final qs = _engine.select(
        _input(
          templates: templates,
          excused: true,
          events: [
            _event('white_days', {QuestSlot.act: 'act.fast'}, prio: 40),
          ],
        ),
      );
      expect(_slot(qs, QuestSlot.act).questId, 'act.dhikr');
      expect(_slot(qs, QuestSlot.act).origin, QuestOrigin.weighted);
    });
  });

  group('language fallback', () {
    test('read/learn get generic quests, act is hidden', () {
      final qs = _engine.select(_input(lang: 'bs'));
      expect(qs.map((q) => q.slot), [QuestSlot.read, QuestSlot.learn]);
      final read = _slot(qs, QuestSlot.read);
      expect(read.origin, QuestOrigin.generic);
      expect(read.generic, GenericQuest.readVerses);
      expect(read.questId, 'generic.read.verses');
      expect(read.target, 10);
      expect(_slot(qs, QuestSlot.learn).generic, GenericQuest.learnWords);
    });

    test('generic read target fits the daily set (I-02)', () {
      QuestSelectionInput withVerses(int? n) => QuestSelectionInput(
        date: _input(lang: 'bs').date,
        seed: _input(lang: 'bs').seed,
        lang: 'bs',
        templates: const [],
        setVerses: n,
      );
      for (final (n, target) in [(7, 7), (12, 10), (null, 10), (0, 10)]) {
        final read = _slot(_engine.select(withVerses(n)), QuestSlot.read);
        expect(read.target, target, reason: '$n verses in the set');
      }
      expect(GenericQuest.learnCards.countFor(setVerses: 0), 1);
      expect(GenericQuest.learnWords.countFor(setVerses: 1), 3);
    });

    test('templates without text in the language are skipped', () {
      final qs = _engine.select(
        _input(
          lang: 'ur',
          templates: [
            _read('read.en', langs: const {'en'}),
            _read('read.ur', langs: const {'en', 'ur'}),
            _learn('learn.a'),
            _act('act.en', langs: const {'en'}),
          ],
        ),
      );
      expect(_slot(qs, QuestSlot.read).questId, 'read.ur');
      expect(qs.where((q) => q.slot == QuestSlot.act), isEmpty);
    });

    test('override template without text: generic read, no act', () {
      final qs = _engine.select(
        _input(
          lang: 'bn',
          templates: [
            _read('read.a'),
            _read('read.kahf', langs: const {'en'}),
            _learn('learn.a'),
            _act('act.a'),
            _act('act.jumuah', langs: const {'en'}),
          ],
          events: [
            _event('jumuah', {
              QuestSlot.read: 'read.kahf',
              QuestSlot.act: 'act.jumuah',
            }),
          ],
        ),
      );
      expect(_slot(qs, QuestSlot.read).generic, GenericQuest.readVerses);
      expect(qs.where((q) => q.slot == QuestSlot.act), isEmpty);
    });

    test('words disabled: no word templates, generic learn cards', () {
      final qs = _engine.select(_input(wordsEnabled: false));
      final learn = _slot(qs, QuestSlot.learn);
      expect(learn.generic, GenericQuest.learnCards);
      expect(learn.rule!.types, {CardType.hadith, CardType.dua});

      final withNames = _engine.select(
        _input(
          wordsEnabled: false,
          templates: [
            _read('read.a'),
            _learn('learn.word'),
            _learn('learn.quiz', type: 'quiz'),
            _learn('learn.name', type: 'name'),
          ],
        ),
      );
      expect(_slot(withNames, QuestSlot.learn).questId, 'learn.name');
    });
  });

  group('auto completion from card_event', () {
    DateTime t(int minute) => DateTime(2026, 10, 29, 9, minute);

    test('read quest completes when rule is met', () {
      final read = _slot(_engine.select(_input()), QuestSlot.read);
      final n = read.target!;
      final events = [
        for (var i = 1; i <= n; i++)
          CardActivity(
            date: _day,
            cardId: AyahCardId(AyahId(2, i)),
            action: CardAction.seen,
            ts: t(i),
          ),
      ];
      final almost = _engine.progress(read, events.take(n - 1))!;
      expect(almost.isComplete, isFalse);
      expect(almost.current, n - 1);
      final done = _engine.progress(read, events)!;
      expect(done.isComplete, isTrue);
      expect(done.completedAt, t(n));
    });

    test('events of another day do not count', () {
      final read = _slot(_engine.select(_input()), QuestSlot.read);
      final events = [
        for (var i = 1; i <= 30; i++)
          CardActivity(
            date: _day.addDays(-1),
            cardId: AyahCardId(AyahId(2, i)),
            action: CardAction.seen,
            ts: t(i),
          ),
      ];
      expect(_engine.progress(read, events)!.current, 0);
    });

    test('act is self reported', () {
      final act = _slot(_engine.select(_input()), QuestSlot.act);
      expect(_engine.progress(act, const []), isNull);
    });
  });

  group('P-01 generic target is stable after completion', () {
    DateTime t(int minute) => DateTime(2026, 10, 29, 9, minute);
    DailyQuest readWith(int? setVerses) => _slot(
      _engine.select(
        QuestSelectionInput(
          date: _day,
          seed: 42,
          lang: 'bs',
          templates: const [],
          setVerses: setVerses,
        ),
      ),
      QuestSlot.read,
    );
    List<CardActivity> verses(int n, {LocalDate? date}) => [
      for (var i = 1; i <= n; i++)
        CardActivity(
          date: date ?? _day,
          cardId: AyahCardId(AyahId(2, i)),
          action: CardAction.seen,
          ts: t(i),
        ),
    ];

    test('read 10 done before the set: stays Read 10 with a 7 verse set', () {
      final before = readWith(null);
      expect(before.target, 10);
      final events = verses(12);
      final doneAt = _engine.progress(before, events)!.completedAt;
      expect(doneAt, t(10));
      // Po splneni vznikla sada so 7 versami: bez settled() by to bolo 7.
      final after = readWith(7);
      expect(after.target, 7);
      final settled = _engine.settled(after, doneAt: doneAt, events: events);
      expect(settled.target, 10);
      expect(settled.generic, GenericQuest.readVerses);
      expect(settled.origin, QuestOrigin.generic);
      final p = _engine.progress(settled, events)!;
      expect((p.current, p.target, p.completedAt), (10, 10, t(10)));
    });

    test('done with the set target keeps min(10, set verses)', () {
      final read = readWith(7);
      final events = verses(9);
      final doneAt = _engine.progress(read, events)!.completedAt;
      expect(doneAt, t(7));
      expect(_engine.settled(read, doneAt: doneAt, events: events), read);
      // Ani neskorsi rozdielny stav dna ciel nezvysi.
      final settled = _engine.settled(
        readWith(12),
        doneAt: doneAt,
        events: events,
      );
      expect(settled.target, 7);
    });

    test('pending, templates and missing events are unchanged', () {
      final read = readWith(7);
      expect(_engine.settled(read, doneAt: null, events: verses(3)), read);
      expect(_engine.settled(read, doneAt: t(5), events: const []), read);
      expect(
        _engine.settled(
          read,
          doneAt: t(5),
          events: verses(5, date: _day.addDays(-1)),
        ),
        read,
      );
      final template = _slot(_engine.select(_input()), QuestSlot.read);
      expect(
        _engine.settled(template, doneAt: t(3), events: verses(3)),
        template,
      );
    });
  });

  group('value types', () {
    test('QuestTemplate validation', () {
      expect(
        () => QuestTemplate(id: '', slot: QuestSlot.act, langs: _all),
        throwsArgumentError,
      );
      expect(
        () =>
            QuestTemplate(id: 'a', slot: QuestSlot.act, langs: _all, weight: 0),
        throwsArgumentError,
      );
      expect(
        () => QuestTemplate(
          id: 'a',
          slot: QuestSlot.act,
          langs: _all,
          cooldownDays: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => QuestTemplate(
          id: 'a',
          slot: QuestSlot.act,
          langs: _all,
          rule: _ayahRule(),
        ),
        throwsArgumentError,
      );
      expect(
        () => QuestTemplate(id: 'r', slot: QuestSlot.read, langs: _all),
        throwsArgumentError,
      );
      expect(
        () => QuestTemplate(
          id: 'r',
          slot: QuestSlot.read,
          langs: _all,
          rule: _ayahRule(const {'param': 'n'}),
        ),
        throwsArgumentError,
      );
      expect(
        () => QuestTemplate(
          id: 'r',
          slot: QuestSlot.read,
          langs: _all,
          rule: _ayahRule(),
          params: const {'n': <int>[]},
        ),
        throwsArgumentError,
      );
    });

    test('QuestTemplate identity by id', () {
      expect(_act('a'), _act('a', weight: 3));
      expect(_act('a').hashCode, _act('a').hashCode);
      expect(_act('a').toString(), contains('act'));
      expect(_act('a').hasText('en'), isTrue);
      expect(_act('a', langs: const {'en'}).hasText('ar'), isFalse);
    });

    test('DailyQuest equality and toString', () {
      final a = _engine.select(_input());
      final b = _engine.select(_input());
      for (var i = 0; i < a.length; i++) {
        expect(a[i].hashCode, b[i].hashCode);
        expect(a[i].toString(), contains(a[i].questId));
      }
      expect(a[0], isNot(a[1]));
    });

    test('GenericQuest ids and rules', () {
      for (final g in GenericQuest.values) {
        expect(GenericQuest.fromId(g.id), g);
        expect(g.id, startsWith('generic.${g.slot.wire}.'));
        expect(g.rule(g.defaultCount).target(const {}), g.defaultCount);
      }
      expect(GenericQuest.fromId('read.a'), isNull);
    });

    test('GenericQuest texts exist in the EN ARB with a count', () {
      final arb = jsonDecode(
        File('lib/l10n/parts/E-03_en.arb').readAsStringSync(),
      ) as Map<String, Object?>;
      for (final g in GenericQuest.values) {
        expect(arb[g.arbKey], isA<String>(), reason: g.arbKey);
        expect(arb[g.arbKey]! as String, contains('{count'));
      }
    });
  });
}
