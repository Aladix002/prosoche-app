import 'package:meta/meta.dart';
import 'package:prosoche/domain/common/local_date.dart';
import 'package:prosoche/domain/notifications/planned_notification.dart';
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
  const NotificationPlanInput({
    required this.now,
    required this.deviceZone,
    this.morningEnabled = true,
    this.morningTime = TimeOfDayHm.morningDefault,
    this.cardMinutes = 10,
  });

  /// Aktualny okamih (z `Clock`).
  final DateTime now;

  /// Casova zona zariadenia.
  final tz.Location deviceZone;

  final bool morningEnabled;
  final TimeOfDayHm morningTime;

  /// Odhad minut pre text rannej notifikacie.
  final int cardMinutes;
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
}

/// Planovanie notifikacii na [days] dni dopredu (TECHNICKY_PLAN 8.2).
///
/// Cista funkcia: rovnaky vstup = rovnaky plan s rovnakymi ID, takze
/// opakovane preplanovanie nic nezmeni (idempotencia). Rozpocet [maxPending]
/// (64, limit iOS) plati aj na Androide (docs/02 D17): 10 rannych a vyzva
/// na otvorenie appky v poslednom dni okna.
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
      if (input.morningEnabled)
        for (var i = 0; i < days; i++)
          if (_morning(input, deviceToday.addDays(i)) case final m
              when inWindow(m.at))
            m,
    ]..sort(_byTime);

    final budget = openAppReminder ? maxPending - 1 : maxPending;
    final kept = items.length > budget ? items.sublist(0, budget) : items;
    final dropped = items.length - kept.length;

    if (openAppReminder && kept.isNotEmpty) {
      final lastDay = _dateIn(kept.last.at, input.deviceZone);
      final at = input.morningTime.on(lastDay, input.deviceZone);
      if (inWindow(at)) {
        // Vyzva nahradza rannu notifikaciu posledneho dna.
        kept
          ..removeWhere(
            (n) => n.kind == NotificationKind.morning && n.day == lastDay,
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

  PlannedNotification _morning(NotificationPlanInput input, LocalDate day) =>
      PlannedNotification(
        kind: NotificationKind.morning,
        day: day,
        at: input.morningTime.on(day, input.deviceZone),
        cardMinutes: input.cardMinutes,
      );

  static int _byTime(PlannedNotification a, PlannedNotification b) {
    final t = a.at.compareTo(b.at);
    return t != 0 ? t : a.id - b.id;
  }

  static LocalDate _dateIn(DateTime instant, tz.Location zone) =>
      LocalDate.fromDateTime(tz.TZDateTime.from(instant, zone));

  static tz.TZDateTime _midnight(LocalDate day, tz.Location zone) =>
      tz.TZDateTime(zone, day.year, day.month, day.day);
}
