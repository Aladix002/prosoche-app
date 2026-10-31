import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:sakina/domain/calendar/event_rule.dart';
import 'package:sakina/domain/calendar/event_rule_parser.dart';
import 'package:sakina/domain/calendar/hijri_date.dart';
import 'package:sakina/domain/calendar/islamic_calendar.dart';
import 'package:sakina/domain/common/active_event.dart';
import 'package:sakina/domain/common/event_effect.dart';
import 'package:sakina/domain/common/local_date.dart';
import 'package:sakina/domain/common/slot.dart';

/// Stav pouzivatela potrebny pre atomy `pref`, `user_flag`, `quest_progress`.
@immutable
final class EventContext {
  EventContext({
    Set<String> prefs = const {},
    Set<UserFlag> flags = const {},
    Map<String, int> questProgress = const {},
  }) : prefs = Set.unmodifiable(prefs),
       flags = Set.unmodifiable(flags),
       questProgress = Map.unmodifiable(questProgress);

  static final empty = EventContext();

  /// Zapnute opt-in nastavenia (napr. `show_optional_days`).
  final Set<String> prefs;

  final Set<UserFlag> flags;

  /// Progres questov (napr. pocet postov Shawwal), chybajuci = 0.
  final Map<String, int> questProgress;
}

/// Kto obsadil poziciu karty v sade (docs/03 4.4 bod 2).
@immutable
sealed class CardClaim {
  const CardClaim(this.eventId);

  final String eventId;
}

/// Eventova karta `event:{eventId}:{date}`.
final class EventCardClaim extends CardClaim {
  const EventCardClaim(super.eventId);

  @override
  bool operator ==(Object other) =>
      other is EventCardClaim && other.eventId == eventId;

  @override
  int get hashCode => Object.hash(EventCardClaim, eventId);

  @override
  String toString() => 'EventCardClaim($eventId)';
}

/// Vers sury [surah] od kurzora [cursor]; [index] je poradie v `ayah_slots`
/// (0 = prvy vers od kurzora).
final class EventAyahClaim extends CardClaim {
  const EventAyahClaim(super.eventId, this.surah, this.cursor, this.index);

  final int surah;
  final String cursor;
  final int index;

  @override
  bool operator ==(Object other) =>
      other is EventAyahClaim &&
      other.eventId == eventId &&
      other.surah == surah &&
      other.cursor == cursor &&
      other.index == index;

  @override
  int get hashCode => Object.hash(eventId, surah, cursor, index);

  @override
  String toString() => 'EventAyahClaim($eventId, $surah, $cursor, #$index)';
}

/// Override questu: slot dostal `quest_template.id` [templateId] z eventu.
@immutable
final class QuestClaim {
  const QuestClaim(this.eventId, this.templateId);

  final String eventId;
  final String templateId;

  @override
  bool operator ==(Object other) =>
      other is QuestClaim &&
      other.eventId == eventId &&
      other.templateId == templateId;

  @override
  int get hashCode => Object.hash(eventId, templateId);

  @override
  String toString() => 'QuestClaim($eventId, $templateId)';
}

/// Uvod eventu na uvodnej karte.
typedef EventIntro = ({String eventId, String introId});

/// Vysledok vyhodnotenia eventov pre jeden den.
@immutable
final class EventResolution {
  EventResolution({
    required this.date,
    required this.hijri,
    required List<ActiveEvent> active,
    required Map<String, EventPhase> activePhase,
    required List<String> suppressed,
    required Map<int, CardClaim> cards,
    required Map<QuestSlot, QuestClaim> quests,
    required Set<String> forbidTags,
    required Map<String, double> boostTags,
    required this.intro,
    required List<EventIntro> badges,
    required List<String> notifications,
    required this.mode,
  }) : active = List.unmodifiable(active),
       activePhase = Map.unmodifiable(activePhase),
       suppressed = List.unmodifiable(suppressed),
       cards = Map.unmodifiable(cards),
       quests = Map.unmodifiable(quests),
       forbidTags = Set.unmodifiable(forbidTags),
       boostTags = Map.unmodifiable(boostTags),
       badges = List.unmodifiable(badges),
       notifications = List.unmodifiable(notifications);

  final LocalDate date;

  /// Hijri datum dna (s offsetom).
  final HijriDate hijri;

