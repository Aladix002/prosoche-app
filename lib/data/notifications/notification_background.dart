import 'package:sakina/core/logging/app_logger.dart';
import 'package:sakina/data/notifications/notification_service.dart';
import 'package:workmanager/workmanager.dart';

/// Periodicke preplanovanie cez workmanager (TECHNICKY_PLAN 8.2).
///
/// Android: periodicky job kazdych 12 h. Beh nie je garantovany (Doze,
/// standby bucket, Android 16 kvoty aj pri FGS, docs/08 B), preto sa
/// preplanuje aj pri kazdom otvoreni appky. Po restarte obnovi notifikacie
/// receiver pluginu (BOOT_COMPLETED) a workmanager si job pamata sam.
///
/// Callback dispatcher je jeden pre celu appku (aj D-03 pouziva
/// workmanager), preto ho pise integracia a ulohu len posunie sem:
///
/// ```dart
/// @pragma('vm:entry-point')
/// void backgroundDispatcher() {
///   Workmanager().executeTask((task, input) async {
///     if (NotificationBackground.handles(task)) {
///       return NotificationBackground.run(
///         () async => NotificationService(...),
///       );
///     }
///     return true;
///   });
/// }
/// ```
abstract final class NotificationBackground {
  /// Unikatny nazov periodickej prace.
  static const uniqueName = 'app.mursa.notifications.reschedule';

  /// Nazov ulohy, ktory dostane dispatcher.
  static const taskName = 'notificationsReschedule';

  static const frequency = Duration(hours: 12);

  /// Zaregistruje periodicku pracu. `update` zachova beziaci plan a len
  /// zmeni parametre (opakovane volanie pri kazdom starte nevadi).
  static Future<void> register(Workmanager workmanager) =>
      workmanager.registerPeriodicTask(
        uniqueName,
        taskName,
        frequency: frequency,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );

  static Future<void> cancel(Workmanager workmanager) =>
      workmanager.cancelByUniqueName(uniqueName);

  /// Patri uloha [task] notifikaciam (Android `taskName`, iOS `uniqueName`).
  static bool handles(String task) => task == taskName || task == uniqueName;

  /// Spusti preplanovanie v background isolate. Vrati false pri chybe,
  /// workmanager potom pouzije backoff.
  static Future<bool> run(
    Future<NotificationService> Function() create, {
    AppLogger? logger,
  }) async {
    try {
      final service = await create();
      await service.reschedule();
      return true;
    } on Object catch (e, st) {
      logger?.error(
        'notif',
        'background reschedule failed',
        error: e,
        stack: st,
      );
      return false;
    }
  }
}
