import 'package:meta/meta.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/quests/card_activity.dart';
import 'package:sakina/domain/quests/quest_rule.dart';

/// Stav riadku `quest_log`.
enum QuestStatus {
  pending('pending'),
  done('done'),
  skipped('skipped');

  QuestStatus(this.wire);

  final String wire;

  static QuestStatus? fromWire(String wire) {
    for (final s in values) {
      if (s.wire == wire) return s;
    }
    return null;
  }
}

/// Riadok `quest_log` pre cooldown a LRU.
@immutable
final class QuestLogEntry {
  const QuestLogEntry({
    required this.date,
    required this.slot,
    required this.questId,
    this.status = QuestStatus.pending,
  });

  final LocalDate date;
  final QuestSlot slot;
  final String questId;
  final QuestStatus status;
}

/// Odkial sa quest dna vzal.
enum QuestOrigin {
  /// Override z aktivneho eventu (docs/03 4.4, `quests`).
  eventOverride,

  /// Vazeny nahodny vyber z poolu (docs/03 3.3).
  weighted,

  /// Prazdny pool po filtroch: najdavnejsie pouzita sablona.
  leastRecentlyUsed,

  /// Genericky quest s UI textom z ARB (ziadna sablona nema text v jazyku).
  generic,
}

/// Vstavane genericke questy bez nabozenskeho obsahu. Texty su v ARB
/// (`lib/l10n/parts/E-03_en.arb`), kluc je [arbKey], parameter `{count}`.
enum GenericQuest {
  /// "Read {count} verses".
  readVerses('generic.read.verses', QuestSlot.read, 'questGenericReadVerses'),

  /// "Learn {count} new words" (len pri zapnutych slovickach).
  learnWords('generic.learn.words', QuestSlot.learn, 'questGenericLearnWords'),

  /// "Read {count} hadith or dua card(s)" (slovicka vypnute).
  learnCards('generic.learn.cards', QuestSlot.learn, 'questGenericLearnCards');

  GenericQuest(this.id, this.slot, this.arbKey);

  /// Hodnota `quest_log.quest_id`; prefix `generic.` nekoliduje s obsahom.
  final String id;
  final QuestSlot slot;
  final String arbKey;

  static GenericQuest? fromId(String id) {
    for (final g in values) {
      if (g.id == id) return g;
    }
    return null;
  }

  /// Podmienka splnenia s cielom [count].
  QuestRule rule(int count) => QuestRule(
    types: switch (this) {
      readVerses => const {CardType.ayah},
      learnWords => const {CardType.word},
      learnCards => const {CardType.hadith, CardType.dua},
    },
    min: QuestTarget.fixed(count),
  );

  /// Predvoleny ciel.
  int get defaultCount => switch (this) {
    readVerses => 10,
    learnWords => 3,
    learnCards => 1,
  };

  /// Ciel dna: [readVerses] najviac [setVerses] (pocet versov v dennej
  /// sade, ak je aspon 1), aby ho splnila samotna sada; volne citanie ho
  /// moze dorovnat. Ostatne [defaultCount].
  int countFor({int? setVerses}) => switch (this) {
    readVerses when setVerses != null && setVerses > 0 =>
      setVerses < defaultCount ? setVerses : defaultCount,
    _ => defaultCount,
  };
}

/// Quest vybrany na dany den a slot.
@immutable
final class DailyQuest {
  DailyQuest({
    required this.date,
    required this.slot,
    required this.questId,
    required this.origin,
    this.rule,
    Map<String, int> params = const {},
    this.eventId,
  }) : params = Map.unmodifiable(params);

  final LocalDate date;
  final QuestSlot slot;

  /// `quest_template.id` alebo [GenericQuest.id].
  final String questId;

  final QuestOrigin origin;

  /// Podmienka auto-splnenia; null pre `act` (self report).
  final QuestRule? rule;

  /// Zvolene parametre sablony, napr. `{n: 10}`.
  final Map<String, int> params;

  /// Event, ktory quest urcil ([QuestOrigin.eventOverride]).
  final String? eventId;

  bool get isSelfReport => rule == null;

  /// Genericky quest, ak nejde o sablonu z obsahu.
  GenericQuest? get generic => GenericQuest.fromId(questId);

  /// Ciel auto questu (null pre self report).
  int? get target => rule?.target(params);

  @override
  bool operator ==(Object other) =>
      other is DailyQuest &&
      other.date == date &&
      other.slot == slot &&
      other.questId == questId &&
      other.origin == origin &&
      other.rule == rule &&
      other.eventId == eventId &&
      other.params.length == params.length &&
      params.entries.every((e) => other.params[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    date,
    slot,
    questId,
    origin,
    rule,
    eventId,
    Object.hashAllUnordered(params.entries.map((e) => (e.key, e.value))),
  );

  @override
  String toString() =>
      'DailyQuest($date, ${slot.wire}, $questId, ${origin.name}, $params)';
}

/// Progres auto questu z `card_event`.
@immutable
final class QuestProgress {
  const QuestProgress({
    required this.current,
    required this.target,
    this.completedAt,
  });

  /// Pocet roznych kariet splnajucich podmienku (max [target]).
  final int current;
  final int target;

  /// Cas udalosti, ktora dosiahla ciel; null = nesplnene.
  final DateTime? completedAt;

  bool get isComplete => completedAt != null;

  @override
  bool operator ==(Object other) =>
      other is QuestProgress &&
      other.current == current &&
      other.target == target &&
      other.completedAt == completedAt;

  @override
  int get hashCode => Object.hash(current, target, completedAt);

  @override
  String toString() => 'QuestProgress($current/$target, $completedAt)';
}

/// Spocita progres podmienky [rule] s cielom [target] z [events] dna [date].
QuestProgress countProgress(
  QuestRule rule,
  int target,
  LocalDate date,
  Iterable<CardActivity> events,
) {
  final matching =
      events.where((e) => e.date == date && rule.matches(e)).toList()
        ..sort((a, b) => a.ts.compareTo(b.ts));
  final seen = <CardId>{};
  for (final e in matching) {
    if (seen.add(e.cardId) && seen.length == target) {
      return QuestProgress(current: target, target: target, completedAt: e.ts);
    }
  }
  return QuestProgress(current: seen.length, target: target);
}
