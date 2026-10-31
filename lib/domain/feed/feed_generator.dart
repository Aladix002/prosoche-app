import 'dart:math';

import 'package:meta/meta.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/card_selector.dart';
import 'package:prosoche/domain/feed/daily_set.dart';
import 'package:prosoche/domain/feed/day_phase.dart';
import 'package:prosoche/domain/feed/feed_inputs.dart';

/// Vysledok generovania: sada a nove hodnoty kurzorov pre `settings`.
///
/// Kurzory sa zapisu spolu s `daily_set` pri prvom otvoreni dna (docs/02 B7).
@immutable
final class FeedResult {
  FeedResult({
    required this.set,
    required this.namesCursor,
    required Map<String, int> eventCursors,
    required this.shorterSetAvailable,
  }) : eventCursors = Map.unmodifiable(eventCursors);

  final DailySet set;

  /// Nova hodnota `names.cursor`.
  final int namesCursor;

  /// Nove hodnoty `event_cursor.{id}` (posledny zobrazeny ayah_id); obsahuje
  /// len kurzory, ktore sa dnes posunuli.
  final Map<String, int> eventCursors;

  /// Today moze ponuknut "shorter set" (docs/01 D6).
  final bool shorterSetAvailable;
}

/// Deterministicka denna sada (plan 7.1, docs/02 0.3, B1-B12, docs/03 3.3).
///
/// Rovnake [FeedInputs] daju vzdy rovnaku sadu. Nahodnost ide len cez
/// `Random(mixSeed(seed, salt))`.
final class FeedGenerator {
  const FeedGenerator();

  /// Po kolkych dnoch neaktivity je dostupna kratsia sada.
  static const shorterSetMinInactiveDays = 7;

  /// Pocet kariet kratsej sady.
  static const shorterSetSize = 6;

  static bool isShorterSetAvailable(int inactiveDays) =>
      inactiveDays >= shorterSetMinInactiveDays;

  /// Skladba podla `feed.cards_count` (plan 7.1; 8 a 16 su rozsirenie).
  static const layouts = <int, List<Slot>>{
    8: [
      Slot.intro,
      Slot.ayah,
      Slot.ayah,
      Slot.ayah,
      Slot.word,
      Slot.hadithDua,
      Slot.name,
      Slot.reflection,
    ],
    12: [
      Slot.intro,
      Slot.ayah,
      Slot.ayah,
      Slot.ayah,
      Slot.word,
      Slot.ayah,
      Slot.ayah,
      Slot.srs,
      Slot.hadithDua,
      Slot.ayah,
      Slot.name,
      Slot.reflection,
    ],
    16: [
      Slot.intro,
      Slot.ayah,
      Slot.ayah,
      Slot.ayah,
      Slot.word,
      Slot.ayah,
      Slot.ayah,
      Slot.srs,
      Slot.hadithDua,
      Slot.ayah,
      Slot.name,
      Slot.ayah,
      Slot.ayah,
      Slot.ayah,
      Slot.ayah,
      Slot.reflection,
    ],
  };

  /// Kratsia sada (docs/01 D6): bez slovicok a SRS.
  static const shorterLayout = <Slot>[
    Slot.intro,
    Slot.ayah,
    Slot.ayah,
    Slot.ayah,
    Slot.hadithDua,
    Slot.reflection,
  ];

  /// Hadisy povolene vo feede (docs/02 B5, E8).
  static const allowedGrades = {'sahih', 'hasan'};

  FeedResult generate(FeedInputs inputs) => _Run(inputs).build();
}

/// Rola pozicie pred naplnenim.
sealed class _Role {
  const _Role();
}

final class _Plain extends _Role {
  const _Plain(this.slot);
  final Slot slot;
}

final class _QuizRole extends _Role {
  const _QuizRole(this.quiz);
  final _Quiz quiz;
}

final class _EventRole extends _Role {
  const _EventRole(this.event);
  final ActiveEvent event;
}

final class _EventAyahRole extends _Role {
  const _EventAyahRole(this.event);
  final ActiveEvent event;
}

final class _Quiz {
  _Quiz(this.id, this.distractors);
  final QuizCardId id;
  final List<int> distractors;
}

/// Salty pre `mixSeed` (jeden na rozhodnutie, nezavisle od pozicie).
abstract final class _Salt {
  static const reflection = 12;
  static const hadithDua = 9;
  static const fallbackHadith = 1000;
  static const quiz = 100000;
}