  /// Aktivne eventy zoradene podla priority zostupne, pri zhode podla id.
  /// Eventy s kategoriou `optional`/`info` maju prazdny efekt.
  final List<ActiveEvent> active;

  /// Ci bol event aktivny cez `day` alebo `eve` (pri `both` vyhrava `day`).
  final Map<String, EventPhase> activePhase;

  /// Eventy, ktorych podmienka plati, ale vypol ich `merge: exclusive`.
  final List<String> suppressed;

  /// Pozicia karty v sade (1..12) -> event, ktory ju obsadil.
  final Map<int, CardClaim> cards;

  final Map<QuestSlot, QuestClaim> quests;

  /// Zjednotenie `forbid_tags` vsetkych aktivnych eventov.
  final Set<String> forbidTags;

  /// Sucin `boost_tags`, max x6, bez zakazanych tagov.
  final Map<String, double> boostTags;

  /// Hlavny uvod (najvyssi aktivny event s `intro`).
  final EventIntro? intro;

  /// Dalsie uvody ako odznaky, max 3.
  final List<EventIntro> badges;

  /// Notifikacie aktivnych eventov v poradi priority, bez duplicit.
  final List<String> notifications;

  /// Mod appky z najvyssieho eventu s `mode` (napr. `ramadan`).
  final String? mode;

  bool isActive(String eventId) => active.any((e) => e.id == eventId);

  /// Ci obsah s tagmi [tags] nie je zakazany (zakaz vyhrava vzdy, aj nad
  /// override questu nizsieho eventu, docs/03 4.4 bod 3).
  bool allows(Iterable<String> tags) => !tags.any(forbidTags.contains);
}

/// Vyhodnoti aktivne eventy dna a ich ucinok (plan 7.5, docs/03 4.4).
///
/// Postup riesenia kolizii (deterministicky):
/// 1. aktivne eventy sa zoradia podla `priority` zostupne, pri zhode podla id,
/// 2. `merge: exclusive` vypne vsetky nasledujuce s nizsou prioritou,
/// 3. kazdu poziciu karty a quest slot dostane prvy event, ktory ho definuje,
/// 4. `forbid_tags` sa zjednocuju, `boost_tags` nasobia (max x6),
/// 5. hlavny uvod ma najvyssi event, dalsie max 3 su odznaky.
final class EventResolver {
  EventResolver(List<EventRule> rules, this.calendar)
    : rules = List.unmodifiable(rules),
      _byId = {for (final r in rules) r.id: r} {
    EventRuleParser.validateSet(this.rules);
  }

  final List<EventRule> rules;
  final IslamicCalendar calendar;
  final Map<String, EventRule> _byId;

  static const maxBadges = 3;

  /// Ci podmienka eventu [eventId] plati v den [date] (bez `exclusive`).
  bool matches(String eventId, LocalDate date, [EventContext? context]) =>
      _Eval(this, context ?? EventContext.empty).phaseOf(eventId, date) != null;

