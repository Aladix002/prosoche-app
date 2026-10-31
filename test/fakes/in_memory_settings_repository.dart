import 'dart:async';

import 'package:prosoche/domain/settings/settings_repository.dart';

/// [SettingsRepository] v pamati pre testy. Uklada zakodovany text ako DB,
/// takze testy prechadzaju aj cez kodovanie klucov.
class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository([Map<String, String>? raw]) : _raw = {...?raw};

  final Map<String, String> _raw;
  final _changes = StreamController<String>.broadcast(sync: true);

  /// Surove hodnoty (nazov kluca -> JSON text) na kontrolu v testoch.
  Map<String, String> get raw => Map.unmodifiable(_raw);

  @override
  Future<T> get<T>(SettingKey<T> key) async => key.read(_raw[key.name]);

  @override
  Future<void> set<T>(SettingKey<T> key, T value) async {
    _raw[key.name] = key.encode(value);
    _changes.add(key.name);
  }

  @override
  Future<void> reset(SettingKey<Object?> key) async {
    _raw.remove(key.name);
    _changes.add(key.name);
  }

  @override
  Stream<T> watch<T>(SettingKey<T> key) {
    late StreamController<T> controller;
    StreamSubscription<String>? sub;
    controller = StreamController<T>(
      onListen: () {
        controller.add(key.read(_raw[key.name]));
        sub = _changes.stream
            .where((name) => name == key.name)
            .listen((_) => controller.add(key.read(_raw[key.name])));
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  Future<void> dispose() => _changes.close();
}
