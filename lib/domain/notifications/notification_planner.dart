import 'package:meta/meta.dart';
import 'package:sakina/domain/common/local_date.dart';
import 'package:sakina/domain/notifications/planned_notification.dart';
import 'package:sakina/domain/prayer/prayer.dart';
import 'package:sakina/domain/prayer/prayer_schedule.dart';
import 'package:timezone/timezone.dart' as tz;

/// Cas dna `HH:mm` (kluc `notif.morning.time`, docs/02 0.7).
@immutable
final class TimeOfDayHm {
  const TimeOfDayHm(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24, 'hour'),
      assert(minute >= 0 && minute < 60, 'minute');

  /// Z textu `HH:mm`; pri neplatnom texte hodi [FormatException].
  factory TimeOfDayHm.parse(String text) {
    final m = _hm.firstMatch(text);
    if (m == null) throw FormatException('Invalid HH:mm', text);
    return TimeOfDayHm(int.parse(m[1]!), int.parse(m[2]!));
  }

  static final _hm = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

  /// Predvolba rannej notifikacie (ROZHODNUTIE, docs/02 0.7).
  static const morningDefault = TimeOfDayHm(7, 30);

  final int hour;
  final int minute;

  /// Okamih v dni [day] v zone [zone]. Cas v medzere pri prechode na letny
  /// cas posunie `timezone` dopredu (napr. 02:30 -> 03:30).
  tz.TZDateTime on(LocalDate day, tz.Location zone) =>
      tz.TZDateTime(zone, day.year, day.month, day.day, hour, minute);

  @override
  bool operator ==(Object other) =>
      other is TimeOfDayHm && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// Vstup planovania. Vsetko, co planner potrebuje, je tu; ziadne I/O.
@immutable
final class NotificationPlanInput {
  NotificationPlanInput({
    required this.now,
    required this.deviceZone,
    this.schedule,
    Set<Prayer> enabledPrayers = const {...Prayer.salah},
    this.prayersPaused = false,
    Set<LocalDate> excusedDays = const {},
    this.morningEnabled = true,
    this.morningTime = TimeOfDayHm.morningDefault,
    this.cardMinutes = 10,
    Map<LocalDate, String> eventNames = const {},
    Set<LocalDate> fastingDays = const {},
    this.suhurLeadMinutes = 45,
  }) : enabledPrayers = Set.unmodifiable(enabledPrayers),
       excusedDays = Set.unmodifiable(excusedDays),
       eventNames = Map.unmodifiable(eventNames),
       fastingDays = Set.unmodifiable(fastingDays);

  /// Aktualny okamih (z `Clock`).
  final DateTime now;

  /// Casova zona zariadenia (ranna notifikacia ide podla nej).
  final tz.Location deviceZone;

  /// Casy modlitieb pre ulozenu polohu; null = bez polohy, ziadne modlitby.
  final PrayerSchedule? schedule;

  /// Modlitby so zapnutou notifikaciou (`notif.prayer.{p}`).
  final Set<Prayer> enabledPrayers;

  /// Zmena casovej zony caka na potvrdenie polohy (docs/01 5.6): modlitby
  /// sa neplanuju, ranna ostava.
  final bool prayersPaused;

  /// Ospravedlnene dni: modlitby sa potichu vynechaju (plan 8.2, 03 6.5).
  final Set<LocalDate> excusedDays;

  final bool morningEnabled;
  final TimeOfDayHm morningTime;

  /// Odhad minut pre text rannej notifikacie.
  final int cardMinutes;

  /// Nazov eventu pre den (ranna notifikacia `notif_morning_event`).
  final Map<LocalDate, String> eventNames;

  /// Dni postu v Ramadane (F-08, `ramadanFastingDays`): maghrib ide ako
  /// [NotificationKind.iftar] a ranna notifikacia ako
  /// [NotificationKind.suhur] (fajr - [suhurLeadMinutes]), docs/04 1.10.
  /// Pocet notifikacii za den sa nemeni.
  final Set<LocalDate> fastingDays;

  /// Suhur pripomienka [suhurLeadMinutes] minut pred fajr.
  final int suhurLeadMinutes;
}

/// Vysledok planovania, zoradeny podla casu.
@immutable
final class NotificationPlan {
  NotificationPlan(List<PlannedNotification> items, {this.dropped = 0})
    : items = List.unmodifiable(items);

  final List<PlannedNotification> items;

  /// Kolko notifikacii sa neveslo do rozpoctu.
  final int dropped;

  int get length => items.length;

