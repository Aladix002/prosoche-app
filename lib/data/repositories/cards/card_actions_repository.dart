import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:sakina/data/db/user_db.dart' as db;
import 'package:sakina/data/repositories/infra/card_events.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/quests/quests.dart';

/// Ulozena karta (A8.3).
@immutable
final class SavedCard {
  const SavedCard(this.cardId, this.savedAt);

  final CardId cardId;

  /// Lokalny cas ulozenia.
  final DateTime savedAt;
}

/// Akcie nad kartou mimo `seen`: ulozenie, zdielanie, audio, zdroj,
/// nahlasenie (docs/02 0.5, B0). Zapis do `card_event` s [CardContext].
abstract interface class CardActionsRepository {
  /// `card_event` s akciou [action] (napr. `shared`, `source_opened`).
  /// Pre `seen` pouzi `DailySetRepository.markSeen` alebo
  /// `QuranRepository.markRead`.
  Future<void> log(
    LocalDate date,
    CardId card,
    CardAction action, {
    required CardContext context,
    int? pos,
    int? value,
  });

  /// Ulozi kartu (`saved_card` + `card_event{saved}`). Len typy
  /// s `CardType.canSave`.
  Future<void> save(
    LocalDate date,
    CardId card, {
    required CardContext context,
  });

  Future<void> unsave(
    LocalDate date,
    CardId card, {
    required CardContext context,
  });

  Stream<bool> watchIsSaved(CardId card);

  /// Ulozene karty, najnovsie prve, volitelne len [type].
  Stream<List<SavedCard>> watchSaved({CardType? type});
}

class DriftCardActionsRepository implements CardActionsRepository {
  DriftCardActionsRepository({required db.UserDb userDb, required this._clock})
    : _db = userDb;

  final db.UserDb _db;
  final Clock _clock;

  @override
  Future<void> log(
    LocalDate date,
    CardId card,
    CardAction action, {
    required CardContext context,
    int? pos,
    int? value,
  }) => logCardEvent(
    _db,
    date: date,
    card: card,
    action: action,
    context: context,
    now: _clock.now(),
    pos: pos,
    value: value,
  );

  @override
  Future<void> save(
    LocalDate date,
    CardId card, {
    required CardContext context,
  }) async {
    if (!card.type.canSave) {
      throw ArgumentError.value(card, 'card', 'cannot be saved');
    }
    await _db.transaction(() async {
      await _db.savedCardDao.save(card, _clock.now().toUtc());
      await log(date, card, CardAction.saved, context: context);
    });
  }

  @override
  Future<void> unsave(
    LocalDate date,
    CardId card, {
    required CardContext context,
  }) => _db.transaction(() async {
    await _db.savedCardDao.unsave(card);
    await log(date, card, CardAction.unsaved, context: context);
  });

  @override
  Stream<bool> watchIsSaved(CardId card) => _db.savedCardDao.watchIsSaved(card);

  @override
  Stream<List<SavedCard>> watchSaved({CardType? type}) => _db.savedCardDao
      .watchAll(type: type)
      .map(
        (rows) => [
          for (final r in rows)
            if (CardId.tryParse(r.cardId) case final id?)
              SavedCard(id, r.savedAt.toLocal()),
        ],
      );
}
