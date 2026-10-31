import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/flags/feature_flags.dart';
import 'package:prosoche/core/logging/logger_provider.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/features/settings/blocking/blocking_providers.dart';

/// Brana (B-02) bezi v druhom engine s vlastnym spojenim na user.db, takze
/// drift streamy hlavnej appky jej zapisy (`seen` v dennej sade, questy,
/// `day_log`) nevidia. Po navrate do appky sa preto sada, questy a streak
/// nacitaju znova. Bez brany (`lite`) nic.
///
/// Pri starte a kazdom navrate sa navyse overi, ze brana bezi
/// ([resumeGate], I-03).
AppLifecycleListener? startGateSync(ProviderContainer container) {
  if (!container.read(featureFlagsProvider).gate) return null;
  unawaited(resumeGate(container));
  return AppLifecycleListener(
    onResume: () {
      refreshAfterGate(container);
      unawaited(resumeGate(container));
    },
  );
}

/// [ensureGateRunning] nad kontajnerom appky; chyba sa len zaloguje.
Future<GateEnableResult?> resumeGate(ProviderContainer container) async {
  try {
    final result = await ensureGateRunning(container);
    container.invalidate(gateNeedsAttentionProvider);
    if (result != null) {
      container.read(appLoggerProvider).info('gate', 'restarted on resume', {
        'status': result.name,
      });
    }
    return result;
  } on Object catch (e, st) {
    // Kontajner moze byt uz zruseny (koniec appky, testy): bez logu.
    try {
      container
          .read(appLoggerProvider)
          .error('gate', 'resume check failed', error: e, stack: st);
    } on Object {
      // nic
    }
    return null;
  }
}

/// Znova nacita data, ktore mohla zmenit brana.
void refreshAfterGate(ProviderContainer container) {
  container
    ..invalidate(dailySetProvider)
    ..invalidate(questsProvider)
    ..invalidate(streakProvider)
    ..invalidate(dayLogProvider);
}
