import 'package:meta/meta.dart';

/// Rastuci odpor brany (G-01): kazde dalsie otvorenie tej istej appky
/// v ten isty den (od lokalnej polnoci) predlzi dwell karty a od
/// [extraCardFrom]. otvorenia prida jednu kartu. Strop: [maxDwellFactor]
/// a [maxExtraCards]. Emergency sa tym nemeni.
@immutable
final class GateFriction {
  const GateFriction._(this.opens, this.dwellFactor, this.extraCards);

  /// Odpor pre [opens]. otvorenie dna (1 = prve, vratane aktualneho).
  factory GateFriction.forOpen(int opens) {
    final n = opens < 1 ? 1 : opens;
    final factor = 1 + dwellStep * (n - 1);
    return GateFriction._(
      n,
      factor > maxDwellFactor ? maxDwellFactor : factor,
      n >= extraCardFrom ? maxExtraCards : 0,
    );
  }

  /// Bez odporu (vypnute alebo prve otvorenie).
  static const none = GateFriction._(1, 1, 0);

  /// Kazde dalsie otvorenie pridava k dwellu tolko nasobku.
  static const dwellStep = 0.25;

  /// Najviac 2x dwell (od 5. otvorenia).
  static const maxDwellFactor = 2.0;

  /// Od tohto otvorenia dna o kartu viac.
  static const extraCardFrom = 4;

  static const maxExtraCards = 1;

  /// Poradie otvorenia dna (1 = prve).
  final int opens;

  /// Nasobok dwellu karty, 1.0 az [maxDwellFactor].
  final double dwellFactor;

  /// Karty navyse k `cards_required`, 0 az [maxExtraCards].
  final int extraCards;

  /// Dwell [base] po odpore, zaokruhleny na cele sekundy nahor.
  Duration dwell(Duration base) {
    final ms = (base.inMilliseconds * dwellFactor).round();
    return Duration(milliseconds: (ms / 1000).ceil() * 1000);
  }

  @override
  bool operator ==(Object other) =>
      other is GateFriction &&
      other.opens == opens &&
      other.dwellFactor == dwellFactor &&
      other.extraCards == extraCards;

  @override
  int get hashCode => Object.hash(opens, dwellFactor, extraCards);

  @override
  String toString() =>
      'GateFriction(opens: $opens, x$dwellFactor, +$extraCards)';
}

/// Ranny zamok "Practice first" (G-01): zvolene appky su od lokalnej
/// polnoci do [until] zamknute, kym nie je dokoncena ranna priprava
/// v Practice. Emergency ostava.
@immutable
final class PracticeFirstRule {
  const PracticeFirstRule({required this.enabled, required this.until});

  /// Default konca zamku (`gate.practice_first.until`).
  static const defaultUntil = '10:00';

  final bool enabled;

  /// Koniec zamku ako `HH:mm` v lokalnom case.
  final String until;

  /// Minuta dna konca zamku; neplatny text = [defaultUntil].
  int get untilMinutes => parseMinutes(until) ?? parseMinutes(defaultUntil)!;

  /// `HH:mm` -> minuta dna, inak null.
  static int? parseMinutes(String text) {
    final m = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(text);
    if (m == null) return null;
    return int.parse(m[1]!) * 60 + int.parse(m[2]!);
  }

  /// Je appka teraz zamknuta? [now] je lokalny cas, [appSelected] =
  /// `blocked_app.practice_first`, [morningDone] = ranna priprava dna.
  bool locks({
    required DateTime now,
    required bool appSelected,
    required bool morningDone,
  }) {
    if (!enabled || !appSelected || morningDone) return false;
    return now.hour * 60 + now.minute < untilMinutes;
  }
}
