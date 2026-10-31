import 'package:meta/meta.dart';
import 'package:prosoche/domain/common/event_effect.dart';

/// Kedy sa podmienka eventu vyhodnocuje (docs/03 4.4).
enum EventPhase {
  /// Podmienka plati pre hijri datum dna.
  day('day'),

  /// Od maghribu predchadzajuceho dna: hijri atomy sa vyhodnocuju pre hijri
  /// datum nasledujuceho gregorianskeho dna. `weekday` ostava dnom samym
  /// (napr. `jumuah_eve` = stvrtok vecer).
  eve('eve'),

  /// Plati `day` alebo `eve`.
  both('both');

  EventPhase(this.wire);

  final String wire;
}

/// Kategoria eventu (docs/03 4.4, 5.1).
enum EventCategory {
  /// Vzdy zapnute.
  core('core'),

  /// Opt-in (napr. `pref: show_optional_days`). Len uvodna karta, nikdy
  /// override slotov ani questov.
  optional('optional'),

  /// Iba informacia na uvodnej karte.
  info('info');

  EventCategory(this.wire);

  final String wire;

  /// Ci event smie menit sloty, questy a mod.
  bool get canOverride => this == core;
}

/// Sposob zlucenia s inymi aktivnymi eventmi (docs/03 4.4 bod 2 a 6).
enum EventMerge {
  /// Per-slot vyhrava vyssia priorita (default).
  slots('slots'),

  /// Vypne vsetky aktivne eventy s nizsou prioritou (Eid).
  exclusive('exclusive');

  EventMerge(this.wire);

  final String wire;
}

/// Pouzivatelsky priznak pre atom `user_flag`.
enum UserFlag {
  /// Ospravedlnene dni (docs/03 6.5).
  excused('excused'),

  /// Pouzivatel ma zapnute posty (`can_fast`).
  fastingEnabled('fasting_enabled');

  UserFlag(this.wire);

  final String wire;
}

/// Mnozina povolenych celych cisel: `int`, `[int]` alebo `{gte, lte}`.
@immutable
sealed class IntMatcher {
  const IntMatcher();

  bool matches(int value);
}

/// Hodnota je jedna z [values].
final class IntSetMatcher extends IntMatcher {
  IntSetMatcher(Iterable<int> values) : values = Set.unmodifiable(values);

  final Set<int> values;

  @override
  bool matches(int value) => values.contains(value);

  @override
  bool operator ==(Object other) =>
      other is IntSetMatcher &&
      other.values.length == values.length &&
      other.values.containsAll(values);

  @override
  int get hashCode => Object.hashAllUnordered(values);

  @override
  String toString() => '$values';
}

/// Hodnota je v intervale [gte]..[lte] vratane.
final class IntRangeMatcher extends IntMatcher {
  const IntRangeMatcher(this.gte, this.lte);

  final int gte;
  final int lte;

  @override
  bool matches(int value) => value >= gte && value <= lte;

  @override
  bool operator ==(Object other) =>
      other is IntRangeMatcher && other.gte == gte && other.lte == lte;

  @override
  int get hashCode => Object.hash(gte, lte);

  @override
  String toString() => '$gte..$lte';
}

/// Podmienka `when` (gramatika docs/03 4.4). Vyhodnocuje ju EventResolver.
@immutable
sealed class EventCondition {
  const EventCondition();

  /// Id eventov, na ktorych podmienka zavisi (`event_active`, `days_before`).
  Iterable<String> get dependencies => const [];
}

final class AllCondition extends EventCondition {
  AllCondition(List<EventCondition> children)
    : children = List.unmodifiable(children);

  final List<EventCondition> children;

  @override
  Iterable<String> get dependencies => children.expand((c) => c.dependencies);
}

final class AnyCondition extends EventCondition {
  AnyCondition(List<EventCondition> children)
    : children = List.unmodifiable(children);

  final List<EventCondition> children;

  @override
  Iterable<String> get dependencies => children.expand((c) => c.dependencies);
}

final class NotCondition extends EventCondition {
  const NotCondition(this.child);

  final EventCondition child;

  @override
  Iterable<String> get dependencies => child.dependencies;
}

