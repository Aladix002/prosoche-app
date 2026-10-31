import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sakina/core/logging/app_logger.dart';
import 'package:sakina/domain/settings/settings_repository.dart';

/// Kedy sa preplanuje v popredi (TECHNICKY_PLAN 8.2): pri starte, pri
/// navrate do appky (lifecycle resumed, aj po navrate z nastaveni presnych
/// alarmov alebo pri zmene casovej zony) a po zmene nastaveni.
///
/// Zmeny nastaveni sa zlucia ([debounce]), aby onboarding, ktory zapise
/// viac klucov naraz, preplanoval len raz.
final class NotificationTriggers {
  NotificationTriggers({
    required this.settings,
    required this.reschedule,
    this.debounce = const Duration(milliseconds: 500),
    this.logger,
  });

  final SettingsRepository settings;
  final Future<void> Function() reschedule;
  final Duration debounce;
  final AppLogger? logger;

  /// Kluce, ktorych zmena meni plan.
  static final List<SettingKey<Object?>> watchedKeys = [
    SettingsKeys.prayerLocation,
    SettingsKeys.prayerMethod,
    SettingsKeys.prayerAsr,
    SettingsKeys.prayerHighLatRule,
    SettingsKeys.prayerAdjust,
    for (final p in SettingsKeys.prayers) SettingsKeys.notifPrayer(p),
    SettingsKeys.notifMorningEnabled,
    SettingsKeys.notifMorningTime,
    SettingsKeys.notifPrivateLockscreen,
    SettingsKeys.uiLocale,
  ];

  final _subs = <StreamSubscription<Object?>>[];
  AppLifecycleListener? _lifecycle;
  Timer? _timer;

  /// Spusti sledovanie a hned preplanuje (start appky).
  Future<void> start() async {
    _lifecycle = AppLifecycleListener(onResume: _run);
    for (final key in watchedKeys) {
      // Prva hodnota streamu je aktualny stav, nie zmena.
      _subs.add(settings.watch(key).skip(1).listen((_) => _schedule()));
    }
    await _run();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(debounce, _run);
  }

  Future<void> _run() async {
    _timer?.cancel();
    try {
      await reschedule();
    } on Object catch (e, st) {
      // Planovanie nesmie zhodit appku; dalsi pokus pri dalsom spusteni.
      logger?.error('notif', 'reschedule failed', error: e, stack: st);
    }
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _lifecycle?.dispose();
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }
}
