import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:sakina/core/logging/app_logger.dart';
import 'package:sakina/core/result.dart';
import 'package:sakina/data/content/bundled_content.dart';
import 'package:sakina/data/content/content_documents.dart';
import 'package:sakina/data/content/content_http_client.dart';
import 'package:sakina/data/content/content_pack_state.dart';
import 'package:sakina/data/content/db_archive.dart';
import 'package:sakina/data/content/remote_config_policy.dart';
import 'package:sakina/data/content/sem_ver.dart';
import 'package:sakina/data/content/signature_verifier.dart';
import 'package:sakina/data/content/trusted_keys.dart';
import 'package:sakina/data/db/content_db.dart';
import 'package:sakina/data/db/content_integrity.dart';

/// Vysledok [ContentPackService.checkForUpdate], ktory nie je chyba.
enum ContentUpdateOutcome {
  /// Nova db je overena a aktivna.
  updated,

  /// `content_version` manifestu nie je vyssia ako nainstalovana
  /// (anti-rollback, akceptuje sa len vyssia).
  notNewer,

  /// `min_app_version` manifestu je vyssia ako appka: obsah sa preskoci.
  appTooOld,

  /// Manifest ma inu `schema_version` ako [ContentDb.contractVersion].
  schemaIncompatible,

  /// Tato `content_version` uz opakovane nesedela so sha256 (docs/06 C.6).
  previouslyRejected,

  /// Kill-switch `content_auto_update` je vypnuty.
  disabledByRemoteConfig,

  /// Nie su nastavene URL (`CONTENT_REPO`), kontrola sa nerobi.
  notConfigured,
}

/// Odkial sa stahuju `manifest.json`, `remote_config.json`,
/// `revocations.json` a ich `.sig` (sakina-content
/// `config/release.yaml` `latest_urls`). `{file}` = nazov suboru.
@immutable
class ContentEndpoints {
  const ContentEndpoints(this.templates);

  /// Zrkadla pre repo `org/sakina-content`, v poradi skusania.
  factory ContentEndpoints.forRepo(String repo) => ContentEndpoints([
    'https://cdn.jsdelivr.net/gh/$repo@cdn/{file}',
    'https://raw.githubusercontent.com/$repo/cdn/{file}',
  ]);

  /// Repo z `--dart-define=CONTENT_REPO=org/sakina-content`; bez neho
  /// [none].
  factory ContentEndpoints.fromEnvironment() {
    const repo = String.fromEnvironment('CONTENT_REPO');
    return repo.isEmpty ? none : ContentEndpoints.forRepo(repo);
  }

  static const none = ContentEndpoints([]);

  final List<String> templates;

  bool get isEmpty => templates.isEmpty;

  List<Uri> urlsFor(String file) => [
    for (final t in templates) Uri.parse(t.replaceAll('{file}', file)),
  ];
}

/// Instalacia, kontrola integrity a aktualizacia content.db
/// (plan 6.3, 17.2, 17.3; docs/06 A.7, B.2, C.6).
///
/// Subory v adresari `directory`: `content.db` (aktivna), `state.json`,
/// docasne `content.db.gz.part` a `content.db.next`. Vsetky operacie idu
/// seriovo. Planovanie (workmanager) je mimo tejto triedy.
class ContentPackService {
  ContentPackService({
    required this._directory,
    required this._bundled,
    required this._http,
    required TrustedKeySet keys,
    required this._appVersion,
    required AppLogger logger,
    this._endpoints = ContentEndpoints.none,
    this._integrity = const ContentIntegrityChecker(),
    this._clock = const Clock(),
    this._delay = _sleep,
    this.remoteConfigInterval = const Duration(hours: 12),
    this.maxDocumentBytes = 1 << 20,
  }) : _verifier = SignatureVerifier(keys),
       _keys = keys,
       _log = logger;

  static const tag = 'content';
  static const dbFileName = 'content.db';

  /// Pauzy medzi pokusmi (docs/06 C.6, bez jitteru).
  static const backoff = [Duration(seconds: 2), Duration(seconds: 8)];
  static const attempts = 3;

