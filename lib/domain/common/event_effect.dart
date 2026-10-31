import 'package:meta/meta.dart';
import 'package:prosoche/domain/common/ayah_id.dart';
import 'package:prosoche/domain/common/slot.dart';

/// Ucinok aktivneho eventu na dennu sadu a questy (docs/02 D2, plan 7.5).
///
/// Tvar v `islamic_event.rule_json`:
/// ```json
/// {"cards": {"event_card_slot": 2, "ayah_slots": [3, 4], "surah": 18,
///            "cursor": "event_cursor.jumuah"},
///  "quests": {"read": "read_kahf"}}
/// ```
/// Pozicie su 1-based pozicie v sade. Ostatne kluce pravidla (`id`, `when`,
/// `priority`, `mode`) parsuje EventRuleParser (E-01), nie tato trieda.
@immutable
final class EventEffect {
  EventEffect({
    this.eventCardSlot,
    List<int> ayahSlots = const [],
    this.surah,
    this.cursor,
    Map<QuestSlot, String> quests = const {},
  }) : ayahSlots = List.unmodifiable(ayahSlots),
       quests = Map.unmodifiable(quests) {
    final problem = _problem(eventCardSlot, ayahSlots, surah, cursor);
    if (problem != null) throw ArgumentError(problem);
  }

  /// Parsuje kluce `cards` a `quests` z [json]. Ostatne kluce na najvyssej
  /// urovni ignoruje, nezname kluce vo vnutri hodia [FormatException].
  factory EventEffect.fromJson(Map<String, Object?> json) {
    final cards = _map(json['cards'], 'cards');
    final quests = _map(json['quests'], 'quests');
    _onlyKeys(cards, _cardKeys, 'cards');
    _onlyKeys(quests, {for (final q in QuestSlot.values) q.wire}, 'quests');
    final eventCardSlot = _get<int>(cards, 'event_card_slot');
    final ayahSlots = [
      for (final p in _get<List<Object?>>(cards, 'ayah_slots') ?? <Object?>[])
        if (p is int) p else throw const FormatException('ayah_slots: int'),
    ];
    final surah = _get<int>(cards, 'surah');
    final cursor = _get<String>(cards, 'cursor');
    final problem = _problem(eventCardSlot, ayahSlots, surah, cursor);
    if (problem != null) {
      throw FormatException('Invalid event effect: $problem');
    }
    return EventEffect(
      eventCardSlot: eventCardSlot,
      ayahSlots: ayahSlots,
      surah: surah,
      cursor: cursor,
      quests: {
        for (final MapEntry(:key, :value) in quests.entries)
          if (value is String)
            QuestSlot.fromWire(key)!: value
          else
            QuestSlot.fromWire(key)!: throw FormatException(
              'quests.$key: string',
            ),
      },
    );
  }

  static String? _problem(
    int? eventCardSlot,
    List<int> ayahSlots,
    int? surah,
    String? cursor,
  ) {
    if (eventCardSlot != null && eventCardSlot < 1) {
      return 'event_card_slot must be >= 1';
    }
    if (ayahSlots.any((p) => p < 1)) return 'ayah_slots must be >= 1';
    if (ayahSlots.toSet().length != ayahSlots.length ||
        (eventCardSlot != null && ayahSlots.contains(eventCardSlot))) {
      return 'duplicate slot position';
    }
    if (ayahSlots.isNotEmpty && (surah == null || cursor == null)) {
      return 'ayah_slots need surah and cursor';
    }
    if (surah != null && (surah < 1 || surah > AyahId.surahCount)) {
      return 'surah must be 1..114';
    }
    if (cursor != null && !cursor.startsWith('event_cursor.')) {
      return 'cursor must be event_cursor.*';
    }
    return null;
  }

  static final empty = EventEffect();

  static const _cardKeys = {'event_card_slot', 'ayah_slots', 'surah', 'cursor'};

  /// Pozicia eventovej karty v sade.
  final int? eventCardSlot;

  /// Pozicie, na ktorych idu versy [surah] od kurzora [cursor].
  final List<int> ayahSlots;

  final int? surah;

  /// Kluc v `settings` s poslednym ayah_id eventu, napr. `event_cursor.jumuah`.
  final String? cursor;

  /// Override quest templatov (slot -> `quest_template.id`).
  final Map<QuestSlot, String> quests;

  bool get isEmpty =>
      eventCardSlot == null && ayahSlots.isEmpty && quests.isEmpty;

  Map<String, Object?> toJson() => {
    if (eventCardSlot != null || ayahSlots.isNotEmpty)
      'cards': {
        'event_card_slot': ?eventCardSlot,
        if (ayahSlots.isNotEmpty) 'ayah_slots': ayahSlots,
        'surah': ?surah,
        'cursor': ?cursor,
      },
    if (quests.isNotEmpty)
      'quests': {for (final e in quests.entries) e.key.wire: e.value},
  };

  @override
  bool operator ==(Object other) =>
      other is EventEffect &&
      other.eventCardSlot == eventCardSlot &&
      other.surah == surah &&
      other.cursor == cursor &&
      _listEq(other.ayahSlots, ayahSlots) &&
      other.quests.length == quests.length &&
      quests.entries.every((e) => other.quests[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    eventCardSlot,
    surah,
    cursor,
    Object.hashAll(ayahSlots),
    Object.hashAllUnordered(quests.entries.map((e) => (e.key, e.value))),
  );

  @override
  String toString() => 'EventEffect(${toJson()})';

  static Map<String, Object?> _map(Object? raw, String name) => switch (raw) {
    null => const {},
    final Map<String, Object?> m => m,
    _ => throw FormatException('$name: expected object'),
  };

  static void _onlyKeys(Map<String, Object?> m, Set<String> ok, String name) {
    final unknown = m.keys.where((k) => !ok.contains(k));
    if (unknown.isNotEmpty) {
      throw FormatException('$name: unknown key(s) ${unknown.join(', ')}');
    }
  }

  static T? _get<T>(Map<String, Object?> m, String key) => switch (m[key]) {
    null => null,
    final T v => v,
    _ => throw FormatException('$key: expected $T'),
  };

  static bool _listEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
