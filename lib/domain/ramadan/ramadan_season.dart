import 'package:meta/meta.dart';
import 'package:prosoche/domain/calendar/hijri_date.dart';
import 'package:prosoche/domain/calendar/islamic_calendar.dart';
import 'package:prosoche/domain/common/local_date.dart';
import 'package:prosoche/domain/settings/setting_key.dart';

/// Odkial je zaciatok sezony (docs/04 1.2).
enum SeasonSource {
  /// Vypocet: Umm al-Qura + globalny `hijri.offset`.
  calc,

  /// Pouzivatel potvrdil podla lokalnej komunity.
  userConfirmed,
}

/// Ramadan jedneho hijri roka v gregorianskych dnoch (docs/04 1.2).
///
/// [startDate] je gregoriansky den 1. postu. Islamsky den zacina
/// maghribom, takze noc N zacina vecer dna N-1 ([nightOfDate]).
@immutable
final class RamadanSeason {
  RamadanSeason({
    required this.hijriYear,
    required this.startDate,
    required this.lengthDays,
    required this.source,
    this.lengthConfirmed = false,
  }) {
    RangeError.checkValueInInterval(lengthDays, 29, 30, 'lengthDays');
  }

  final int hijriYear;

  /// Gregoriansky den 1. postu.
  final LocalDate startDate;

  /// 29 alebo 30. Kym koniec nie je potvrdeny, podla Umm al-Qura.
  final int lengthDays;

  final SeasonSource source;

  /// Pouzivatel odpovedal na otazku "Je zajtra Eid?".
  final bool lengthConfirmed;

  /// Posledny den postu.
  LocalDate get lastDay => startDate.addDays(lengthDays - 1);

  /// Den Eid al-Fitr.
  LocalDate get eidDate => startDate.addDays(lengthDays);

  /// Den Ramadanu (1..[lengthDays]) gregorianskeho dna [date], inak null.
  int? dayOf(LocalDate date) {
    final diff = date.daysSince(startDate);
    return diff >= 0 && diff < lengthDays ? diff + 1 : null;
  }

  /// Je [date] den postu.
  bool isFastingDay(LocalDate date) => dayOf(date) != null;

  /// Noc Ramadanu (1..[lengthDays]) pre den [date]: pred maghribom noc
  /// rovnakeho cisla ako den, po maghribe ([afterMaghrib]) nasledujuca.
  /// Noc 27 je teda vecer 26. dna (docs/04 1.1).
  int? nightOfDate(LocalDate date, {required bool afterMaghrib}) =>
      dayOf(afterMaghrib ? date.addDays(1) : date);

  @override
  bool operator ==(Object other) =>
      other is RamadanSeason &&
      other.hijriYear == hijriYear &&
      other.startDate == startDate &&
      other.lengthDays == lengthDays &&
      other.source == source &&
      other.lengthConfirmed == lengthConfirmed;

  @override
  int get hashCode =>
      Object.hash(hijriYear, startDate, lengthDays, source, lengthConfirmed);

  @override
  String toString() =>
      'RamadanSeason($hijriYear, $startDate, $lengthDays d, ${source.name})';
}

/// Ulozene potvrdenie sezony (kluc [settingKey] v `settings`).
///
/// Uklada sa absolutny [startDate], nie posun: zmena globalneho
/// `hijri.offset` potvrdenu sezonu nezmeni a potvrdenie nemeni globalny
/// offset (docs/04 1.2 "sezonny offset").
@immutable
final class RamadanConfirmation {
  const RamadanConfirmation({
    required this.hijriYear,
    required this.startDate,
    required this.source,
    this.lengthDays,
  });

