import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/domain/calendar/calendar.dart';
import 'package:prosoche/domain/common/common.dart';

import 'fixtures/event_rules_fixture.dart';

/// Kolizie z docs/03 5.2 nad testovacimi fixtures (nie produkcne eventy).
/// Datumy su Umm al-Qura pri offsete 0 (zdroj vid reference_dates.dart);
/// kazdy test si hijri datum overi, aby bolo jasne, co testuje.
void main() {
  final rules = EventRuleParser.parseAll(fixtureRules);
  final resolver0 = EventResolver(rules, IslamicCalendar());

  EventResolution resolve(String iso, {int offset = 0, EventContext? context}) {
    final r = offset == 0
        ? resolver0
        : EventResolver(rules, IslamicCalendar(offset: offset));
    return r.resolve(LocalDate.parse(iso), context);
  }

  List<String> ids(EventResolution r) => [for (final e in r.active) e.id];

  const kahf0 = EventAyahClaim('jumuah', 18, 'event_cursor.jumuah', 0);
  const kahf1 = EventAyahClaim('jumuah', 18, 'event_cursor.jumuah', 1);

  group('docs/03 5.2 collisions', () {
    test('Friday in Ramadan: ramadan takes 9 and act, jumuah 2-4 and read', () {
      final r = resolve('2027-02-12');
      expect(r.hijri, HijriDate(1448, 9, 5));
      expect(ids(r), ['ramadan', 'jumuah']);
      expect(r.mode, 'ramadan');
      expect(r.cards, {
        2: const EventCardClaim('jumuah'),
        3: kahf0,
        4: kahf1,
        9: const EventCardClaim('ramadan'),
      });
      expect(r.quests, {
        QuestSlot.act: const QuestClaim('ramadan', 'act.fixture.ramadan'),
        QuestSlot.read: const QuestClaim('jumuah', 'read.fixture.kahf_full'),
      });
      // Piatkovy act ostava len ako odznak na uvodnej karte.
      expect(r.intro, (eventId: 'ramadan', introId: 'intro.fixture.ramadan'));
      expect(r.badges, [(eventId: 'jumuah', introId: 'intro.fixture.jumuah')]);
    });

    test('Friday in last 10 nights with odd night: plus Laylat al-Qadr', () {
      final r = resolve('2027-03-05');
      expect(r.hijri, HijriDate(1448, 9, 26));
      expect(ids(r), ['laylat_al_qadr', 'ramadan_last10', 'ramadan', 'jumuah']);
      // Noc na 27. zacina vecer 26. dna (phase eve).
      expect(r.activePhase['laylat_al_qadr'], EventPhase.eve);
      expect(r.activePhase['ramadan'], EventPhase.day);
      expect(r.notifications, ['notif.fixture.laylat_qadr']);
      expect(r.cards[2], const EventCardClaim('jumuah'));
      expect(r.cards[3], kahf0);
      expect(r.cards[9], const EventCardClaim('ramadan'));
      expect(r.cards[12], const EventCardClaim('ramadan_last10'));
      expect(r.quests[QuestSlot.read]!.eventId, 'jumuah');
      expect(r.quests[QuestSlot.act]!.eventId, 'laylat_al_qadr');
      expect(r.boostTags, {
        'dua': 4.0,
        'quran': 4.0,
        'siyam': 2.0,
        'sadaqa': 2.0,
        'dhikr': 2.0,
      });
    });

    test('Laylat al-Qadr only before odd nights', () {
      // 25. Ramadan (vecer pred 26. nocou) - parna noc.
      expect(resolve('2027-03-04').isActive('laylat_al_qadr'), isFalse);
      // 24. Ramadan, vecer pred 25. nocou.
      expect(resolve('2027-03-03').isActive('laylat_al_qadr'), isTrue);
      // 20. Ramadan 1448 = 2027-02-27, vecer pred 21. nocou.
      final first = resolve('2027-02-27');
      expect(first.hijri, HijriDate(1448, 9, 20));
      expect(first.isActive('laylat_al_qadr'), isTrue);
      // 29. Ramadan 1448 je posledny den (29 dni), noc na 1. Shawwal nie.
      final last = resolve('2027-03-08');
      expect(last.hijri, HijriDate(1448, 9, 29));
      expect(last.isActive('laylat_al_qadr'), isFalse);
      expect(resolve('2027-03-07').isActive('laylat_al_qadr'), isTrue);
    });

    test('Arafah on Friday: act = Arafah fast, jumuah keeps 2-4 and read', () {
      final r = resolve('2030-04-12');
      expect(r.hijri, HijriDate(1451, 12, 9));
      expect(ids(r), ['arafah', 'jumuah', 'sacred_months']);
      expect(r.quests[QuestSlot.act]!.templateId, 'act.fixture.siyam_arafah');
      expect(r.quests[QuestSlot.read]!.eventId, 'jumuah');
      expect(r.cards[9], const EventCardClaim('arafah'));
      expect(r.cards[2], const EventCardClaim('jumuah'));
      expect(r.forbidTags, isEmpty);
      expect(r.allows(['siyam']), isTrue);
    });

    test('White day on Friday: white day quest stays', () {
      final r = resolve('2026-09-25');
      expect(r.hijri, HijriDate(1448, 4, 14));
      expect(ids(r), ['white_days', 'jumuah']);
      expect(r.quests[QuestSlot.act]!.eventId, 'white_days');
      expect(r.quests[QuestSlot.read]!.eventId, 'jumuah');
      expect(r.cards[2], const EventCardClaim('jumuah'));
    });

    test('13 Dhul Hijja: tashriq forbids siyam, white_days excluded', () {
      final r = resolve('2029-04-27');
      expect(r.hijri, HijriDate(1450, 12, 13));
      expect(r.isActive('tashriq'), isTrue);
      expect(r.isActive('white_days'), isFalse);
      expect(r.forbidTags, {'siyam'});
      expect(r.allows(['siyam', 'dhikr']), isFalse);
      expect(r.allows(['dhikr']), isTrue);
      expect(r.quests[QuestSlot.act]!.eventId, 'tashriq');
      // 2029-04-27 je piatok: jumuah ostava pre read a sloty 2-4.
      expect(r.quests[QuestSlot.read]!.eventId, 'jumuah');
      // 14. a 15. Dhul Hijja su biele dni, 13. nie.
      expect(resolve('2029-04-28').isActive('white_days'), isTrue);
    });

    test('Eid on Friday: Eid is exclusive, jumuah is disabled', () {
      final r = resolve('2026-03-20');
      expect(r.hijri, HijriDate(1447, 10, 1));
      expect(ids(r), ['eid_al_fitr']);
      expect(r.suppressed, ['jumuah']);
      expect(r.cards, {9: const EventCardClaim('eid_al_fitr')});
      expect(r.quests.keys, [QuestSlot.act]);
      expect(r.intro?.eventId, 'eid_al_fitr');
      expect(r.badges, isEmpty);
      expect(r.forbidTags, {'siyam'});
      expect(r.mode, isNull);
    });

    test('Eid al-Adha on Friday suppresses all lower events', () {
      final r = resolve('2025-06-06');
      expect(r.hijri, HijriDate(1446, 12, 10));
      expect(ids(r), ['eid_al_adha']);
      expect(r.suppressed, ['jumuah', 'sacred_months']);
    });

    test('Ashura on Friday: Ashura quest stays', () {
      final r = resolve('2023-07-28');
      expect(r.hijri, HijriDate(1445, 1, 10));
      expect(r.quests[QuestSlot.act]!.eventId, 'ashura');
      expect(r.quests[QuestSlot.read]!.eventId, 'jumuah');
      // ashura x2 a muharram x2
      expect(r.boostTags['siyam'], 4.0);
    });

    test('Ashura on Saturday and Tasua on Friday (9th and 10th together)', () {
      final tasua = resolve('2025-07-04');
      expect(tasua.hijri, HijriDate(1447, 1, 9));
      expect(tasua.quests[QuestSlot.act]!.eventId, 'tasua');
      expect(tasua.quests[QuestSlot.read]!.eventId, 'jumuah');
      final ashura = resolve('2025-07-05');
      expect(ashura.hijri, HijriDate(1447, 1, 10));
      expect(ashura.quests[QuestSlot.act]!.eventId, 'ashura');
      expect(resolve('2028-06-03').quests[QuestSlot.act]!.eventId, 'ashura');
    });

    test('Day before Ramadan on Monday: forbid nafl wins over boost', () {
      final r = resolve('2029-01-15');
      expect(r.hijri, HijriDate(1450, 8, 30));
      expect(ids(r), ['pre_ramadan', 'shaban', 'mon_thu']);
      expect(r.forbidTags, {'siyam_nafl'});
      expect(r.boostTags.containsKey('siyam_nafl'), isFalse);
      expect(r.allows(['siyam_nafl']), isFalse);
      expect(r.quests[QuestSlot.act]!.eventId, 'pre_ramadan');
      expect(r.boostTags['siyam'], 3.0);
    });

    test('pre_ramadan is 1-2 days before Ramadan only', () {
      expect(resolve('2029-01-14').isActive('pre_ramadan'), isTrue);
      expect(resolve('2029-01-13').isActive('pre_ramadan'), isFalse);
      final first = resolve('2029-01-16');
      expect(first.hijri, HijriDate(1450, 9, 1));
      expect(first.isActive('pre_ramadan'), isFalse);
      expect(first.isActive('ramadan'), isTrue);
    });

    test('mon_thu is off in Ramadan', () {
      final r = resolve('2029-01-22');
      expect(LocalDate.parse('2029-01-22').weekday, DateTime.monday);
      expect(r.isActive('ramadan'), isTrue);
      expect(r.isActive('mon_thu'), isFalse);
    });

    test('opt-in event on Friday never overrides (mawlid)', () {
      final on = EventContext(prefs: const {'show_optional_days'});
      // Offset +1: 12. Rabi al-Awwal 1450 pripadne na piatok 2028-08-04.
      final r = resolve('2028-08-04', offset: 1, context: on);
      expect(r.hijri, HijriDate(1450, 3, 12));
      expect(LocalDate.parse('2028-08-04').weekday, DateTime.friday);
      expect(ids(r), ['jumuah', 'mawlid']);
      final mawlid = r.active.last;
      expect(mawlid.effect, EventEffect.empty);
      expect(mawlid.mode, isNull);
      expect(r.cards.values.map((c) => c.eventId).toSet(), {'jumuah'});
      expect(r.quests.values.map((q) => q.eventId).toSet(), {'jumuah'});
      expect(r.intro?.eventId, 'jumuah');
      expect(r.badges, [(eventId: 'mawlid', introId: 'intro.fixture.mawlid')]);
      // Bez opt-in nastavenia sa event nezobrazi.
      expect(resolve('2028-08-04', offset: 1).isActive('mawlid'), isFalse);
    });

    test('opt-in events cannot occur in Ramadan', () {
      final on = EventContext(prefs: const {'show_optional_days'});
      final cal = IslamicCalendar();
      for (final d in cal.daysOfMonth(1448, 9)) {
        final r = resolver0.resolve(d, on);
        expect(
          r.active.where((e) => e.id == 'mawlid' || e.id.contains('isra')),
          isEmpty,
        );
        expect(r.isActive('nisf_shaban'), isFalse, reason: '$d');
      }
    });

    test('excused days: events and intro stay (quest swap is QuestEngine)', () {
      final excused = EventContext(flags: const {UserFlag.excused});
      final normal = resolve('2023-07-28');
      final r = resolve('2023-07-28', context: excused);
      expect(ids(r), ids(normal));
      expect(r.intro, normal.intro);
      expect(r.quests, normal.quests);
    });
  });

  group('phases', () {
    test('eve evaluates hijri atoms for the next day (nisf_shaban)', () {
      final on = EventContext(prefs: const {'show_optional_days'});
      final cal = IslamicCalendar();
      final day15 = cal.gregorianOf(HijriDate(1448, 8, 15));
      expect(day15, LocalDate(2027, 1, 23));
      final eve = resolver0.resolve(day15.addDays(-1), on);
      expect(eve.activePhase['nisf_shaban'], EventPhase.eve);
      expect(resolver0.resolve(day15, on).isActive('nisf_shaban'), isFalse);
    });

    test('eve keeps weekday of the day itself (jumuah_eve on Thursday)', () {
      final thu = resolve('2026-10-29');
      expect(thu.activePhase['jumuah_eve'], EventPhase.eve);
      expect(thu.notifications, contains('notif.fixture.jumuah_eve'));
      expect(resolve('2026-10-30').isActive('jumuah_eve'), isFalse);
    });

    test('both: day wins over eve', () {
      final rs = EventRuleParser.parseAll([
        {
          'id': 'b',
          'when': {
            'hijri_day': [1, 2],
          },
          'phase': 'both',
        },
      ]);
      final res = EventResolver(rs, IslamicCalendar());
      final cal = IslamicCalendar();
      final d1 = cal.gregorianOf(HijriDate(1448, 9, 1));
      expect(res.resolve(d1.addDays(-1)).activePhase['b'], EventPhase.eve);
      expect(res.resolve(d1).activePhase['b'], EventPhase.day);
      expect(res.resolve(d1.addDays(1)).activePhase['b'], EventPhase.day);
      expect(res.matches('b', d1.addDays(2)), isFalse);
    });
  });

  group('offset', () {
    test('offset +1 moves Ramadan start one day later (docs/02 A9)', () {
      final start = LocalDate(2027, 2, 8);
      final plus = EventResolver(rules, IslamicCalendar(offset: 1));
      expect(resolver0.matches('ramadan', start), isTrue);
      expect(resolver0.matches('ramadan', start.addDays(-1)), isFalse);
      expect(plus.matches('ramadan', start), isFalse);
      expect(plus.matches('ramadan', start.addDays(1)), isTrue);
      final minus = EventResolver(rules, IslamicCalendar(offset: -1));
      expect(minus.matches('ramadan', start.addDays(-1)), isTrue);
      expect(minus.matches('ramadan', start.addDays(-2)), isFalse);
    });

    test('Eid with offset -1 and +1', () {
      final eid = LocalDate(2027, 3, 9);
      for (final (offset, date) in [
        (0, eid),
        (1, eid.addDays(1)),
        (-1, eid.addDays(-1)),
      ]) {
        final r = EventResolver(rules, IslamicCalendar(offset: offset));
        expect(
          r.resolve(date).active.first.id,
          'eid_al_fitr',
          reason: '$offset',
        );
      }
    });
  });

  group('resolution rules (docs/03 4.4)', () {
    EventResolver custom(List<Map<String, Object?>> json) =>
        EventResolver(EventRuleParser.parseAll(json), IslamicCalendar());
    final friday = LocalDate(2026, 10, 30);

    Map<String, Object?> fri(String id, Map<String, Object?> extra) => {
      'id': id,
      'when': {'weekday': 5},
      ...extra,
    };

    test('equal priority: id alphabetical decides slots', () {
      final r = custom([
        fri('b', {
          'priority': 5,
          'quests': {'act': 'b.act'},
        }),
        fri('a', {
          'priority': 5,
          'quests': {'act': 'a.act'},
        }),
      ]).resolve(friday);
      expect(ids(r), ['a', 'b']);
      expect(r.quests[QuestSlot.act]!.templateId, 'a.act');
    });

    test('per-slot: lower event fills slots the higher one left free', () {
      final r = custom([
        fri('high', {
          'priority': 9,
          'cards': {
            'ayah_slots': [3],
            'surah': 36,
            'cursor': 'event_cursor.high',
          },
        }),
        fri('low', {
          'priority': 1,
          'cards': {
            'event_card_slot': 2,
            'ayah_slots': [3, 4],
            'surah': 18,
            'cursor': 'event_cursor.low',
          },
        }),
      ]).resolve(friday);
      expect(r.cards, {
        2: const EventCardClaim('low'),
        3: const EventAyahClaim('high', 36, 'event_cursor.high', 0),
        4: const EventAyahClaim('low', 18, 'event_cursor.low', 1),
      });
      expect(
        r.cards[4].toString(),
        'EventAyahClaim(low, 18, '
        'event_cursor.low, #1)',
      );
      expect(r.cards[2].toString(), 'EventCardClaim(low)');
      expect(r.active.first.toString(), contains('high'));
    });

    test('boosts multiply and cap at x6', () {
      final r = custom([
        fri('a', {
          'boost_tags': {'dhikr': 3},
        }),
        fri('b', {
          'boost_tags': {'dhikr': 3, 'dua': 1.5},
        }),
      ]).resolve(friday);
      expect(r.boostTags, {'dhikr': 6.0, 'dua': 1.5});
    });

    test('intro: highest is main, max 3 badges', () {
      final r = custom([
        for (var i = 1; i <= 5; i++)
          fri('e$i', {'priority': 10 - i, 'intro': 'intro.e$i'}),
        fri('no_intro', {'priority': 100}),
      ]).resolve(friday);
      expect(r.intro, (eventId: 'e1', introId: 'intro.e1'));
      expect(r.badges.map((b) => b.eventId), ['e2', 'e3', 'e4']);
    });

    test('exclusive keeps events with equal priority', () {
      final r = custom([
        fri('x', {'priority': 7, 'merge': 'exclusive'}),
        fri('y', {'priority': 7}),
        fri('z', {'priority': 6}),
      ]).resolve(friday);
      expect(ids(r), ['x', 'y']);
      expect(r.suppressed, ['z']);
    });

    test('mode comes from the highest event with mode', () {
      final r = custom([
        fri('m', {'priority': 1, 'mode': 'ramadan'}),
        fri('n', {'priority': 2}),
      ]).resolve(friday);
      expect(r.mode, 'ramadan');
      expect(r.active.last.mode, 'ramadan');
    });

    test('notifications are deduplicated in priority order', () {
      final r = custom([
        fri('a', {
          'priority': 2,
          'notifications': ['n.1', 'n.2'],
        }),
        fri('b', {
          'priority': 1,
          'notifications': ['n.2', 'n.3'],
        }),
      ]).resolve(friday);
      expect(r.notifications, ['n.1', 'n.2', 'n.3']);
    });

    test('user_flag, quest_progress and any', () {
      final res = custom([
        {
          'id': 'f',
          'when': {'user_flag': 'fasting_enabled'},
        },
        {
          'id': 'q',
          'when': {
            'quest_progress': {'id': 'shawwal6', 'lt': 6},
          },
        },
        {
          'id': 'any',
          'when': {
            'any': [
              {'weekday': 1},
              {'event_active': 'f'},
            ],
          },
        },
      ]);
      final none = res.resolve(friday);
      expect(ids(none), ['q']);
      final ctx = EventContext(
        flags: const {UserFlag.fastingEnabled},
        questProgress: const {'shawwal6': 6},
      );
      expect(ids(res.resolve(friday, ctx)), ['any', 'f']);
    });

    test('days_before with a list of n', () {
      final res = custom([
        {
          'id': 'target',
          'when': {'hijri_month': 9},
        },
        {
          'id': 'before',
          'when': {
            'days_before': {
              'event': 'target',
              'n': [3],
            },
          },
        },
      ]);
      final start = LocalDate(2027, 2, 8);
      expect(res.matches('before', start.addDays(-3)), isTrue);
      expect(res.matches('before', start.addDays(-2)), isFalse);
      expect(res.matches('before', start.addDays(-4)), isFalse);
    });

    test('resolver validates the rule set', () {
      expect(
        () => EventResolver(
          EventRuleParser.parseAll([fri('a', {})]) +
              EventRuleParser.parseAll([fri('a', {})]),
          IslamicCalendar(),
        ),
        throwsA(isA<EventRuleFormatException>()),
      );
    });

    test('claims: value equality and toString', () {
      expect(
        const EventCardClaim('a').hashCode,
        const EventCardClaim('a').hashCode,
      );
      expect(const EventCardClaim('a'), isNot(const EventCardClaim('b')));
      expect(kahf0.hashCode, kahf0.hashCode);
      expect(kahf0, isNot(kahf1));
      const q = QuestClaim('a', 't');
      expect(q, const QuestClaim('a', 't'));
      expect(q.hashCode, const QuestClaim('a', 't').hashCode);
      expect(q.toString(), 'QuestClaim(a, t)');
      final rule = EventRule(
        id: 'r',
        when: const WeekdayCondition(IntRangeMatcher(1, 7)),
      );
      expect(rule.effect, EventEffect.empty);
    });

    test('no events: empty resolution', () {
      final r = custom([]).resolve(friday);
      expect(r.active, isEmpty);
      expect(r.intro, isNull);
      expect(r.cards, isEmpty);
      expect(r.mode, isNull);
      expect(r.hijri, IslamicCalendar().hijriOf(friday));
      expect(r.date, friday);
    });
  });

  group('known dates (fixture rules)', () {
    // Gregorian -> ocakavany aktivny event (Umm al-Qura, offset 0).
    const expected = <(String, String, bool)>[
      ('2027-02-08', 'ramadan', true),
      ('2027-02-07', 'ramadan', false),
      ('2027-03-08', 'ramadan', true),
      ('2027-03-09', 'eid_al_fitr', true),
      ('2027-03-10', 'eid_al_fitr', false),
      ('2027-05-15', 'arafah', true),
      ('2027-05-16', 'eid_al_adha', true),
      ('2027-05-17', 'tashriq', true),
      ('2027-05-19', 'tashriq', true),
      ('2027-05-20', 'tashriq', false),
      ('2027-05-07', 'dhul_hijja_10', true),
      ('2027-06-06', 'hijri_new_year', true),
      ('2027-06-14', 'tasua', true),
      ('2027-06-15', 'ashura', true),
      ('2027-01-09', 'shaban', true),
      ('2027-03-10', 'shawwal_6', true),
      ('2027-02-12', 'jumuah', true),
      ('2027-02-13', 'jumuah', false),
    ];
    for (final (iso, id, active) in expected) {
      test('$iso $id = $active', () {
        expect(resolve(iso).isActive(id), active);
      });
    }

    test('shawwal_6 ends after 6 fasts', () {
      final done = EventContext(questProgress: const {'shawwal6': 6});
      expect(
        resolve('2027-03-10', context: done).isActive('shawwal_6'),
        isFalse,
      );
    });

    test('hijri new year: info event is only an intro badge', () {
      final r = resolve('2027-06-06');
      expect(r.hijri, HijriDate(1449, 1, 1));
      final info = r.active.firstWhere((e) => e.id == 'hijri_new_year');
      expect(info.effect, EventEffect.empty);
      expect(r.intro?.eventId, 'sacred_months');
      expect(r.badges.map((b) => b.eventId), contains('hijri_new_year'));
    });
  });
}
