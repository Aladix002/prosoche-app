import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Rola kluca (docs/06 B.2). `root` podpisuje revokacie a v nudzi obsah,
/// `content` podpisuje manifest a remote config.
enum KeyRole {
  root,
  content;

  static KeyRole? fromWire(String? wire) => switch (wire) {
    'root' => KeyRole.root,
    'content' => KeyRole.content,
    _ => null,
  };
}

/// Role, ktore smu podpisat manifest a remote config.
const Set<KeyRole> kContentRoles = {KeyRole.content, KeyRole.root};

/// Role, ktore smu podpisat `revocations.json` (len root).
const Set<KeyRole> kRootOnly = {KeyRole.root};

/// Dovereny verejny Ed25519 kluc zapeceny v binarke.
@immutable
class TrustedKey {
  const TrustedKey(this.kid, this.publicKeyB64, this.role);

  final String kid;

  /// Raw 32 B verejny kluc v base64 (`sign.py pubkey`). Prazdny = kluc este
  /// nie je vygenerovany, ignoruje sa.
  final String publicKeyB64;
  final KeyRole role;
}

/// Produkcne kluce (= `prosoche-content/config/public_keys.json`).
///
/// Prazdne `publicKeyB64` znamena, ze majitel kluc este nevygeneroval
/// (PLAN_VYVOJA 6). Pred prvym releasom obsahu ich treba doplnit.
const kTrustedKeys = <TrustedKey>[
  TrustedKey('root-1', '', KeyRole.root),
  TrustedKey('content-2026a', '', KeyRole.content),
  TrustedKey('content-2027a', '', KeyRole.content),
];

/// Lokalny vyvojovy kluc `prosoche-content` (`keys/content-dev.pem`,
/// `dist/public_keys.json`). Doveruje mu len flavor `dev`.
const kDevTrustedKeys = <TrustedKey>[
  TrustedKey(
    'content-dev',
    '4hJ2HKlfOYpaITcjOquhTJB5vMa7wCqnIcsQ17igrgU=',
    KeyRole.content,
  ),
];

/// Overena mnozina klucov podla `kid`.
@immutable
class TrustedKeySet {
  /// Preskoci kluce s prazdnym `publicKeyB64`. Zly tvar alebo duplicitny
  /// `kid` je programatorska chyba ([ArgumentError]).
  factory TrustedKeySet(Iterable<TrustedKey> keys) {
    final byKid = <String, ResolvedKey>{};
    for (final k in keys) {
      if (k.publicKeyB64.trim().isEmpty) continue;
      final Uint8List bytes;
      try {
        bytes = base64Decode(k.publicKeyB64.trim());
      } on FormatException {
        throw ArgumentError.value(k.kid, 'kid', 'public key is not base64');
      }
      if (bytes.length != 32) {
        throw ArgumentError.value(k.kid, 'kid', 'public key must be 32 B');
      }
      if (byKid.containsKey(k.kid)) {
        throw ArgumentError.value(k.kid, 'kid', 'duplicate kid');
      }
      byKid[k.kid] = ResolvedKey(k.kid, k.role, bytes);
    }
    return TrustedKeySet._(Map.unmodifiable(byKid));
  }

  const TrustedKeySet._(this._byKid);

  final Map<String, ResolvedKey> _byKid;

  ResolvedKey? operator [](String kid) => _byKid[kid];

  Iterable<String> get kids => _byKid.keys;

  bool get isEmpty => _byKid.isEmpty;
}

/// Kluc s dekodovanymi bajtmi.
@immutable
class ResolvedKey {
  const ResolvedKey(this.kid, this.role, this.publicKey);

  final String kid;
  final KeyRole role;
  final Uint8List publicKey;
}
