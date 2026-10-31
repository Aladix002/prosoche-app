import 'dart:math';

import 'package:prosoche/data/db/daos/settings_dao.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';

/// [SettingsRepository] nad tabulkou `settings` v user.db (docs/02 0.7).
///
/// Uklada `SettingKey.encode` pod `SettingKey.name`, cita cez
/// `SettingKey.read`: chybajuca alebo neplatna hodnota = default.
class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._dao);

  final SettingsDao _dao;

  @override
  Future<T> get<T>(SettingKey<T> key) async =>
      key.read(await _dao.read(key.name));

  @override
  Future<void> set<T>(SettingKey<T> key, T value) =>
      _dao.write(key.name, key.encode(value));

  @override
  Future<void> reset(SettingKey<Object?> key) => _dao.remove(key.name);

  @override
  Stream<T> watch<T>(SettingKey<T> key) =>
      _dao.watch(key.name).map(key.read).distinct();
}

/// `install_id`: existujuci alebo novo vygenerovany UUID v4 (seed sady,
/// nikdy neodchadza z appky, docs/02 0.7).
///
/// Subezne volania nad tym istym repozitarom vratia to iste ID.
///
/// Otvorene (Q-02): `install_id` sa zalohuje spolu s user.db (Android
/// Auto Backup `files/`). Ma ist mimo zalohy (`getNoBackupFilesDir`),
/// co vyzaduje platformovy kanal; docasne ostava kluc v `settings`.
Future<String> ensureInstallId(SettingsRepository settings, {Random? random}) =>
    _pendingInstallId[settings] ??= _ensureInstallId(settings, random);

final _pendingInstallId = Expando<Future<String>>('install_id');

Future<String> _ensureInstallId(
  SettingsRepository settings,
  Random? random,
) async {
  final existing = await settings.get(SettingsKeys.installId);
  if (existing != null && existing.isNotEmpty) return existing;
  final id = uuidV4(random ?? Random.secure());
  await settings.set(SettingsKeys.installId, id);
  return id;
}

/// Nahodny UUID v4 (RFC 4122) bez dalsej zavislosti.
String uuidV4(Random random) {
  final b = List<int>.generate(16, (_) => random.nextInt(256));
  b[6] = (b[6] & 0x0F) | 0x40;
  b[8] = (b[8] & 0x3F) | 0x80;
  final hex = [for (final x in b) x.toRadixString(16).padLeft(2, '0')].join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
