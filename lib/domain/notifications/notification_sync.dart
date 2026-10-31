import 'package:meta/meta.dart';
import 'package:prosoche/domain/notifications/planned_notification.dart';

/// Cakajuca notifikacia v systeme (ID a ulozeny payload).
@immutable
final class PendingNotification {
  const PendingNotification(this.id, this.payload);

  final int id;
  final String? payload;

  @override
  bool operator ==(Object other) =>
      other is PendingNotification &&
      other.id == id &&
      other.payload == payload;

  @override
  int get hashCode => Object.hash(id, payload);

  @override
  String toString() => 'PendingNotification($id)';
}

/// Co treba zrusit a co naplanovat, aby system zodpovedal planu.
@immutable
final class NotificationSyncPlan {
  NotificationSyncPlan({
    required List<int> cancel,
    required List<PlannedNotification> schedule,
    required this.unchanged,
  }) : cancel = List.unmodifiable(cancel),
       schedule = List.unmodifiable(schedule);

  /// ID planovanych notifikacii, ktore v plane nie su alebo sa zmenili.
  final List<int> cancel;

  /// Nove alebo zmenene notifikacie.
  final List<PlannedNotification> schedule;

  /// Pocet notifikacii, ktore uz su naplanovane presne podla planu.
  final int unchanged;

  bool get isEmpty => cancel.isEmpty && schedule.isEmpty;
}

/// Rozdiel medzi cakajucimi notifikaciami a planom.
///
/// Notifikacia je rovnaka, ked ma rovnake ID aj [payloadOf] (payload nesie
/// odtlacok obsahu, jazyk a rezim alarmu). ID mimo
/// [NotificationIds.isPlanned] sa ignoruju (okamzite notifikacie, brana).
/// Druhe volanie po aplikovani rozdielu vrati prazdny plan (idempotencia).
NotificationSyncPlan diffNotifications({
  required Iterable<PendingNotification> pending,
  required List<PlannedNotification> planned,
  required String Function(PlannedNotification) payloadOf,
}) {
  final wanted = {for (final n in planned) n.id: payloadOf(n)};
  final current = <int, String?>{
    for (final p in pending)
      if (NotificationIds.isPlanned(p.id)) p.id: p.payload,
  };
  final cancel = [
    for (final MapEntry(key: id, value: payload) in current.entries)
      if (wanted[id] != payload) id,
  ]..sort();
  final schedule = [
    for (final n in planned)
      if (current[n.id] != wanted[n.id] || !current.containsKey(n.id)) n,
  ];
  return NotificationSyncPlan(
    cancel: cancel,
    schedule: schedule,
    unchanged: planned.length - schedule.length,
  );
}
