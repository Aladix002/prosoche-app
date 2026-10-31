import 'dart:async';
import 'dart:collection';

import 'package:sakina/core/logging/app_logger.dart';
import 'package:sakina/data/observability/analytics.dart';

/// Odosielanie uz prefiltrovanych eventov (PostHog, v testoch fake).
abstract interface class AnalyticsTransport {
  /// Inicializacia SDK. Vola sa az po suhlase.
  Future<void> start();

  Future<void> capture(String event, Map<String, Object> props);

  /// Okamzite vypnutie. [wipe] = zmazat fronty a anonymne ID v SDK
  /// (odvolanie suhlasu).
  Future<void> stop({required bool wipe});
}

enum _State { off, starting, on }

/// [Analytics] s allowlistom (docs/02 0.6) a lokalnou frontou.
///
/// - Vypnuta (default): [track] event zahodi, nic sa neuklada.
/// - Pocas startu SDK sa eventy drzia v pamati (max [maxQueue]) a po starte
///   sa odoslu.
/// - [disable] (odvolanie suhlasu, kill-switch) frontu okamzite zmaze
///   a zastavi transport so zmazanim jeho front.
/// - [enqueueConsented]: eventy nazbierane pred suhlasom (onboarding O7);
///   cakaju na najblizsie [enable] alebo ich zmaze [disable].
class AllowlistAnalytics implements Analytics {
  AllowlistAnalytics(
    this._transport, {
    Map<String, Object?> Function()? superProperties,
    this._logger,
    this.maxQueue = 200,
  }) : _superProperties = superProperties ?? (() => const {});

  final AnalyticsTransport _transport;
  final Map<String, Object?> Function() _superProperties;
  final AppLogger? _logger;
  final int maxQueue;

  final ListQueue<(String, Map<String, Object>)> _queue = ListQueue();
  _State _state = _State.off;
  var _transportStarted = false;

  bool get isEnabled => _state != _State.off;

  /// Pocet eventov cakajucich na odoslanie (len pre testy a diagnostiku).
  int get queuedCount => _queue.length;

  @override
  void track(String event, [Map<String, Object?> props = const {}]) {
    if (_state == _State.off) return;
    _accept(event, props);
  }

  /// Eventy, na ktore sa vztahuje prave udeleny suhlas (onboarding O7).
  /// Odoslu sa po [enable], [disable] ich zahodi.
  void enqueueConsented(Iterable<(String, Map<String, Object?>)> events) {
    for (final (name, props) in events) {
      _accept(name, props);
    }
  }

  void _accept(String event, Map<String, Object?> props) {
    if (!AnalyticsSchema.isKnownEvent(event)) {
      _logger?.debug('analytics', 'unknown event dropped');
      return;
    }
    final safe = {
      ...AnalyticsSchema.sanitizeSuper(_superProperties()),
      ...AnalyticsSchema.sanitize(event, props),
    };
    if (_state == _State.on) {
      _send(event, safe);
    } else {
      _queue.addLast((event, safe));
      while (_queue.length > maxQueue) {
        _queue.removeFirst();
      }
    }
  }

  void _send(String event, Map<String, Object> props) {
    unawaited(
      _transport.capture(event, props).catchError((Object e, StackTrace st) {
        _logger?.warn('analytics', 'capture failed', {
          'type': e.runtimeType.toString(),
        });
      }),
    );
  }

  /// Zapne odosielanie (po suhlase). Idempotentne.
  Future<void> enable() async {
    if (_state != _State.off) return;
    _state = _State.starting;
    try {
      await _transport.start();
      _transportStarted = true;
    } on Object catch (e) {
      _state = _State.off;
      _queue.clear();
      _logger?.warn('analytics', 'start failed', {
        'type': e.runtimeType.toString(),
      });
      return;
    }
    // Medzitym prislo disable(): SDK hned zastavit a zmazat.
    if (_state != _State.starting) {
      await disable();
      return;
    }
    _state = _State.on;
    while (_queue.isNotEmpty) {
      final (event, props) = _queue.removeFirst();
      _send(event, props);
    }
  }

  /// Vypne odosielanie a zmaze lokalnu frontu; [wipe] zmaze aj fronty
  /// a anonymne ID v SDK (odvolanie suhlasu, kill-switch).
  Future<void> disable({bool wipe = true}) async {
    _state = _State.off;
    _queue.clear();
    if (!_transportStarted) return;
    _transportStarted = false;
    try {
      await _transport.stop(wipe: wipe);
    } on Object catch (e) {
      _logger?.warn('analytics', 'stop failed', {
        'type': e.runtimeType.toString(),
      });
    }
  }
}
