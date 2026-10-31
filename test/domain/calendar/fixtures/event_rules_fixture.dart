/// TESTOVACIE FIXTURES, nie produkcne eventy.
///
/// Produkcne pravidla a ich texty pisu ludia v `prosoche-content` (K-06).
/// Tu su len struktury podla tabulky docs/03 5.1 (id, `when`, faza,
/// kategoria, priorita), aby sa dali otestovat kolizie z docs/03 5.2.
/// Id introv, questov a notifikacii su placeholdery `*.fixture.*`.
///
/// Odchylky od docs/03 5.1 (vid handoff E-01):
/// - `white_days` ma prioritu 55 namiesto 40, inak by `jumuah` (50, act
///   pool) vzal act quest a neplatil by riadok "Biely den v piatok".
/// - `ramadan` nedefinuje `read` (khatm plan), inak by v piatok nevzal
///   `jumuah` read quest (riadok "Piatok v Ramadane").
/// - Pooly kariet (sloty 9, 12) su zjednodusene na `event_card_slot`,
///   lebo kontrakt `EventEffect` pooly nema.
library;

const fixtureRules = <Map<String, Object?>>[
  {
    'id': 'eid_al_fitr',
    'when': {
      'hijri_month_day': [
        [10, 1],
      ],
    },
    'priority': 110,
    'merge': 'exclusive',
    'intro': 'intro.fixture.eid_al_fitr',
    'cards': {'event_card_slot': 9},
    'quests': {'act': 'act.fixture.eid'},
    'forbid_tags': ['siyam'],
  },
  {
    'id': 'eid_al_adha',
    'when': {
      'hijri_month_day': [
        [12, 10],
      ],
    },
    'priority': 110,
    'merge': 'exclusive',
    'intro': 'intro.fixture.eid_al_adha',
    'cards': {'event_card_slot': 9},
    'quests': {'act': 'act.fixture.eid'},
    'forbid_tags': ['siyam'],
  },
  {
    'id': 'laylat_al_qadr',
    'when': {
      'all': [
        {'hijri_month': 9},
        {
          'hijri_day': [21, 23, 25, 27, 29],
        },
      ],
    },
    'phase': 'eve',
    'priority': 105,
    'intro': 'intro.fixture.laylat_al_qadr',
    'quests': {'act': 'act.fixture.laylat_qadr'},
    'notifications': ['notif.fixture.laylat_qadr'],
  },
  {
    'id': 'ramadan_last10',
    'when': {
      'all': [
        {'hijri_month': 9},
        {
          'hijri_day': {'gte': 20, 'lte': 30},
        },
      ],
    },
    'priority': 102,
    'cards': {'event_card_slot': 12},
    'quests': {'act': 'act.fixture.last10'},
    'boost_tags': {'dua': 2.0, 'quran': 2.0},
  },
  {
    'id': 'ramadan',
    'when': {'hijri_month': 9},
    'priority': 100,
    'mode': 'ramadan',
    'intro': 'intro.fixture.ramadan',
    'cards': {'event_card_slot': 9},
    'quests': {'act': 'act.fixture.ramadan'},
    'boost_tags': {'siyam': 2.0, 'quran': 2.0, 'sadaqa': 2.0},
    'forbid_tags': ['white_day'],
  },
  {
    'id': 'arafah',
    'when': {
      'hijri_month_day': [
        [12, 9],
      ],
    },
    'priority': 95,
    'intro': 'intro.fixture.arafah',
    'cards': {'event_card_slot': 9},
    'quests': {'act': 'act.fixture.siyam_arafah'},
    'boost_tags': {'dua': 2.0},
  },
  {
    'id': 'tashriq',
    'when': {
      'all': [
        {'hijri_month': 12},
        {
          'hijri_day': {'gte': 11, 'lte': 13},
        },
      ],
    },
    'priority': 90,
    'intro': 'intro.fixture.tashriq',
    'quests': {'act': 'act.fixture.takbir'},
    'forbid_tags': ['siyam'],
  },
  {
    'id': 'dhul_hijja_10',
    'when': {
      'all': [
        {'hijri_month': 12},
        {
          'hijri_day': {'gte': 1, 'lte': 8},
        },
      ],
    },
    'priority': 80,
    'cards': {'event_card_slot': 9},
    'quests': {'act': 'act.fixture.dh10'},
    'boost_tags': {'dhikr': 2.0, 'sadaqa': 2.0},
  },
  {
    'id': 'ashura',
    'when': {
      'hijri_month_day': [
        [1, 10],
      ],
    },
    'priority': 70,
    'intro': 'intro.fixture.ashura',
    'quests': {'act': 'act.fixture.siyam_ashura'},
    'boost_tags': {'siyam': 2.0},
  },
  {
    'id': 'tasua',
    'when': {
      'hijri_month_day': [
        [1, 9],
      ],
    },
    'priority': 70,
    'intro': 'intro.fixture.tasua',
    'quests': {'act': 'act.fixture.siyam_tasua'},
  },
  {
    'id': 'shawwal_6',
    'when': {
      'all': [
        {'hijri_month': 10},
        {
          'hijri_day': {'gte': 2, 'lte': 30},
        },
        {
          'quest_progress': {'id': 'shawwal6', 'lt': 6},
        },
      ],
    },
    'priority': 60,
    'intro': 'intro.fixture.shawwal_6',
    'quests': {'act': 'act.fixture.siyam_shawwal6'},
  },
  {
    'id': 'white_days',
    'when': {
      'all': [
        {
          'hijri_day': [13, 14, 15],
        },
        {
          'not': {'hijri_month': 9},
        },
        {
          'not': {
            'hijri_month_day': [
              [12, 13],
            ],
          },
        },
      ],
    },
    'priority': 55,
    'intro': 'intro.fixture.white_days',
    'quests': {'act': 'act.fixture.siyam_white_day'},
  },
  {
    'id': 'jumuah',
    'when': {'weekday': 5},
    'priority': 50,
    'intro': 'intro.fixture.jumuah',
    'cards': {
      'event_card_slot': 2,
      'ayah_slots': [3, 4],
      'surah': 18,
      'cursor': 'event_cursor.jumuah',
    },
    'quests': {'read': 'read.fixture.kahf_full', 'act': 'act.fixture.jumuah'},
    'boost_tags': {'dhikr': 2.0, 'dua': 2.0},
  },
  {
    'id': 'jumuah_eve',
    'when': {'weekday': 4},
    'phase': 'eve',
    'priority': 50,
    'notifications': ['notif.fixture.jumuah_eve'],
  },
  {
    'id': 'pre_ramadan',
    'when': {
      'days_before': {
        'event': 'ramadan',
        'n': {'gte': 1, 'lte': 2},
      },
    },
    'priority': 35,
    'intro': 'intro.fixture.pre_ramadan',
    'quests': {'act': 'act.fixture.pre_ramadan'},
    'forbid_tags': ['siyam_nafl'],
  },
  {
    'id': 'shaban',
    'when': {'hijri_month': 8},
    'priority': 30,
    'intro': 'intro.fixture.shaban',
    'quests': {'act': 'act.fixture.shaban'},
    'boost_tags': {'siyam': 3.0},
  },
  {
    'id': 'mon_thu',
    'when': {
      'all': [
        {
          'weekday': [1, 4],
        },
        {
          'not': {'event_active': 'ramadan'},
        },
      ],
    },
    'priority': 20,
    'boost_tags': {'siyam_nafl': 2.0},
  },
  {
    'id': 'sacred_months',
    'when': {
      'hijri_month': [1, 7, 11, 12],
    },
    'priority': 15,
    'intro': 'intro.fixture.sacred_months',
    'boost_tags': {'adab_tongue': 1.5},
  },
  {
    'id': 'muharram',
    'when': {'hijri_month': 1},
    'priority': 15,
    'boost_tags': {'siyam': 2.0},
  },
  {
    'id': 'hijri_new_year',
    'when': {
      'hijri_month_day': [
        [1, 1],
      ],
    },
    'category': 'info',
    'priority': 10,
    'intro': 'intro.fixture.hijri_new_year',
  },
  {
    'id': 'isra_miraj',
    'when': {
      'all': [
        {
          'hijri_month_day': [
            [7, 27],
          ],
        },
        {'pref': 'show_optional_days'},
      ],
    },
    'category': 'optional',
    'priority': 10,
    'intro': 'intro.fixture.isra_miraj',
  },
  {
    'id': 'nisf_shaban',
    'when': {
      'all': [
        {
          'hijri_month_day': [
            [8, 15],
          ],
        },
        {'pref': 'show_optional_days'},
      ],
    },
    'phase': 'eve',
    'category': 'optional',
    'priority': 10,
    'intro': 'intro.fixture.nisf_shaban',
  },
  {
    'id': 'mawlid',
    'when': {
      'all': [
        {
          'hijri_month_day': [
            [3, 12],
          ],
        },
        {'pref': 'show_optional_days'},
      ],
    },
    'category': 'optional',
    'priority': 10,
    'intro': 'intro.fixture.mawlid',
  },
];
