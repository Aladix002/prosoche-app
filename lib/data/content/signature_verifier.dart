import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:sakina/core/result.dart';
import 'package:sakina/data/content/trusted_keys.dart';

/// Overenie obalky `*.sig` (docs/06 B.2) nad surovymi bajtmi suboru.
///
/// Poradie kontrol je zavazne a zhodne so `sakina-content/pipeline/sign.py`
/// `verify_envelope` (testovacie vektory `test/fixtures/content_vectors`):
/// obalka nie je JSON objekt -> `alg` -> `kid` -> rola -> revokacia ->
/// `sig` nie je base64 s 64 B -> podpis.
class SignatureVerifier {
  SignatureVerifier(this._keys, {Ed25519? algorithm})
    : _ed = algorithm ?? Ed25519();

  static const alg = 'Ed25519';

  final TrustedKeySet _keys;
  final Ed25519 _ed;

  /// [Ok] s klucom, ktory podpisal, alebo [Err] so [SecurityFailure].
  Future<Result<ResolvedKey>> verify(
    Uint8List payload,
    Uint8List envelope, {
    Set<KeyRole> allowed = kContentRoles,
    Set<String> revoked = const {},
  }) async {
    final Object? env;
    try {
      env = jsonDecode(utf8.decode(envelope));
    } on FormatException {
      return const Err(SecurityFailure.malformedSignature());
    }
    if (env is! Map<String, Object?>) {
      return const Err(SecurityFailure.malformedSignature());
    }
    if (env['alg'] != alg) {
      return const Err(SecurityFailure.unknownAlgorithm());
    }
    final kid = env['kid'];
    final key = kid is String ? _keys[kid] : null;
    if (key == null) return const Err(SecurityFailure.unknownKey());
    if (!allowed.contains(key.role)) {
      return const Err(SecurityFailure.wrongKeyRole());
    }
    if (revoked.contains(key.kid)) {
      return const Err(SecurityFailure.revokedKey());
    }
    final sigB64 = env['sig'];
    final Uint8List sig;
    try {
      if (sigB64 is! String) throw const FormatException('sig');
      sig = base64.decode(sigB64);
    } on FormatException {
      return const Err(SecurityFailure.malformedSignature());
    }
    if (sig.length != 64) {
      return const Err(SecurityFailure.malformedSignature());
    }
    final ok = await _ed.verify(
      payload,
      signature: Signature(
        sig,
        publicKey: SimplePublicKey(key.publicKey, type: KeyPairType.ed25519),
      ),
    );
    return ok ? Ok(key) : const Err(SecurityFailure.badSignature());
  }
}
