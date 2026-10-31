import 'package:prosoche/domain/settings/setting_key.dart';

export 'package:prosoche/domain/settings/setting_key.dart';
export 'package:prosoche/domain/settings/settings_keys.dart';

/// Pristup k tabulke `settings` v user.db (docs/02 0.7).
///
/// Implementacia (D-02) uklada `SettingKey.encode` text pod `SettingKey.name`
/// a cita cez `SettingKey.read`, takze chybajuca alebo neplatna hodnota je
/// vzdy default. V testoch `InMemorySettingsRepository` z `test/fakes/`.
abstract interface class SettingsRepository {
  /// Aktualna hodnota alebo default.
  Future<T> get<T>(SettingKey<T> key);

  /// Ulozi [value]. Neplatnu hodnotu odmietne cez [ArgumentError].
  Future<void> set<T>(SettingKey<T> key, T value);

  /// Zmaze ulozenu hodnotu, dalsie citanie vrati default.
  Future<void> reset(SettingKey<Object?> key);

  /// Aktualna hodnota a potom kazda zmena kluca [key].
  Stream<T> watch<T>(SettingKey<T> key);
}
