import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:sakina/core/logging/app_logger.dart';
import 'package:sakina/core/result.dart';
import 'package:sakina/data/content/bundled_content.dart';
import 'package:sakina/data/content/content_documents.dart';
import 'package:sakina/data/content/content_http_client.dart';
import 'package:sakina/data/content/content_pack_service.dart';
import 'package:sakina/data/content/db_archive.dart';
import 'package:sakina/data/content/hadith_extra_pack_status.dart';
import 'package:sakina/data/content/signature_verifier.dart';
import 'package:sakina/data/content/trusted_keys.dart';
import 'package:sakina/data/db/content_db.dart';
import 'package:sakina/data/db/hadith_extra_db.dart';
import 'package:sakina/data/db/hadith_extra_repository.dart' as db;
import 'package:sqlite3/sqlite3.dart';

export 'package:sakina/data/content/hadith_extra_pack_status.dart';

/// Stiahnuty balik nesedi s manifestom alebo s `meta.hadith_extra_sha256`
/// content.db (`packHashMismatch` vo vektoroch). Zahodi sa len balik.
const packHashMismatch = ContentIntegrityFailed('pack_sha256');

/// Manifest balik neobsahuje (`unknownPack` vo vektoroch) alebo ho
/// content.db neohlasuje.
const unknownPack = ContentIntegrityFailed('pack_unknown');

/// `PRAGMA user_version`, `schema_version` alebo `pack_id` balika nesedi
/// s appkou.
const packSchemaMismatch = ContentIntegrityFailed('pack_schema');

/// Balik (alebo manifest) patri k inej `content_version` ako aktivna
/// content.db.
const packContentVersionMismatch = ContentIntegrityFailed(
  'pack_content_version',
);

/// Co balik potrebuje z aktivnej content.db (`meta`).
@immutable
class HadithExtraBase {
  const HadithExtraBase({required this.contentVersion, this.sha256, this.size});

  /// `meta.content_version`.
  final int contentVersion;

  /// `meta.hadith_extra_sha256` a `hadith_extra_size` (rozbalena db).
  final String? sha256;
  final int? size;

  /// Ci content.db balik ohlasuje (fixture a stare db maju nuly).
  bool get announced =>
      sha256 != null &&
      RegExp(r'^[0-9a-f]{64}$').hasMatch(sha256!) &&
      sha256 != '0' * 64 &&
      (size ?? 0) > 0;
}

/// `PRAGMA user_version` a `meta` rozbaleneho balika.
@immutable
class HadithExtraPackMeta {
  const HadithExtraPackMeta({required this.userVersion, required this.meta});

  final int userVersion;
  final Map<String, String> meta;
}

typedef HadithExtraInspector = Future<HadithExtraPackMeta> Function(File file);

/// Precita [HadithExtraPackMeta] cez sqlite3 (read-only).
Future<HadithExtraPackMeta> readHadithExtraMeta(File file) async {
  final db = sqlite3.open(file.path, mode: OpenMode.readOnly);
  try {
    final version = db.select('PRAGMA user_version').first.columnAt(0);
    return HadithExtraPackMeta(
      userVersion: version is int ? version : -1,
      meta: {
        for (final r in db.select('SELECT key, value FROM meta'))
          r.columnAt(0) as String: '${r.columnAt(1)}',
      },
    );
  } finally {
    db.close();
  }
}

/// Stiahnutie a otvorenie volitelneho balika `hadith_extra.db` na
/// poziadanie (D-05, TECHNICKY_PLAN 23.1 bod 5).
///
/// Manifest: overeny `manifest.json` z CDN (podpis, revokacie ako D-03),
/// inak pribaleny manifest; pouzije sa ten s `content_version` aktivnej
/// content.db. Poradie kontrol ako `sakina-content/pipeline/sign.py`:
/// obalka -> `invalidManifest` -> `unknownPack` -> `packHashMismatch`;
/// potom `meta.hadith_extra_sha256/size` content.db, `PRAGMA user_version`
/// a `meta.content_version` balika. Az potom atomicky rename na
/// `<content dir>/hadith_extra.db` a [db.FileHadithExtraRepository.reload].
///
/// Pri akejkolvek chybe ostava content.db aj predchadzajuci subor balika.
/// Po aktualizacii content.db (`ContentPackService.swaps`) sa balik
/// znova vyhodnoti; ak nesedi, je [HadithExtraStale] a [repository] vracia
/// `null`.
///
/// Subory: `hadith_extra.db`, `hadith_extra.sha256` (overeny sha256, aby
/// sa 25 MB nehashovalo pri kazdom starte), docasne `.gz.part` a `.next`.
class HadithExtraPackService {
  HadithExtraPackService({
    required this._directory,
    required this._content,
    required this._http,
    required TrustedKeySet keys,
    required this._bundled,
    required AppLogger logger,
    this._endpoints = ContentEndpoints.none,
    this._inspect = readHadithExtraMeta,
    this._delay = _sleep,
    this.maxDocumentBytes = 1 << 20,
  }) : _verifier = SignatureVerifier(keys),
       _log = logger {
    _swapSub = _content.swaps.listen((_) => unawaited(refresh()));
  }

