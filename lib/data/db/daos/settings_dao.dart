import 'package:drift/drift.dart';
import 'package:sakina/data/db/user_db.dart';

part 'settings_dao.g.dart';

/// Surova tabulka `settings` (kluc -> JSON text). Typy a defaulty riesi
/// `SettingsRepository` (D-02) cez `SettingKey`.
@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<UserDb> with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase);

  SimpleSelectStatement<$SettingsTable, SettingRow> _byKey(String key) =>
      select(settings)..where((t) => t.key.equals(key));

  Future<String?> read(String key) async =>
      (await _byKey(key).getSingleOrNull())?.valueJson;

  /// Aktualna hodnota a kazda zmena (null = nenastavene).
  Stream<String?> watch(String key) =>
      _byKey(key).watchSingleOrNull().map((r) => r?.valueJson);

  Future<void> write(String key, String valueJson) => into(settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: key, valueJson: valueJson),
      );

  Future<void> remove(String key) =>
      (delete(settings)..where((t) => t.key.equals(key))).go();

  /// Vsetky kluce a hodnoty (export F-09).
  Future<Map<String, String>> readAll() async => {
    for (final r in await select(settings).get()) r.key: r.valueJson,
  };
}