  EventResolution resolve(LocalDate date, [EventContext? context]) {
    final eval = _Eval(this, context ?? EventContext.empty);
    final matching = <(EventRule, EventPhase)>[
      for (final r in rules)
        if (eval.phaseOf(r.id, date) case final phase?) (r, phase),
    ]..sort((a, b) => _order(a.$1, b.$1));

    final active = <(EventRule, EventPhase)>[];
    final suppressed = <String>[];
    int? exclusiveFloor;
    for (final m in matching) {
      if (exclusiveFloor != null && m.$1.priority < exclusiveFloor) {
        suppressed.add(m.$1.id);
        continue;
      }
      active.add(m);
      if (m.$1.merge == EventMerge.exclusive) {
        exclusiveFloor ??= m.$1.priority;
      }
    }

    final cards = <int, CardClaim>{};
    final quests = <QuestSlot, QuestClaim>{};
    final forbid = <String>{};
    final boost = <String, double>{};
    final intros = <EventIntro>[];
    final notifications = <String>[];
    String? mode;
    for (final (r, _) in active) {
      forbid.addAll(r.forbidTags);
      for (final MapEntry(:key, :value) in r.boostTags.entries) {
        boost[key] = (boost[key] ?? 1) * value;
      }
      if (r.intro case final intro?) {
        intros.add((eventId: r.id, introId: intro));
      }
      for (final n in r.notifications) {
        if (!notifications.contains(n)) notifications.add(n);
      }
      if (!r.category.canOverride) continue;
      mode ??= r.mode?.wire;
      final e = r.effect;
      if (e.eventCardSlot case final pos?) {
        cards.putIfAbsent(pos, () => EventCardClaim(r.id));
      }
      for (final (i, pos) in e.ayahSlots.indexed) {
        cards.putIfAbsent(
          pos,
          () => EventAyahClaim(r.id, e.surah!, e.cursor!, i),
        );
      }
      for (final MapEntry(:key, :value) in e.quests.entries) {
        quests.putIfAbsent(key, () => QuestClaim(r.id, value));
      }
    }

    return EventResolution(
      date: date,
      hijri: calendar.hijriOf(date),
      active: [
        for (final (r, _) in active)
          ActiveEvent(
            id: r.id,
            priority: r.priority,
            mode: r.category.canOverride ? r.mode?.wire : null,
            effect: r.category.canOverride ? r.effect : EventEffect.empty,
          ),
      ],
      activePhase: {for (final (r, p) in active) r.id: p},
      suppressed: suppressed,
      cards: cards,
      quests: quests,
      forbidTags: forbid,
      boostTags: {
        for (final MapEntry(:key, :value) in boost.entries)
          if (!forbid.contains(key)) key: math.min(value, maxBoostFactor),
      },
      intro: intros.firstOrNull,
      badges: intros.skip(1).take(maxBadges).toList(),
      notifications: notifications,
      mode: mode,
    );
  }

  static const double maxBoostFactor = EventRuleParser.maxBoost;

  static int _order(EventRule a, EventRule b) {
    final p = b.priority.compareTo(a.priority);
    return p != 0 ? p : a.id.compareTo(b.id);
  }
}

/// Vyhodnotenie s pamatou pre jedno volanie (`event_active`, `days_before`).
final class _Eval {
  _Eval(this.resolver, this.context);

  final EventResolver resolver;
  final EventContext context;
  final _phase = <(String, LocalDate), EventPhase?>{};
  final _hijri = <LocalDate, HijriDate>{};

  HijriDate hijri(LocalDate d) =>
      _hijri.putIfAbsent(d, () => resolver.calendar.hijriOf(d));

  /// Faza, v ktorej event plati v den [date], alebo null.
  EventPhase? phaseOf(String id, LocalDate date) {
    final key = (id, date);
    if (_phase.containsKey(key)) return _phase[key];
    final rule = resolver._byId[id]!;
    EventPhase? result;
    if (rule.phase != EventPhase.eve && test(rule.when, date, hijri(date))) {
      result = EventPhase.day;
    } else if (rule.phase != EventPhase.day &&
        test(rule.when, date, hijri(date.addDays(1)))) {
      result = EventPhase.eve;
    }
    return _phase[key] = result;
  }

  bool active(String id, LocalDate date) => phaseOf(id, date) != null;

  bool test(EventCondition c, LocalDate date, HijriDate h) => switch (c) {
    AllCondition(:final children) => children.every((x) => test(x, date, h)),
    AnyCondition(:final children) => children.any((x) => test(x, date, h)),
    NotCondition(:final child) => !test(child, date, h),
    HijriMonthCondition(:final months) => months.matches(h.month),
    HijriDayCondition(:final days) => days.matches(h.day),
    HijriMonthDayCondition(:final days) => days.contains((h.month, h.day)),
    WeekdayCondition(:final weekdays) => weekdays.matches(date.weekday),
    DaysBeforeCondition(:final eventId, :final days) => _daysBefore(
      eventId,
      days,
      date,
    ),
    EventActiveCondition(:final eventId) => active(eventId, date),
    PrefCondition(:final key) => context.prefs.contains(key),
    UserFlagCondition(:final flag) => context.flags.contains(flag),
    QuestProgressCondition(:final questId, :final lt) =>
      (context.questProgress[questId] ?? 0) < lt,
  };

  /// Event zacina presne n dni po [date] pre niektore n z [days] (1..30).
  bool _daysBefore(String id, IntMatcher days, LocalDate date) {
    for (var n = 1; n <= 30; n++) {
      if (!days.matches(n)) continue;
      final start = date.addDays(n);
      if (active(id, start) && !active(id, start.addDays(-1))) return true;
    }
    return false;
  }
}
