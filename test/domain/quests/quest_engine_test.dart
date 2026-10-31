import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/quests.dart';

// Sablony su testovacie fixtures (len ID, bez textov), nie produkcny obsah.
const _engine = QuestEngine();
final _day = LocalDate(2026, 10, 29);
const _all = {'en', 'de'};

QuestRule _quoteRule([Object min = 5]) => QuestRule.fromJson({
  'count': {'type': 'quote', 'min': min},
});

QuestTemplate _read(
  String id, {
  Set<String> langs = _all,
  bool excusedOk = false,
  int? cooldownDays,
}) => QuestTemplate(
  id: id,
  slot: QuestSlot.read,
  langs: langs,
  rule: _quoteRule(const {'param': 'n'}),
  params: const {
    'n': [10, 15, 20],
  },
  excusedOk: excusedOk,
  cooldownDays: cooldownDays,
);

QuestTemplate _learn(
  String id, {
  String type = 'concept',
  Set<String>? langs,
}) => QuestTemplate(
  id: id,
  slot: QuestSlot.learn,
  langs: langs ?? _all,
  rule: QuestRule.fromJson({
    'count': {'type': type, 'min': 1},
  }),
);

QuestTemplate _act(
  String id, {
  Set<String> langs = _all,
  bool excusedOk = false,
  double weight = 1,
}) => QuestTemplate(
  id: id,
  slot: QuestSlot.act,
  langs: langs,
  excusedOk: excusedOk,
  weight: weight,
);