  final Future<Directory> Function() _directory;
  final BundledContentSource _bundled;
  final ContentHttpClient _http;
  final SignatureVerifier _verifier;
  final TrustedKeySet _keys;
  final SemVer _appVersion;
  final AppLogger _log;
  final ContentEndpoints _endpoints;
  final ContentIntegrityChecker _integrity;
  final Clock _clock;
  final Future<void> Function(Duration) _delay;

  /// Remote config sa pri starte stahuje max 1x za tento interval (A.7).
  final Duration remoteConfigInterval;

  /// Limit pre manifest, config, revokacie a `.sig`.
  final int maxDocumentBytes;

  final _changes = StreamController<ContentPackState>.broadcast();
  final _swaps = StreamController<int>.broadcast();
  Future<void> _queue = Future.value();
  ContentPackState? _state;
  Directory? _dir;
  File? _verified;

  /// Kazda zmena perzistentneho stavu (disabled_ids, config, verzia).
  Stream<ContentPackState> get changes => _changes.stream;

  /// `content_version` po atomickej vymene db; otvorene spojenia treba
  /// zavriet a otvorit znova (`contentDatabaseProvider`).
  Stream<int> get swaps => _swaps.stream;

  static Future<void> _sleep(Duration d) => Future<void>.delayed(d);

  /// Aktualny perzistentny stav.
  Future<ContentPackState> state() => _serial(_loadState);

  /// Posledny overeny a neexpirovany remote config, alebo `null`
  /// (defaulty z kodu).
  RemoteConfig? remoteConfigOf(ContentPackState state) {
    final raw = state.remoteConfigRaw;
    if (raw == null) return null;
    final config = RemoteConfig.parse(raw).valueOrNull;
    if (config == null || config.isExpiredAt(_clock.now().toUtc())) {
      return null;
    }
    return config;
  }

  /// Kill-switch pre tuto verziu appky.
  RemoteConfigPolicy policyOf(ContentPackState state) =>
      RemoteConfigPolicy(remoteConfigOf(state), _appVersion);

  // ------------------------------------------------------------ instalacia

  /// Zabezpeci overenu aktivnu content.db a vrati jej subor.
  ///
  /// Dalsi start: len [_quickCheck] aktivnej db. Prvy start (alebo novsia
  /// pribalena verzia): rozbalenie
  /// `content.db.gz` z assetov, kontrola `gz_sha256` a sha256 podla
  /// pribaleneho manifestu a integrity (plan 17.3). Pri
  /// zlyhani integrity stiahnutej db navrat k pribalenej a hlasenie cez
  /// `AppLogger`. Vysledok sa pamata do dalsej vymeny db.
  Future<Result<File>> ensureInstalled() => _serial(_ensureInstalled);

  Future<Result<File>> _ensureInstalled() async {
    final verified = _verified;
    if (verified != null && verified.existsSync()) return Ok(verified);
    final dir = await _contentDir();
    final active = File(p.join(dir.path, dbFileName));
    final st = await _loadState();
    final bundledManifest = await _bundledManifest();
    final installed = st.installedVersion;
    final bundledNewer =
        bundledManifest != null &&
        (installed == null || bundledManifest.contentVersion > installed);
    if (active.existsSync() && installed != null && !bundledNewer) {
      final watch = Stopwatch()..start();
      // Plna kontrola integrity (17.3) prebehla pri instalacii; pri dalsom
      // starte len lacna kontrola meta (plna by cez drift synchronne citala
      // 6236 ajatov na hlavnom izolate, ~50-300 ms pri kazdom starte).
      final check = _quickCheck(active, installed);
      if (check is Ok<int>) {
        _log.debug(tag, 'active content.db verified', {
          'ms': watch.elapsedMilliseconds,
        });
        return Ok(_verified = active);
      }
      _log
        ..failure(tag, (check as Err<int>).failure)
        ..warn(tag, 'active content.db failed integrity, using bundled', {
          'content_version': installed,
        });
    }
    return await _installBundled(dir, active, bundledManifest);
  }