final class _Run {
  _Run(this.inputs)
    : lang = inputs.prefs.lang,
      phase = DayPhase.resolve(
        inputs.generatedAtLocalTime,
        boundaries: inputs.dayBoundaries,
      ),
      selector = CardSelector(
        date: inputs.date,
        seed: inputs.seed,
        lang: inputs.prefs.lang,
        activeEvents: inputs.activeEvents,
        lastShown: inputs.history.lastShown,
        disabled: inputs.history.disabledIds,
      ),
      events = CardSelector.sortEvents(inputs.activeEvents),
      _reading = (inputs.readingPosition ?? AyahId.last).next,
      namesCursor = inputs.history.namesCursor;

  final FeedInputs inputs;
  final String lang;
  final DayPhase phase;
  final CardSelector selector;
  final List<ActiveEvent> events;

  FeedPools get pools => inputs.pools;
  FeedHistory get history => inputs.history;

  final _cards = <DailySetCard>[];
  final _used = <CardId>{};
  final _eventCursors = <String, int>{};
  AyahId _reading;
  int namesCursor;
  int _fallbacks = 0;
  String? _theme;
  FeedCandidate? _reflection;

  bool get _wordsOn => inputs.wordsEnabled && pools.lemmas != null;

  FeedResult build() {
    final roles = _roles();
    _reflection = selector.pick(
      pools.reflections.where((r) => r.reviewed),
      salt: _Salt.reflection,
    );
    _theme = _reflection?.tags.firstOrNull;
    roles.forEach(_fill);
    return FeedResult(
      set: DailySet(
        date: inputs.date,
        phase: phase,
        cards: _cards,
        contentVersion: inputs.contentVersion,
        tz: inputs.tz,
      ),
      namesCursor: namesCursor,
      eventCursors: _eventCursors,
      shorterSetAvailable: FeedGenerator.isShorterSetAvailable(
        inputs.inactiveDays,
      ),
    );
  }

  // --- skladba ---

  List<_Role> _roles() {
    final shorter =
        inputs.prefs.shorterSet &&
        FeedGenerator.isShorterSetAvailable(inputs.inactiveDays);
    var layout = shorter
        ? FeedGenerator.shorterLayout
        : FeedGenerator.layouts[inputs.prefs.cardsCount]!;
    if (!inputs.wordsEnabled) {
      // ROZHODNUTIE: bez slovicok vypadnu sloty word a srs, slot SRS alebo
      // meno je vzdy meno Allaha (pri 12 kartach N = 10).
      layout = [
        for (final s in layout)
          if (s != Slot.word && s != Slot.srs) s,
      ];
    }
    final roles = <_Role>[for (final s in layout) _Plain(s)];
    _applyEvents(roles);
    _resolveSrs(roles);
    return roles;
  }

  /// Kazda pozicia dostane efekt prveho eventu, ktory ju definuje
  /// (docs/03 4.4 kolizie). Pozicia 1 (intro) sa nenahradza.
  void _applyEvents(List<_Role> roles) {
    final claimed = <int>{1};
    bool claim(int pos) => pos >= 1 && pos <= roles.length && claimed.add(pos);
    for (final e in events) {
      final effect = e.effect;
      if (effect.eventCardSlot case final p? when claim(p)) {
        roles[p - 1] = _EventRole(e);
      }
      for (final p in effect.ayahSlots) {
        if (claim(p)) roles[p - 1] = _EventAyahRole(e);
      }
    }
  }

  /// Sloty `srs` a `name` podla poctu due poloziek (docs/02 B4 fallback):
  /// 0 due = 8 meno, 11 vers; 1 due = 8 kviz, 11 meno; 2+ due = dva kvizy.
  void _resolveSrs(List<_Role> roles) {
    final due = _wordsOn ? _readyQuizzes() : <_Quiz>[];
    var nameUsed = false;
    for (var i = 0; i < roles.length; i++) {
      final role = roles[i];
      if (role is! _Plain) continue;
      if (role.slot == Slot.srs ||
          (role.slot == Slot.name && inputs.wordsEnabled)) {
        if (due.isNotEmpty) {
          roles[i] = _QuizRole(due.removeAt(0));
        } else if (nameUsed && role.slot == Slot.name) {
          roles[i] = const _Plain(Slot.ayah);
        } else {
          roles[i] = const _Plain(Slot.name);
          nameUsed = true;
        }
      }
    }
  }

