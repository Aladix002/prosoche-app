import 'package:meta/meta.dart';
import 'package:sakina/domain/common/ayah_id.dart';
import 'package:sakina/domain/common/local_date.dart';

/// Typ karty = prva cast `card_id` a hodnota `card_event.type` (docs/02 0.2).
enum CardType {
  intro('intro', canSave: false, canShare: false),
  ayah('ayah', canSave: true, canShare: true),
  word('word', canSave: false, canShare: true),
  quiz('quiz', canSave: false, canShare: false),
  hadith('hadith', canSave: true, canShare: true),
  dua('dua', canSave: true, canShare: true),
  name('name', canSave: true, canShare: true),
  reflection('reflection', canSave: true, canShare: true),
  event('event', canSave: false, canShare: false),
  done('done', canSave: false, canShare: false),
  khatm('khatm', canSave: false, canShare: false);

  CardType(this.wire, {required this.canSave, required this.canShare});

  /// Retazec v `card_id` a v DB.
  final String wire;
  final bool canSave;
  final bool canShare;

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
/// final id = CardId.parse('ayah:2255');
/// switch (id) {
///   case AyahCardId(:final ayahId): ...
///   ...
/// }
/// ```
@immutable
sealed class CardId {
  const CardId();

  /// Parsuje `card_id`. Pri neplatnom tvare hodi [FormatException].
  factory CardId.parse(String text) {
    final parts = text.split(':');
    final type = CardType.fromWire(parts.first);
    if (type == null) throw FormatException('Unknown card type', text);
    final args = parts.sublist(1);
    // Validacia je tu, konstruktory potom uz nehadzu.
    return switch (type) {
      CardType.intro => IntroCardId(_date(args, text)),
      CardType.ayah => AyahCardId(
        AyahId.tryFromValue(_int(args, text)) ??
            (throw FormatException('Ayah out of range', text)),
      ),
      CardType.word => WordCardId(_int(args, text)),
      CardType.quiz => QuizCardId(
        _int(args, text, arity: 2),
        _key(args[1], text),
      ),
      CardType.hadith => HadithCardId(_int(args, text)),
      CardType.dua => DuaCardId(_int(args, text)),
      CardType.name => NameCardId(_int(args, text, max: 99)),
      CardType.reflection => ReflectionCardId(_int(args, text)),
      CardType.event => EventCardId(
        _key(_arity(args, 2, text).first, text),
        LocalDate.parse(args[1]),
      ),
      CardType.done => DoneCardId(_date(args, text)),
      CardType.khatm => KhatmCardId(_int(args, text)),
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

  static List<String> _arity(List<String> args, int n, String text) {
    if (args.length != n || args.any((a) => a.isEmpty)) {
      throw FormatException('Expected $n key part(s)', text);
    }
    return args;
  }

  static int _int(List<String> args, String text, {int arity = 1, int? max}) {
    final raw = _arity(args, arity, text).first;
    if (!_digits.hasMatch(raw)) {
      throw FormatException('Expected positive integer', text);
    }
    final value = int.parse(raw);
    if (max != null && value > max) {
      throw FormatException('Value out of range 1..$max', text);
    }
    return value;
  }

  static LocalDate _date(List<String> args, String text) =>
      LocalDate.parse(_arity(args, 1, text).first);

  static String _key(String raw, String text) {
    if (!keyPattern.hasMatch(raw)) {
      throw FormatException('Expected [a-z0-9_] key', text);
    }
    return raw;
  }

  static final _digits = RegExp(r'^[1-9]\d{0,8}$');

  /// Povoleny tvar textovych klucov (`event_id`, `qtype`).
  static final keyPattern = RegExp(r'^[a-z0-9_]{1,64}$');
}

void _checkPositive(int value, String name) {
  if (value < 1) throw RangeError.value(value, name, 'must be >= 1');
}

void _checkKey(String value, String name) {
  if (!CardId.keyPattern.hasMatch(value)) {
    throw ArgumentError.value(value, name, 'must match [a-z0-9_]{1,64}');
  }
}

/// `intro:{date}`
final class IntroCardId extends CardId {
  const IntroCardId(this.date);
  final LocalDate date;
  @override
  CardType get type => CardType.intro;
  @override
  String get key => '$date';
}

/// `ayah:{ayah_id}`
final class AyahCardId extends CardId {
  const AyahCardId(this.ayahId);
  final AyahId ayahId;
  @override
  CardType get type => CardType.ayah;
  @override
  String get key => '${ayahId.value}';
}

/// `word:{lemma_id}`
final class WordCardId extends CardId {
  WordCardId(this.lemmaId) {
    _checkPositive(lemmaId, 'lemmaId');
  }
  final int lemmaId;
  @override
  CardType get type => CardType.word;
  @override
  String get key => '$lemmaId';
}

/// `quiz:{lemma_id}:{qtype}`, napr. `quiz:1043:ar2mean`.
final class QuizCardId extends CardId {
  QuizCardId(this.lemmaId, this.qtype) {
    _checkPositive(lemmaId, 'lemmaId');
    _checkKey(qtype, 'qtype');
  }
  final int lemmaId;
  final String qtype;
  @override
  CardType get type => CardType.quiz;
  @override
  String get key => '$lemmaId:$qtype';
}

/// `hadith:{hadith_id}`
final class HadithCardId extends CardId {
  HadithCardId(this.hadithId) {
    _checkPositive(hadithId, 'hadithId');
  }
  final int hadithId;
  @override
  CardType get type => CardType.hadith;
  @override
  String get key => '$hadithId';
}

/// `dua:{dua_id}`
final class DuaCardId extends CardId {
  DuaCardId(this.duaId) {
    _checkPositive(duaId, 'duaId');
  }
  final int duaId;
  @override
  CardType get type => CardType.dua;
  @override
  String get key => '$duaId';
}

/// `name:{name_id}` (1..99)
final class NameCardId extends CardId {
  NameCardId(this.nameId) {
    RangeError.checkValueInInterval(nameId, 1, 99, 'nameId');
  }
  final int nameId;
  @override
  CardType get type => CardType.name;
  @override
  String get key => '$nameId';
}

/// `reflection:{reflection_id}`
final class ReflectionCardId extends CardId {
  ReflectionCardId(this.reflectionId) {
    _checkPositive(reflectionId, 'reflectionId');
  }
  final int reflectionId;
  @override
  CardType get type => CardType.reflection;
  @override
  String get key => '$reflectionId';
}

/// `event:{event_id}:{date}`, napr. `event:jumuah:2026-10-30`.
final class EventCardId extends CardId {
  EventCardId(this.eventId, this.date) {
    _checkKey(eventId, 'eventId');
  }
  final String eventId;
  final LocalDate date;
  @override
  CardType get type => CardType.event;
  @override
  String get key => '$eventId:$date';
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

/// `khatm:{n}` - n-te dokoncenie Koranu.
final class KhatmCardId extends CardId {
  KhatmCardId(this.n) {
    _checkPositive(n, 'n');
  }
  final int n;
  @override
  CardType get type => CardType.khatm;
  @override
  String get key => '$n';
}
