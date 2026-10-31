import 'package:meta/meta.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/quests/card_activity.dart';
import 'package:sakina/domain/quests/daily_quest.dart';
import 'package:sakina/domain/quests/quest_template.dart';

/// Vstup vyberu questov na jeden den.
@immutable
final class QuestSelectionInput {
  QuestSelectionInput({
    required this.date,
    required this.seed,
    required this.lang,
    required List<QuestTemplate> templates,
    List<ActiveEvent> activeEvents = const [],
    List<QuestLogEntry> history = const [],
    this.excused = false,
    this.wordsEnabled = true,
    this.setVerses,
  }) : templates = List.unmodifiable(templates),
       activeEvents = List.unmodifiable(activeEvents),
       history = List.unmodifiable(history);

  /// `activeSetDate` (docs/02 0.1).
  final LocalDate date;

  /// Seed dna, napr. [QuestEngine.daySeed].
  final int seed;

  /// Jazyk pouzivatela (`ui.locale` / jazyk obsahu), napr. `en`.
  final String lang;

  /// Schvalene sablony zo vsetkych slotov.
  final List<QuestTemplate> templates;

  /// Aktivne eventy dna (E-01 EventResolver).
  final List<ActiveEvent> activeEvents;

  /// `quest_log`; zaznamy s datumom >= [date] sa ignoruju, aby bol vyber
  /// pre den vzdy rovnaky.
  final List<QuestLogEntry> history;

  /// Zapnute "ospravedlnene dni" (docs/03 6.5): len `excused_ok` sablony.
  final bool excused;

  /// `words_enabled`; ked je false, nevyberu sa sablony nad kartami
  /// `word`/`quiz`.
  final bool wordsEnabled;

  /// Pocet versov (ayah kariet) v dennej sade dna; null = sada este nie
  /// je. Genericky "Read {count} verses" ma ciel najviac tolko, aby sa dal
  /// splnit samotnou sadou ([GenericQuest.countFor]).
  final int? setVerses;
}

/// Vyber dennych questov a ich progres (plan 7.2, docs/03 3.3, 4.2).
///
/// Cisto deterministicky: rovnaky [QuestSelectionInput] da rovnake questy.
final class QuestEngine {
  const QuestEngine();

  /// Seed dna z `install_id` (FNV-1a 32 bit), stabilny naprieci verziami.
  static int daySeed(String installId, LocalDate date) =>
      _fnv('$installId|$date'.codeUnits);

  /// Questy dna v poradi `read`, `learn`, `act`.
  ///
  /// `act` chyba, ked ziadna vhodna sablona nema text v jazyku
  /// [QuestSelectionInput.lang] (den je splneny aj s 2 questami). `read`
  /// a `learn` vtedy dostanu [GenericQuest].
  List<DailyQuest> select(QuestSelectionInput input) => [
    for (final slot in QuestSlot.values) ?_selectSlot(input, slot),
  ];

  /// Progres auto questu z [events]; null pre `act` (self report, stav je
  /// v `quest_log`).
  QuestProgress? progress(DailyQuest quest, Iterable<CardActivity> events) {
    final rule = quest.rule;
    if (rule == null) return null;
    return countProgress(rule, rule.target(quest.params), quest.date, events);
  }

  /// Splneny [GenericQuest] drzi ciel z casu splnenia (P-01).
  ///
  /// Ciel generickeho questu sa odvodzuje zo stavu dna (napr. `setVerses`),
  /// ktory sa moze zmenit aj po splneni (sada vznikla az neskor). Po
  /// splneni ([doneAt]) plati pocet roznych kariet splnajucich podmienku do
  /// [doneAt] vratane - presne ten, pri ktorom quest dosiahol ciel. Bez
  /// takych udalosti (alebo pre sablony a nesplnene questy) vrati [quest].
  DailyQuest settled(
    DailyQuest quest, {
    required DateTime? doneAt,
    required Iterable<CardActivity> events,
  }) {
    final generic = quest.generic;
    final rule = quest.rule;
    if (generic == null || rule == null || doneAt == null) return quest;
    final reached = {
      for (final e in events)
        if (e.date == quest.date && rule.matches(e) && !e.ts.isAfter(doneAt))
          e.cardId,
    }.length;
    if (reached == 0 || reached == quest.target) return quest;
    return DailyQuest(
      date: quest.date,
      slot: quest.slot,
      questId: quest.questId,
      origin: quest.origin,
      rule: generic.rule(
        reached < generic.defaultCount ? reached : generic.defaultCount,
      ),
      params: quest.params,
      eventId: quest.eventId,
    );
  }