  Future<Result<File>> _installBundled(
    Directory dir,
    File active,
    ContentManifest? manifest,
  ) async {
    final watch = Stopwatch()..start();
    final Uint8List gz;
    try {
      gz = await _bundled.loadDbArchive();
    } on Object catch (e) {
      _log.error(tag, 'bundled content.db missing', error: e);
      return const Err(DbCorrupted('content'));
    }
    final part = File(p.join(dir.path, '$dbFileName.bundled.gz'));
    final next = File(p.join(dir.path, '$dbFileName.next'));
    final Result<void> inflated;
    try {
      await part.writeAsBytes(gz, flush: true);
      // Mimo hlavneho izolatu: rozbalenie a hash ~32 MB trva na
      // emulatore 1-3 s a pri prvom starte uz bezi onboarding.
      final info = manifest?.db;
      inflated = await Isolate.run(() => unpackBundled(part, next, info));
    } on FileSystemException catch (e) {
      _deleteQuietly(next);
      _log.error(tag, 'bundled content.db not written', error: e);
      return const Err(StorageFull());
    } finally {
      _deleteQuietly(part);
    }
    if (inflated case Err(:final failure)) {
      _log.failure(tag, failure);
      return Err(failure);
    }
    final check = await _checkDb(next);
    switch (check) {
      case Err(:final failure):
        _deleteQuietly(next);
        _log.failure(tag, failure);
        return Err(failure);
      case Ok(:final value):
        await next.rename(active.path);
        await _saveState(
          (await _loadState()).copyWith(
            installedVersion: value,
            origin: ContentDbOrigin.bundled,
          ),
        );
        _log.info(tag, 'bundled content installed', {
          'content_version': value,
          'ms': watch.elapsedMilliseconds,
        });
        return Ok(_verified = active);
    }
  }

  Future<ContentManifest?> _bundledManifest() async {
    final bytes = await _bundled.loadManifest();
    return bytes == null ? null : ContentManifest.parse(bytes).valueOrNull;
  }

  /// Uz nainstalovana db: citatelna sqlite, `schema_version` kontraktu
  /// a `content_version` zo `state.json` (bez drift, bez hashovania).
  Result<int> _quickCheck(File file, int installed) {
    try {
      final meta = readContentMeta(file, const [
        'schema_version',
        'content_version',
      ]);
      if (meta['schema_version'] != '${ContentDb.contractVersion}') {
        return const Err(ContentIntegrityFailed('schema_version'));
      }
      final cv = int.tryParse(meta['content_version'] ?? '') ?? 0;
      return cv == installed
          ? Ok(cv)
          : const Err(ContentIntegrityFailed('content_version'));
    } on Object catch (e) {
      _log.error(tag, 'content.db unreadable', error: e);
      return const Err(DbCorrupted('content'));
    }
  }

  /// Integrita (17.3) a `meta.content_version`. Ziadna vynimka nevybuchne
  /// von: poskodeny subor alebo novsia schema = [DbCorrupted].
  Future<Result<int>> _checkDb(File file) async {
    ContentDb? db;
    try {
      db = ContentDb.openReadOnly(file);
      final r = await _integrity.check(db);
      if (r case Err(:final failure)) return Err(failure);
      final cv = await db.contentMetaDao.metaValue('content_version');
      return Ok(int.tryParse(cv ?? '') ?? 0);
    } on Object catch (e) {
      _log.error(tag, 'content.db unreadable', error: e);
      return const Err(DbCorrupted('content'));
    } finally {
      await db?.close();
    }
  }

  // ------------------------------------------------------------ aktualizacia

  /// Stiahne revokacie, remote config a manifest; ak je obsah novsi
  /// a kompatibilny, stiahne, overi a atomicky vymeni db (plan 6.3).
  ///
  /// `disabled_ids` z platneho manifestu sa aplikuju hned, aj bez novej
  /// db. Pri akejkolvek chybe ostava stara db.
  Future<Result<ContentUpdateOutcome>> checkForUpdate() =>
      _serial(_checkForUpdate);

