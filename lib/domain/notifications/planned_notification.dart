import 'package:meta/meta.dart';
import 'package:prosoche/domain/common/local_date.dart';
import 'package:timezone/timezone.dart' as tz;

/// Kanal notifikacie (docs/01 7.5). `gate_service` patri B-01.
enum NotificationChannel { daily, system }

/// Druh planovanej notifikacie. Text sa vybera az v data vrstve z ARB,
/// domena nesie len druh a parametre (TECHNICKY_PLAN 8.2).
enum NotificationKind {
  /// `notif_morning`.
  morning(NotificationChannel.daily, 5),

  /// `notif_evening`: vecerna reflexia (F-01), otvori Practice.
  evening(NotificationChannel.daily, 4),

  /// `notif_open_app_ios`: posledna notifikacia okna vyzve na otvorenie.
  openApp(NotificationChannel.system, 6);

  NotificationKind(this.channel, this._slot);

  final NotificationChannel channel;
  final int _slot;
}

/// Deterministicke ID planovanych notifikacii.
///
/// `den * 10 + slot`, kde den je pocet dni od 2020-01-01 a slot je 4
/// vecerna reflexia, 5 ranna a 6 vyzva na otvorenie (0-3 su volne).
/// Rovnaky den
/// a druh ma vzdy rovnake ID, takze preplanovanie je idempotentne. ID mimo
/// [isPlanned] (okamzite notifikacie, brana) planner nikdy nezrusi.
abstract final class NotificationIds {
  static final LocalDate _epoch = LocalDate(2020, 1, 1);

  /// Horna hranica (vylucne) rozsahu planovanych ID.
  static const int plannedLimit = 1000000;

  static int of(NotificationKind kind, LocalDate day) {
    final dayIndex = day.daysSince(_epoch);
    if (dayIndex < 0) throw ArgumentError.value(day, 'day', 'before 2020');
    return dayIndex * 10 + kind._slot + 1;
  }

  /// Patri ID do rozsahu planovanych notifikacii.
  static bool isPlanned(int id) => id > 0 && id < plannedLimit;
}

/// Jedna notifikacia v plane. [at] je okamih v zone zariadenia.
@immutable
final class PlannedNotification {
  PlannedNotification({
    required this.kind,
    required this.day,
    required this.at,
    this.cardMinutes,
  }) : id = NotificationIds.of(kind, day);

  final int id;
  final NotificationKind kind;

  /// Den, ku ktoremu notifikacia patri.
  final LocalDate day;
  final tz.TZDateTime at;

  /// Odhad minut pre rannu notifikaciu.
  final int? cardMinutes;

  NotificationChannel get channel => kind.channel;

  /// Ciel po kliknuti (docs/01 4.3, schema `prosoche`).
  String get deepLink => switch (kind) {
    NotificationKind.morning || NotificationKind.openApp => 'prosoche://today',
    NotificationKind.evening => 'prosoche://practice',
  };

  /// Odtlacok obsahu. Zmena casu alebo parametrov = ina notifikacia.
  String get fingerprint =>
      [kind.name, at.millisecondsSinceEpoch, cardMinutes ?? ''].join('|');

  @override
  bool operator ==(Object other) =>
      other is PlannedNotification &&
      other.id == id &&
      other.fingerprint == fingerprint;

  @override
  int get hashCode => Object.hash(id, fingerprint);

  @override
  String toString() => 'PlannedNotification($id, ${kind.name}, $day, $at)';
}
