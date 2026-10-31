import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:prosoche/data/repositories/repositories.dart';

/// Atribucia zdroja obsahu karty z tabulky `source` v content.db
/// (docs/09: nazov, verzia a atribucia zdroja).
@immutable
final class CardSourceInfo {
  const CardSourceInfo({
    required this.id,
    required this.name,
    required this.version,
    required this.attribution,
  });

  /// `source.id`, napr. `gutenberg-meditations-long`.
  final String id;
  final String name;

  /// `source.version`, napr. `snapshot-2026-10-29`.
  final String version;

  /// `source.attribution`, text pre obrazovku Zdroje (doslovne z DB).
  final String attribution;
}

/// Zdroj `source.id` z content.db; null = riadok chyba.
final FutureProviderFamily<CardSourceInfo?, String> cardSourceProvider =
    FutureProvider.family<CardSourceInfo?, String>((ref, id) async {
      final db = await ref.watch(contentDbProvider.future);
      final row = await db.contentMetaDao.source(id);
      if (row == null) return null;
      return CardSourceInfo(
        id: row.id,
        name: row.name,
        version: row.version,
        attribution: row.attribution,
      );
    }, name: 'cardSourceProvider');
