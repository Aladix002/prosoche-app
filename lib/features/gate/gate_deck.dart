import 'package:meta/meta.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/feed/feed.dart';

/// Karta zobrazena v brane.
@immutable
sealed class GateItem {
  const GateItem({this.autoSeenBefore = const []});

  /// Karty sady bez zobrazenia (intro, event, khatm), ktore sa oznacia
  /// `seen` s `context=gate` pred touto kartou, aby cursor nemal medzeru
  /// (docs/02 A4).
  final List<DailySetCard> autoSeenBefore;

  CardId get cardId;
}

/// Karta z dnesnej sady (posuva ten isty cursor ako Feed).
final class SetGateItem extends GateItem {
  const SetGateItem(this.card, {super.autoSeenBefore});

  final DailySetCard card;

  @override
  CardId get cardId => card.cardId;
}

/// Vers volneho citania (B11): `ayah:{id}`, mimo `cards_json`.
final class FreeReadingItem extends GateItem {
  const FreeReadingItem(this.ayah, {super.autoSeenBefore});

  final AyahId ayah;

  @override
  CardId get cardId => AyahCardId(ayah);
}

/// Poradie kariet brany (docs/02 A4, docs/01 5.3).
///
/// Karty sady od `cursor + 1`; `intro`, `event`, `done` a `khatm` sa
/// nezobrazia (prilepia sa ako [GateItem.autoSeenBefore]). Najviac
/// [maxQuiz] kvizov na branu (brana nie je test), dalsie kvizy sa preskocia
/// bez zapisu. Po konci sady nekonecne volne citanie od
/// `reading_position + 1` (za poslednym khatm versom sady, ktory brana
/// ukaze).
class GateDeck {
  GateDeck({
    required List<DailySetCard> cards,
    required int cursor,
    required AyahId? readingPosition,
    this.maxQuiz = 1,
  }) : _rest = [
         for (final c in cards)
           if (c.pos > cursor) c,
       ],
       _lastAyah = readingPosition;

  /// Typy, ktore sa v brane pocitaju do N (docs/02 A4).
  static const Set<CardType> counted = {
    CardType.ayah,
    CardType.word,
    CardType.quiz,
    CardType.hadith,
    CardType.dua,
    CardType.name,
    CardType.reflection,
  };

  final int maxQuiz;
  final List<DailySetCard> _rest;
  int _index = 0;
  int _quizzes = 0;

  /// Posledny vers khatmu, ktory bude precitany pred volnym citanim.
  AyahId? _lastAyah;

  /// true, kym sa beru karty zo sady.
  bool get inSet => _index < _rest.length;

  /// Dalsia karta na zobrazenie (nikdy nekonci, po sade ide volne citanie).
  GateItem next() {
    final auto = <DailySetCard>[];
    while (_index < _rest.length) {
      final c = _rest[_index++];
      final type = c.cardId.type;
      if (!counted.contains(type)) {
        auto.add(c);
        continue;
      }
      if (type == CardType.quiz) {
        if (_quizzes >= maxQuiz) continue;
        _quizzes++;
      }
      final id = c.cardId;
      if (c.khatm && id is AyahCardId) {
        final last = _lastAyah;
        if (last == null || id.ayahId.value > last.value) _lastAyah = id.ayahId;
      }
      return SetGateItem(c, autoSeenBefore: auto);
    }
    final ayah = _lastAyah = _nextAyah(_lastAyah);
    return FreeReadingItem(ayah, autoSeenBefore: auto);
  }
}

/// Vers po [position]; po 114:6 (khatm konci) alebo bez pozicie 1:1
/// (docs/02 B11).
AyahId _nextAyah(AyahId? position) =>
    position == null || position == AyahId.last ? AyahId.first : position.next;