  Future<Result<ContentUpdateOutcome>> _checkForUpdate() async {
    if (_endpoints.isEmpty) {
      return const Ok(ContentUpdateOutcome.notConfigured);
    }
    await _refreshRevocations();
    await _refreshRemoteConfig(force: false);
    var st = await _loadState();
    if (!policyOf(st).isFeatureEnabled(RemoteFeature.contentAutoUpdate)) {
      return const Ok(ContentUpdateOutcome.disabledByRemoteConfig);
    }
    final fetched = await _fetchVerified('manifest.json', kContentRoles);
    final Uint8List bytes;
    switch (fetched) {
      case Err(:final failure):
        _log.failure(tag, failure);
        return Err(failure);
      case Ok(:final value):
        bytes = value;
    }
    final ContentManifest manifest;
    switch (ContentManifest.parse(bytes)) {
      case Err(:final failure):
        _log.failure(tag, failure);
        return Err(failure);
      case Ok(:final value):
        manifest = value;
    }
    st = await _applyDisabledIds(st, manifest);
    final skip = decide(
      manifest,
      appVersion: _appVersion,
      installedVersion: st.installedVersion,
      rejectedVersion: st.rejectedVersion,
    );
    if (skip != null) {
      _log.info(tag, 'content update skipped', {
        'code': skip.name,
        'content_version': manifest.contentVersion,
      });
      return Ok(skip);
    }
    return await _downloadAndSwap(manifest);
  }

  /// Rozhodnutie nad overenym manifestom; `null` = stiahnut. Poradie:
  /// `min_app_version`, anti-rollback, odmietnuta verzia, schema.
  static ContentUpdateOutcome? decide(
    ContentManifest manifest, {
    required SemVer appVersion,
    int? installedVersion,
    int? rejectedVersion,
  }) {
    if (manifest.minAppVersion > appVersion) {
      return ContentUpdateOutcome.appTooOld;
    }
    if (manifest.contentVersion <= (installedVersion ?? 0)) {
      return ContentUpdateOutcome.notNewer;
    }
    if (manifest.contentVersion == rejectedVersion) {
      return ContentUpdateOutcome.previouslyRejected;
    }
    if (manifest.schemaVersion != ContentDb.contractVersion) {
      return ContentUpdateOutcome.schemaIncompatible;
    }
    return null;
  }

  Future<ContentPackState> _applyDisabledIds(
    ContentPackState st,
    ContentManifest m,
  ) async {
    // Starsi (prehrany) manifest neprepise novsie disabled_ids.
    if (m.contentVersion < st.disabledIdsVersion) return st;
    if (m.contentVersion == st.disabledIdsVersion &&
        _sameSet(m.disabledIds, st.disabledIds)) {
      return st;
    }
    final next = st.copyWith(
      disabledIds: m.disabledIds,
      disabledIdsVersion: m.contentVersion,
    );
    await _saveState(next);
    return next;
  }

  Future<Result<ContentUpdateOutcome>> _downloadAndSwap(
    ContentManifest m,
  ) async {
    final dir = await _contentDir();
    final part = File(p.join(dir.path, '$dbFileName.gz.part'));
    final next = File(p.join(dir.path, '$dbFileName.next'));
    final active = File(p.join(dir.path, dbFileName));

    final downloaded = await _downloadArchive(m.db, part);
    if (downloaded case Err(:final failure)) {
      _deleteQuietly(part);
      _log.failure(tag, failure);
      if (failure is ContentIntegrityFailed) {
        await _reject(m.contentVersion);
      }
      return Err(failure);
    }
    final inflated = await inflateArchive(part, next, m.db);
    _deleteQuietly(part);
    final failure = switch (inflated) {
      Err(:final failure) => failure,
      Ok() => switch (await _checkDb(next)) {
        Err(:final failure) => failure,
        Ok(:final value) when value != m.contentVersion =>
          const ContentIntegrityFailed('content_version'),
        Ok() => null,
      },
    };
    if (failure != null) {
      _deleteQuietly(next);
      _log.failure(tag, failure);
      await _reject(m.contentVersion);
      return Err(failure);
    }
    // Atomicka vymena (rename v ramci adresara). Otvorene spojenia citaju
    // stary inode, kym ich provider nezavrie.
    await next.rename(active.path);
    _verified = active;
    await _saveState(
      (await _loadState()).copyWith(
        installedVersion: m.contentVersion,
        origin: ContentDbOrigin.downloaded,
      ),
    );
    _swaps.add(m.contentVersion);
    _log.info(tag, 'content updated', {'content_version': m.contentVersion});
    return const Ok(ContentUpdateOutcome.updated);
  }

  Future<void> _reject(int contentVersion) async => await _saveState(
    (await _loadState()).copyWith(rejectedVersion: contentVersion),
  );

