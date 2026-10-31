import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/day_phase.dart';

/// Jedna polozka `cards_json.cards` (docs/02 0.3).
@immutable
final class DailySetCard {
  DailySetCard({
    required this.pos,
    required this.cardId,
    required this.slot,
    this.ctxAyahId,
    List<int> distractors = const [],
    this.khatm = false,
    this.eventId,
  }) : distractors = List.unmodifiable(distractors) {
    if (pos < 1) throw RangeError.value(pos, 'pos', 'must be >= 1');
    if (cardId is DoneCardId) {
      throw ArgumentError.value(cardId, 'cardId', 'done is not in cards');
    }
  }

  factory DailySetCard.fromJson(Map<String, Object?> json) {
    final slotWire = _req<String>(json, 'slot');
    final ctx = _opt<int>(json, 'ctx_ayah_id');
    return DailySetCard(
      pos: _req<int>(json, 'pos'),
      cardId: CardId.parse(_req<String>(json, 'card_id')),
      slot:
          Slot.fromWire(slotWire) ??
          (throw FormatException('Unknown slot', slotWire)),
      ctxAyahId: ctx == null
          ? null
          : AyahId.tryFromValue(ctx) ??
                (throw FormatException('ctx_ayah_id out of range', '$ctx')),
      distractors: [
        for (final d in _opt<List<Object?>>(json, 'distractors') ?? <Object?>[])
          if (d is int) d else throw const FormatException('distractors: int'),
      ],
      khatm: _opt<bool>(json, 'khatm') ?? false,
      eventId: _opt<String>(json, 'event_id'),
    );
  }

  /// 1-based poradie karty v sade.
  final int pos;
  final CardId cardId;

  /// Rola karty v sade po vyhodnoteni fallbackov.
  final Slot slot;

  /// Vers, z ktoreho je slovo (len `word`).
  final AyahId? ctxAyahId;

  /// `lemma_id` distraktorov kvizu (len `quiz`).
  final List<int> distractors;

  /// Vers je pokracovanim khatmu a jeho `seen` posuva `reading_position`
  /// (docs/02 B2). Eventove versy maju false.
  final bool khatm;

  /// Event zobrazeny na uvodnej karte (len `intro`); null = len hijri datum.
  final String? eventId;

  Map<String, Object?> toJson() => {
    'pos': pos,
    'card_id': cardId.format(),
    'slot': slot.wire,
    if (ctxAyahId != null) 'ctx_ayah_id': ctxAyahId!.value,
    if (distractors.isNotEmpty) 'distractors': distractors,
    if (khatm) 'khatm': true,
    'event_id': ?eventId,
  };

  @override
  bool operator ==(Object other) =>
      other is DailySetCard &&
      other.pos == pos &&
      other.cardId == cardId &&
      other.slot == slot &&
      other.ctxAyahId == ctxAyahId &&
      other.khatm == khatm &&
      other.eventId == eventId &&
      _listEq(other.distractors, distractors);

  @override
  int get hashCode => Object.hash(
    pos,
    cardId,
    slot,
    ctxAyahId,
    khatm,
    eventId,
    Object.hashAll(distractors),
  );

  @override
  String toString() => 'DailySetCard(${toJson()})';
}

/// Denna sada ulozena v `daily_set` (plan 7.1, docs/02 0.3, D13).
///
/// `cards` obsahuje N obsahovych kariet a pripadne kartu khatm, ktora sa do N
/// nepocita. Karta "Dnes si hotovy" v `cards` nie je, UI ju zobrazi ako N+1
/// ([doneCardId]).
@immutable
final class DailySet {
  DailySet({
    required this.date,
    required this.phase,
    required List<DailySetCard> cards,
    this.contentVersion,
    this.tz,
    this.generatorVersion = currentGeneratorVersion,
  }) : cards = List.unmodifiable(cards) {
    for (final (i, c) in this.cards.indexed) {
      if (c.pos != i + 1) {
        throw ArgumentError('cards must have pos 1..${this.cards.length}');
      }
    }
  }

  /// Dekoduje `cards_json` v1. Datum je stlpec `daily_set.date`.
  factory DailySet.fromJson(
    Map<String, Object?> json, {
    required LocalDate date,
  }) {
    final v = _req<int>(json, 'v');
    if (v != formatVersion) {
      throw FormatException('Unsupported cards_json version', '$v');
    }
    final phaseWire = _req<String>(json, 'phase');
    return DailySet(
      date: date,
      phase:
          DayPhase.fromWire(phaseWire) ??
          (throw FormatException('Unknown phase', phaseWire)),
      generatorVersion: _req<int>(json, 'generator_version'),
      contentVersion: _opt<String>(json, 'content_version'),
      tz: _opt<String>(json, 'tz'),
      cards: [
        for (final c in _req<List<Object?>>(json, 'cards'))
          if (c is Map<String, Object?>)
            DailySetCard.fromJson(c)
          else
            throw const FormatException('cards: expected objects'),
      ],
    );
  }

  /// Ako [DailySet.fromJson] z textu `daily_set.cards_json`.
  factory DailySet.decode(String cardsJson, {required LocalDate date}) {
    final raw = jsonDecode(cardsJson);
    if (raw is! Map<String, Object?>) {
      throw const FormatException('cards_json: expected object');
    }
    return DailySet.fromJson(raw, date: date);
  }

  /// Verzia formatu `cards_json`.
  static const formatVersion = 1;

  /// Verzia algoritmu FeedGenerator (zmena = ina sada pre rovnaky vstup).
  static const currentGeneratorVersion = 1;

  final LocalDate date;
  final DayPhase phase;
  final List<DailySetCard> cards;
  final int generatorVersion;
  final String? contentVersion;
  final String? tz;

  /// Obsahove karty (bez khatm).
  List<DailySetCard> get contentCards =>
      cards.where((c) => c.cardId is! KhatmCardId).toList();

  /// N = pocet obsahovych kariet (nepocita khatm ani done).
  int get n => contentCards.length;

  /// Karta N+1, mimo `cards`.
  DoneCardId get doneCardId => DoneCardId(date);

  Map<String, Object?> toJson() => {
    'v': formatVersion,
    'generator_version': generatorVersion,
    'content_version': ?contentVersion,
    'tz': ?tz,
    'phase': phase.wire,
    'cards': [for (final c in cards) c.toJson()],
  };

  /// Text pre `daily_set.cards_json`.
  String encode() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      other is DailySet &&
      other.date == date &&
      other.phase == phase &&
      other.generatorVersion == generatorVersion &&
      other.contentVersion == contentVersion &&
      other.tz == tz &&
      _listEq(other.cards, cards);

  @override
  int get hashCode => Object.hash(
    date,
    phase,
    generatorVersion,
    contentVersion,
    tz,
    Object.hashAll(cards),
  );

  @override
  String toString() =>
      'DailySet($date, ${phase.wire}, '
      '${cards.map((c) => c.cardId).join(', ')})';
}

T _req<T>(Map<String, Object?> m, String key) => switch (m[key]) {
  final T v => v,
  _ => throw FormatException('$key: expected $T'),
};

T? _opt<T>(Map<String, Object?> m, String key) => switch (m[key]) {
  null => null,
  final T v => v,
  _ => throw FormatException('$key: expected $T'),
};

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