  static const tag = 'hadith_extra';
  static const String packId = HadithExtraDb.packId;
  static const fileName = 'hadith_extra.db';
  static const markerName = 'hadith_extra.sha256';

  final Future<Directory> Function() _directory;
  final ContentPackService _content;
  final ContentHttpClient _http;
  final SignatureVerifier _verifier;
  final BundledContentSource _bundled;
  final AppLogger _log;
  final ContentEndpoints _endpoints;
  final HadithExtraInspector _inspect;
  final Future<void> Function(Duration) _delay;

  /// Limit pre `manifest.json` a `.sig`.
  final int maxDocumentBytes;

  final _changes = StreamController<HadithExtraPackStatus>.broadcast();
  late final StreamSubscription<int> _swapSub;
  Future<void> _queue = Future.value();
  Future<HadithExtraPackStatus>? _init;
  Future<Result<void>>? _inflight;
  HadithExtraPackStatus? _status;
  Directory? _dir;
  db.FileHadithExtraRepository? _files;

  static Future<void> _sleep(Duration d) => Future<void>.delayed(d);

  /// Kazda zmena stavu (aj priebeh stahovania).
  Stream<HadithExtraPackStatus> get changes => _changes.stream;

  /// Posledny znamy stav; `null`, kym sa prvy raz nevyhodnoti.
  HadithExtraPackStatus? get current => _status;

  /// Aktualny stav (prvy dotaz vyhodnoti subor na disku).
  Future<HadithExtraPackStatus> status() async {
    await (_init ??= refresh());
    return _status!;
  }

  /// Znova vyhodnoti balik voci aktivnej content.db.
  Future<HadithExtraPackStatus> refresh() => _serial(() async {
    final base = await _readBase();
    return switch (base) {
      Err(:final failure) => await _fail(failure),
      Ok(:final value) => await _set(await _statusFor(value)),
    };
  });

  /// Vysvetlivky z balika; `null`, kym balik nie je [HadithExtraReady].
  /// Kazde volanie vrati novu instanciu (provider ju po zmene stavu
  /// vymeni, aby sa zahodili ulozene `null` vysledky).
  db.HadithExtraRepository get repository => _GatedRepository(this);

  /// Stiahne, overi a nainstaluje balik. Ak je uz [HadithExtraReady],
  /// nic nerobi. Subezne volania zdielaju jeden beh.
  Future<Result<void>> download() {
    // Prve vyhodnotenie musi prebehnut pred stahovanim, nie po nom.
    _init ??= refresh();
    return _inflight ??= _serial(_download)
        .whenComplete(() => _inflight = null);
  }

  /// Zmaze balik (napr. z nastaveni). content.db ostava.
  Future<HadithExtraPackStatus> delete() {
    _init ??= refresh();
    return _serial(() async {
      await _closeFiles();
      final dir = await _contentDir();
      for (final name in [
        fileName,
        markerName,
        '$fileName.gz.part',
        '$fileName.next',
      ]) {
        _deleteQuietly(File(p.join(dir.path, name)));
      }
      _log.info(tag, 'pack deleted');
      final base = await _readBase();
      return switch (base) {
        Err(:final failure) => await _fail(failure),
        Ok(:final value) => await _set(await _statusFor(value)),
      };
    });
  }

  // ------------------------------------------------------------ stav

  Future<HadithExtraPackStatus> _statusFor(HadithExtraBase base) async {
    final dir = await _contentDir();
    final pack = File(p.join(dir.path, fileName));
    if (!base.announced) return const HadithExtraUnavailable();
    if (!pack.existsSync()) {
      _deleteQuietly(File(p.join(dir.path, markerName)));
      return const HadithExtraNotDownloaded();
    }
    if (await _matches(pack, base)) {
      if (_files?.contentVersion != base.contentVersion) {
        await _openFiles(pack, base);
      }
      return HadithExtraReady(sizeBytes: base.size!);
    }
    return const HadithExtraStale();
  }

