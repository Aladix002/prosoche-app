import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:sakina/data/db/content_db.dart';
import 'package:sakina/data/db/hadith_extra_db.dart';

/// Vysvetlivka a poznamky HadeethEnc k jednemu hadisu (C-06). Texty su
/// bajtovo zo zdroja, appka ich nemeni.
@immutable
class HadithExplanation {
  const HadithExplanation({
    required this.hadithId,
    required this.lang,
    required this.explanation,
    required this.hints,
    required this.sourceId,
  });

  final int hadithId;
  final String lang;
  final String? explanation;

  /// Poznamky (`hints`) v poradi zdroja; prazdne, ak ich zdroj nema.
  final List<String> hints;

  /// `source.id` (= `hadith_text.source_id` v content.db).
  final String sourceId;
}

/// Pristup k volitelnemu balika hadith_extra.db. Kym balik nie je
/// stiahnuty (D-05) alebo nesedi, vsetko vracia `null`.
abstract interface class HadithExtraRepository {
  Future<HadithExplanation?> explanationFor(int hadithId, String lang);
}

/// Ci otvoreny balik patri k tejto appke (kontrakt `hadith_extra_schema.sql`
/// meta): `pack_id`, `schema_version`, `base_schema_version` a volitelne
/// `content_version` aktivnej content.db.
Future<bool> isCompatibleHadithExtra(
  HadithExtraDb db, {
  int? contentVersion,
}) async {
  final dao = db.hadithExtraDao;
  return await dao.metaValue('pack_id') == HadithExtraDb.packId &&
      await dao.metaValue('schema_version') ==
          '${HadithExtraDb.contractVersion}' &&
      await dao.metaValue('base_schema_version') ==
          '${ContentDb.contractVersion}' &&
      (contentVersion == null ||
          await dao.metaValue('content_version') == '$contentVersion');
}

/// [HadithExtraRepository] nad suborom [file]. Subor sa otvori (read-only)
/// pri prvom dotaze, ak existuje a [isCompatibleHadithExtra]; inak `null`
/// (a dalsi dotaz to skusi znova). Po vymene otvoreneho suboru (D-05)
/// treba zavolat [reload].
class FileHadithExtraRepository implements HadithExtraRepository {
  FileHadithExtraRepository(
    this.file, {
    this.contentVersion,
    HadithExtraDb Function(File file)? open,
  }) : _open = open ?? HadithExtraDb.openReadOnly;

  final File file;

  /// `content_version` aktivnej content.db; `null` = nekontroluje sa.
  final int? contentVersion;

  final HadithExtraDb Function(File file) _open;
  Future<HadithExtraDb?>? _db;

  @override
  Future<HadithExplanation?> explanationFor(int hadithId, String lang) async {
    final db = await (_db ??= _tryOpen());
    if (db == null) {
      // Balik este nie je (alebo nesedi): skusi sa znova pri dalsom dotaze.
      _db = null;
      return null;
    }
    final HadithExplanationRow? row;
    try {
      row = await db.hadithExtraDao.explanationFor(hadithId, lang);
    } on Object {
      return null;
    }
    if (row == null) return null;
    return HadithExplanation(
      hadithId: row.hadithId,
      lang: row.lang,
      explanation: row.explanation,
      hints: parseHints(row.hints),
      sourceId: row.sourceId,
    );
  }

  /// Zavrie balik; dalsi dotaz ho otvori znova.
  Future<void> reload() async {
    final db = await _db;
    _db = null;
    await db?.close();
  }

  Future<HadithExtraDb?> _tryOpen() async {
    if (!file.existsSync()) return null;
    final db = _open(file);
    try {
      if (await isCompatibleHadithExtra(db, contentVersion: contentVersion)) {
        return db;
      }
    } on Object {
      // Poskodeny alebo cudzi subor: ako keby balik nebol.
    }
    await db.close();
    return null;
  }

  /// `hints` je JSON pole retazcov; iny tvar = ziadne poznamky.
  @visibleForTesting
  static List<String> parseHints(String? json) {
    if (json == null) return const [];
    try {
      final v = jsonDecode(json);
      if (v is List<Object?> && v.every((e) => e is String)) {
        return List.unmodifiable(v.cast<String>());
      }
    } on FormatException {
      // nizsie
    }
    return const [];
  }
}