QuestSelectionInput _input({
  List<QuestTemplate>? templates,
  List<QuestLogEntry> history = const [],
  LocalDate? date,
  int seed = 42,
  String lang = 'en',
  bool excused = false,
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
  history: history,
  excused: excused,
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

  group('excused days', () {
    final templates = [
      _read('read.a'),
      _read('read.excused', excusedOk: true),
      _learn('learn.a'),
      _act('act.walk'),
      _act('act.rest', excusedOk: true),
    ];

    test('only excused_ok templates', () {
      for (var seed = 0; seed < 50; seed++) {
        final qs = _engine.select(
          _input(templates: templates, seed: seed, excused: true),
        );
        expect(_slot(qs, QuestSlot.read).questId, 'read.excused');
        expect(_slot(qs, QuestSlot.act).questId, 'act.rest');
        // learn.a nie je excused_ok: genericky quest.
        expect(_slot(qs, QuestSlot.learn).origin, QuestOrigin.generic);
      }
    });
  });

  group('language fallback', () {
    test('no template with text: generic quests in every slot', () {
      final qs = _engine.select(_input(lang: 'fr'));
      expect(qs.map((q) => q.slot), QuestSlot.values);
      final read = _slot(qs, QuestSlot.read);
      expect(read.origin, QuestOrigin.generic);
      expect(read.generic, GenericQuest.readCards);
      expect(read.questId, 'generic.read.cards');
      expect(read.target, 5);
      expect(read.rule!.types, {CardType.quote, CardType.passage});
      final learn = _slot(qs, QuestSlot.learn);
      expect(learn.generic, GenericQuest.learnIdea);
      expect(learn.rule!.types, {CardType.concept, CardType.author});
      final act = _slot(qs, QuestSlot.act);
      expect(act.generic, GenericQuest.actPractice);
      expect(act.isSelfReport, isTrue);
    });

    test('generic read target fits the daily set (I-02)', () {
      QuestSelectionInput withCards(int? n) => QuestSelectionInput(
        date: _day,
        seed: 42,
        lang: 'fr',
        templates: const [],
        setCards: n,
      );
      for (final (n, target) in [(3, 3), (11, 5), (null, 5), (0, 5)]) {
        final read = _slot(_engine.select(withCards(n)), QuestSlot.read);
        expect(read.target, target, reason: '$n cards in the set');
      }
      expect(GenericQuest.learnIdea.countFor(setCards: 0), 1);
      expect(GenericQuest.actPractice.countFor(setCards: 9), 1);
      expect(GenericQuest.actPractice.rule(1), isNull);
    });

    test('templates without text in the language are skipped', () {
      final qs = _engine.select(
        _input(
          lang: 'de',
          templates: [
            _read('read.en', langs: const {'en'}),
            _read('read.de'),
            _learn('learn.a'),
            _act('act.en', langs: const {'en'}),
          ],
        ),
      );
      expect(_slot(qs, QuestSlot.read).questId, 'read.de');
      expect(_slot(qs, QuestSlot.act).generic, GenericQuest.actPractice);
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
            cardId: ContentCardId.quote('q_$i'),
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
            cardId: ContentCardId.quote('q_$i'),
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
    DailyQuest readWith(int? setCards) => _slot(
      _engine.select(
        QuestSelectionInput(
          date: _day,
          seed: 42,
          lang: 'fr',
          templates: const [],
          setCards: setCards,
        ),
      ),
      QuestSlot.read,
    );
    List<CardActivity> cards(int n, {LocalDate? date}) => [
      for (var i = 1; i <= n; i++)
        CardActivity(
          date: date ?? _day,
          cardId: ContentCardId.quote('q_$i'),
          action: CardAction.seen,
          ts: t(i),
        ),
    ];

    test('read 5 done before the set: stays Read 5 with a 3 card set', () {
      final before = readWith(null);
      expect(before.target, 5);
      final events = cards(8);
      final doneAt = _engine.progress(before, events)!.completedAt;
      expect(doneAt, t(5));
      // Po splneni vznikla sada s 3 citatmi: bez settled() by to bolo 3.
      final after = readWith(3);
      expect(after.target, 3);
      final settled = _engine.settled(after, doneAt: doneAt, events: events);
      expect(settled.target, 5);
      expect(settled.generic, GenericQuest.readCards);
      expect(settled.origin, QuestOrigin.generic);
      final p = _engine.progress(settled, events)!;
      expect((p.current, p.target, p.completedAt), (5, 5, t(5)));
    });

    test('done with the set target keeps min(5, set cards)', () {
      final read = readWith(3);
      final events = cards(4);
      final doneAt = _engine.progress(read, events)!.completedAt;
      expect(doneAt, t(3));
      expect(_engine.settled(read, doneAt: doneAt, events: events), read);
      // Ani neskorsi rozdielny stav dna ciel nezvysi.
      final settled = _engine.settled(
        readWith(11),
        doneAt: doneAt,
        events: events,
      );
      expect(settled.target, 3);
    });

    test('pending, templates and missing events are unchanged', () {
      final read = readWith(7);
      expect(_engine.settled(read, doneAt: null, events: cards(3)), read);
      expect(_engine.settled(read, doneAt: t(5), events: const []), read);
      expect(
        _engine.settled(
          read,
          doneAt: t(5),
          events: cards(5, date: _day.addDays(-1)),
        ),
        read,
      );
      final template = _slot(_engine.select(_input()), QuestSlot.read);
      expect(
        _engine.settled(template, doneAt: t(3), events: cards(3)),
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
          rule: _quoteRule(),
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
          rule: _quoteRule(const {'param': 'n'}),
        ),
        throwsArgumentError,
      );
      expect(
        () => QuestTemplate(
          id: 'r',
          slot: QuestSlot.read,
          langs: _all,
          rule: _quoteRule(),
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
        final rule = g.rule(g.defaultCount);
        if (g.slot == QuestSlot.act) {
          expect(rule, isNull);
        } else {
          expect(rule!.target(const {}), g.defaultCount);
        }
      }
      expect(GenericQuest.fromId('read.a'), isNull);
    });

    test('GenericQuest texts exist in the EN ARB', () {
      final arb = jsonDecode(
        File('lib/l10n/app_en.arb').readAsStringSync(),
      ) as Map<String, Object?>;
      for (final g in GenericQuest.values) {
        expect(arb[g.arbKey], isA<String>(), reason: g.arbKey);
      }
      expect(arb[GenericQuest.readCards.arbKey]! as String, contains('{count'));
    });
  });
}
