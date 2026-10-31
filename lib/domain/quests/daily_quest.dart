import 'package:meta/meta.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/card_activity.dart';
import 'package:prosoche/domain/quests/quest_rule.dart';

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
  /// Vazeny nahodny vyber z poolu (docs/03 3.3).
  weighted,

  /// Prazdny pool po filtroch: najdavnejsie pouzita sablona.
  leastRecentlyUsed,

  /// Genericky quest s UI textom z ARB (ziadna vhodna sablona).
  generic,
}

/// Vstavane genericke questy (bez sablony z obsahu). Texty su v ARB
/// (`lib/l10n/parts/E-03_en.arb`), kluc je [arbKey], parameter `{count}`.
enum GenericQuest {
  /// "Read {count} cards": citaty a uryvky.
  readCards('generic.read.cards', QuestSlot.read, 'questGenericReadCards'),

  /// "Learn one idea": karta pojmu alebo autora.
  learnIdea('generic.learn.idea', QuestSlot.learn, 'questGenericLearnIdea'),

  /// "Try one practice": self report (ako kazdy `act`).
  actPractice('generic.act.practice', QuestSlot.act, 'questGenericActPractice');

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

  /// Typy kariet, ktore quest pocita (prazdne pre self report).
  Set<CardType> get types => switch (this) {
    readCards => const {CardType.quote, CardType.passage},
    learnIdea => const {CardType.concept, CardType.author},
    actPractice => const {},
  };

  /// Podmienka splnenia s cielom [count]; null pre self report (`act`).
  QuestRule? rule(int count) => slot == QuestSlot.act
      ? null
      : QuestRule(types: types, min: QuestTarget.fixed(count));

  /// Predvoleny ciel.
  int get defaultCount => switch (this) {
    readCards => 5,
    learnIdea || actPractice => 1,
  };

  /// Ciel dna: [readCards] najviac [setCards] (pocet citatov a uryvkov
  /// v dennej sade, ak je aspon 1), aby ho splnila samotna sada. Ostatne
  /// [defaultCount].
  int countFor({int? setCards}) => switch (this) {
    readCards when setCards != null && setCards > 0 =>
      setCards < defaultCount ? setCards : defaultCount,
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
      other.params.length == params.length &&
      params.entries.every((e) => other.params[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    date,
    slot,
    questId,
    origin,
    rule,
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
