import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/common/common.dart';

/// Pravidla feedu bez UI (docs/02 0.4, B0.5).
abstract final class FeedRules {
  /// `card.seen_dwell_ms` default (docs/02 0.7).
  static const defaultDwellMs = 2500;
  static const defaultDwell = Duration(milliseconds: defaultDwellMs);

  /// Horna hranica dwellu pretekajucej karty.
  static const maxDwell = Duration(seconds: 15);

  /// Cas na znak prekladu pri pretekajucej karte.
  static const perChar = Duration(milliseconds: 40);

  /// Dwell pretekajucej karty: `max(base, 40 ms * znaky)`, najviac 15 s
  /// (docs/02 B0.5).
  static Duration dwellForOverflow(Duration base, int chars) {
    final byText = perChar * chars;
    if (byText <= base) return base;
    return byText > maxDwell ? maxDwell : byText;
  }
}

/// Pocet znakov textu, ktory pouzivatel cita (preklad, text karty).
int translationChars(CardContent? content) => switch (content) {
  AyahContent(:final ayah) => ayah.translation?.text.length ?? 0,
  HadithContent(:final text) => text?.length ?? 0,
  DuaContent(:final text) => text?.length ?? 0,
  NameContent(:final meaning, :final shortNote) =>
    (meaning?.length ?? 0) + (shortNote?.length ?? 0),
  ReflectionContent(:final text, :final question) =>
    text.length + (question?.length ?? 0),
  EventContent(:final text) => text?.body?.length ?? 0,
  IntroContent() || KhatmContent() || null => 0,
};

/// Kde pokracuje volne citanie (khatm): vers po `reading_position`, po
/// 114:6 alebo bez pozicie od 1:1 (docs/02 A2, B10).
AyahId nextReadingAyah(AyahId? position) =>
    position == null || position == AyahId.last ? AyahId.first : position.next;
