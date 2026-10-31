import 'package:sakina/data/db/user_db.dart' as db;
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/domain/quests/quests.dart';

/// Domenove enumy `card_event` (E-03) -> enumy stlpcov user.db (D-01).
/// Nazvy hodnot su zhodne, `wire` tiez.
db.CardContext dbContext(CardContext c) => db.CardContext.values.byName(c.name);

db.CardAction dbAction(CardAction a) => db.CardAction.values.byName(a.name);

CardContext domainContext(db.CardContext c) =>
    CardContext.values.byName(c.name);

CardAction domainAction(db.CardAction a) => CardAction.values.byName(a.name);

/// Riadky `card_event` ako vstup QuestEngine (cas lokalny).
List<CardActivity> cardActivities(Iterable<db.CardEventRow> rows) => [
  for (final r in rows)
    if (CardId.tryParse(r.cardId) case final id?)
      CardActivity(
        date: r.date,
        cardId: id,
        action: domainAction(r.action),
        context: domainContext(r.context),
        ts: r.ts.toLocal(),
      ),
];

/// Zapise udalost karty. `seen` je najviac raz za `(date, card_id,
/// context)`; vrati `false`, ked uz bola zapisana.
Future<bool> logCardEvent(
  db.UserDb userDb, {
  required LocalDate date,
  required CardId card,
  required CardAction action,
  required CardContext context,
  required DateTime now,
  int? pos,
  int? value,
  bool? correct,
}) => userDb.cardEventDao.log(
  date: date,
  card: card,
  context: dbContext(context),
  action: dbAction(action),
  ts: now.toUtc(),
  pos: pos,
  value: value,
  correct: correct,
);
