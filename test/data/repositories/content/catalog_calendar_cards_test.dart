import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/data/repositories/cards/card_content_repository.dart';
import 'package:prosoche/data/repositories/cards/hadith_extra_repository.dart';
import 'package:prosoche/data/repositories/catalog/content_catalog.dart';
import 'package:prosoche/data/repositories/catalog/content_rules.dart';
import 'package:prosoche/data/repositories/infra/curated_id.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';

import '../../db/fixtures/content_fixture.dart';
import '../harness.dart';

Harness? _h;
Harness get h => _h!;
set h(Harness v) => _h = v;

void main() {
  final fri = LocalDate(2026, 10, 30);
  final thu = LocalDate(2026, 10, 29);

  tearDown(() async {
    await _h?.dispose();
    _h = null;
  });

  group('content rules', () {
    test('event rule from pipeline shape', () {
      final json = eventRuleJson(
        id: 'ev',
        priority: 3,
        category: 'core',
        ruleJson: jsonEncode({
          'when': {'weekday': 5},
          'phase': 'day',
          'merge': null,
          'effects': {
            'quests': {'read': 'read.x.y'},
          },
        }),
        cardOverridesJson: jsonEncode({'event_card_slot': 2}),
        questOverridesJson: jsonEncode({'act': 'ignored'}),
      );
      expect(json, {
        'when': {'weekday': 5},
        'phase': 'day',
        'quests': {'read': 'read.x.y'},
        'cards': {'event_card_slot': 2},
        'id': 'ev',
        'priority': 3,
        'category': 'core',
      });
      final rule = parseEventRow(
        id: 'ev',
        priority: 3,
        category: 'core',
        ruleJson: jsonEncode({
          'when': {'weekday': 5},
        }),
        questOverridesJson: jsonEncode({'act': 'act.x.y'}),
      );
      expect(rule.effect.quests[QuestSlot.act], 'act.x.y');
      expect(
        () => eventRuleJson(
          id: 'x',
          priority: 0,
          category: 'core',
          ruleJson: '[]',
        ),
        throwsFormatException,
      );
    });

    test('quest template: completion, count, act, params, season', () {
      final t = parseQuestRow(
        id: 'read.a.b',
        slot: 'read',
        ruleJson: jsonEncode({
          'when': {
            'all': [
              {'event_active': 'ramadan'},
              {'weekday': 5},
            ],
          },
          'completion': {
            'mode': 'auto',
            'metric': 'ayah_read',
            'target': {'param': 'n'},
          },
          'params': {
            'n': [5, 10],
          },
        }),
        langs: {'en'},
        weight: 2,
        cooldownDays: 7,
        facetsJson: jsonEncode({
          'excused_ok': true,
          'season': ['eid'],
        }),
      );
      expect(t.rule!.types, {CardType.ayah});
      expect(t.params, {
        'n': [5, 10],
      });
      expect(t.season, {'ramadan', 'eid'});
      expect(t.excusedOk, isTrue);

      final count = parseQuestRow(
        id: 'learn.a.b',
        slot: 'learn',
        ruleJson: jsonEncode({
          'count': {'type': 'name', 'min': 1},
        }),
        langs: {'en'},
      );
      expect(count.rule!.types, {CardType.name});

      final fixed = parseQuestRow(
        id: 'learn.a.c',
        slot: 'learn',
        ruleJson: jsonEncode({
          'completion': {'mode': 'auto', 'metric': 'srs_reviewed', 'target': 2},
        }),
        langs: {'en'},
      );
      expect(fixed.rule!.target(const {}), 2);

      final act = parseQuestRow(
        id: 'act.a.b',
        slot: 'act',
        ruleJson: jsonEncode({
          'completion': {'mode': 'self_report'},
        }),
        langs: {'en'},
      );
      expect(act.rule, isNull);

      for (final bad in [
        {
          'completion': {
            'mode': 'auto',
            'metric': 'surah_completed',
            'target': 1,
          },
        },
        {
          'completion': {'mode': 'auto', 'metric': 'ayah_read', 'target': 'x'},
        },
        {
          'params': {'n': 'x'},
          'count': {'type': 'ayah', 'min': 1},
        },
      ]) {
        expect(
          () => parseQuestRow(
            id: 'read.a.b',
            slot: 'read',
            ruleJson: jsonEncode(bad),
            langs: const {},
          ),
          throwsFormatException,
        );
      }
      expect(
        () => parseQuestRow(
          id: 'x',
          slot: 'nope',
          ruleJson: '{}',
          langs: const {},
        ),
        throwsFormatException,
      );
    });

    test('stringList tolerates garbage', () {
      expect(stringList(null), isEmpty);
      expect(stringList('not json'), isEmpty);
      expect(stringList('{"a":1}'), isEmpty);
      expect(stringList('["a", 1, "b"]'), ['a', 'b']);
    });

    test('curated numeric ids are stable and drop collisions', () {
      expect(
        curatedNumericId('dua.morning.a'),
        curatedNumericId('dua.morning.a'),
      );
      expect(curatedNumericId('dua.morning.a'), inInclusiveRange(1, 999999999));
      final index = CuratedIdIndex(['a', 'b', 'a']);
      expect(index.textId(curatedNumericId('b')), 'b');
      expect(index.number('a'), curatedNumericId('a'));
      expect(index.textIds, containsAll(['a', 'b']));
      expect(index.collisions, 0);
    });
  });

  group('ContentCatalog', () {
    test('loads valid rows, skips invalid ones and logs only counts', () async {
      h = await Harness.create();
      final sink = RingBufferLog();
      final catalog = ContentCatalog(
        Future.value(h.content),
        logger: AppLogger(sinks: [sink], echoToConsole: false),
      );
      expect((await catalog.eventRules()).map((r) => r.id), ['fx_friday']);
      expect(
        (await catalog.questTemplates()).map((t) => t.id),
        unorderedEquals(['q_act', 'read.fx.verses']),
      );
      final pools = await catalog.feedPools();
      expect(pools.hadiths, hasLength(3));
      expect(pools.hadiths.first.langs, {'en'});
      expect(pools.duas, hasLength(3));
      expect(pools.reflections.single.reviewed, isFalse);
      expect(pools.names.map((n) => n.id), [NameCardId(1), NameCardId(2)]);
      expect(pools.eventTextLangs['fx_friday'], {'en'});
      expect(await catalog.contentVersion(), 'fixture');
      expect(sink.entries.map((e) => e.kv['type']), contains('event_rule'));
    });

    test('broken event set is pruned', () async {
      h = await Harness.create(rules: false);
      await h.content.customStatement(
        'INSERT INTO islamic_event (id, status, origin, category, priority, '
        'rule_json) VALUES (?, ?, ?, ?, ?, ?)',
        [
          'fx_ref',
          'approved',
          'example',
          'core',
          1,
          jsonEncode({
            'when': {'event_active': 'missing'},
          }),
        ],
      );
      expect(await h.catalog.eventRules(), isEmpty);
    });
  });

  group('CalendarRepository', () {
    setUp(() async => h = await Harness.create());

    test('hijri date follows the offset', () async {
      final base = await h.calendar.hijriDate(thu);
      await h.settings.set(SettingsKeys.hijriOffset, 1);
      final shifted = await h.calendar.hijriDate(thu);
      expect(shifted, isNot(base));
      expect((await h.calendar.calendar()).offset, 1);
    });

    test('friday event, month view and texts', () async {
      final r = await h.calendar.resolve(fri);
      expect(r.isActive('fx_friday'), isTrue);
      expect((await h.calendar.resolve(thu)).active, isEmpty);
      final hijri = await h.calendar.hijriDate(fri);
      final month = await h.calendar.month(hijri.year, hijri.month);
      expect(month.days.length, inInclusiveRange(29, 30));
      expect(month.eventIds, ['fx_friday']);
      expect(
        month.days
            .where((d) => d.eventIds.isNotEmpty)
            .every((d) => d.date.weekday == DateTime.friday),
        isTrue,
      );
      expect(
        (await h.calendar.eventText('fx_friday', 'en'))!.title,
        '[PLACEHOLDER friday]',
      );
      expect(await h.calendar.eventText('fx_friday', 'tr'), isNull);
      final fallback = await h.calendar.eventText(
        'fx_friday',
        'tr',
        allowEnFallback: true,
      );
      expect(fallback!.lang, 'en');
    });
  });

  group('CardContentRepository', () {
    setUp(() async => h = await Harness.create());

    Future<CardContent?> load(CardId id, [String lang = 'en']) =>
        h.cards.load(id, lang: lang);

    test('intro, event and khatm', () async {
      final intro = (await load(IntroCardId(fri)))! as IntroContent;
      expect(intro.event!.eventId, 'fx_friday');
      expect(intro.moreEvents, 0);
      expect(intro.hijri, await h.calendar.hijriDate(fri));
      final plain = (await load(IntroCardId(thu)))! as IntroContent;
      expect(plain.event, isNull);
      final ev = (await load(EventCardId('fx_friday', fri)))! as EventContent;
      expect(ev.text!.title, '[PLACEHOLDER friday]');
      expect(((await load(KhatmCardId(2)))! as KhatmContent).n, 2);
    });

    test('ayah with surah, missing ayah is null', () async {
      final a = (await load(AyahCardId(AyahId(2, 255))))! as AyahContent;
      expect(a.ayah.textUthmani, uthmaniOf(2, 255));
      expect(a.surah.id, 2);
      expect(await load(AyahCardId(AyahId(18, 1))), isNull);
    });

    test('hadith, dua, name and reflection in the content language', () async {
      final hd = (await load(HadithCardId(13)))! as HadithContent;
      expect(hd.grade, 'hasan');
      // BF-02: arabsky original stupna pre AR UI.
      expect(hd.gradeAr, '[PLACEHOLDER grade]');
      expect(hd.lang, 'en');
      expect(hd.text, isNotNull);
      expect(hd.arabicOnly, isFalse);
      expect(await load(HadithCardId(99)), isNull);

      final duas = await h.catalog.duaIds();
      final morning =
          (await load(DuaCardId(duas.number('dua_morning')!)))! as DuaContent;
      expect(morning.text, '[PLACEHOLDER dua text]');
      expect(morning.lang, 'en');
      final noText =
          (await load(DuaCardId(duas.number('dua_any')!)))! as DuaContent;
      expect(noText.text, isNull);
      expect(await load(DuaCardId(12345)), isNull);

      final name = (await load(NameCardId(1)))! as NameContent;
      expect(name.refAyah, AyahId(1, 1));
      expect(name.meaning, '[PLACEHOLDER name meaning]');
      final bare = (await load(NameCardId(2)))! as NameContent;
      expect(bare.meaning, isNull);
      expect(await load(NameCardId(50)), isNull);

      final refl = await h.catalog.reflectionIds();
      final r =
          (await load(ReflectionCardId(refl.number('refl_a')!)))!
              as ReflectionContent;
      expect(r.lang, 'en');
      expect(await load(ReflectionCardId(1)), isNull);
    });

    // BF-01: nabozensky text sa nikdy nefallbackuje na EN (docs/03 7.3).
    test('missing language: Arabic original only, never en', () async {
      final hd = (await load(HadithCardId(13), 'bn'))! as HadithContent;
      expect(hd.textAr, isNotEmpty);
      expect(hd.text, isNull);
      expect(hd.lang, isNull);
      expect(hd.title, isNull);
      expect(hd.arabicOnly, isFalse);
      // Zbierka, cislo a stupen ostavaju (plan 17.11).
      expect(hd.collection, isNotEmpty);
      expect(hd.grade, 'hasan');

      final duas = await h.catalog.duaIds();
      final dua =
          (await load(DuaCardId(duas.number('dua_morning')!), 'bn'))!
              as DuaContent;
      expect(dua.text, isNull);
      expect(dua.lang, isNull);
      expect(dua.textAr, isNotEmpty);
      expect(dua.arabicOnly, isFalse);

      final name = (await load(NameCardId(1), 'bn'))! as NameContent;
      expect(name.meaning, isNull);
      expect(name.shortNote, isNull);
      expect(name.lang, isNull);

      // Zamyslenie nema original: bez textu sa karta preskoci.
      final refl = await h.catalog.reflectionIds();
      expect(
        await load(ReflectionCardId(refl.number('refl_a')!), 'tr'),
        isNull,
      );
    });

    test('Arabic UI: the original is the text, no translation', () async {
      final hd = (await load(HadithCardId(13), 'ar'))! as HadithContent;
      expect(hd.gradeAr, '[PLACEHOLDER grade]');
      expect(hd.text, isNull);
      expect(hd.lang, isNull);
      expect(hd.arabicOnly, isTrue);

      final duas = await h.catalog.duaIds();
      final dua =
          (await load(DuaCardId(duas.number('dua_morning')!), 'ar'))!
              as DuaContent;
      expect(dua.text, isNull);
      expect(dua.arabicOnly, isTrue);

      final name = (await load(NameCardId(1), 'ar'))! as NameContent;
      expect(name.meaning, isNull);
      expect(name.arabicOnly, isTrue);

      final ayah =
          (await load(AyahCardId(AyahId(2, 255)), 'ar'))! as AyahContent;
      expect(ayah.arabicOnly, isTrue);
      expect(ayah.ayah.translation, isNull);
    });

    test('verse keeps the B0.6 en fallback with the EN tag', () async {
      final a = (await load(AyahCardId(AyahId(2, 255)), 'bn'))! as AyahContent;
      expect(a.arabicOnly, isFalse);
      expect(a.ayah.translation?.lang, 'en');
      expect(a.ayah.translation?.isFallback, isTrue);
    });

    test('word, quiz and done have no content', () async {
      expect(await load(WordCardId(1)), isNull);
      expect(await load(QuizCardId(1, 'ar2mean')), isNull);
      expect(await load(DoneCardId(thu)), isNull);
    });

    test('hadith extra is unavailable until D-05', () async {
      expect(
        await const NoHadithExtraRepository().explanation(11, 'en'),
        isNull,
      );
      expect(fixtureAyahCount, 293);
    });
  });
}
