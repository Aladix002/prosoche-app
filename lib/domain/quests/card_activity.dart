import 'package:meta/meta.dart';
import 'package:prosoche/domain/common/common.dart';

/// Hodnota `card_event.action` (docs/02 0.5, D1).
enum CardAction {
  seen('seen'),
  answered('answered'),
  saved('saved'),
  unsaved('unsaved'),
  skipped('skipped'),
  shared('shared'),
  sourceOpened('source_opened'),
  reported('reported');

  CardAction(this.wire);

  final String wire;

  static CardAction? fromWire(String wire) {
    for (final a in values) {
      if (a.wire == wire) return a;
    }
    return null;
  }
}

/// Hodnota `card_event.context` (docs/02 D1).
enum CardContext {
  feed('feed'),
  gate('gate'),
  reader('reader'),
  saved('saved');

  CardContext(this.wire);

  final String wire;

  static CardContext? fromWire(String wire) {
    for (final c in values) {
      if (c.wire == wire) return c;
    }
    return null;
  }
}

/// Jeden riadok `card_event` v tvare, ktory potrebuje QuestEngine.
///
/// [date] je `activeSetDate` (docs/02 0.1), nie datum z [ts].
@immutable
final class CardActivity {
  const CardActivity({
    required this.date,
    required this.cardId,
    required this.action,
    required this.ts,
    this.context = CardContext.feed,
  });

  final LocalDate date;
  final CardId cardId;
  final CardAction action;
  final CardContext context;

  /// Cas zapisu (lokalny), pouzije sa ako cas splnenia questu.
  final DateTime ts;

  CardType get type => cardId.type;

  @override
  bool operator ==(Object other) =>
      other is CardActivity &&
      other.date == date &&
      other.cardId == cardId &&
      other.action == action &&
      other.context == context &&
      other.ts == ts;

  @override
  int get hashCode => Object.hash(date, cardId, action, context, ts);

  @override
  String toString() =>
      'CardActivity($date, $cardId, ${action.wire}, ${context.wire})';
}
