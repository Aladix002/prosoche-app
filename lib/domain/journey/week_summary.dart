import 'package:meta/meta.dart';
import 'package:prosoche/domain/common/local_date.dart';
import 'package:prosoche/domain/practice/routine.dart';

/// Okno tyzdenneho prehladu (J-01): poslednych 7 dni vratane dnes.
///
/// Preco nie kalendarny tyzden (pondelok - nedela): v pondelok rano by
/// prehlad bol takmer prazdny a prvy den tyzdna sa podla locale lisi
/// (v1 je len EN, ale US zacina nedelou). Klzave okno ma vzdy 7 dni,
/// je rovnake ako "this week" v nastaveniach brany (A10.1) a v nedelu
/// je to presne pondelok az nedela.
@immutable
final class WeekWindow {
  const WeekWindow._(this.start, this.end);

  /// Okno, ktore konci dnom [today] (vratane).
  factory WeekWindow.endingOn(LocalDate today) =>
      WeekWindow._(today.addDays(1 - days), today);

  static const days = 7;

  /// Prvy den okna.
  final LocalDate start;

  /// Posledny den okna (dnes).
  final LocalDate end;

  bool contains(LocalDate date) => !date.isBefore(start) && !date.isAfter(end);

  /// Lokalna polnoc prveho dna (dolna hranica dotazov nad casom).
  DateTime get from => start.toLocalDateTime();

  /// Lokalna polnoc po poslednom dni (horna hranica, vylucna).
  DateTime get until => end.addDays(1).toLocalDateTime();

  @override
  bool operator ==(Object other) =>
      other is WeekWindow && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'WeekWindow($start..$end)';
}

/// Ako skoncilo jedno otvorenie brany (zrkadlo `gate_session.result`).
enum GateOutcome {
  /// Karty precitane, appka sa odomkla.
  passed,

  /// Nudzove odomknutie.
  emergency,

  /// "Close" / "Go back" / "Not now": appka sa neotvorila.
  dismissed,

  /// Brana zlyhala.
  error,

  /// Brana este bezi (result null).
  open,
}

/// Jedno otvorenie brany v lokalnom case.
@immutable
final class GateVisit {
  const GateVisit({required this.at, required this.outcome, this.appLabel});

  /// `opened_at` v lokalnej zone zariadenia.
  final DateTime at;
  final GateOutcome outcome;

  /// Nazov appky (`blocked_app.label`), ak je znamy. Nikdy nie package.
  final String? appLabel;
}

/// Surove data tyzdna z user.db (bez dennika).
@immutable
final class WeekActivity {
  const WeekActivity({
    this.gateVisits = const [],
    this.cardsReadByDay = const {},
    this.practice = const {},
    this.firstActiveDay,
  });

  static const empty = WeekActivity();

  final List<GateVisit> gateVisits;

  /// Pocet roznych precitanych kariet podla dna.
  final Map<LocalDate, int> cardsReadByDay;

  /// Dokoncena prax podla dna.
  final Map<LocalDate, Set<RoutineKind>> practice;

  /// Prvy den, ked appka nieco zaznamenala (null = este nic).
  final LocalDate? firstActiveDay;
}

/// Brana za tyzden.
@immutable
final class GateWeek {
  const GateWeek({
    required this.paused,
    required this.notOpened,
    this.topApps = const [],
  });

  /// Kolkokrat brana zastavila otvorenie appky.
  final int paused;

  /// Kolkokrat sa pouzivatel rozhodol appku neotvorit (ukoncene cez
  /// Close / Go back bez odomknutia).
  final int notOpened;

  /// Najcastejsie zastavene appky (najviac [WeekSummary.maxTopApps]).
  /// Na obrazok idu len po vyslovnom suhlase.
  final List<String> topApps;
}

