import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:prosoche/core/logging/logger_provider.dart';
import 'package:prosoche/data/content/content_providers.dart';
import 'package:prosoche/data/content/hadith_extra_pack_service.dart';
import 'package:prosoche/data/db/hadith_extra_repository.dart' as db;
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:prosoche/data/content/hadith_extra_pack_service.dart';

part 'hadith_extra_pack_providers.g.dart';

/// Balik `hadith_extra.db` (D-05). UI vola `download()` a `delete()`.
@Riverpod(keepAlive: true)
HadithExtraPackService hadithExtraPackService(Ref ref) {
  final service = HadithExtraPackService(
    directory: ref.watch(contentDirectoryProvider),
    content: ref.watch(contentPackServiceProvider),
    http: ref.watch(contentHttpClientProvider),
    keys: ref.watch(trustedKeysProvider),
    bundled: ref.watch(bundledContentSourceProvider),
    logger: ref.watch(appLoggerProvider),
    endpoints: ref.watch(contentEndpointsProvider),
  );
  ref.onDispose(service.dispose);
  return service;
}

/// Stav balika vratane priebehu stahovania.
@Riverpod(keepAlive: true)
Stream<HadithExtraPackStatus> hadithExtraPackStatus(Ref ref) {
  final service = ref.watch(hadithExtraPackServiceProvider);
  final controller = StreamController<HadithExtraPackStatus>();
  final sub = service.changes.listen(controller.add);
  ref.onDispose(() async {
    await sub.cancel();
    await controller.close();
  });
  unawaited(
    service.status().then((s) {
      // Medzicasom mohla prist novsia zmena cez `changes`.
      final current = service.current ?? s;
      if (!controller.isClosed) controller.add(current);
    }, onError: controller.addError),
  );
  return controller.stream;
}

/// Repozitar vysvetliviek nad balikom; vracia `null`, kym balik nie je
/// [HadithExtraReady]. Prestavi sa pri zmene pripravenosti, takze
/// zavisle providery (`hadithExtraProvider`) sa prepocitaju.
@Riverpod(keepAlive: true)
db.HadithExtraRepository hadithExtraPackRepository(Ref ref) {
  ref.watch(hadithExtraPackStatusProvider.select((s) => s.value?.isReady));
  return ref.watch(hadithExtraPackServiceProvider).repository;
}