  /// `url`, potom `fallback_url`; kazda max [attempts] pokusov. Nesulad
  /// sha256 sa skusi stiahnut este raz, potom stop (docs/06 C.6).
  Future<Result<void>> _downloadArchive(DbArchiveInfo db, File part) async {
    Result<void> last = const Err(Offline());
    var mismatches = 0;
    for (final url in [db.url, db.fallbackUrl]) {
      for (var attempt = 0; attempt < attempts; attempt++) {
        last = await _downloadOnce(url, part, db);
        final failure = switch (last) {
          Ok() => null,
          Err(:final failure) => failure,
        };
        if (failure == null) return last;
        _log.warn(tag, 'content.db download failed', {
          'code': failure.code,
          'attempt': attempt + 1,
        });
        if (failure is ContentIntegrityFailed) {
          if (++mismatches >= 2) return last;
          continue;
        }
        if (!failure.retryable) break;
        if (attempt < backoff.length) await _delay(backoff[attempt]);
      }
    }
    return last;
  }

  Future<Result<void>> _downloadOnce(
    Uri url,
    File part,
    DbArchiveInfo db,
  ) async {
    final sink = part.openWrite();
    var size = 0;
    var tooLarge = false;
    try {
      final res = await _http.get(url);
      if (res.statusCode != 200) {
        unawaited(res.body.drain<void>().catchError((Object _) {}));
        return Err(HttpStatus(res.statusCode));
      }
      await for (final chunk in res.body) {
        size += chunk.length;
        if (size > db.gzSize) {
          tooLarge = true;
          break;
        }
        sink.add(chunk);
      }
    } on ContentHttpException catch (e) {
      return Err(e.failure);
    } on FileSystemException {
      return const Err(StorageFull());
    } finally {
      await sink.close();
    }
    if (tooLarge) return const Err(dbHashMismatch);
    return await checkArchive(part, db);
  }

  // ---------------------------------------------------- revokacie, config

  /// Stiahne a overi `remote_config.json` (A.7). Bez [force] max 1x za
  /// [remoteConfigInterval]. Vracia platny config alebo `null`, ak sa
  /// nestahoval.
  Future<Result<RemoteConfig?>> refreshRemoteConfig({bool force = false}) =>
      _serial(() => _refreshRemoteConfig(force: force));

  Future<Result<RemoteConfig?>> _refreshRemoteConfig({
    required bool force,
  }) async {
    if (_endpoints.isEmpty) return const Ok(null);
    final st = await _loadState();
    final now = _clock.now().toUtc();
    final last = st.remoteConfigFetchedAt;
    if (!force && last != null && now.difference(last) < remoteConfigInterval) {
      return const Ok(null);
    }
    final fetched = await _fetchVerified('remote_config.json', kContentRoles);
    final Uint8List bytes;
    switch (fetched) {
      case Err(:final failure):
        _log.failure(tag, failure);
        return Err(failure);
      case Ok(:final value):
        bytes = value;
    }
    final RemoteConfig config;
    switch (RemoteConfig.parse(bytes)) {
      case Err(:final failure):
        _log.failure(tag, failure);
        return Err(failure);
      case Ok(:final value):
        config = value;
    }
    if (config.seq < st.remoteConfigSeq) {
      const f = SecurityFailure.rollback();
      _log.failure(tag, f);
      return const Err(f);
    }
    if (config.isExpiredAt(now)) {
      _log.warn(tag, 'remote config expired, ignored', {'to': config.seq});
      return const Ok(null);
    }
    await _saveState(
      st.copyWith(
        remoteConfigSeq: config.seq,
        remoteConfigRaw: bytes,
        remoteConfigFetchedAt: now,
      ),
    );
    return Ok(config);
  }

