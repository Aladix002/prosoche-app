ContentPackService (D-03): pribalena content.db, integrita, aktualizacie obsahu,
revokacie klucov a remote config (kill-switch).

- `content_pack_service.dart`: `ensureInstalled()` (rozbalenie
  `content.db.gz` z assetov pri prvom starte, kontrola integrity, navrat
  k pribalenej db), `checkForUpdate()`, `refreshRemoteConfig()`.
- `signature_verifier.dart` + `trusted_keys.dart`: Ed25519 obalka `.sig`
  (docs/06 B.2), poradie kontrol ako `sakina-content/pipeline/sign.py`.
- `content_documents.dart`: manifest, remote config, revokacie.
- `db_archive.dart`: overenie `gz_sha256` a `sha256`, rozbalenie.
- `content_providers.dart`: `contentDatabaseProvider`, `contentPackStateProvider`,
  `disabledContentIdsProvider`, `remoteConfigPolicyProvider`.
- Subory v `<app support>/content/`: `content.db`, `state.json`.
- Pribalenie db: `tool/bundle_content.sh` (assets/content je gitignored),
  pribaluje sa `content.db.gz` + `manifest.json` (gz_sha256, sha256).
- `hadith_extra_pack_service.dart` cita meta content.db cez sqlite3, nie
  cez druhy `ContentDb` (drift warning "created multiple times").
- Testovacie vektory: `test/fixtures/content_vectors/` (len testovacie kluce).
