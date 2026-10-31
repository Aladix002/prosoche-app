import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:prosoche/data/repositories/infra/databases.dart';
import 'package:prosoche/data/repositories/infra/time_providers.dart';
import 'package:prosoche/data/repositories/settings/drift_settings_repository.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';

/// Repozitar nastaveni. V testoch obrazoviek ho prepise
/// `InMemorySettingsRepository` z `test/fakes/`.
final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>(
      (ref) => DriftSettingsRepository(ref.watch(userDbProvider).settingsDao),
      name: 'settingsRepositoryProvider',
    );

/// Hodnota kluca `key` a kazda jej zmena (docs/02 0.9 `settingsProvider`).
///
/// Typovy pristup cez [settingOf]:
/// `ref.watch(settingOf(SettingsKeys.simpleMode))` vrati `AsyncValue<bool>`.
final StreamProviderFamily<Object?, SettingKey<Object?>> settingProvider =
    StreamProvider.family<Object?, SettingKey<Object?>>(
      (ref, key) => ref.watch(settingsRepositoryProvider).watch(key),
      name: 'settingProvider',
    );

/// Typovy [settingProvider].
ProviderListenable<AsyncValue<T>> settingOf<T>(SettingKey<T> key) =>
    settingProvider(key).select((v) => v.whenData((x) => x as T));

/// `install_id`, pri prvom citani sa vygeneruje a ulozi.
final FutureProvider<String> installIdProvider = FutureProvider<String>(
  (ref) => ensureInstallId(ref.watch(settingsRepositoryProvider)),
  name: 'installIdProvider',
);

/// Jazyky obsahu a UI v MVP (docs/02 O1).
const supportedContentLanguages = ['en', 'ar', 'id', 'ur', 'bn', 'tr'];

/// Jazyk obsahu = `ui.locale`, inak jazyk systemu, inak `en`.
String resolveContentLanguage(String? stored, String device) {
  if (stored != null && supportedContentLanguages.contains(stored)) {
    return stored;
  }
  return supportedContentLanguages.contains(device) ? device : 'en';
}

/// Jazyk obsahu z nastaveni a jazyka systemu.
Future<String> currentContentLanguage(
  SettingsRepository settings,
  String deviceLanguage,
) async => resolveContentLanguage(
  await settings.get(SettingsKeys.uiLocale),
  deviceLanguage,
);

/// Jazyk obsahu (preklady, texty kariet a questov). Sleduje `ui.locale`.
final FutureProvider<String> contentLanguageProvider = FutureProvider<String>((
  ref,
) async {
  // Zmena `ui.locale` provider prepocita; hodnota sa cita priamo, aby
  // provider nezavisel od (pozastaveneho) streamu bez posluchaca.
  ref.listen(settingProvider(SettingsKeys.uiLocale), (prev, next) {
    if (prev?.value != next.value && prev?.hasValue == true) {
      ref.invalidateSelf();
    }
  });
  return await currentContentLanguage(
    ref.watch(settingsRepositoryProvider),
    ref.watch(deviceLanguageProvider),
  );
}, name: 'contentLanguageProvider');