  DailyQuest? _selectSlot(QuestSelectionInput input, QuestSlot slot) {
    final byId = {
      for (final t in input.templates)
        if (t.slot == slot) t.id: t,
    };
    final prng = _Prng(_fnv([input.seed, slot.index + 1]));

    // 1. Override z eventu: najvyssia priorita, pri zhode id abecedne.
    final events = [...input.activeEvents]
      ..sort((a, b) {
        final p = b.priority.compareTo(a.priority);
        return p != 0 ? p : a.id.compareTo(b.id);
      });
    for (final event in events) {
      final templateId = event.effect.quests[slot];
      if (templateId == null) continue;
      final template = byId[templateId];
      // Neznama sablona alebo nevhodna pocas ospravedlnenych dni:
      // pokracuje sa beznym vyberom (docs/03 5.2, posledny riadok).
      if (template == null || !_allowed(input, template)) break;
      if (!template.hasText(input.lang)) return _generic(input, slot);
      return _build(input, template, prng, QuestOrigin.eventOverride, event.id);
    }

    // 2. Pool: tvrde filtre (jazyk, season, excused, slovicka).
    final active = {for (final e in input.activeEvents) e.id};
    final candidates =
        byId.values
            .where(
              (t) =>
                  t.hasText(input.lang) &&
                  _allowed(input, t) &&
                  (t.season.isEmpty || t.season.any(active.contains)),
            )
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    if (candidates.isEmpty) return _generic(input, slot);

    final lastUsed = _lastUsed(input);
    final eligible = [
      for (final t in candidates)
        if (_cooldownOver(t, lastUsed[t.id], input.date)) t,
    ];
    if (eligible.isEmpty) {
      // 3. Fallback: najdavnejsie pouzita sablona (docs/03 3.3 bod 5).
      final oldest = candidates.reduce(
        (a, b) => lastUsed[b.id]!.isBefore(lastUsed[a.id]!) ? b : a,
      );
      return _build(input, oldest, prng, QuestOrigin.leastRecentlyUsed, null);
    }

    // 4. Vazeny nahodny vyber, dlhsie nepouzite ma vyssiu vahu (LRU).
    final weights = [
      for (final t in eligible) t.weight * _lruFactor(t, lastUsed[t.id], input),
    ];
    final total = weights.fold<double>(0, (a, b) => a + b);
    var r = prng.nextDouble() * total;
    var picked = eligible.last;
    for (var i = 0; i < eligible.length; i++) {
      r -= weights[i];
      if (r < 0) {
        picked = eligible[i];
        break;
      }
    }
    return _build(input, picked, prng, QuestOrigin.weighted, null);
  }

  bool _allowed(QuestSelectionInput input, QuestTemplate t) {
    if (input.excused && !t.excusedOk) return false;
    if (!input.wordsEnabled) {
      final types = t.rule?.types ?? const <CardType>{};
      if (types.contains(CardType.word) || types.contains(CardType.quiz)) {
        return false;
      }
    }
    return true;
  }

  Map<String, LocalDate> _lastUsed(QuestSelectionInput input) {
    final last = <String, LocalDate>{};
    for (final e in input.history) {
      if (!e.date.isBefore(input.date)) continue;
      final prev = last[e.questId];
      if (prev == null || e.date.isAfter(prev)) last[e.questId] = e.date;
    }
    return last;
  }

  static bool _cooldownOver(QuestTemplate t, LocalDate? last, LocalDate day) =>
      last == null || day.daysSince(last) >= t.effectiveCooldownDays;

  /// 1..2: nikdy nepouzita 2, inak podiel dni od pouzitia k cooldownu.
  static double _lruFactor(
    QuestTemplate t,
    LocalDate? last,
    QuestSelectionInput input,
  ) {
    if (last == null) return 2;
    final cooldown = t.effectiveCooldownDays;
    if (cooldown == 0) return 1;
    final ratio = input.date.daysSince(last) / cooldown;
    return ratio > 2 ? 2 : ratio;
  }

  DailyQuest _build(
    QuestSelectionInput input,
    QuestTemplate t,
    _Prng prng,
    QuestOrigin origin,
    String? eventId,
  ) {
    final keys = t.params.keys.toList()..sort();
    return DailyQuest(
      date: input.date,
      slot: t.slot,
      questId: t.id,
      origin: origin,
      rule: t.rule,
      params: {
        for (final k in keys)
          k: t.params[k]![prng.nextInt(t.params[k]!.length)],
      },
      eventId: eventId,
    );
  }

  DailyQuest? _generic(QuestSelectionInput input, QuestSlot slot) {
    final generic = switch (slot) {
      QuestSlot.read => GenericQuest.readVerses,
      QuestSlot.learn =>
        input.wordsEnabled ? GenericQuest.learnWords : GenericQuest.learnCards,
      QuestSlot.act => null,
    };
    if (generic == null) return null;
    return DailyQuest(
      date: input.date,
      slot: slot,
      questId: generic.id,
      origin: QuestOrigin.generic,
      rule: generic.rule(generic.countFor(setVerses: input.setVerses)),
    );
  }
}

const _mask32 = 0xFFFFFFFF;

/// FNV-1a 32 bit nad [values] (kazda hodnota ako 32 bit slovo).
int _fnv(Iterable<int> values) {
  var h = 0x811C9DC5;
  for (final v in values) {
    for (var shift = 0; shift < 32; shift += 8) {
      h ^= (v >> shift) & 0xFF;
      h = (h * 0x01000193) & _mask32;
    }
  }
  return h;
}

/// Mulberry32: maly deterministicky PRNG nezavisly od implementacie
/// `dart:math` Random.
final class _Prng {
  _Prng(int seed) : _state = seed & _mask32;

  int _state;

  int _nextUint32() {
    _state = (_state + 0x6D2B79F5) & _mask32;
    var t = _state;
    t = _imul(t ^ (t >> 15), t | 1);
    t = (t ^ ((t + _imul(t ^ (t >> 7), t | 61)) & _mask32)) & _mask32;
    return (t ^ (t >> 14)) & _mask32;
  }

  double nextDouble() => _nextUint32() / 4294967296.0;

  int nextInt(int max) => (nextDouble() * max).floor();

  static int _imul(int a, int b) {
    // Rozdelenie na 16 bit casti, aby sucin nepretiekol.
    final lo = (a & 0xFFFF) * b;
    final hi = (((a >> 16) & 0xFFFF) * b) & 0xFFFF;
    return (lo + (hi << 16)) & _mask32;
  }
}