  /// Velkost a sha256 podla content.db; sha256 sa overi raz a zapamata
  /// (aj pre subor nahraty cez `tool/push_hadith_extra.sh`).
  Future<bool> _matches(File pack, HadithExtraBase base) async {
    if (pack.lengthSync() != base.size) return false;
    final marker = File(p.join(pack.parent.path, markerName));
    try {
      if (marker.existsSync() &&
          (await marker.readAsString()).trim() == base.sha256) {
        return true;
      }
      final digest = await sha256.bind(pack.openRead()).first;
      if (digest.toString() != base.sha256) return false;
      await _writeMarker(marker, base.sha256!);
      return true;
    } on FileSystemException {
      return false;
    }
  }

  Future<HadithExtraPackStatus> _set(HadithExtraPackStatus s) async {
    if (!s.isReady) await _closeFiles();
    _emit(s);
    return s;
  }

  Future<HadithExtraPackStatus> _fail(AppFailure f) {
    if (f is NetworkFailure) {
      _log.warn(tag, 'pack download failed', {'code': f.code});
    } else {
      _log.failure(tag, f);
    }
    return _set(HadithExtraFailed(f));
  }

  void _emit(HadithExtraPackStatus s) {
    if (s == _status) return;
    _status = s;
    if (!_changes.isClosed) _changes.add(s);
  }

  Future<void> _openFiles(File pack, HadithExtraBase base) async {
    await _closeFiles();
    _files = db.FileHadithExtraRepository(
      pack,
      contentVersion: base.contentVersion,
    );
  }

  Future<void> _closeFiles() async {
    final files = _files;
    _files = null;
    await files?.reload();
  }

  // ------------------------------------------------------------ content.db

