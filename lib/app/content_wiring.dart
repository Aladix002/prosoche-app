import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show appBuildName;
import 'package:flutter_riverpod/misc.dart';
import 'package:path/path.dart' as p;
import 'package:sakina/data/content/content_providers.dart';
import 'package:sakina/data/content/hadith_extra_pack_providers.dart';
import 'package:sakina/data/content/sem_ver.dart';
import 'package:sakina/data/db/hadith_extra_repository.dart' as db;
import 'package:sakina/data/repositories/cards/hadith_extra_repository.dart';
import 'package:sakina/data/repositories/infra/databases.dart';
import 'package:sakina/domain/common/common.dart';
import 'package:sakina/features/cards/hadith_explanations_pack.dart';

/// Prepojenie obsahu (I-01): D-02 repozitare citaju content.db z D-03
/// [contentDatabaseProvider] (instalacia pribalenej db, integrita,
/// aktualizacie), `disabled_ids` z manifestu a vysvetlivky hadisov z
/// volitelneho balika `hadith_extra.db` (D-01). [supportDir] je
/// `getApplicationSupportDirectory()` (bootstrap ho zisti pred `runApp`).
List<Override> contentOverrides({required Directory supportDir}) => [
  // contentDatabaseProvider vlastni spojenie (zavrie ho pri vymene db),
  // preto override bez `onDispose(db.close)` z D-02 defaultu.
  contentDbProvider.overrideWith(
    (ref) => ref.watch(contentDatabaseProvider.future),
  ),
  disabledCardIdsProvider.overrideWith(
    (ref) => disabledCardIds(ref.watch(disabledContentIdsProvider)),
  ),
  // D-05: balik cez HadithExtraPackService (null, kym nie je stiahnuty
  // a nesedi s aktivnou content.db).
  hadithExtraRepositoryProvider.overrideWith(
    (ref) =>
        FileHadithExtraAdapter(ref.watch(hadithExtraPackRepositoryProvider)),
  ),
  // BF-01: tlacidlo "Download explanations" na karte hadisu.
  hadithExplanationsPackProvider.overrideWith(
    (ref) => ServiceHadithExplanationsPack(
      ref.watch(hadithExtraPackServiceProvider),
    ),
  ),
  appVersionProvider.overrideWithValue(appVersionOf(appBuildName)),
];

/// `card_id` z manifestu; neplatne id sa ignoruju.
Set<CardId> disabledCardIds(Set<String> ids) => {
  for (final id in ids) ?CardId.tryParse(id),
};

/// Verzia appky: `FLUTTER_BUILD_NAME` (flutter tool ju vklada z pubspec
/// `version` alebo `--build-name`), inak `--dart-define=APP_VERSION`.
SemVer appVersionOf(String? buildName) =>
    (buildName == null ? null : SemVer.tryParse(buildName)) ??
    SemVer.parse(
      const String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0'),
    );

/// `<application support>/content/hadith_extra.db` (stahuje D-05
/// [HadithExtraPackService]).
File hadithExtraFile(Directory supportDir) =>
    File(p.join(supportDir.path, 'content', 'hadith_extra.db'));

/// Stav balika D-05 v tvare karty hadisu (BF-01).
HadithExplanationsPackStatus explanationsStatusOf(HadithExtraPackStatus s) =>
    switch (s) {
      HadithExtraUnavailable() => HadithExplanationsPackStatus.notAvailable,
      HadithExtraNotDownloaded() ||
      HadithExtraStale() => HadithExplanationsPackStatus.notDownloaded,
      HadithExtraDownloading() => HadithExplanationsPackStatus.downloading,
      HadithExtraReady() => HadithExplanationsPackStatus.ready,
      HadithExtraFailed() => HadithExplanationsPackStatus.failed,
    };

/// [HadithExplanationsPack] (BF-01) nad [HadithExtraPackService] (D-05).
class ServiceHadithExplanationsPack implements HadithExplanationsPack {
  const ServiceHadithExplanationsPack(this._service);

  final HadithExtraPackService _service;

  /// Prva hodnota je aktualny stav, potom kazda zmena (priebeh stahovania
  /// sa zluci do jedneho `downloading`).
  @override
  Stream<HadithExplanationsPackStatus> watchStatus() {
    late final StreamController<HadithExtraPackStatus> controller;
    StreamSubscription<HadithExtraPackStatus>? sub;
    controller = StreamController<HadithExtraPackStatus>(
      onListen: () {
        // Najprv odber zmien, aby sa nic nestratilo pocas prveho dotazu.
        sub = _service.changes.listen(controller.add);
        _service.status().then((s) {
          if (!controller.isClosed) controller.add(_service.current ?? s);
        }, onError: controller.addError).ignore();
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream.map(explanationsStatusOf).distinct();
  }

  /// Skonci az ked je balik `ready` alebo `failed` (chyba je v stave, nie
  /// vo vynimke).
  @override
  Future<void> download() async {
    await _service.download();
    await _service.status();
  }
}

/// D-01 [db.HadithExtraRepository] v tvare D-02 [HadithExtraRepository].
class FileHadithExtraAdapter implements HadithExtraRepository {
  const FileHadithExtraAdapter(this._inner);

  final db.HadithExtraRepository _inner;

  @override
  Future<HadithExtra?> explanation(int hadithId, String lang) async {
    final e = await _inner.explanationFor(hadithId, lang);
    if (e == null) return null;
    return HadithExtra(
      hadithId: e.hadithId,
      lang: e.lang,
      explanation: e.explanation,
      hints: e.hints.isEmpty ? null : e.hints.join('\n'),
    );
  }
}
