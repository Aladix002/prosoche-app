import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/flags/feature_flags.dart';
import 'package:sakina/core/logging/app_logger.dart';
import 'package:sakina/core/logging/logger_provider.dart';
import 'package:sakina/core/router/routes.dart';
import 'package:sakina/data/repositories/settings/settings_providers.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/onboarding/onboarding_routes.dart';
import 'package:sakina/features/onboarding/onboarding_steps.dart';

/// Stav onboardingu pre router (`onboarding.completed`, `onboarding.step`).
@immutable
final class OnboardingStatus {
  const OnboardingStatus({required this.completed, this.step});

  final bool completed;

  /// Ulozeny krok (`onboarding.step`).
  final String? step;

  @override
  bool operator ==(Object other) =>
      other is OnboardingStatus &&
      other.completed == completed &&
      other.step == step;

  @override
  int get hashCode => Object.hash(completed, step);
}

/// Redirect podla docs/02 C3 (cista funkcia). [path] je cielova cesta po
/// mapovani deep linku. Vrati novu cestu alebo null (bez zmeny).
///
/// 1. Nedokonceny onboarding a ciel mimo `/onboarding/*` (okrem `/gate`)
///    -> `/onboarding/{onboarding.step}`.
/// 2. Dokonceny onboarding a ciel `/onboarding/*` -> `/today`.
String? onboardingRedirect(
  String path,
  OnboardingStatus status,
  OnboardingFlow flow,
) {
  final inOnboarding =
      path == OnboardingRoutes.root ||
      path.startsWith('${OnboardingRoutes.root}/');
  if (status.completed) return inOnboarding ? AppRoutes.today : null;
  if (inOnboarding) return null;
  if (path == AppRoutes.gate || path.startsWith('${AppRoutes.gate}/')) {
    return null;
  }
  return OnboardingRoutes.step(flow.resume(status.step).key);
}

/// Onboarding guard routera (docs/02 C3). Drzi posledny stav z nastaveni
/// synchronne, aby redirect nemusel cakat; prvy redirect pred nacitanim
/// pocka na nastavenia. Zmena `onboarding.completed` upozorni router
/// (`refreshListenable`).
class OnboardingGuard extends ChangeNotifier {
  OnboardingGuard({required this._settings, required this.flow, this._logger});

  final SettingsRepository _settings;
  final AppLogger? _logger;
  final OnboardingFlow flow;

  OnboardingStatus? _status;
  Future<OnboardingStatus?>? _loading;
  final _subs = <StreamSubscription<Object?>>[];

  /// Posledny znamy stav (null = este nenacitany).
  OnboardingStatus? get status => _status;

  /// Redirect pre `GoRouter.redirect`. [upstream] je vysledok globalneho
  /// redirectu (deep link, vypnute funkcie); guard ho bud prepise, alebo
  /// vrati bez zmeny.
  FutureOr<String?> redirect(Uri uri, String? upstream) {
    final path = upstream == null ? uri.path : Uri.parse(upstream).path;
    String? apply(OnboardingStatus? s) =>
        s == null ? upstream : onboardingRedirect(path, s, flow) ?? upstream;
    final current = _status;
    if (current != null) return apply(current);
    return _load().then(apply);
  }

  /// Onboarding je dokonceny: router hned pusti na `/today` (pred tym, ako
  /// pride zmena zo streamu nastaveni).
  void markCompleted() => _update(const OnboardingStatus(completed: true));

  Future<OnboardingStatus?> _load() => _loading ??= () async {
    try {
      final status = OnboardingStatus(
        completed: await _settings.get(SettingsKeys.onboardingCompleted),
        step: await _settings.get(SettingsKeys.onboardingStep),
      );
      _status ??= status;
      _watch();
      return _status;
    } on Object catch (e, st) {
      // Nastavenia sa nedaju precitat: bez presmerovania (appka ukaze
      // chybove stavy obrazoviek), dalsi pokus pri dalsej navigacii.
      _logger?.error('onboarding', 'status load failed', error: e, stack: st);
      _loading = null;
      return null;
    }
  }();

  void _watch() {
    if (_subs.isNotEmpty) return;
    _subs
      ..add(
        _settings.watch(SettingsKeys.onboardingCompleted).listen((completed) {
          _update(OnboardingStatus(completed: completed, step: _status?.step));
        }, onError: (Object _) {}),
      )
      ..add(
        _settings.watch(SettingsKeys.onboardingStep).listen((step) {
          final s = _status;
          // Krok meni len ciel obnovenia, router netreba obnovovat.
          _status = OnboardingStatus(
            completed: s?.completed ?? false,
            step: step,
          );
        }, onError: (Object _) {}),
      );
  }

  void _update(OnboardingStatus next) {
    final changed = _status?.completed != next.completed;
    _status = next;
    if (changed) notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}

/// Guard pre `appRouterProvider`. Flow podla [featureFlagsProvider].
final Provider<OnboardingGuard> onboardingGuardProvider =
    Provider<OnboardingGuard>((ref) {
      final guard = OnboardingGuard(
        settings: ref.watch(settingsRepositoryProvider),
        flow: OnboardingFlow(gate: ref.watch(featureFlagsProvider).gate),
        logger: ref.watch(appLoggerProvider),
      );
      ref.onDispose(guard.dispose);
      return guard;
    }, name: 'onboardingGuardProvider');
