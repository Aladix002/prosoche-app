/// Druh slotu v dennej sade = pole `slot` v `cards_json` (docs/02 0.3,
/// plan 7.1). Pozicie slotov urcuje FeedGenerator, tu je len slovnik.
enum Slot {
  /// Uvodna karta dna (pozicia 1).
  intro('intro'),

  /// Vers v poradi citania (2-4, 6-7, 10).
  ayah('ayah'),

  /// Slovo z precitanych versov (5).
  word('word'),

  /// SRS kviz (8, pripadne 11).
  srs('srs'),

  /// Hadis alebo dua (9).
  hadithDua('hadith_dua'),

  /// Meno Allaha (11).
  name('name'),

  /// Zamyslenie (12).
  reflection('reflection'),

  /// Eventova karta (napr. piatok, docs/02 D2 `event_card_slot`).
  event('event'),

  /// Vers eventu s vlastnym kurzorom (docs/02 D2 `ayah_slots`).
  eventAyah('event_ayah'),

  /// Karta dokoncenia Koranu.
  khatm('khatm');

  Slot(this.wire);

  /// Hodnota v `cards_json`.
  final String wire;

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