  Iterable<PlannedNotification> get prayers =>
      items.where((n) => n.kind.isPrayer);
}

/// Planovanie notifikacii na [days] dni dopredu (TECHNICKY_PLAN 8.2).
///
/// Cista funkcia: rovnaky vstup = rovnaky plan s rovnakymi ID, takze
/// opakovane preplanovanie nic nezmeni (idempotencia). Rozpocet [maxPending]
/// (64, limit iOS) plati aj na Androide (docs/02 D17): 5 modlitieb x 10 dni
/// + 10 rannych + 1 vyzva na otvorenie appky.
final class NotificationPlanner {
  const NotificationPlanner({
    this.days = 10,
    this.maxPending = 64,
    this.openAppReminder = true,
  }) : assert(days > 0, 'days'),
       assert(maxPending > 1, 'maxPending');

  final int days;
  final int maxPending;

  /// Posledna notifikacia okna vyzve na otvorenie appky (plan 17.8).
  final bool openAppReminder;

  NotificationPlan plan(NotificationPlanInput input) {
    final now = input.now;
    final deviceToday = _dateIn(now, input.deviceZone);
    final horizonEnd = _midnight(deviceToday.addDays(days), input.deviceZone);

    bool inWindow(DateTime at) => at.isAfter(now) && at.isBefore(horizonEnd);

    final items = <PlannedNotification>[
      ..._prayers(input, inWindow),
      if (input.morningEnabled)
        for (var i = 0; i < days; i++)
          if (_morning(input, deviceToday.addDays(i)) case final m
              when inWindow(m.at))
            m,
    ]..sort(_byTime);

    final budget = openAppReminder ? maxPending - 1 : maxPending;
    final kept = items.length > budget ? items.sublist(0, budget) : items;
    final dropped = items.length - kept.length;

    if (openAppReminder && kept.any((n) => n.kind.isPrayer)) {
      final lastDay = _dateIn(kept.last.at, input.deviceZone);
      final at = input.morningTime.on(lastDay, input.deviceZone);
      if (inWindow(at)) {
        // Vyzva nahradza rannu notifikaciu posledneho dna.
        kept
          ..removeWhere(
            (n) =>
                (n.kind == NotificationKind.morning ||
                    n.kind == NotificationKind.morningEvent ||
                    n.kind == NotificationKind.suhur) &&
                n.day == lastDay,
          )
          ..add(
            PlannedNotification(
              kind: NotificationKind.openApp,
              day: lastDay,
              at: at,
            ),
          )
          ..sort(_byTime);
      }
    }
    return NotificationPlan(kept, dropped: dropped);
  }

  Iterable<PlannedNotification> _prayers(
    NotificationPlanInput input,
    bool Function(DateTime) inWindow,
  ) sync* {
    final schedule = input.schedule;
    if (schedule == null || input.prayersPaused) return;
    if (input.enabledPrayers.isEmpty) return;
    // Od vcera: isha po polnoci patri predoslemu dnu (docs/02 E2).
    final from = _dateIn(input.now, schedule.zone).addDays(-1);
    for (final day in schedule.days(from, days + 2)) {
      if (input.excusedDays.contains(day.date)) continue;
      for (final p in Prayer.salah) {
        if (!input.enabledPrayers.contains(p)) continue;
        final at = day[p];
        if (!inWindow(at)) continue;
        final friday = day.date.weekday == DateTime.friday;
        final fasting = input.fastingDays.contains(day.date);
        yield PlannedNotification(
          kind: p == Prayer.dhuhr && friday
              ? NotificationKind.jumuah
              : p == Prayer.maghrib && fasting
              ? NotificationKind.iftar
              : NotificationKind.prayer,
          day: day.date,
          at: at,
          prayer: p,
        );
      }
    }
  }

  PlannedNotification _morning(NotificationPlanInput input, LocalDate day) {
    final schedule = input.schedule;
    if (schedule != null &&
        !input.prayersPaused &&
        input.fastingDays.contains(day)) {
      // Suhur nahradza rannu notifikaciu (docs/04 1.10).
      final fajr = schedule.day(day)[Prayer.fajr];
      return PlannedNotification(
        kind: NotificationKind.suhur,
        day: day,
        at: fajr.subtract(Duration(minutes: input.suhurLeadMinutes)),
        prayer: Prayer.fajr,
        cardMinutes: input.suhurLeadMinutes,
      );
    }
    final event = input.eventNames[day];
    return PlannedNotification(
      kind: event == null
          ? NotificationKind.morning
          : NotificationKind.morningEvent,
      day: day,
      at: input.morningTime.on(day, input.deviceZone),
      eventName: event,
      cardMinutes: input.cardMinutes,
    );
  }

  static int _byTime(PlannedNotification a, PlannedNotification b) {
    final t = a.at.compareTo(b.at);
    return t != 0 ? t : a.id - b.id;
  }

  static LocalDate _dateIn(DateTime instant, tz.Location zone) =>
      LocalDate.fromDateTime(tz.TZDateTime.from(instant, zone));

  static tz.TZDateTime _midnight(LocalDate day, tz.Location zone) =>
      tz.TZDateTime(zone, day.year, day.month, day.day);
}
