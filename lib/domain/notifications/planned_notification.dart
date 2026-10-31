import 'package:meta/meta.dart';
import 'package:prosoche/domain/common/local_date.dart';
import 'package:prosoche/domain/prayer/prayer.dart';
import 'package:timezone/timezone.dart' as tz;

/// Kanal notifikacie (docs/01 7.5). `gate_service` patri B-01.
enum NotificationChannel { prayer, daily, system }

/// Druh planovanej notifikacie. Text sa vybera az v data vrstve z ARB,
/// domena nesie len druh a parametre (TECHNICKY_PLAN 8.2).
enum NotificationKind {
  /// `notif_prayer_{fajr..isha}`.
  prayer(NotificationChannel.prayer, 0),

  /// `notif_prayer_jumuah` (dhuhr v piatok).
  jumuah(NotificationChannel.prayer, 0),

  /// `notif_morning`.
  morning(NotificationChannel.daily, 5),

  /// `notif_morning_event`.
  morningEvent(NotificationChannel.daily, 5),

  /// `notif_open_app_ios`: posledna notifikacia okna vyzve na otvorenie.
  openApp(NotificationChannel.system, 6),

  /// Ramadan (F-08): suhur pripomienka nahradza rannu notifikaciu dna
  /// postu (rovnaky slot a ID), docs/04 1.10.
  suhur(NotificationChannel.daily, 5),

  /// Ramadan (F-08): maghrib zluceny s iftarom v den postu (rovnake ID
  /// ako maghrib), docs/04 1.10.
  iftar(NotificationChannel.prayer, 0);

  NotificationKind(this.channel, this._slot);

  final NotificationChannel channel;
  final int _slot;

  bool get isPrayer => channel == NotificationChannel.prayer;
}

/// Deterministicke ID planovanych notifikacii.
///
/// `den * 10 + slot`, kde den je pocet dni od 2020-01-01 a slot je 0-4
/// pre modlitby (fajr..isha), 5 ranna a 6 vyzva na otvorenie. Rovnaky den
/// a druh ma vzdy rovnake ID, takze preplanovanie je idempotentne. ID mimo
/// [isPlanned] (okamzite notifikacie, brana) planner nikdy nezrusi.
abstract final class NotificationIds {
  static final LocalDate _epoch = LocalDate(2020, 1, 1);

  /// Horna hranica (vylucne) rozsahu planovanych ID.
  static const int plannedLimit = 1000000;

  static int of(NotificationKind kind, LocalDate day, [Prayer? prayer]) {
    final dayIndex = day.daysSince(_epoch);
    if (dayIndex < 0) throw ArgumentError.value(day, 'day', 'before 2020');
    final slot = !kind.isPrayer
        ? kind._slot
        : prayer == null
        ? -1
        : Prayer.salah.indexOf(prayer);
    if (slot < 0) throw ArgumentError.value(prayer, 'prayer', 'salah needed');
    return dayIndex * 10 + slot + 1;
  }

  /// Patri ID do rozsahu planovanych notifikacii.
  static bool isPlanned(int id) => id > 0 && id < plannedLimit;
}

/// Jedna notifikacia v plane. [at] je okamih (v zone polohy pre modlitby,
/// v zone zariadenia pre rannu).
@immutable
final class PlannedNotification {
  PlannedNotification({
    required this.kind,
    required this.day,
    required this.at,
    this.prayer,
    this.eventName,
    this.cardMinutes,
  }) : id = NotificationIds.of(kind, day, prayer);

  final int id;
  final NotificationKind kind;

  /// Den, ku ktoremu notifikacia patri (isha po polnoci = predosly den).
  final LocalDate day;
  final tz.TZDateTime at;
  final Prayer? prayer;

  /// Nazov eventu pre [NotificationKind.morningEvent].
  final String? eventName;

  /// Odhad minut pre rannu notifikaciu; pri [NotificationKind.suhur]
  /// minuty do konca suhuru (fajr).
  final int? cardMinutes;

  NotificationChannel get channel => kind.channel;

  /// Ciel po kliknuti (docs/01 4.3, schema `prosoche`).
  String get deepLink => switch (kind) {
    NotificationKind.prayer ||
    NotificationKind.jumuah ||
    NotificationKind.iftar => 'prosoche://prayer?p=${prayer!.name}',
    NotificationKind.morning ||
    NotificationKind.morningEvent ||
    NotificationKind.openApp ||
    NotificationKind.suhur => 'prosoche://today',
  };

  /// Odtlacok obsahu. Zmena casu alebo parametrov = ina notifikacia.
  String get fingerprint => [
    kind.name,
    at.millisecondsSinceEpoch,
    prayer?.name ?? '',
    eventName ?? '',
    cardMinutes ?? '',
  ].join('|');

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
