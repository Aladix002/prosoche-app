import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:prosoche/core/clock/clock_provider.dart';
import 'package:prosoche/core/flavor/flavor.dart';
import 'package:prosoche/core/logging/logger_provider.dart';
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/content/bundled_content.dart';
import 'package:prosoche/data/content/content_http_client.dart';
import 'package:prosoche/data/content/content_pack_service.dart';
import 'package:prosoche/data/content/content_pack_state.dart';
import 'package:prosoche/data/content/remote_config_policy.dart';
import 'package:prosoche/data/content/sem_ver.dart';
import 'package:prosoche/data/content/trusted_keys.dart';
import 'package:prosoche/data/db/content_db.dart';
import 'package:prosoche/data/db/content_integrity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'content_providers.g.dart';

/// Verzia appky pre `min_app_version` a kill-switch. Bootstrap ju prepise
/// skutocnou verziou (`--dart-define=APP_VERSION=...` alebo
/// package_info), default zodpoveda pubspec.
@Riverpod(keepAlive: true)
SemVer appVersion(Ref ref) => SemVer.parse(
  const String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0'),
);

/// `<application support>/content`.
@Riverpod(keepAlive: true)
Future<Directory> Function() contentDirectory(Ref ref) =>
    () async => Directory(
      p.join((await getApplicationSupportDirectory()).path, 'content'),
    );

@Riverpod(keepAlive: true)
BundledContentSource bundledContentSource(Ref ref) =>
    AssetBundledContentSource();

@Riverpod(keepAlive: true)
ContentHttpClient contentHttpClient(Ref ref) {
  final client = IoContentHttpClient();
  ref.onDispose(client.close);
  return client;
}

@Riverpod(keepAlive: true)
ContentEndpoints contentEndpoints(Ref ref) =>
    ContentEndpoints.fromEnvironment();

/// Zapecene kluce; flavor `dev` doveruje aj lokalnemu `content-dev`.
@Riverpod(keepAlive: true)
TrustedKeySet trustedKeys(Ref ref) => TrustedKeySet([
  ...kTrustedKeys,
  if (ref.watch(flavorProvider).isDev) ...kDevTrustedKeys,
]);

/// V `dev` sa prijme aj vyvojovy obsah (`meta.dev_content = 1`).
@Riverpod(keepAlive: true)
ContentIntegrityChecker contentIntegrityChecker(Ref ref) =>
    ContentIntegrityChecker(allowDevContent: ref.watch(flavorProvider).isDev);

@Riverpod(keepAlive: true)
ContentPackService contentPackService(Ref ref) {
  final service = ContentPackService(
    directory: ref.watch(contentDirectoryProvider),
    bundled: ref.watch(bundledContentSourceProvider),
    http: ref.watch(contentHttpClientProvider),
    keys: ref.watch(trustedKeysProvider),
    appVersion: ref.watch(appVersionProvider),
    logger: ref.watch(appLoggerProvider),
    endpoints: ref.watch(contentEndpointsProvider),
    integrity: ref.watch(contentIntegrityCheckerProvider),
    clock: ref.watch(appClockProvider),
  );
  ref.onDispose(service.dispose);
  return service;
}

/// Perzistentny stav obsahu, aktualizuje sa pri kazdej zmene.
@Riverpod(keepAlive: true)
Stream<ContentPackState> contentPackState(Ref ref) {
  final service = ref.watch(contentPackServiceProvider);
  final controller = StreamController<ContentPackState>();
  final sub = service.changes.listen(controller.add);
  ref.onDispose(() async {
    await sub.cancel();
    await controller.close();
  });
  unawaited(service.state().then(controller.add, onError: controller.addError));
  return controller.stream;
}

/// `card_id` vypnute cez `disabled_ids` (docs/03 7.4). FeedGenerator ich
/// vynecha; kym sa stav nenacita, prazdna mnozina.
@Riverpod(keepAlive: true)
Set<String> disabledContentIds(Ref ref) =>
    ref.watch(contentPackStateProvider).value?.disabledIds ?? const {};

/// Kill-switch (docs/06 A.7): funkcie, `updateRequired`, oznam. Bez
/// platneho configu defaulty z kodu (vsetko zapnute).
@Riverpod(keepAlive: true)
RemoteConfigPolicy remoteConfigPolicy(Ref ref) {
  final state = ref.watch(contentPackStateProvider).value;
  final service = ref.watch(contentPackServiceProvider);
  return state == null
      ? RemoteConfigPolicy(null, ref.watch(appVersionProvider))
      : service.policyOf(state);
}

/// Pribalena db sa opakovanim neopravi; chyba ide hned do UI.
Duration? _noRetry(int retryCount, Object error) => null;

/// Chyba pri otvarani content.db (ani pribalena db nepresla integritou).
class ContentUnavailableException implements Exception {
  const ContentUnavailableException(this.failure);

  final AppFailure failure;

  @override
  String toString() => 'ContentUnavailableException(${failure.code})';
}

/// Otvorena, overena content.db (read-only). Po aktualizacii obsahu sa
/// stare spojenie zavrie a otvori nove.
///
/// D-02 `contentDbProvider` sa na neho prepoji:
/// `ref.watch(contentDatabaseProvider.future)` v jeho tele, alebo override
/// `contentDbProvider.overrideWith((ref) => ref.watch(
/// contentDatabaseProvider.future))`.
@Riverpod(keepAlive: true, retry: _noRetry)
Future<ContentDb> contentDatabase(Ref ref) async {
  final service = ref.watch(contentPackServiceProvider);
  final sub = service.swaps.listen((_) => ref.invalidateSelf());
  ref.onDispose(sub.cancel);
  final file = switch (await service.ensureInstalled()) {
    Ok(:final value) => value,
    Err(:final failure) => throw ContentUnavailableException(failure),
  };
  final db = ContentDb.openReadOnly(file);
  ref.onDispose(db.close);
  return db;
}
