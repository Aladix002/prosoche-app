import 'package:prosoche/domain/common/card_id.dart';

/// Druh slotu v dennej sade = pole `slot` v `cards_json` (docs/02 0.3,
/// plan 7.1). Pozicie slotov urcuje FeedGenerator, tu je len slovnik.
enum Slot {
  /// Uvodna karta dna (pozicia 1).
  intro('intro'),

  /// Kratky citat.
  quote('quote'),

  /// Dlhsi uryvok.
  passage('passage'),

  /// Cvicenie.
  practice('practice'),

  /// Otazka na zamyslenie.
  prompt('prompt'),

  /// Pojem.
  concept('concept'),

  /// Uvod k autorovi.
  author('author');

  Slot(this.wire);

  /// Hodnota v `cards_json`.
  final String wire;

  /// Typ karty, ktory slot plni (pre [intro] [CardType.intro]).
  CardType get cardType => CardType.fromWire(wire)!;

  static Slot? fromWire(String wire) {
    for (final s in values) {
      if (s.wire == wire) return s;
    }
    return null;
  }
}

/// Denne quest sloty (plan 7.2).
enum QuestSlot {
  read('read'),
  learn('learn'),
  act('act');

  QuestSlot(this.wire);

  final String wire;

  static QuestSlot? fromWire(String wire) {
    for (final s in values) {
      if (s.wire == wire) return s;
    }
    return null;
  }
}
