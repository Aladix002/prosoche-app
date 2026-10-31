import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:sakina/core/result.dart';
import 'package:sakina/data/content/content_documents.dart';
import 'package:sqlite3/sqlite3.dart';

/// Kontrola a rozbalenie stiahnuteho `content.db.gz` (docs/06 B.2).
///
/// Nesulad velkosti alebo sha256 (aj poskodeny gzip) je
/// `ContentIntegrityFailed('sha256')` = `dbHashMismatch` vo vektoroch.
const dbHashMismatch = ContentIntegrityFailed('sha256');

/// sha256 a velkost stiahnuteho gz ([DbArchiveInfo.gzSha256], `gz_size`).
Future<Result<void>> checkArchive(File gz, DbArchiveInfo db) async {
  if (gz.lengthSync() != db.gzSize) return const Err(dbHashMismatch);
  final digest = await sha256.bind(gz.openRead()).first;
  return digest.toString() == db.gzSha256
      ? const Ok(null)
      : const Err(dbHashMismatch);
}

/// Pribalena db: s [db] (manifest) `gz_sha256`/`gz_size`, potom
/// rozbalenie s kontrolou sha256/size; bez manifestu [inflateUnchecked].
Future<Result<void>> unpackBundled(File gz, File out, DbArchiveInfo? db) async {
  if (db == null) return await inflateUnchecked(gz, out);
  return switch (await checkArchive(gz, db)) {
    Err(:final failure) => Err(failure),
    Ok() => await inflateArchive(gz, out, db),
  };
}

/// Rozbali [gz] do [out] a overi [DbArchiveInfo.sha256] a `size`. Pri
/// chybe [out] zmaze.
Future<Result<void>> inflateArchive(File gz, File out, DbArchiveInfo db) =>
    _inflate(gz, out, db);

/// Rozbali [gz] do [out] bez porovnania s manifestom (pribalena db bez
/// `manifest.json`; integritu overi az `ContentIntegrityChecker`).
/// Poskodeny gzip je [dbHashMismatch] a [out] sa zmaze.
Future<Result<void>> inflateUnchecked(File gz, File out) =>
    _inflate(gz, out, null);

Future<Result<void>> _inflate(File gz, File out, DbArchiveInfo? db) async {
  final sink = out.openWrite();
  final hash = _DigestSink();
  final hasher = sha256.startChunkedConversion(hash);
  var size = 0;
  var ok = true;
  try {
    await for (final chunk in gz.openRead().transform(gzip.decoder)) {
      size += chunk.length;
      if (db != null) {
        if (size > db.size) {
          ok = false;
          break;
        }
        hasher.add(chunk);
      }
      sink.add(chunk);
    }
  } on FormatException {
    ok = false;
  } finally {
    await sink.flush();
    await sink.close();
  }
  hasher.close();
  if (ok &&
      (db == null || (size == db.size && hash.value.toString() == db.sha256))) {
    return const Ok(null);
  }
  if (out.existsSync()) out.deleteSync();
  return const Err(dbHashMismatch);
}

/// Hodnoty [keys] z tabulky `meta` content.db cez sqlite3 (read-only, bez
/// drift). Chybajuci kluc v mape nie je.
Map<String, String> readContentMeta(File file, List<String> keys) {
  final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
  try {
    final marks = List.filled(keys.length, '?').join(', ');
    final rows = db.select(
      'SELECT key, value FROM meta WHERE key IN ($marks)',
      keys,
    );
    return {
      for (final r in rows)
        if (r.columnAt(1) != null) r.columnAt(0) as String: '${r.columnAt(1)}',
    };
  } finally {
    db.close();
  }
}

class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
