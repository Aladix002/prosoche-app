import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:meta/meta.dart';
import 'package:sakina/domain/common/local_date.dart';
import 'package:sakina/domain/prayer/calc_settings.dart';
import 'package:sakina/domain/prayer/prayer.dart';
import 'package:sakina/domain/settings/prayer_location.dart';
import 'package:timezone/timezone.dart' as tz;

/// Casy modlitieb jedneho dna v case polohy.
@immutable
final class PrayerDay {
  PrayerDay(this.date, Map<Prayer, tz.TZDateTime> times)
    : times = Map.unmodifiable(times);

  /// Den, ku ktoremu casy patria (isha po polnoci patri tomuto dnu,
  /// docs/02 E2).
  final LocalDate date;

  /// Cas kazdeho [Prayer] v casovej zone polohy, presnost na minutu.
  final Map<Prayer, tz.TZDateTime> times;

  tz.TZDateTime operator [](Prayer prayer) => times[prayer]!;

  @override
  String toString() {
    final parts = [for (final p in Prayer.values) '${p.name} ${_hm(this[p])}'];
    return 'PrayerDay($date, ${parts.join(', ')})';
  }

  static String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}

/// Jeden cas modlitby: ktora, ku ktoremu dnu patri a kedy je.
@immutable
final class PrayerMoment {
  const PrayerMoment(this.prayer, this.day, this.time);

  final Prayer prayer;
  final LocalDate day;
  final tz.TZDateTime time;

  @override
  bool operator ==(Object other) =>
      other is PrayerMoment &&
      other.prayer == prayer &&
      other.day == day &&
      other.time.isAtSameMomentAs(time);

  @override
  int get hashCode => Object.hash(prayer, day, time.millisecondsSinceEpoch);

  @override
  String toString() => 'PrayerMoment(${prayer.name}, $day, $time)';
}

/// Vypocet casov modlitieb pre polohu (obal nad adhan_dart, plan 8.1).
///
/// Poloha je uz zaokruhlena na 2 desatinne miesta ([PrayerLocation]).
/// Casy sa pocitaju ako okamihy v UTC a az potom sa prevedu do zony
/// polohy, takze zmena letneho casu ziadnu modlitbu neposunie o hodinu.
final class PrayerSchedule {
  PrayerSchedule({
    required this.lat,
    required this.lng,
    required this.zone,
    required this.settings,
  }) : _coordinates = adhan.Coordinates(lat, lng),
       _params = settings.toAdhan();

  /// Rozvrh pre ulozenu polohu. Databaza zon (`timezone`) musi byt
  /// inicializovana, inak hodi `tz.LocationNotFoundException`.
  factory PrayerSchedule.forLocation(
    PrayerLocation location,
    CalcSettings settings,
  ) => PrayerSchedule(
    lat: location.lat,
    lng: location.lng,
    zone: tz.getLocation(location.tz),
    settings: settings,
  );

  final double lat;
  final double lng;
  final tz.Location zone;
  final CalcSettings settings;

  final adhan.Coordinates _coordinates;
  final adhan.CalculationParameters _params;

  /// Casy pre kalendarny den [date] v zone polohy.
  ///
  /// Isha nikdy nie je neskor ako fajr nasledujuceho dna. Pri pravidle
  /// `middle_of_night` pocita adhan_dart oba casy z inej noci, takze isha
  /// mohla vyjst o minutu po zajtrajsom fajr (Oslo, Reykjavik v juni).
  PrayerDay day(LocalDate date) {
    final times = _adhan(date);
    final nextFajr = _adhan(date.addDays(1)).fajr;
    return PrayerDay(date, {
      for (final p in Prayer.values)
        p: tz.TZDateTime.from(
          p == Prayer.isha && times.isha.isAfter(nextFajr)
              ? nextFajr
              : times.timeForPrayer(p.adhanPrayer),
          zone,
        ),
    });
  }

  adhan.PrayerTimes _adhan(LocalDate date) => adhan.PrayerTimes(
    date: DateTime.utc(date.year, date.month, date.day),
    coordinates: _coordinates,
    calculationParameters: _params,
  );

  /// [count] dni od [from] (pre planovanie notifikacii, P-02).
  List<PrayerDay> days(LocalDate from, int count) => [
    for (var i = 0; i < count; i++) day(from.addDays(i)),
  ];

  /// Posledny cas, ktory uz nastal v okamihu [now] (vratane [Prayer.sunrise]).
  ///
  /// Pred fajr je aktualna isha predchadzajuceho dna, aj ked je po polnoci
  /// (docs/02 E2).
  PrayerMoment current(DateTime now) =>
      _around(now).lastWhere((m) => !m.time.isAfter(now));

  /// Najblizsi cas po okamihu [now].
  PrayerMoment next(DateTime now) =>
      _around(now).firstWhere((m) => m.time.isAfter(now));

  /// Casy predosleho, aktualneho a nasledujuceho dna v poradi. Pri rovnakom
  /// case ide skor starsi den (isha pred zajtrajsim fajr).
  List<PrayerMoment> _around(DateTime now) {
    final today = LocalDate.fromDateTime(tz.TZDateTime.from(now, zone));
    return [
      for (final d in [today.addDays(-1), today, today.addDays(1)])
        for (final MapEntry(:key, :value) in day(d).times.entries)
          PrayerMoment(key, d, value),
    ]..sort((a, b) {
      final byTime = a.time.compareTo(b.time);
      if (byTime != 0) return byTime;
      final byDay = a.day.compareTo(b.day);
      return byDay != 0 ? byDay : a.prayer.index - b.prayer.index;
    });
  }
}
