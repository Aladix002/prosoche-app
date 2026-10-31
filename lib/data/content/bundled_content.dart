import 'package:flutter/services.dart';

/// Pribalena content.db v assetoch (`tool/bundle_content.sh`).
///
/// Db je pribalena ako `content.db.gz` (~9,5 MB namiesto ~32 MB v AAB),
/// rozbali sa pri prvom starte (`ContentPackService.ensureInstalled`).
abstract interface class BundledContentSource {
  /// Bajty `content.db.gz` (gzip).
  Future<Uint8List> loadDbArchive();

  /// `manifest.json` z toho isteho buildu (nepodpisany, v binarke), alebo
  /// `null`, ak nie je pribaleny.
  Future<Uint8List?> loadManifest();
}

/// [BundledContentSource] nad [AssetBundle].
class AssetBundledContentSource implements BundledContentSource {
  AssetBundledContentSource([AssetBundle? bundle])
    : _bundle = bundle ?? rootBundle;

  static const dbArchiveAsset = 'assets/content/content.db.gz';
  static const manifestAsset = 'assets/content/manifest.json';

  final AssetBundle _bundle;

  @override
  Future<Uint8List> loadDbArchive() async =>
      _bytes(await _bundle.load(dbArchiveAsset));

  @override
  Future<Uint8List?> loadManifest() async {
    try {
      return _bytes(await _bundle.load(manifestAsset));
    } on Object {
      // Chybajuci asset (FlutterError): verzia sa precita z db.
      return null;
    }
  }

  static Uint8List _bytes(ByteData data) =>
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}
