import 'dart:io';

import 'package:flutter/services.dart' show appBuildName;
import 'package:flutter_riverpod/misc.dart';
import 'package:prosoche/data/content/content_providers.dart';
import 'package:prosoche/data/content/sem_ver.dart';
import 'package:prosoche/data/repositories/infra/databases.dart';
import 'package:prosoche/domain/common/common.dart';

/// Prepojenie obsahu (I-01): D-02 repozitare citaju content.db z D-03
/// [contentDatabaseProvider] (instalacia pribalenej db, integrita,
/// aktualizacie) a `disabled_ids` z manifestu. [supportDir] je
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
