import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/feed/feed.dart';

import 'feed_fixtures.dart';

void main() {
  const generator = FeedGenerator();
  FeedResult gen(FeedInputs i) => generator.generate(i);
  List<String> ids(FeedResult r) => [
    for (final c in r.set.cards) c.cardId.format(),
  ];
  List<String> slots(FeedResult r) => [
    for (final c in r.set.cards) c.slot.wire,
  ];
  List<int> readingAyahs(FeedResult r) => [
    for (final c in r.set.cards)
      if (c.khatm) (c.cardId as AyahCardId).ayahId.value,
  ];

  group('determinism', () {
    test('same input gives identical set (1000 seeds)', () {
      for (var seed = 0; seed < 1000; seed++) {
        FeedInputs make() => inputs(
          seed: seed,
          date: thursday.addDays(seed % 14),
          lang: allLangs[seed % allLangs.length],
          hour: 3 + seed % 20,
          cardsCount: const [8, 12, 16][seed % 3],
          wordsEnabled: seed % 5 != 0,
          readingPosition: AyahId.fromValue(
            const [1001, 2250, 18100, 114003][seed % 4],
          ),
          events: [if (seed % 7 == 1) jumuah, if (seed % 11 == 0) ramadan],
          pools_: pools(
            due: [
              for (var i = 0; i < seed % 3; i++)
                SrsDue(
                  lemmaId: 30 + i * 13,
                  due: thursday,
                  reps: seed % 4,
                  seenInContext: seed.isOdd,
                ),
            ],
          ),
        );
        final a = gen(make());
        final b = gen(make());
        expect(a.set, b.set, reason: 'seed $seed');
        expect(a.set.encode(), b.set.encode());
        expect(a.namesCursor, b.namesCursor);
        expect(a.eventCursors, b.eventCursors);
      }
    });

    test('different seeds vary the curated cards', () {
      final picks = {
        for (var seed = 0; seed < 30; seed++)
          gen(inputs(seed: seed)).set.cards[8].cardId,
      };
      expect(picks.length, greaterThan(3));
    });

    test('cards_json round trip of generated set', () {
      final r = gen(
        inputs(
          date: friday,
          events: [jumuah],
          pools_: pools(due: [SrsDue(lemmaId: 40, due: thursday, reps: 2)]),
        ),
      );
      expect(DailySet.decode(r.set.encode(), date: friday), r.set);
    });
  });

  group('composition', () {
    test('default 12 cards in plan 7.1 order, done outside N', () {
      final r = gen(
        inputs(
          pools_: pools(
            due: [
              SrsDue(lemmaId: 40, due: thursday),
              SrsDue(lemmaId: 41, due: thursday),
            ],
          ),
        ),
      );
      expect(slots(r), [
        'intro',
        'ayah',
        'ayah',
        'ayah',
        'word',
        'ayah',
        'ayah',
        'srs',
        'hadith_dua',
        'ayah',
        'srs',
        'reflection',
      ]);
      expect(r.set.n, 12);
      expect(r.set.cards.any((c) => c.cardId is DoneCardId), isFalse);
      expect(r.set.doneCardId, DoneCardId(thursday));
      expect(r.set.cards.first.cardId, IntroCardId(thursday));
      expect(r.set.contentVersion, '2026.11.1');
      expect(r.set.tz, 'Europe/Bratislava');
      expect(r.shorterSetAvailable, isFalse);
    });

    test('N matches feed.cards_count 8 and 16', () {
      expect(gen(inputs(cardsCount: 8)).set.n, 8);
      expect(gen(inputs(cardsCount: 16)).set.n, 16);
      expect(gen(inputs(cardsCount: 16)).set.cards.last.slot, Slot.reflection);
    });

    test('reading verses continue from reading_position', () {
      final r = gen(inputs(readingPosition: AyahId(2, 250)));
      // Bez due je aj slot 11 vers (docs/02 B4), spolu 7 versov.
      expect(readingAyahs(r), [for (var i = 0; i < 7; i++) 2251 + i]);
    });

    test('no reading position starts at 1:1', () {
      final r = generator.generate(
        FeedInputs(
          date: thursday,
          seed: 1,
          generatedAtLocalTime: DateTime(2026, 10, 29, 13),
          prefs: FeedPrefs(lang: 'en'),
          pools: pools(),
        ),
      );
      expect(readingAyahs(r).first, 1001);
    });
  });

  group('words disabled [ROZHODNUTIE]', () {
    test('N = 10, no word or quiz, slot 11 is name', () {
      final r = gen(
        inputs(
          wordsEnabled: false,
          pools_: pools(due: [SrsDue(lemmaId: 40, due: thursday)]),
        ),
      );
      expect(r.set.n, 10);
      expect(
        r.set.cards.where(
          (c) => c.cardId is WordCardId || c.cardId is QuizCardId,
        ),
        isEmpty,
      );
      expect(slots(r), [
        'intro',
        'ayah',
        'ayah',
        'ayah',
        'ayah',
        'ayah',
        'hadith_dua',
        'ayah',
        'name',
        'reflection',
      ]);
    });

    test('8 cards without words = 7', () {
      final r = gen(inputs(wordsEnabled: false, cardsCount: 8));
      expect(r.set.n, 7);
      expect(r.set.cards[5].slot, Slot.name);
    });
  });

  group('SRS slots (docs/02 B4)', () {
    test('no due: slot 8 name, slot 11 verse', () {
      final r = gen(inputs());
      expect(r.set.cards[7].cardId, isA<NameCardId>());
      expect(r.set.cards[10].cardId, isA<AyahCardId>());
      expect(readingAyahs(r), hasLength(7));
    });

    test('one due: slot 8 quiz, slot 11 name', () {
      final r = gen(
        inputs(
          pools_: pools(due: [SrsDue(lemmaId: 40, due: thursday)]),
        ),
      );
      final quiz = r.set.cards[7];
      expect(quiz.cardId, QuizCardId(40, 'ar2mean'));
      expect(quiz.distractors, hasLength(3));
      expect(quiz.distractors, isNot(contains(40)));
      for (final d in quiz.distractors) {
        expect(lemmaIndex.lemma(d)!.root, isNot(lemmaIndex.lemma(40)!.root));
        expect((d - 40).abs(), lessThanOrEqualTo(50));
      }
      expect(r.set.cards[10].cardId, isA<NameCardId>());
    });

    test('due sorted by date, qtypes depend on reps and context', () {
      final r = gen(
        inputs(
          pools_: pools(
            due: [
              SrsDue(lemmaId: 60, due: thursday, reps: 3, seenInContext: true),
              SrsDue(lemmaId: 50, due: thursday.addDays(-2)),
            ],
          ),
        ),
      );
      expect(r.set.cards[7].cardId, QuizCardId(50, 'ar2mean'));
      final second = r.set.cards[10].cardId as QuizCardId;
      expect(second.lemmaId, 60);
      final qtypes = {
        for (var seed = 0; seed < 40; seed++)
          (gen(
                    inputs(
                      seed: seed,
                      pools_: pools(
                        due: [
                          SrsDue(
                            lemmaId: 60,
                            due: thursday,
                            reps: 3,
                            seenInContext: true,
                          ),
                        ],
                      ),
                    ),
                  ).set.cards[7].cardId
                  as QuizCardId)
              .qtype,
      };
      expect(qtypes, {'ar2mean', 'mean2ar', 'context'});
    });

    test('due lemma without meaning in language is skipped', () {
      final r = gen(
        inputs(
          lang: 'bn',
          pools_: pools(due: [SrsDue(lemmaId: 40, due: thursday)]),
        ),
      );
      expect(r.set.cards.any((c) => c.cardId is QuizCardId), isFalse);
    });

    test('distractors fall back to farther ranks when needed', () {
      final small = InMemoryLemmaIndex([
        for (var i = 1; i <= 4; i++)
          LemmaInfo(lemmaId: i, rank: i * 100, langs: const {'en'}),
      ]);
      final r = gen(
        inputs(
          pools_: pools(
            lemmas: small,
            due: [SrsDue(lemmaId: 1, due: thursday)],
          ),
        ),
      );
      expect(r.set.cards[7].distractors, [2, 3, 4]);
      final tooFew = gen(
        inputs(
          pools_: pools(
            lemmas: InMemoryLemmaIndex([
              LemmaInfo(lemmaId: 1, rank: 1, langs: const {'en'}),
            ]),
            due: [SrsDue(lemmaId: 1, due: thursday)],
          ),
        ),
      );
      expect(tooFew.set.cards[7].cardId, isA<NameCardId>());
    });
  });

  group('word card (docs/02 B3)', () {
    test('lowest-rank lemma from verses 2-4 not in SRS', () {
      final r = gen(inputs());
      final verses = [
        for (final c in r.set.cards.sublist(1, 4))
          (c.cardId as AyahCardId).ayahId,
      ];
      final candidates = [
        for (final a in verses)
          for (final l in lemmaIndex.lemmasInAyah(a)) (l.rank, l.lemmaId, a),
      ]..sort((x, y) => x.$1.compareTo(y.$1));
      final word = r.set.cards[4];
      expect(word.cardId, WordCardId(candidates.first.$2));
      expect(word.ctxAyahId, candidates.first.$3);

      final inSrs = gen(
        inputs(pools_: pools(srs: {for (final c in candidates) c.$2})),
      );
      final next = inSrs.set.cards[4];
      expect(next.cardId, isA<WordCardId>());
      expect(verses, isNot(contains(next.ctxAyahId)));
    });

    test('falls back to first lemma by rank without occurrences', () {
      final r = gen(
        inputs(
          pools_: pools(
            lemmas: InMemoryLemmaIndex([
              LemmaInfo(lemmaId: 5, rank: 2, langs: const {'en'}),
              LemmaInfo(lemmaId: 6, rank: 1, langs: const {'en'}),
            ]),
            srs: {6},
          ),
        ),
      );
      expect(r.set.cards[4].cardId, WordCardId(5));
      expect(r.set.cards[4].ctxAyahId, isNull);
    });

    test('no lemma data: word slot falls back to a verse', () {
      final r = gen(inputs(pools_: pools(withLemmas: false)));
      expect(r.set.n, 12);
      expect(r.set.cards[4].cardId, isA<AyahCardId>());
      expect(r.set.cards[7].cardId, isA<NameCardId>());
    });
  });

  group('slot 9 by phase (docs/03 3.4)', () {
    Set<Type> typesAt(int hour) => {
      for (var seed = 0; seed < 20; seed++)
        gen(inputs(seed: seed, hour: hour)).set.cards[8].cardId.runtimeType,
    };

    test('morning and evening prefer dua, day and night hadith', () {
      expect(typesAt(7), {DuaCardId});
      expect(typesAt(17), {DuaCardId});
      expect(typesAt(13), {HadithCardId});
      expect(typesAt(23), {HadithCardId});
      for (var seed = 0; seed < 20; seed++) {
        final m = gen(inputs(seed: seed, hour: 7)).set;
        expect((m.cards[8].cardId as DuaCardId).duaId, lessThanOrEqualTo(7));
        expect(m.phase, DayPhase.morning);
        final e = gen(inputs(seed: seed, hour: 17)).set;
        expect((e.cards[8].cardId as DuaCardId).duaId, inInclusiveRange(8, 14));
      }
    });

    test('phase from prayer boundaries', () {
      final base = inputs();
      final r = generator.generate(
        FeedInputs(
          date: base.date,
          seed: 1,
          generatedAtLocalTime: base.generatedAtLocalTime,
          dayBoundaries: DayBoundaries(
            fajr: DateTime(2026, 10, 29, 5),
            dhuhr: DateTime(2026, 10, 29, 11),
            asr: DateTime(2026, 10, 29, 12, 30),
            isha: DateTime(2026, 10, 29, 18),
          ),
          prefs: base.prefs,
          pools: base.pools,
        ),
      );
      expect(r.set.phase, DayPhase.evening);
      expect(r.set.cards[8].cardId, isA<DuaCardId>());
    });

    test('only sahih and hasan hadith', () {
      for (var seed = 0; seed < 200; seed++) {
        final id = gen(inputs(seed: seed)).set.cards[8].cardId as HadithCardId;
        expect(id.hadithId, lessThan(39));
      }
    });

    test('language without morning dua uses general pool', () {
      final r = gen(inputs(lang: 'id', hour: 7));
      final id = r.set.cards[8].cardId;
      expect(id, isA<HadithCardId>());
      expect((id as HadithCardId).hadithId.isEven, isTrue);
    });
  });

  group('names (docs/02 B7)', () {
    test('cursor 99 gives name 99 and wraps to 1', () {
      final r = gen(inputs(history: FeedHistory(namesCursor: 99)));
      expect(r.set.cards[7].cardId, NameCardId(99));
      expect(r.namesCursor, 1);
    });

    test('names without text in language are skipped', () {
      final r = gen(inputs(lang: 'id', history: FeedHistory(namesCursor: 2)));
      expect(r.set.cards[7].cardId, NameCardId(3));
      expect(r.namesCursor, 4);
    });
  });

  group('friday event (docs/02 B9, D2, E4)', () {
    test('event card in slot 2 and al-Kahf in 3-4 with event_cursor', () {
      final r = gen(inputs(date: friday, events: [jumuah]));
      expect(r.set.cards[1].cardId, EventCardId('jumuah_fixture', friday));
      expect(r.set.cards[1].slot, Slot.event);
      expect(ids(r).sublist(2, 4), ['ayah:18001', 'ayah:18002']);
      expect(r.set.cards[2].slot, Slot.eventAyah);
      expect(r.set.cards[2].khatm, isFalse);
      expect(r.eventCursors, {'event_cursor.jumuah_fixture': 18002});
      expect(r.set.cards.first.eventId, 'jumuah_fixture');
      // Citanie khatmu pokracuje od reading_position, nie od eventu.
      expect(readingAyahs(r).first, 2251);
      expect(r.set.n, 12);
    });

    test('next friday continues, wraps after 18:110', () {
      final next = gen(
        inputs(
          date: friday.addDays(7),
          events: [jumuah],
          history: FeedHistory(
            eventCursors: const {'event_cursor.jumuah_fixture': 18002},
          ),
        ),
      );
      expect(ids(next).sublist(2, 4), ['ayah:18003', 'ayah:18004']);
      final wrap = gen(
        inputs(
          date: friday,
          events: [jumuah],
          history: FeedHistory(
            eventCursors: const {'event_cursor.jumuah_fixture': 18109},
          ),
        ),
      );
      expect(ids(wrap).sublist(2, 4), ['ayah:18110', 'ayah:18001']);
      expect(wrap.eventCursors['event_cursor.jumuah_fixture'], 18001);
    });

    test('cursor from another surah restarts at verse 1', () {
      final r = gen(
        inputs(
          date: friday,
          events: [jumuah],
          history: FeedHistory(
            eventCursors: const {'event_cursor.jumuah_fixture': 2255},
          ),
        ),
      );
      expect(ids(r)[2], 'ayah:18001');
    });

    test('event without text in language: fallback, intro only hijri', () {
      final r = gen(inputs(date: friday, lang: 'tr', events: [jumuah]));
      expect(r.set.cards[1].cardId, isA<AyahCardId>());
      expect(r.set.cards[1].khatm, isTrue);
      expect(r.set.cards.first.eventId, isNull);
      expect(ids(r).sublist(2, 4), ['ayah:18001', 'ayah:18002']);
      expect(r.set.n, 12);
    });
  });

  group('events and Ramadan', () {
    test('Ramadan changes composition: event card and seasonal pool', () {
      final r = gen(inputs(events: [ramadan]));
      expect(r.set.cards[1].cardId, EventCardId('ramadan_fixture', thursday));
      expect(ramadanHadiths.map((c) => c.id), contains(r.set.cards[8].cardId));
      expect(r.set.n, 12);
    });

    test('friday in Ramadan: per-slot merge by priority', () {
      final r = gen(inputs(date: friday, events: [jumuah, ramadan]));
      // Ramadan (100) berie slot 2, jumuah (50) ostane na 3-4.
      expect(r.set.cards[1].cardId, EventCardId('ramadan_fixture', friday));
      expect(ids(r).sublist(2, 4), ['ayah:18001', 'ayah:18002']);
      expect(r.set.cards.first.eventId, 'ramadan_fixture');
    });

    test('event slot 1 or out of range is ignored', () {
      final odd = ActiveEvent(
        id: 'odd_fixture',
        effect: EventEffect(
          eventCardSlot: 1,
          ayahSlots: const [40],
          surah: 1,
          cursor: 'event_cursor.odd_fixture',
        ),
      );
      final r = gen(inputs(events: [odd]));
      expect(r.set.cards.first.cardId, IntroCardId(thursday));
      expect(r.set.n, 12);
      expect(r.eventCursors, isEmpty);
    });
  });

  group('khatm (docs/02 B2, B12)', () {
    test('114:6 continues with 1:1 and inserts khatm card outside N', () {
      final r = gen(
        inputs(
          readingPosition: AyahId(114, 4),
          history: FeedHistory(completedKhatms: 2),
        ),
      );
      expect(readingAyahs(r).take(4), [114005, 114006, 1001, 1002]);
      final i = ids(r).indexOf('ayah:114006');
      expect(r.set.cards[i + 1].cardId, KhatmCardId(3));
      expect(r.set.cards[i + 1].slot, Slot.khatm);
      expect(r.set.n, 12);
      expect(r.set.cards, hasLength(13));
      expect(DailySet.decode(r.set.encode(), date: thursday), r.set);
    });
  });

  group('shorter set (docs/01 D6)', () {
    test('available after >= 7 inactive days, 6 cards', () {
      final r = gen(inputs(inactiveDays: 7, shorterSet: true));
      expect(r.shorterSetAvailable, isTrue);
      expect(r.set.n, FeedGenerator.shorterSetSize);
      expect(slots(r), [
        'intro',
        'ayah',
        'ayah',
        'ayah',
        'hadith_dua',
        'reflection',
      ]);
      final notYet = gen(inputs(inactiveDays: 6, shorterSet: true));
      expect(notYet.shorterSetAvailable, isFalse);
      expect(notYet.set.n, 12);
      final offered = gen(inputs(inactiveDays: 9));
      expect(offered.shorterSetAvailable, isTrue);
      expect(offered.set.n, 12);
    });
  });

  group('disabled_ids', () {
    test('disabled items are never selected', () {
      final disabled = <CardId>{
        for (final h in hadiths) h.id,
        NameCardId(1),
        AyahCardId(AyahId(2, 251)),
        for (var i = 1; i <= 10; i++) ReflectionCardId(i),
        EventCardId('jumuah_fixture', friday),
        AyahCardId(AyahId(18, 1)),
      };
      for (var seed = 0; seed < 50; seed++) {
        final r = gen(
          inputs(
            seed: seed,
            date: friday,
            events: [jumuah],
            history: FeedHistory(disabledIds: disabled),
          ),
        );
        for (final c in r.set.cards) {
          expect(disabled, isNot(contains(c.cardId)), reason: '$c');
        }
        expect(r.set.n, 12);
        expect(ids(r)[2], 'ayah:18002');
      }
    });
  });

  group('language fallback [ROZHODNUTIE]', () {
    for (final lang in allLangs) {
      test('$lang: every card has text and N is constant', () {
        for (var seed = 0; seed < 60; seed++) {
          final r = gen(
            inputs(
              seed: seed,
              lang: lang,
              date: thursday.addDays(seed % 7),
              hour: 4 + seed % 20,
              events: [
                if (thursday.addDays(seed % 7).weekday == 5) jumuah,
                if (seed % 9 == 0) ramadan,
              ],
              pools_: pools(
                due: [
                  SrsDue(lemmaId: 40 + seed % 5, due: thursday),
                  SrsDue(lemmaId: 90, due: thursday, reps: 2),
                ],
              ),
            ),
          );
          expect(r.set.n, 12, reason: '$lang seed $seed');
          for (final c in r.set.cards) {
            expect(hasText(c, lang), isTrue, reason: '$lang $c');
            for (final d in c.distractors) {
              expect(lemmaIndex.lemma(d)!.langs, contains(lang));
            }
          }
          expect(
            r.set.cards.map((c) => c.cardId).toSet(),
            hasLength(r.set.cards.length),
          );
        }
      });
    }

    test('fallbacks alternate verse and hadith in reading order', () {
      // bn: bez slovicok, mien, zamysleni, dua; hadisy kazdy piaty.
      final r = gen(inputs(lang: 'bn'));
      expect(slots(r), [
        'intro',
        'ayah',
        'ayah',
        'ayah',
        'ayah', // word -> fallback 1 = vers
        'ayah',
        'ayah',
        'hadith_dua', // name -> fallback 2 = hadis
        'hadith_dua',
        'ayah',
        'ayah', // slot 11 bez due = vers (docs/02 B4)
        'ayah', // reflection -> fallback 3 = vers
      ]);
      final reading = readingAyahs(r);
      expect(reading, [for (var i = 0; i < 9; i++) 2251 + i]);
      for (final c in r.set.cards.where((c) => c.cardId is HadithCardId)) {
        expect((c.cardId as HadithCardId).hadithId % 5, 0);
      }
    });

    test('no hadith in language: fallback is always a verse', () {
      final r = gen(
        inputs(
          lang: 'ur',
          pools_: FeedPools(names: names, eventTextLangs: eventTextLangs),
        ),
      );
      expect(r.set.n, 12);
      expect(
        r.set.cards.where((c) => c.cardId is! AyahCardId).map((c) => c.slot),
        [Slot.intro, Slot.name],
      );
    });
  });
}
