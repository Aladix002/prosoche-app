import 'package:meta/meta.dart';
import 'package:prosoche/domain/common/local_date.dart';

/// Typ karty = prva cast `card_id` a hodnota `card_event.type` (docs/02 0.2).
///
/// Obsahove typy podla PLAN.md kap. 2 (Prosoche) a kontraktu content.db v1
/// (`card.type`).
enum CardType {
  intro('intro', canSave: false, canShare: false),

  /// Kratky citat.
  quote('quote', canSave: true, canShare: true),

  /// Dlhsi uryvok z diela.
  passage('passage', canSave: true, canShare: true),

  /// Cvicenie (ranna priprava, vecerna reflexia, ...).
  practice('practice', canSave: true, canShare: true),

  /// Otazka na zamyslenie.
  prompt('prompt', canSave: true, canShare: true),

  /// Pojem (logos, prohairesis, ...).
  concept('concept', canSave: true, canShare: true),

  /// Uvod k autorovi.
  author('author', canSave: true, canShare: true),
  done('done', canSave: false, canShare: false);

  CardType(this.wire, {required this.canSave, required this.canShare});

  /// Retazec v `card_id` a v DB.
  final String wire;
  final bool canSave;
  final bool canShare;

  /// Typy s obsahom z content.db ([ContentCardId]).
  bool get isContent => this != intro && this != done;

  static CardType? fromWire(String wire) {
    for (final t in values) {
      if (t.wire == wire) return t;
    }
    return null;
  }
}

/// Stabilny identifikator karty `typ:kluc` (docs/02 0.2).
///
/// ```dart
/// final id = CardId.parse('quote:meditations.2.1.a');
/// switch (id) {
///   case ContentCardId(:final type, :final key): ...
///   case IntroCardId() || DoneCardId(): ...
/// }
/// ```
@immutable
sealed class CardId {
  const CardId();

  /// Parsuje `card_id`. Pri neplatnom tvare hodi [FormatException].
  factory CardId.parse(String text) {
    final sep = text.indexOf(':');
    final type = CardType.fromWire(sep < 0 ? text : text.substring(0, sep));
    if (type == null || sep < 0) {
      throw FormatException('Unknown card type', text);
    }
    final rest = text.substring(sep + 1);
    // Validacia je tu, konstruktory potom uz nehadzu.
    return switch (type) {
      CardType.intro => IntroCardId(LocalDate.parse(rest)),
      CardType.done => DoneCardId(LocalDate.parse(rest)),
      _ when keyPattern.hasMatch(rest) => ContentCardId(type, rest),
      _ => throw FormatException('Expected [A-Za-z0-9_.:-] key', text),
    };
  }

  /// Ako [CardId.parse], ale pri chybe vrati null.
  static CardId? tryParse(String text) {
    try {
      return CardId.parse(text);
    } on FormatException {
      return null;
    }
  }

  CardType get type;

  /// Cast za `typ:`.
  String get key;

  /// Tvar `typ:kluc` pre DB a `cards_json`.
  String format() => '${type.wire}:$key';

  @override
  String toString() => format();

  @override
  bool operator ==(Object other) =>
      other is CardId && other.format() == format();

  @override
  int get hashCode => format().hashCode;

  /// Povoleny tvar kluca za `typ:` (kontrakt content.db v1:
  /// `card.id` = `^[a-z][a-z_]*:[A-Za-z0-9_.:-]+$`, napr.
  /// `meditations.2.1.a`, `morning-preparation`). Max 128 znakov.
  static final keyPattern = RegExp(r'^[A-Za-z0-9_.:-]{1,128}$');
}

/// `intro:{date}` - uvodna karta dna.
final class IntroCardId extends CardId {
  const IntroCardId(this.date);
  final LocalDate date;
  @override
  CardType get type => CardType.intro;
  @override
  String get key => '$date';
}

/// `done:{date}` - karta "Dnes si hotovy", nie je v `cards` (docs/02 0.3).
final class DoneCardId extends CardId {
  const DoneCardId(this.date);
  final LocalDate date;
  @override
  CardType get type => CardType.done;
  @override
  String get key => '$date';
}

/// `{typ}:{kluc}` - obsahova karta z content.db, napr.
/// `quote:meditations.2.1.a`. Cely retazec je `card.id` v content.db.
///
/// [key] je cast za `typ:` ([CardId.keyPattern]).
final class ContentCardId extends CardId {
  ContentCardId(this.type, this.key) {
    if (!type.isContent) {
      throw ArgumentError.value(type, 'type', 'must be a content type');
    }
    if (!CardId.keyPattern.hasMatch(key)) {
      throw ArgumentError.value(key, 'key', 'must match [A-Za-z0-9_.:-]');
    }
  }

  /// `quote:{id}`.
  factory ContentCardId.quote(String id) => ContentCardId(CardType.quote, id);

  @override
  final CardType type;
  @override
  final String key;
}
