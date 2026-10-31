import 'package:meta/meta.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/quests/quest_rule.dart';

/// Sablona questu z `quest_template` (docs/03 4.2), uz len schvalena
/// (`status=approved`, filtruje pipeline).
///
/// Texty su v `quest_text(lang)`; tu staci vediet, pre ktore jazyky existuju
/// ([langs]), aby sa sablona bez textu nevybrala.
@immutable
final class QuestTemplate {
  QuestTemplate({
    required this.id,
    required this.slot,
    required Set<String> langs,
    this.rule,
    this.weight = 1,
    this.cooldownDays,
    this.excusedOk = false,
    Set<String> season = const {},
    Map<String, List<int>> params = const {},
  }) : langs = Set.unmodifiable(langs),
       season = Set.unmodifiable(season),
       params = Map.unmodifiable({
         for (final e in params.entries) e.key: List<int>.unmodifiable(e.value),
       }) {
    if (id.isEmpty) throw ArgumentError.value(id, 'id', 'must not be empty');
    if (weight <= 0) throw ArgumentError.value(weight, 'weight', 'must be > 0');
    if (cooldownDays != null && cooldownDays! < 0) {
      throw ArgumentError.value(cooldownDays, 'cooldownDays', 'must be >= 0');
    }
    if (slot == QuestSlot.act && rule != null) {
      throw ArgumentError('act is self-reported, rule must be null');
    }
    if (slot != QuestSlot.act && rule == null) {
      throw ArgumentError('${slot.wire} needs an auto-completion rule');
    }
    if (params.values.any((v) => v.isEmpty || v.any((n) => n < 1))) {
      throw ArgumentError('params need non-empty lists of values >= 1');
    }
    final param = rule?.min.param;
    if (param != null && !params.containsKey(param)) {
      throw ArgumentError('rule uses param "$param" missing in params');
    }
  }

  /// Stabilne ID, napr. `read.quran.verses_n`.
  final String id;

  final QuestSlot slot;

  /// Jazyky, v ktorych ma sablona schvaleny text.
  final Set<String> langs;

  /// Podmienka auto-splnenia (`read`, `learn`); `act` ma null (self report).
  final QuestRule? rule;

  final double weight;

  /// `cooldown_days` zo sablony; minimum podla slotu plati vzdy
  /// ([QuestCooldown.minDays]).
  final int? cooldownDays;

  /// Faseta `excused_ok` (docs/03 3.2, 6.5).
  final bool excusedOk;

  /// ID eventov, pocas ktorych sa sablona smie pouzit; prazdne = vzdy.
  final Set<String> season;

  /// Volby parametrov, napr. `{n: [10, 15, 20]}`.
  final Map<String, List<int>> params;

  /// Ucinny cooldown v dnoch.
  int get effectiveCooldownDays {
    final min = QuestCooldown.minDays(slot);
    final own = cooldownDays ?? min;
    return own > min ? own : min;
  }

  bool hasText(String lang) => langs.contains(lang);

  @override
  bool operator ==(Object other) => other is QuestTemplate && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'QuestTemplate($id, ${slot.wire})';
}

/// Minimalne cooldowny (plan 7.2, docs/03 3.4, P7).
abstract final class QuestCooldown {
  /// `act`: LRU s minimom 21 dni.
  static const actDays = 21;

  /// `read` a `learn`: 7 dni.
  static const readLearnDays = 7;

  static int minDays(QuestSlot slot) =>
      slot == QuestSlot.act ? actDays : readLearnDays;
}
