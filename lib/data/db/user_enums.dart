// Hodnoty ENUM stlpcov user.db (plan 5.2, docs/02 D1, D8, D10, D12).
// `wire` je text v DB; nazov v Darte je lowerCamelCase.
import 'package:prosoche/data/db/converters.dart';

/// `card_event.context` (docs/02 D1).
enum CardContext implements WireEnum {
  feed,
  gate,
  reader,
  quiz,
  saved,
  review;

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
  audioPlayed('audio_played'),
  sourceOpened('source_opened'),
  tafsirOpened('tafsir_opened'),
  wordOpened('word_opened'),
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

/// `srs_item.state` (docs/02 D10).
enum SrsState implements WireEnum {
  fresh('new'),
  learning('learning'),
  review('review'),
  relearning('relearning');

  SrsState(this.wire);

  @override
  final String wire;
}

/// `srs_item.source` (docs/02 D10).
enum SrsSource implements WireEnum {
  wordCard('word_card'),
  manual('manual');

  SrsSource(this.wire);

  @override
  final String wire;
}

/// `prayer_log.prayer`.
enum PrayerKind implements WireEnum {
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha;

  @override
  String get wire => name;
}

/// `prayer_log.status` (excused: docs/03 6.5).
enum PrayerStatus implements WireEnum {
  onTime('on_time'),
  late('late'),
  missed('missed'),
  qada('qada'),
  excused('excused');

  PrayerStatus(this.wire);

  @override
  final String wire;
}

/// `fast_log.type`.
enum FastType implements WireEnum {
  ramadan,
  sunnah,
  qada,
  nafl;

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
  prayerLocked('prayer_locked'),
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
