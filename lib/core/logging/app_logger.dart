import 'dart:collection';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:sakina/core/failures.dart';

/// Urovne logovania (docs/06 C.7). V prod `minLevel = info`.
enum LogLevel { trace, debug, info, warn, error, fatal }

/// Jeden zaznam logu. Serializuje sa ako JSON line.
@immutable
class LogEntry {
  const LogEntry(this.time, this.level, this.tag, this.msg, this.kv);

  final DateTime time;
  final LogLevel level;
  final String tag;
  final String msg;
  final Map<String, Object?> kv;

  Map<String, Object?> toJson() => {
    't': time.toUtc().toIso8601String(),
    'l': level.name,
    'tag': tag,
    'msg': msg,
    if (kv.isNotEmpty) 'kv': kv,
  };

  String toJsonLine() => jsonEncode(toJson());
}

/// Ciel, kam idu uz prefiltrovane zaznamy (ring buffer, Sentry breadcrumbs).
abstract interface class LogSink {
  void add(LogEntry entry);
}

/// Pamatovy ring buffer. Perzistentna verzia (docs/06 C.9) pride neskor.
class RingBufferLog implements LogSink {
  RingBufferLog({this.capacity = 500});

  final int capacity;
  final _entries = ListQueue<LogEntry>();

  List<LogEntry> get entries => List.unmodifiable(_entries);

  @override
  void add(LogEntry entry) {
    _entries.addLast(entry);
    while (_entries.length > capacity) {
      _entries.removeFirst();
    }
  }
}

/// Logger s allowlistom klucov (docs/06 C.7).
///
/// Pravidla:
/// - `msg` je staticky retazec, ziadna interpolacia dat pouzivatela.
/// - premenne idu len do `kv` a len s povolenymi klucmi, ostatne sa zahodia.
/// - nikdy nelogovat nabozenske data, polohu, casy modlitieb, nazvy
///   blokovanych appiek, installId ani obsah exportu.
class AppLogger {
  AppLogger({
    required this._sinks,
    this.minLevel = LogLevel.info,
    this._clock = const Clock(),
    this.echoToConsole = kDebugMode,
  });

  final List<LogSink> _sinks;
  final Clock _clock;
  final LogLevel minLevel;
  final bool echoToConsole;

  /// Jedine kluce, ktore sa mozu dostat do logu.
  static const allowedKeys = <String>{
    'code',
    'op',
    'attempt',
    'status',
    'ms',
    'bytes',
    'from',
    'to',
    'content_version',
    'schema',
    'permission',
    'granted',
    'type',
    'track',
  };

  void trace(String tag, String msg, [Map<String, Object?> kv = const {}]) =>
      _log(LogLevel.trace, tag, msg, kv);

  void debug(String tag, String msg, [Map<String, Object?> kv = const {}]) =>
      _log(LogLevel.debug, tag, msg, kv);

  void info(String tag, String msg, [Map<String, Object?> kv = const {}]) =>
      _log(LogLevel.info, tag, msg, kv);

  void warn(String tag, String msg, [Map<String, Object?> kv = const {}]) =>
      _log(LogLevel.warn, tag, msg, kv);

  /// Exception sa nelogi ako text (moze obsahovat data), len jej typ.
  void error(
    String tag,
    String msg, {
    Object? error,
    StackTrace? stack,
    Map<String, Object?> kv = const {},
  }) {
    _log(LogLevel.error, tag, msg, {
      ...kv,
      if (error != null) 'type': error.runtimeType.toString(),
    });
  }

  void failure(String tag, AppFailure f) => _log(
    f.reportable ? LogLevel.error : LogLevel.warn,
    tag,
    'failure',
    {'code': f.code},
  );

  void _log(LogLevel l, String tag, String msg, Map<String, Object?> kv) {
    if (l.index < minLevel.index) return;
    final safe = <String, Object?>{
      for (final e in kv.entries)
        if (allowedKeys.contains(e.key)) e.key: e.value,
    };
    final entry = LogEntry(_clock.now().toUtc(), l, tag, msg, safe);
    for (final sink in _sinks) {
      sink.add(entry);
    }
    if (echoToConsole) {
      debugPrint('[${l.name}] $tag: $msg $safe');
    }
  }
}