/// Tyzdenny prehlad pre Journey a zdielany obrazok.
///
/// Odhad usetreneho casu tu zamerne nie je. Poctivo sa odvodit neda:
/// appka nemeria cas v inych appkach (ziadne povolenie Usage Access),
/// "neotvoril som" neznamena, ze by inak appka bezala dlho, a dlzka
/// odomknutia (`unlock_minutes`) je strop jedneho okna, nie realne
/// pouzitie. Kazde cislo by bolo vymyslene.
@immutable
final class WeekSummary {
  const WeekSummary({
    required this.window,
    required this.since,
    required this.cardsRead,
    required this.morningDays,
    required this.eveningDays,
    required this.practiceDays,
    this.gate,
    this.streak,
  });

  /// Zostavi prehlad z [activity] v okne [window].
  ///
  /// [gateAvailable]: brana je v tejto edicii a je zapnuta. Ak nie je
  /// a za tyzden nema ani jedno otvorenie, riadky brany sa nezobrazia
  /// (lite flavor). [streak] null = skryty (simple mode).
  factory WeekSummary.compute({
    required WeekWindow window,
    required WeekActivity activity,
    required bool gateAvailable,
    int? streak,
  }) {
    final first = activity.firstActiveDay;
    final since = first != null && first.isAfter(window.start)
        ? (first.isAfter(window.end) ? window.end : first)
        : window.start;

    final visits = [
      for (final v in activity.gateVisits)
        if (window.contains(LocalDate.fromDateTime(v.at))) v,
    ];
    GateWeek? gate;
    if (gateAvailable || visits.isNotEmpty) {
      final perApp = <String, int>{};
      for (final v in visits) {
        final label = v.appLabel?.trim();
        if (label == null || label.isEmpty) continue;
        perApp[label] = (perApp[label] ?? 0) + 1;
      }
      final top = perApp.entries.toList()
        ..sort((a, b) {
          final c = b.value.compareTo(a.value);
          return c != 0 ? c : a.key.compareTo(b.key);
        });
      gate = GateWeek(
        paused: visits.length,
        notOpened: visits
            .where((v) => v.outcome == GateOutcome.dismissed)
            .length,
        topApps: [for (final e in top.take(maxTopApps)) e.key],
      );
    }

    var cards = 0;
    for (final e in activity.cardsReadByDay.entries) {
      if (window.contains(e.key)) cards += e.value;
    }

    var morning = 0;
    var evening = 0;
    var practiced = 0;
    for (final e in activity.practice.entries) {
      if (!window.contains(e.key) || e.value.isEmpty) continue;
      practiced++;
      if (e.value.contains(RoutineKind.morning)) morning++;
      if (e.value.contains(RoutineKind.evening)) evening++;
    }

    return WeekSummary(
      window: window,
      since: since,
      gate: gate,
      cardsRead: cards,
      morningDays: morning,
      eveningDays: evening,
      practiceDays: practiced,
      streak: streak,
    );
  }

  static const maxTopApps = 3;

  final WeekWindow window;

  /// Od ktoreho dna sa pocita: zaciatok okna, alebo prvy den appky, ak
  /// je to prvy tyzden.
  final LocalDate since;

  /// null = brana nie je (lite) alebo nebola pouzita.
  final GateWeek? gate;

  final int cardsRead;

  /// Dni s rannou pripravou.
  final int morningDays;

  /// Dni s vecernou reflexiou.
  final int eveningDays;

  /// Dni s aspon jednou praxou (ranna alebo vecerna).
  final int practiceDays;

  /// Aktualny streak; null = skryty.
  final int? streak;

  /// Prvy tyzden: appka sa zacala pouzivat az pocas okna.
  bool get isPartial => since != window.start;

  /// Pocet dni, za ktore su data (1-7).
  int get dayCount => window.end.daysSince(since) + 1;

  /// Nic na ukazanie: ziadna karta, prax, brana ani streak.
  bool get isEmpty =>
      cardsRead == 0 &&
      practiceDays == 0 &&
      (gate?.paused ?? 0) == 0 &&
      (streak ?? 0) == 0;
}
