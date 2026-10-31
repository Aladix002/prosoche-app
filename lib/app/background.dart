import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/app/notification_wiring.dart';
import 'package:prosoche/core/logging/logger_provider.dart';
import 'package:prosoche/data/notifications/notifications.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:workmanager/workmanager.dart';

/// Jediny workmanager callback dispatcher appky (bezi v background
/// isolate). Kazda uloha dostane vlastny [ProviderContainer], ktory sa po
/// behu zlikviduje (zavrie user.db).
@pragma('vm:entry-point')
void backgroundDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().executeTask(runBackgroundTask);
}

/// Spusti background ulohu [task]. Nezname ulohy skoncia uspechom, aby ich
/// workmanager neopakoval.
Future<bool> runBackgroundTask(
  String task,
  Map<String, dynamic>? input, {
  ProviderContainer Function()? createContainer,
}) async {
  final container = (createContainer ?? ProviderContainer.new)();
  try {
    if (NotificationBackground.handles(task)) {
      // Pred onboardingom (aj po zmazani dat) sa nic neplanuje.
      if (!await _onboarded(container)) return true;
      return await NotificationBackground.run(
        () => Future.value(container.read(notificationServiceProvider)),
        logger: container.read(appLoggerProvider),
      );
    }
    // Miesto pre buducu ulohu D-03: periodicky
    // `ContentPackService.checkForUpdate()` (contentPackServiceProvider).
    return true;
  } finally {
    container.dispose();
  }
}

Future<bool> _onboarded(ProviderContainer container) async {
  try {
    return await container
        .read(settingsRepositoryProvider)
        .get(SettingsKeys.onboardingCompleted);
  } on Object catch (e, st) {
    container
        .read(appLoggerProvider)
        .error('notif', 'onboarding check failed', error: e, stack: st);
    return false;
  }
}
