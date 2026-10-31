import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:prosoche/app/notification_wiring.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/core/logging/logger_provider.dart';
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/blocker/blocker_gateway_provider.dart';
import 'package:prosoche/data/observability/observability_providers.dart';
import 'package:prosoche/features/settings/settings_providers.dart';

/// "Delete all my data" (docs/02 A10.9, F-07): co appka urobi po zmazani
/// user.db.
List<Override> dataDeletionOverrides() => [
  afterDataDeletedProvider.overrideWith(
    (ref) =>
        () => afterDataDeleted(ref),
  ),
];

/// Po zmazani user.db:
/// - zrusi vsetky naplanovane notifikacie; dalsie preplanovanie (zmena
///   nastaveni, resume, start, workmanager) nic nenaplanuje, kym sa znova
///   nedokonci onboarding ([NotificationScheduler]),
/// - znova vyhodnoti suhlasy: `settings` su prazdne, takze PostHog aj Sentry
///   sa vypnu a zmazu fronty aj anonymne ID (`ObservabilityController`).
///
/// - pri `FEATURE_GATE` zmaze odomknutia v nativnom `UnlockStore`
///   (Pigeon `clearUnlocks`); ciele a vypnutie brany riesi uz
///   `SettingsActions.deleteAllData`.
///
/// Kazdy krok bezi aj ked predchadzajuci zlyha.
Future<void> afterDataDeleted(Ref ref) async {
  final log = ref.read(appLoggerProvider);
  Future<void> step(String what, Future<void> Function() run) async {
    try {
      await run();
    } on Object catch (e, st) {
      log.error('delete', '$what failed', error: e, stack: st);
    }
  }

  await step(
    'notifications',
    () => ref.read(notificationSchedulerProvider).cancelAll(),
  );
  if (ref.read(featureFlagsProvider).gate) {
    await step('unlocks', () async {
      final result = await ref.read(blockerGatewayProvider).clearUnlocks();
      if (result case Err(:final failure)) throw StateError(failure.code);
    });
  }
  await step(
    'observability',
    () => ref.read(observabilityControllerProvider).refresh(),
  );
}
