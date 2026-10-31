import 'dart:convert';

import 'package:meta/meta.dart';

/// Typovany kluc v tabulke `settings` (docs/02 0.7).
///
/// Hodnota sa uklada ako JSON text. [read] vrati [defaultValue], ked hodnota
/// chyba alebo je neplatna (napr. po zmene povolenych hodnot), [encode]
/// neplatnu hodnotu odmietne cez [ArgumentError].
@immutable
final class SettingKey<T> {
  const SettingKey._(
    this.name,
    this.defaultValue,
    this._fromJson,
    this._toJson,
  );

  static SettingKey<bool> boolean(String name, {required bool defaultValue}) =>
      SettingKey._(name, defaultValue, _as<bool>, _id);

  static SettingKey<int> integer(
    String name, {
    required int defaultValue,
    int? min,
    int? max,
    Set<int>? allowed,
  }) => SettingKey._(name, defaultValue, (json) {
    final v = _as<int>(json);
    if ((min != null && v < min) ||
        (max != null && v > max) ||
        (allowed != null && !allowed.contains(v))) {
      throw FormatException('$name: $v out of range');
    }
    return v;
  }, _id);

  static SettingKey<int?> optionalInt(
    String name, {
    bool Function(int value)? isValid,
  }) => SettingKey._(name, null, (json) {
    final v = _as<int>(json);
    if (isValid != null && !isValid(v)) {
      throw FormatException('$name: invalid $v');
    }
    return v;
  }, _id);

  static SettingKey<double> decimal(
    String name, {
    required double defaultValue,
    required double min,
    required double max,
  }) => SettingKey._(name, defaultValue, (json) {
    final v = _as<num>(json).toDouble();
    if (v < min || v > max) throw FormatException('$name: $v out of range');
    return v;
  }, _id);

  static SettingKey<String> string(
    String name, {
    required String defaultValue,
    Set<String>? allowed,
    RegExp? pattern,
  }) => SettingKey._(name, defaultValue, (json) {
    final v = _as<String>(json);
    if ((allowed != null && !allowed.contains(v)) ||
        (pattern != null && !pattern.hasMatch(v))) {
      throw FormatException('$name: invalid "$v"');
    }
    return v;
  }, _id);

  static SettingKey<String?> optionalString(String name) =>
      SettingKey._(name, null, _as<String>, _id);

  /// Kluc so zlozenou hodnotou (objekt alebo mapa v JSON). [fromJson] musi
  /// pri neplatnom vstupe hodit [FormatException].
  static SettingKey<V> json<V>(
    String name, {
    required V defaultValue,
    required V Function(Object json) fromJson,
    required Object? Function(V value) toJson,
  }) => SettingKey._(name, defaultValue, fromJson, toJson);

  /// Nazov kluca v DB, napr. `feed.cards_count`.
  final String name;

  final T defaultValue;

  final T Function(Object json) _fromJson;
  final Object? Function(T value) _toJson;

  /// JSON text pre DB. `null` hodnota sa uklada ako `null`.
  String encode(T value) {
    final text = jsonEncode(value == null ? null : _toJson(value));
    try {
      decode(text);
    } on FormatException catch (e) {
      throw ArgumentError.value(value, name, e.message);
    }
    return text;
  }

  /// Hodnota z JSON textu. Pri neplatnom texte hodi [FormatException].
  T decode(String raw) {
    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      throw FormatException('$name: not JSON', raw);
    }
    if (json == null) {
      if (defaultValue == null) return defaultValue;
      throw FormatException('$name: null not allowed', raw);
    }
    return _fromJson(json);
  }

  /// Hodnota z DB; chybajuca alebo neplatna = [defaultValue].
  T read(String? raw) {
    if (raw == null) return defaultValue;
    try {
      return decode(raw);
    } on FormatException {
      return defaultValue;
    }
  }

  @override
  bool operator ==(Object other) => other is SettingKey && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'SettingKey($name)';

  static V _as<V>(Object json) {
    if (json is V) return json as V;
    throw FormatException('expected $V, got ${json.runtimeType}');
  }

  static Object? _id(Object? v) => v;
}