  factory RamadanConfirmation.fromJson(Object json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('ramadan.season: expected object');
    }
    final year = json['year'];
    final start = json['start'];
    final source = json['source'];
    final length = json['length'];
    if (year is! int || start is! String || source is! String) {
      throw const FormatException('ramadan.season: missing fields');
    }
    final date = LocalDate.tryParse(start);
    final src = SeasonSource.values.where((s) => s.name == source);
    if (date == null || src.isEmpty) {
      throw const FormatException('ramadan.season: invalid value');
    }
    if (length != null && length != 29 && length != 30) {
      throw const FormatException('ramadan.season: invalid length');
    }
    return RamadanConfirmation(
      hijriYear: year,
      startDate: date,
      source: src.single,
      lengthDays: length as int?,
    );
  }

  /// `ramadan.season` (F-08), v kontrakte ako `SettingsKeys.ramadanSeason`.
  static final SettingKey<RamadanConfirmation?> settingKey =
      SettingKey.json<RamadanConfirmation?>(
        'ramadan.season',
        defaultValue: null,
        fromJson: RamadanConfirmation.fromJson,
        toJson: (v) => v?.toJson(),
      );

  final int hijriYear;
  final LocalDate startDate;
  final SeasonSource source;

  /// Odpoved na "Je zajtra Eid?" (29 = ano, 30 = nie), null = bez odpovede.
  final int? lengthDays;

  RamadanConfirmation withLength(int lengthDays) => RamadanConfirmation(
    hijriYear: hijriYear,
    startDate: startDate,
    source: source,
    lengthDays: lengthDays,
  );

  Map<String, Object?> toJson() => {
    'year': hijriYear,
    'start': startDate.toString(),
    'source': source.name,
    if (lengthDays != null) 'length': lengthDays,
  };

  @override
  bool operator ==(Object other) =>
      other is RamadanConfirmation &&
      other.hijriYear == hijriYear &&
      other.startDate == startDate &&
      other.source == source &&
      other.lengthDays == lengthDays;

  @override
  int get hashCode => Object.hash(hijriYear, startDate, source, lengthDays);

  @override
  String toString() =>
      'RamadanConfirmation($hijriYear, $startDate, ${source.name}, '
      '$lengthDays)';
}

/// Hijri rok sezony, ku ktorej [date] moze patrit (Shaban az Shawwal),
/// inak null. Mimo bezpecneho rozsahu tabulky Umm al-Qura tiez null.
int? ramadanSeasonYearOf(IslamicCalendar calendar, LocalDate date) {
  if (date.isBefore(_tableFrom) || date.isAfter(_tableTo)) return null;
  final h = calendar.hijriOf(date);
  return h.month >= 8 && h.month <= 10 ? h.year : null;
}

// 1356 AH zacina 14. 3. 1937 a 1500 AH konci 16. 11. 2077; rezerva na
// posun -2..+2 a dni sezony.
final _tableFrom = LocalDate(1938, 1, 1);
final _tableTo = LocalDate(2076, 12, 31);

/// Sezona z kalendara a ulozeneho potvrdenia (docs/04 1.2 Resolver).
final class RamadanSeasonResolver {
  const RamadanSeasonResolver(this.calendar);

  /// Umm al-Qura s globalnym `hijri.offset`.
  final IslamicCalendar calendar;

  /// Vypocitany zaciatok (1. Ramadan podla [calendar]).
  LocalDate calcStart(int hijriYear) =>
      calendar.gregorianOf(HijriDate(hijriYear, 9, 1));

  /// Den otazky na zaciatok: 29. Shaban.
  LocalDate questionDay(int hijriYear) =>
      calendar.gregorianOf(HijriDate(hijriYear, 8, 29));

  /// Od tohto dna je sezona `upcoming`: 25. Shaban.
  LocalDate upcomingFrom(int hijriYear) =>
      calendar.gregorianOf(HijriDate(hijriYear, 8, 25));

  RamadanSeason resolve(int hijriYear, {RamadanConfirmation? stored}) {
    final own = stored != null && stored.hijriYear == hijriYear;
    final length = own ? stored.lengthDays : null;
    return RamadanSeason(
      hijriYear: hijriYear,
      startDate: own ? stored.startDate : calcStart(hijriYear),
      lengthDays: length ?? calendar.monthLength(hijriYear, 9),
      source: own ? stored.source : SeasonSource.calc,
      lengthConfirmed: length != null,
    );
  }
}