  List<_Quiz> _readyQuizzes() {
    final lemmas = pools.lemmas!;
    final due = pools.dueSrs.toList()
      ..sort((a, b) {
        final d = a.due.compareTo(b.due);
        return d != 0 ? d : a.lemmaId.compareTo(b.lemmaId);
      });
    final out = <_Quiz>[];
    for (final item in due) {
      final lemma = lemmas.lemma(item.lemmaId);
      if (lemma == null || !lemma.langs.contains(lang)) continue;
      final rng = Random(mixSeed(inputs.seed, _Salt.quiz + item.lemmaId));
      final qtypes = [
        'ar2mean',
        if (item.reps >= 1) 'mean2ar',
        if (item.seenInContext) 'context',
      ];
      final id = QuizCardId(lemma.lemmaId, qtypes[rng.nextInt(qtypes.length)]);
      if (selector.disabled.contains(id) ||
          selector.disabled.contains(WordCardId(lemma.lemmaId))) {
        continue;
      }
      final distractors = _distractors(lemma, lemmas, rng);
      if (distractors.length == 3) out.add(_Quiz(id, distractors));
    }
    return out;
  }

  /// 3 lemy s podobnym `rank` (+-50), nikdy s rovnakym korenom (docs/02 B4).
  List<int> _distractors(LemmaInfo target, LemmaIndex lemmas, Random rng) {
    final pool =
        lemmas.byRank
            .where(
              (l) =>
                  l.lemmaId != target.lemmaId &&
                  l.langs.contains(lang) &&
                  (target.root == null || l.root != target.root),
            )
            .toList()
          ..sort((a, b) {
            final d = (a.rank - target.rank).abs().compareTo(
              (b.rank - target.rank).abs(),
            );
            return d != 0 ? d : a.lemmaId.compareTo(b.lemmaId);
          });
    final near = [
      for (final l in pool)
        if ((l.rank - target.rank).abs() <= 50) l.lemmaId,
    ]..shuffle(rng);
    final far = [
      for (final l in pool)
        if ((l.rank - target.rank).abs() > 50) l.lemmaId,
    ];
    return [...near, ...far].take(3).toList();
  }

  // --- plnenie ---

  void _fill(_Role role) {
    switch (role) {
      case _Plain(slot: Slot.intro):
        _add(IntroCardId(inputs.date), Slot.intro, eventId: _introEvent());
      case _Plain(slot: Slot.ayah):
        _addReading(Slot.ayah);
      case _Plain(slot: Slot.word):
        _fillWord();
      case _Plain(slot: Slot.name):
        _fillName();
      case _Plain(slot: Slot.hadithDua):
        _fillHadithDua();
      case _Plain(slot: Slot.reflection):
        if (_reflection case final r?) {
          _add(r.id, Slot.reflection);
        } else {
          _fallback();
        }
      case _Plain():
        throw StateError('Unexpected slot $role');
      case _QuizRole(:final quiz):
        _add(quiz.id, Slot.srs, distractors: quiz.distractors);
      case _EventRole(:final event):
        final id = EventCardId(event.id, inputs.date);
        if (selector.isReady(id, pools.eventTextLangs[event.id] ?? const {})) {
          _add(id, Slot.event);
        } else {
          _fallback();
        }
      case _EventAyahRole(:final event):
        _addEventAyah(event);
    }
  }

  /// Najvyssi event s textom v jazyku; bez textu intro ukaze len hijri datum.
  String? _introEvent() {
    for (final e in events) {
      if (pools.eventTextLangs[e.id]?.contains(lang) ?? false) return e.id;
    }
    return null;
  }

  void _add(
    CardId id,
    Slot slot, {
    AyahId? ctx,
    List<int> distractors = const [],
    bool khatm = false,
    String? eventId,
  }) {
    _used.add(id);
    _cards.add(
      DailySetCard(
        pos: _cards.length + 1,
        cardId: id,
        slot: slot,
        ctxAyahId: ctx,
        distractors: distractors,
        khatm: khatm,
        eventId: eventId,
      ),
    );
  }

  /// Dalsi vers v poradi citania; po 114:6 vlozi kartu khatm (mimo N).
  void _addReading(Slot slot) {
    for (var i = 0; i < AyahId.totalAyahs; i++) {
      final ayah = _reading;
      _reading = ayah.next;
      final id = AyahCardId(ayah);
      if (selector.disabled.contains(id) || _used.contains(id)) continue;
      _add(id, slot, khatm: true);
      if (ayah == AyahId.last) {
        _add(KhatmCardId(history.completedKhatms + 1), Slot.khatm);
      }
      return;
    }
    throw StateError('No readable ayah');
  }

