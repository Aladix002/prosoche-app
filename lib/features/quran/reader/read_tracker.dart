import 'dart:async';

import 'package:flutter/foundation.dart';

/// Vers je precitany, ked je jeho riadok >= 60 % viditelny aspon 2,5 s
/// a appka je v popredi (docs/02 A5.2 Zapisy).
///
/// Tracker dostava mnozinu prave viditelnych versov ([update]); pre kazdy
/// novy spusti casovac, pri zmiznuti ho zrusi. Kazdy vers ohlasi najviac
/// raz za zivot trackera (obrazovky). Casovace novych versov sa spustaju
/// vzostupne, takze pri rovnakom case sa ohlasia v poradi citania.
class ReadTracker {
  ReadTracker({required this.onRead, this.dwell = defaultDwell});

  static const defaultDwell = Duration(milliseconds: 2500);

  /// Podiel vysky riadku, ktory musi byt viditelny.
  static const visibleFraction = 0.6;

  final Duration dwell;
  final void Function(int ayahNumber) onRead;

  final _timers = <int, Timer>{};
  final _reported = <int>{};
  Set<int> _visible = const {};
  bool _paused = false;
  bool _disposed = false;

  /// Uz ohlasene versy.
  Set<int> get reported => Set.unmodifiable(_reported);

  @visibleForTesting
  Set<int> get pending => Set.unmodifiable(_timers.keys);

  /// Prave viditelne versy (>= [visibleFraction]).
  void update(Set<int> visible) {
    if (_disposed) return;
    _visible = visible;
    if (_paused) return;
    for (final n in _timers.keys.toList()) {
      if (!visible.contains(n)) _timers.remove(n)?.cancel();
    }
    final fresh =
        visible
            .where((n) => !_timers.containsKey(n) && !_reported.contains(n))
            .toList()
          ..sort();
    for (final n in fresh) {
      _timers[n] = Timer(dwell, () {
        _timers.remove(n);
        if (_disposed || _paused) return;
        _reported.add(n);
        onRead(n);
      });
    }
  }

  /// Appka ide do pozadia: casovace sa zrusia (dwell plati len v popredi).
  void pause() {
    _paused = true;
    _cancelAll();
  }

  /// Navrat do popredia: viditelne versy zacnu znova od nuly.
  void resume() {
    if (!_paused) return;
    _paused = false;
    update(_visible);
  }

  void dispose() {
    _disposed = true;
    _cancelAll();
  }

  void _cancelAll() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }
}

/// Podiel viditelnej casti riadku [top]..[bottom] vo viewporte
/// [viewTop]..[viewBottom]. Riadok vyssi nez viewport sa pocita voci
/// vyske viewportu (dlhy vers 2:282 sa da precitat).
double visibleFractionOf({
  required double top,
  required double bottom,
  required double viewTop,
  required double viewBottom,
}) {
  final height = bottom - top;
  final viewHeight = viewBottom - viewTop;
  if (height <= 0 || viewHeight <= 0) return 0;
  final visible =
      (bottom < viewBottom ? bottom : viewBottom) -
      (top > viewTop ? top : viewTop);
  if (visible <= 0) return 0;
  final base = height < viewHeight ? height : viewHeight;
  return (visible / base).clamp(0.0, 1.0);
}