  /// `revocations.json` podpisany len root klucom. Revokovane `kid` sa
  /// pridaju natrvalo (aj zo starsieho suboru sa len pridavaju).
  Future<void> _refreshRevocations() async {
    final fetched = await _fetchVerified('revocations.json', kRootOnly);
    final Uint8List bytes;
    switch (fetched) {
      case Err(failure: HttpStatus(status: 404)):
        return;
      case Err(:final failure):
        _log.failure(tag, failure);
        return;
      case Ok(:final value):
        bytes = value;
    }
    final rootKids = [
      for (final kid in _keys.kids)
        if (_keys[kid]!.role == KeyRole.root) kid,
    ];
    switch (Revocations.parse(bytes, rootKids: rootKids)) {
      case Err(:final failure):
        _log.failure(tag, failure);
      case Ok(:final value):
        final st = await _loadState();
        final union = {...st.revokedKids, ...value.revoked};
        if (union.length == st.revokedKids.length &&
            value.seq <= st.revocationsSeq) {
          return;
        }
        await _saveState(
          st.copyWith(
            revokedKids: union,
            revocationsSeq: value.seq > st.revocationsSeq
                ? value.seq
                : st.revocationsSeq,
          ),
        );
        _log.warn(tag, 'signing keys revoked', {'to': value.seq});
    }
  }

  /// Subor a jeho `.sig` z prveho zrkadla, ktore odpovie a prejde
  /// overenim podpisu (revokovane kluce sa neprijmu).
  Future<Result<Uint8List>> _fetchVerified(
    String file,
    Set<KeyRole> roles,
  ) async {
    final payloads = _endpoints.urlsFor(file);
    final sigs = _endpoints.urlsFor('$file.sig');
    Result<Uint8List> last = const Err(Offline());
    for (var i = 0; i < payloads.length; i++) {
      final r = await _fetchAndVerify(payloads[i], sigs[i], roles);
      if (r case Err(:final failure)) {
        // 404 revokacii je bezny stav; ostatne do logu (bez URL).
        if (failure is! HttpStatus || failure.status != 404) {
          _log.warn(tag, 'document rejected', {
            'code': failure.code,
            'op': file,
          });
        }
        // Chyba overenia ma prednost pred sietovou chybou dalsieho zrkadla.
        if (failure is! NetworkFailure || last.isNetworkFailure) last = r;
        continue;
      }
      return r;
    }
    return last;
  }

  Future<Result<Uint8List>> _fetchAndVerify(
    Uri payloadUrl,
    Uri sigUrl,
    Set<KeyRole> roles,
  ) async {
    final Uint8List payload;
    switch (await _fetchDocument(payloadUrl)) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        payload = value;
    }
    final Uint8List sig;
    switch (await _fetchDocument(sigUrl)) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        sig = value;
    }
    final verified = await _verifier.verify(
      payload,
      sig,
      allowed: roles,
      revoked: (await _loadState()).revokedKids,
    );
    return switch (verified) {
      Ok() => Ok(payload),
      Err(:final failure) => Err(failure),
    };
  }

  /// Maly subor s retry podla docs/06 C.6.
  Future<Result<Uint8List>> _fetchDocument(Uri url) async {
    Result<Uint8List> last = const Err(Offline());
    for (var attempt = 0; attempt < attempts; attempt++) {
      last = await _getBytes(url);
      final failure = switch (last) {
        Ok() => null,
        Err(:final failure) => failure,
      };
      if (failure == null || !failure.retryable) return last;
      if (attempt < backoff.length) await _delay(backoff[attempt]);
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

  // ------------------------------------------------------------ pomocne

  Future<Directory> _contentDir() async {
    final dir = _dir ??= await _directory();
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  Future<ContentPackState> _loadState() async {
    if (_state case final s?) return s;
    final dir = await _contentDir();
    return _state = await ContentPackStateStore(
      File(p.join(dir.path, 'state.json')),
    ).load();
  }

  Future<void> _saveState(ContentPackState s) async {
    final dir = await _contentDir();
    await ContentPackStateStore(File(p.join(dir.path, 'state.json'))).save(s);
    _state = s;
    _changes.add(s);
  }

  Future<T> _serial<T>(Future<T> Function() op) {
    final result = _queue.then((_) => op());
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  static void _deleteQuietly(File f) {
    try {
      if (f.existsSync()) f.deleteSync();
    } on FileSystemException {
      // docasny subor, zmaze sa pri dalsom behu
    }
  }

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  Future<void> dispose() async {
    await _changes.close();
    await _swaps.close();
  }
}

extension on Result<Object?> {
  bool get isNetworkFailure => switch (this) {
    Err(:final failure) => failure is NetworkFailure,
    Ok() => false,
  };
}