  /// Vers sury eventu od `event_cursor` (po konci sury znova od 1).
  void _addEventAyah(ActiveEvent event) {
    final surah = event.effect.surah!;
    final key = event.effect.cursor!;
    final count = AyahId.ayahCount(surah);
    final last =
        _eventCursors[key] ??
        AyahId.tryFromValue(history.eventCursors[key] ?? 0)?.value;
    var ayah = last != null && last ~/ 1000 == surah ? last % 1000 : 0;
    for (var i = 0; i < count; i++) {
      ayah = ayah % count + 1;
      final id = AyahCardId(AyahId(surah, ayah));
      if (selector.disabled.contains(id) || _used.contains(id)) continue;
      _eventCursors[key] = id.ayahId.value;
      _add(id, Slot.eventAyah);
      return;
    }
    _addReading(Slot.ayah);
  }

  /// ROZHODNUTIE: jazykovy fallback: striedavo dalsi vers v poradi citania
  /// a hadis s textom v jazyku (prvy fallback v sade je vers).
  void _fallback() {
    final useHadith = _fallbacks.isOdd;
    _fallbacks++;
    if (useHadith) {
      final h = selector.pick(
        _hadiths,
        salt: _Salt.fallbackHadith + _cards.length,
        exclude: _used,
        themeTag: _theme,
      );
      if (h != null) return _add(h.id, Slot.hadithDua);
    }
    _addReading(Slot.ayah);
  }

  Iterable<FeedCandidate> get _hadiths =>
      pools.hadiths.where((h) => FeedGenerator.allowedGrades.contains(h.grade));

  /// Slot 9: override eventu, inak rano/vecer dua, inak hadis (docs/03 3.4).
  void _fillHadithDua() {
    final facet = TimeOfDayFacet.fromPhase(phase);
    final all = [..._hadiths, ...pools.duas];
    FeedCandidate? pick(Iterable<FeedCandidate> pool, {bool timed = false}) =>
        selector.pick(
          pool,
          salt: _Salt.hadithDua,
          exclude: _used,
          themeTag: _theme,
          timeOfDay: timed ? facet : null,
        );
    final FeedCandidate? chosen;
    if (selector.hasOverride(all, exclude: _used)) {
      chosen = pick(all, timed: true);
    } else if (phase == DayPhase.morning || phase == DayPhase.evening) {
      chosen =
          pick(pools.duas.where((d) => d.timeOfDay == facet)) ??
          pick(all, timed: true);
    } else {
      chosen = pick(_hadiths) ?? pick(pools.duas);
    }
    if (chosen == null) {
      _fallback();
    } else {
      _add(chosen.id, Slot.hadithDua);
    }
  }

  /// Meno od `names.cursor`; mena bez textu v jazyku sa preskocia.
  void _fillName() {
    final byId = {for (final c in pools.names) (c.id as NameCardId).nameId: c};
    for (var i = 0; i < 99; i++) {
      final nameId = (namesCursor - 1 + i) % 99 + 1;
      final c = byId[nameId];
      if (c == null ||
          !selector.isReady(c.id, c.langs) ||
          _used.contains(c.id)) {
        continue;
      }
      namesCursor = nameId % 99 + 1;
      return _add(c.id, Slot.name);
    }
    _fallback();
  }

  /// Lema z versov sady (najprv predchadzajuce, potom nasledujuce), ktora nie
  /// je v SRS, s najnizsim `rank`; inak prva lema podla `rank` (docs/02 B3).
  void _fillWord() {
    final lemmas = pools.lemmas;
    if (lemmas == null) return _fallback();
    bool ok(LemmaInfo l) =>
        l.langs.contains(lang) &&
        !pools.srsLemmaIds.contains(l.lemmaId) &&
        !selector.disabled.contains(WordCardId(l.lemmaId)) &&
        !_used.any((u) => u is QuizCardId && u.lemmaId == l.lemmaId);

    final before = [
      for (final c in _cards)
        if (c.slot == Slot.ayah || c.slot == Slot.eventAyah)
          (c.cardId as AyahCardId).ayahId,
    ];
    final after = <AyahId>[];
    var next = _reading;
    for (var i = 0; i < inputs.prefs.cardsCount; i++) {
      after.add(next);
      next = next.next;
    }
    for (final group in [before, after]) {
      LemmaInfo? best;
      AyahId? ctx;
      for (final ayah in group) {
        for (final l in lemmas.lemmasInAyah(ayah)) {
          if (ok(l) && (best == null || l.rank < best.rank)) {
            best = l;
            ctx = ayah;
          }
        }
      }
      if (best != null) {
        return _add(WordCardId(best.lemmaId), Slot.word, ctx: ctx);
      }
    }
    for (final l in lemmas.byRank) {
      if (ok(l)) return _add(WordCardId(l.lemmaId), Slot.word);
    }
    _fallback();
  }
}
