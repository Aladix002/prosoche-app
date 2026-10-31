import 'package:meta/meta.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/feed/card_selector.dart';
import 'package:prosoche/domain/feed/daily_set.dart';
import 'package:prosoche/domain/feed/day_phase.dart';
import 'package:prosoche/domain/feed/feed_inputs.dart';

/// Vysledok generovania.
@immutable
final class FeedResult {
  const FeedResult({required this.set, required this.shorterSetAvailable});

  final DailySet set;

  /// Today moze ponuknut "shorter set" (docs/01 D6).
  final bool shorterSetAvailable;
}

/// Deterministicka denna sada (plan 7.1, docs/02 0.3).
///
/// Rovnake [FeedInputs] daju vzdy rovnaku sadu. Nahodnost ide len cez
/// `Random(mixSeed(seed, salt))`.
///
/// S-01: skladba je uvodna karta a citaty. F-01 doplni dalsie typy do
/// [layouts]; slot bez kandidata sa naplni citatom ([fallbackSlot]) a ak
/// nie je ani citat, karta sa vynecha (sada je kratsia).
final class FeedGenerator {
  const FeedGenerator();

  /// Po kolkych dnoch neaktivity je dostupna kratsia sada.
  static const shorterSetMinInactiveDays = 7;

  /// Pocet kariet kratsej sady.
  static const shorterSetSize = 6;

  static bool isShorterSetAvailable(int inactiveDays) =>
      inactiveDays >= shorterSetMinInactiveDays;

  /// Slot, ktorym sa nahradi slot bez kandidata.
  static const Slot fallbackSlot = Slot.quote;

  /// Skladba podla `feed.cards_count`.
  static final Map<int, List<Slot>> layouts = {
    for (final n in FeedPrefs.allowedCardsCounts) n: _quotes(n),
  };

  /// Kratsia sada (docs/01 D6).
  static final List<Slot> shorterLayout = _quotes(shorterSetSize);

  static List<Slot> _quotes(int n) =>
      List.unmodifiable([Slot.intro, for (var i = 1; i < n; i++) Slot.quote]);

  FeedResult generate(FeedInputs inputs) => _Run(inputs).build();
}

final class _Run {
  _Run(this.inputs)
    : phase = DayPhase.resolve(
        inputs.generatedAtLocalTime,
        boundaries: inputs.dayBoundaries,
      ),
      selector = CardSelector(
        date: inputs.date,
        seed: inputs.seed,
        lastShown: inputs.history.lastShown,
        disabled: inputs.history.disabledIds,
      );

  final FeedInputs inputs;
  final DayPhase phase;
  final CardSelector selector;

  final _cards = <DailySetCard>[];
  final _used = <CardId>{};

  FeedResult build() {
    final shorter =
        inputs.prefs.shorterSet &&
        FeedGenerator.isShorterSetAvailable(inputs.inactiveDays);
    final layout = shorter
        ? FeedGenerator.shorterLayout
        : FeedGenerator.layouts[inputs.prefs.cardsCount]!;
    for (final (i, slot) in layout.indexed) {
      _fill(slot, salt: i + 1);
    }
    return FeedResult(
      set: DailySet(
        date: inputs.date,
        phase: phase,
        cards: _cards,
        contentVersion: inputs.contentVersion,
        tz: inputs.tz,
      ),
      shorterSetAvailable: FeedGenerator.isShorterSetAvailable(
        inputs.inactiveDays,
      ),
    );
  }

  void _fill(Slot slot, {required int salt}) {
    if (slot == Slot.intro) return _add(IntroCardId(inputs.date), slot);
    final picked =
        _pick(slot, salt) ??
        (slot == FeedGenerator.fallbackSlot
            ? null
            : _pick(FeedGenerator.fallbackSlot, salt));
    if (picked != null) _add(picked.id, Slot.fromWire(picked.type.wire)!);
  }

  FeedCandidate? _pick(Slot slot, int salt) => selector.pick(
    inputs.pools.of(slot.cardType),
    salt: salt,
    exclude: _used,
    timeOfDay: TimeOfDayFacet.fromPhase(phase),
  );

  void _add(CardId id, Slot slot) {
    _used.add(id);
    _cards.add(DailySetCard(pos: _cards.length + 1, cardId: id, slot: slot));
  }
}