/// `{"hijri_month": int | [int]}`, 1..12.
final class HijriMonthCondition extends EventCondition {
  const HijriMonthCondition(this.months);

  final IntMatcher months;
}

/// `{"hijri_day": int | [int] | {gte, lte}}`, 1..30.
final class HijriDayCondition extends EventCondition {
  const HijriDayCondition(this.days);

  final IntMatcher days;
}

/// `{"hijri_month_day": [[m, d], ...]}`.
final class HijriMonthDayCondition extends EventCondition {
  HijriMonthDayCondition(Iterable<(int, int)> days)
    : days = Set.unmodifiable(days);

  final Set<(int, int)> days;
}

/// `{"weekday": int | [int]}`, ISO 1 = pondelok .. 7 = nedela.
final class WeekdayCondition extends EventCondition {
  const WeekdayCondition(this.weekdays);

  final IntMatcher weekdays;
}

/// `{"days_before": {"event": id, "n": int | [int] | {gte, lte}}}`.
///
/// Plati, ak event [eventId] zacina presne `n` dni po dnesku (je aktivny
/// v den `d + n` a nie je aktivny v den `d + n - 1`).
final class DaysBeforeCondition extends EventCondition {
  const DaysBeforeCondition(this.eventId, this.days);

  final String eventId;
  final IntMatcher days;

  @override
  Iterable<String> get dependencies => [eventId];
}

/// `{"event_active": id}` - podmienka eventu [eventId] plati v ten isty den
/// (bez ohladu na `merge: exclusive`).
final class EventActiveCondition extends EventCondition {
  const EventActiveCondition(this.eventId);

  final String eventId;

  @override
  Iterable<String> get dependencies => [eventId];
}

/// `{"pref": key}` - opt-in nastavenie je zapnute.
final class PrefCondition extends EventCondition {
  const PrefCondition(this.key);

  final String key;
}

/// `{"user_flag": "excused" | "fasting_enabled"}`.
final class UserFlagCondition extends EventCondition {
  const UserFlagCondition(this.flag);

  final UserFlag flag;
}

/// `{"quest_progress": {"id": id, "lt": int}}` - progres questu < [lt].
final class QuestProgressCondition extends EventCondition {
  const QuestProgressCondition(this.questId, this.lt);

  final String questId;
  final int lt;
}

/// Mod appky, ktory event zapina (`mode`).
enum EventMode {
  ramadan('ramadan');

  EventMode(this.wire);

  final String wire;
}

/// Jedno pravidlo z `islamic_event.rule_json` (plan 7.5, docs/03 4.4).
///
/// Vytvara ho `EventRuleParser`; konstruktor nerobi validaciu gramatiky.
@immutable
final class EventRule {
  EventRule({
    required this.id,
    required this.when,
    this.phase = EventPhase.day,
    this.priority = 0,
    this.category = EventCategory.core,
    this.merge = EventMerge.slots,
    this.mode,
    EventEffect? effect,
    this.intro,
    Set<String> forbidTags = const {},
    Map<String, double> boostTags = const {},
    List<String> notifications = const [],
  }) : effect = effect ?? EventEffect.empty,
       forbidTags = Set.unmodifiable(forbidTags),
       boostTags = Map.unmodifiable(boostTags),
       notifications = List.unmodifiable(notifications);

  /// `islamic_event.id`.
  final String id;

  final EventCondition when;
  final EventPhase phase;
  final int priority;
  final EventCategory category;
  final EventMerge merge;
  final EventMode? mode;

  /// Override kariet a questov (`cards`, `quests`).
  final EventEffect effect;

  /// Id uvodneho textu (`islamic_event_text`), napr. `intro.jumuah`.
  final String? intro;

  /// Tagy zakazane pocas eventu (zakaz vzdy vyhrava, docs/03 4.4 bod 3).
  final Set<String> forbidTags;

  /// Nasobice vahy tagov (docs/03 4.4 bod 4).
  final Map<String, double> boostTags;

  /// Id notifikacii eventu (planuje P-02).
  final List<String> notifications;

  /// Id eventov, na ktorych zavisi [when].
  Set<String> get dependencies => when.dependencies.toSet();

  @override
  String toString() => 'EventRule($id, priority: $priority)';
}
