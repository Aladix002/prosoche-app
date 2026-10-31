import 'package:prosoche/data/repositories/repositories.dart';

/// Pravidla feedu bez UI (docs/02 0.4, B0.5).
abstract final class FeedRules {
  /// `card.seen_dwell_ms` default (docs/02 0.7).
  static const defaultDwellMs = 2500;
  static const defaultDwell = Duration(milliseconds: defaultDwellMs);

  /// Horna hranica dwellu pretekajucej karty.
  static const maxDwell = Duration(seconds: 15);

  /// Cas na znak textu pri pretekajucej karte.
  static const perChar = Duration(milliseconds: 40);

  /// Dwell pretekajucej karty: `max(base, 40 ms * znaky)`, najviac 15 s
  /// (docs/02 B0.5).
  static Duration dwellForOverflow(Duration base, int chars) {
    final byText = perChar * chars;
    if (byText <= base) return base;
    return byText > maxDwell ? maxDwell : byText;
  }
}

/// Pocet znakov textu, ktory pouzivatel cita (text karty).
int translationChars(CardContent? content) => switch (content) {
  IntroContent() || null => 0,
  final CardContent c => c.shareText?.length ?? 0,
};
