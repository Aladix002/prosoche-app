import 'package:meta/meta.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/feed.dart';

/// Karta zobrazena v brane.
@immutable
sealed class GateItem {
  const GateItem({this.autoSeenBefore = const []});

  /// Karty sady bez zobrazenia (intro), ktore sa oznacia `seen`
  /// s `context=gate` pred touto kartou, aby cursor nemal medzeru
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

/// Karta volneho citania po konci sady (B11), mimo `cards_json`.
final class FreeReadingItem extends GateItem {
  const FreeReadingItem(this.cardId, {super.autoSeenBefore});

  @override
  final CardId cardId;
}

/// Poradie kariet brany (docs/02 A4, docs/01 5.3).
///
/// Karty sady od `cursor + 1`; `intro` a `done` sa nezobrazia (prilepia sa
/// ako [GateItem.autoSeenBefore]). Po konci sady volne citanie z `extra`
/// (dokola); bez neho vrati [next] null a brana skonci stavom empty.
class GateDeck {
  GateDeck({
    required List<DailySetCard> cards,
    required int cursor,
    List<CardId> extra = const [],
  }) : _rest = [
         for (final c in cards)
           if (c.pos > cursor) c,
       ],
       _extra = [
         for (final id in extra)
           if (id.type.isContent && !cards.any((c) => c.cardId == id)) id,
       ];

  final List<DailySetCard> _rest;
  final List<CardId> _extra;
  int _index = 0;
  int _extraIndex = 0;

  /// true, kym sa beru karty zo sady.
  bool get inSet => _index < _rest.length;

  /// Dalsia karta na zobrazenie; null = nie je co ukazat.
  GateItem? next() {
    final auto = <DailySetCard>[];
    while (_index < _rest.length) {
      final c = _rest[_index++];
      if (!c.cardId.type.isContent) {
        auto.add(c);
        continue;
      }
      return SetGateItem(c, autoSeenBefore: auto);
    }
    if (_extra.isEmpty) return null;
    final id = _extra[_extraIndex++ % _extra.length];
    return FreeReadingItem(id, autoSeenBefore: auto);
  }
}
