// Hodnoty ENUM stlpcov user.db (plan 5.2, docs/02 D1, D8, D12).
// `wire` je text v DB; nazov v Darte je lowerCamelCase.
import 'package:prosoche/data/db/converters.dart';

/// `card_event.context` (docs/02 D1).
enum CardContext implements WireEnum {
  feed,
  gate,
  reader,
  saved;

  @override
  String get wire => name;
}

/// `card_event.action` (docs/02 0.5, D1).
enum CardAction implements WireEnum {
  seen('seen'),
  answered('answered'),
  saved('saved'),
  unsaved('unsaved'),
  skipped('skipped'),
  shared('shared'),
  sourceOpened('source_opened'),
  reported('reported');

  CardAction(this.wire);

  @override
  final String wire;
}

/// `daily_set.phase` (docs/03 3.4).
enum DayPhase implements WireEnum {
  morning,
  day,
  evening,
  night;

  @override
  String get wire => name;
}

/// `quest_log.slot`.
enum QuestSlotKind implements WireEnum {
  read,
  learn,
  act;

  @override
  String get wire => name;
}

/// `quest_log.status`.
enum QuestStatus implements WireEnum {
  open,
  done,
  skipped;

  @override
  String get wire => name;
}

/// `day_log.status` (docs/02 D8, docs/03 6.5).
enum DayStatus implements WireEnum {
  done,
  grace,
  missed,
  excused;

  @override
  String get wire => name;
}

/// `gate_session.result` (docs/02 D12, docs/01 D5).
enum GateResult implements WireEnum {
  passed('passed'),
  emergency('emergency'),
  dismissed('dismissed'),
  error('error');

  GateResult(this.wire);

  @override
  final String wire;
}

/// `unlock_event.source` (docs/02 D12, bez `schedule`).
enum UnlockSource implements WireEnum {
  cards,
  emergency,
  error;

  @override
  String get wire => name;
}