  Future<Result<HadithExtraBase>> _readBase() async {
    final File file;
    switch (await _content.ensureInstalled()) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        file = value;
    }
    try {
      // Raw sqlite3 namiesto druheho ContentDb: drift by pri otvorenom
      // contentDatabaseProvider varoval "created multiple times".
      final meta = readContentMeta(file, const [
        'content_version',
        'hadith_extra_sha256',
        'hadith_extra_size',
      ]);
      return Ok(
        HadithExtraBase(
          contentVersion: int.tryParse(meta['content_version'] ?? '') ?? 0,
          sha256: meta['hadith_extra_sha256'],
          size: int.tryParse(meta['hadith_extra_size'] ?? ''),
        ),
      );
    } on Object catch (e) {
      _log.error(tag, 'content.db meta unreadable', error: e);
      return const Err(DbCorrupted('content'));
    }
  }

  // ------------------------------------------------------------ stiahnutie

  Future<Result<void>> _download() async {
    final HadithExtraBase base;
    switch (await _readBase()) {
      case Err(:final failure):
        await _fail(failure);
        return Err(failure);
      case Ok(:final value):
        base = value;
    }
    final existing = await _statusFor(base);
    if (existing is HadithExtraReady) {
      await _set(existing);
      return const Ok(null);
    }
    if (!base.announced) return await _abort(unknownPack);
    _emit(const HadithExtraDownloading());

    final ContentPackInfo pack;
    switch (await _manifestFor(base)) {
      case Err(:final failure):
        return await _abort(failure);
      case Ok(value: final m):
        final info = m.packs[packId];
        if (info == null) return await _abort(unknownPack);
        pack = info;
    }
    if (pack.schemaVersion != HadithExtraDb.contractVersion) {
      return await _abort(packSchemaMismatch);
    }
    // Manifest musi ohlasovat presne ten balik, ktory pozna content.db.
    if (pack.archive.sha256 != base.sha256 || pack.archive.size != base.size) {
      return await _abort(packHashMismatch);
    }

    final dir = await _contentDir();
    final part = File(p.join(dir.path, '$fileName.gz.part'));
    final next = File(p.join(dir.path, '$fileName.next'));
    final target = File(p.join(dir.path, fileName));
    _emit(HadithExtraDownloading(totalBytes: pack.archive.gzSize));
    final downloaded = await _downloadArchive(pack.archive, part);
    if (downloaded case Err(:final failure)) {
      _deleteQuietly(part);
      return await _abort(
        failure is ContentIntegrityFailed ? packHashMismatch : failure,
      );
    }
    _emit(
      HadithExtraDownloading(
        receivedBytes: pack.archive.gzSize,
        totalBytes: pack.archive.gzSize,
      ),
    );
    final inflated = await inflateArchive(part, next, pack.archive);
    _deleteQuietly(part);
    final failure = switch (inflated) {
      Err() => packHashMismatch,
      Ok() => await _checkPack(next, pack, base),
    };
    if (failure != null) {
      _deleteQuietly(next);
      return await _abort(failure);
    }
    // Atomicka vymena v ramci adresara; otvorene spojenie sa zavrie.
    await _closeFiles();
    try {
      await next.rename(target.path);
      await _writeMarker(
        File(p.join(dir.path, markerName)),
        pack.archive.sha256,
      );
    } on FileSystemException {
      _deleteQuietly(next);
      return await _abort(const StorageFull());
    }
    await _openFiles(target, base);
    _emit(HadithExtraReady(sizeBytes: pack.archive.size));
    _log.info(tag, 'pack installed', {'content_version': base.contentVersion});
    return const Ok(null);
  }

  Future<Result<void>> _abort(AppFailure f) async {
    await _fail(f);
    return Err(f);
  }

  /// Kontroly rozbalenej db (sha256 a velkost voci manifestu uz presli).
  Future<AppFailure?> _checkPack(
    File file,
    ContentPackInfo pack,
    HadithExtraBase base,
  ) async {
    final HadithExtraPackMeta meta;
    try {
      meta = await _inspect(file);
    } on Object catch (e) {
      _log.error(tag, 'pack unreadable', error: e);
      return packHashMismatch;
    }
    if (meta.userVersion != pack.schemaVersion ||
        meta.meta['schema_version'] != '${pack.schemaVersion}' ||
        meta.meta['pack_id'] != packId ||
        meta.meta['base_schema_version'] != '${ContentDb.contractVersion}') {
      return packSchemaMismatch;
    }
    if (meta.meta['content_version'] != '${base.contentVersion}') {
      return packContentVersionMismatch;
    }
    return null;
  }

  /// Manifest s `content_version` aktivnej content.db: najprv overeny
  /// z CDN, potom pribaleny. Ak ziadny nesedi, chyba z CDN (napr.
  /// `badSignature`), inak [packContentVersionMismatch].
  Future<Result<ContentManifest>> _manifestFor(HadithExtraBase base) async {
    final remote = _endpoints.isEmpty ? null : await _fetchManifest();
    final bundledBytes = await _bundled.loadManifest();
    final bundled = bundledBytes == null
        ? null
        : ContentManifest.parse(bundledBytes).valueOrNull;
    final matching = [
      ?remote?.valueOrNull,
      ?bundled,
    ].where((m) => m.contentVersion == base.contentVersion).toList();
    if (matching.isNotEmpty) {
      return Ok(
        matching.firstWhere(
          (m) => m.packs.containsKey(packId),
          orElse: () => matching.first,
        ),
      );
    }
    if (remote case Err(:final failure)) return Err(failure);
    return const Err(packContentVersionMismatch);
  }

  /// `manifest.json` a `.sig` z prveho zrkadla, ktore prejde overenim.
  Future<Result<ContentManifest>> _fetchManifest() async {
    final payloads = _endpoints.urlsFor('manifest.json');
    final sigs = _endpoints.urlsFor('manifest.json.sig');
    Result<ContentManifest> last = const Err(Offline());
    for (var i = 0; i < payloads.length; i++) {
      final r = await _fetchDocument(payloads[i]).then2(
        (payload) =>
            _fetchDocument(sigs[i])
                .then2((sig) => _verifyManifest(payload, sig)),
      );
      switch (r) {
        case Ok():
          return r;
        case Err(:final failure):
          _log.warn(tag, 'manifest rejected', {'code': failure.code});
          // Chyba overenia ma prednost pred sietovou chybou zrkadla.
          if (failure is! NetworkFailure || _isNetwork(last)) last = r;
      }
    }
    return last;
  }

  Future<Result<ContentManifest>> _verifyManifest(
    Uint8List payload,
    Uint8List sig,
  ) async {
    final verified = await _verifier.verify(
      payload,
      sig,
      revoked: (await _content.state()).revokedKids,
    );
    if (verified case Err(:final failure)) return Err(failure);
    return ContentManifest.parse(payload);
  }

  /// Maly subor s retry podla docs/06 C.6.
  Future<Result<Uint8List>> _fetchDocument(Uri url) async {
    Result<Uint8List> last = const Err(Offline());
    for (var attempt = 0; attempt < ContentPackService.attempts; attempt++) {
      last = await _getBytes(url);
      final failure = _failureOf(last);
      if (failure == null || !failure.retryable) return last;
      await _backoff(attempt);
    }
    return last;
  }

  Future<Result<Uint8List>> _getBytes(Uri url) async {
    try {
      final res = await _http.get(url);
      if (res.statusCode != 200) {
        unawaited(res.body.drain<void>().catchError((Object _) {}));
        return Err(HttpStatus(res.statusCode));
      }
      final out = BytesBuilder(copy: false);
      await for (final chunk in res.body) {
        out.add(chunk);
        if (out.length > maxDocumentBytes) {
          return const Err(ContentIntegrityFailed('size'));
        }
      }
      return Ok(out.takeBytes());
    } on ContentHttpException catch (e) {
      return Err(e.failure);
    }
  }

  /// `url`, potom `fallback_url`; kazda max [ContentPackService.attempts]
  /// pokusov. Nesulad sha256 sa skusi este raz, potom stop (ako D-03).
  Future<Result<void>> _downloadArchive(DbArchiveInfo a, File part) async {
    Result<void> last = const Err(Offline());
    var mismatches = 0;
    for (final url in [a.url, a.fallbackUrl]) {
      for (var attempt = 0; attempt < ContentPackService.attempts; attempt++) {
        last = await _downloadOnce(url, part, a);
        final failure = _failureOf(last);
        if (failure == null) return last;
        _log.warn(tag, 'pack download attempt failed', {
          'code': failure.code,
          'attempt': attempt + 1,
        });
        if (failure is ContentIntegrityFailed) {
          if (++mismatches >= 2) return last;
          continue;
        }
        if (!failure.retryable) break;
        await _backoff(attempt);
      }
    }
    return last;
  }

  Future<Result<void>> _downloadOnce(
    Uri url,
    File part,
    DbArchiveInfo a,
  ) async {
    IOSink? sink;
    var size = 0;
    var percent = -1;
    var tooLarge = false;
    try {
      sink = part.openWrite();
      final res = await _http.get(url);
      if (res.statusCode != 200) {
        unawaited(res.body.drain<void>().catchError((Object _) {}));
        return Err(HttpStatus(res.statusCode));
      }
      await for (final chunk in res.body) {
        size += chunk.length;
        if (size > a.gzSize) {
          tooLarge = true;
          break;
        }
        sink.add(chunk);
        final now = size * 100 ~/ a.gzSize;
        if (now != percent) {
          percent = now;
          _emit(
            HadithExtraDownloading(receivedBytes: size, totalBytes: a.gzSize),
          );
        }
      }
    } on ContentHttpException catch (e) {
      return Err(e.failure);
    } on FileSystemException {
      return const Err(StorageFull());
    } finally {
      await sink?.close();
    }
    if (tooLarge) return const Err(dbHashMismatch);
    return await checkArchive(part, a);
  }

  Future<void> _backoff(int attempt) async {
    if (attempt < ContentPackService.backoff.length) {
      await _delay(ContentPackService.backoff[attempt]);
    }
  }

  // ------------------------------------------------------------ pomocne

  Future<Directory> _contentDir() async {
    final dir = _dir ??= await _directory();
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  static Future<void> _writeMarker(File marker, String sha) async {
    final tmp = File('${marker.path}.tmp');
    await tmp.writeAsString(sha, flush: true);
    await tmp.rename(marker.path);
  }

  Future<T> _serial<T>(Future<T> Function() op) {
    final result = _queue.then((_) => op());
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  static AppFailure? _failureOf(Result<Object?> r) => switch (r) {
    Ok() => null,
    Err(:final failure) => failure,
  };

  static bool _isNetwork(Result<Object?> r) => _failureOf(r) is NetworkFailure;

  static void _deleteQuietly(File f) {
    try {
      if (f.existsSync()) f.deleteSync();
    } on FileSystemException {
      // docasny subor, zmaze sa pri dalsom behu
    }
  }

  Future<void> dispose() async {
    await _swapSub.cancel();
    await _closeFiles();
    await _changes.close();
  }
}

/// [db.HadithExtraRepository], ktory cita len [HadithExtraReady] balik.
class _GatedRepository implements db.HadithExtraRepository {
  _GatedRepository(this._service);

  final HadithExtraPackService _service;

  @override
  Future<db.HadithExplanation?> explanationFor(
    int hadithId,
    String lang,
  ) async {
    if (!(await _service.status()).isReady) return null;
    return await _service._files?.explanationFor(hadithId, lang);
  }
}
