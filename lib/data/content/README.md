ContentPackService: pribalena content.db v1 (prosoche-content), integrita
a aktualizacie obsahu podla kontraktu `prosoche-content/docs/CONTENT_CONTRACT.md`.

- `content_pack_service.dart`: `ensureInstalled()` (rozbalenie
  `content.db.gz` z assetov pri prvom starte, kontrola integrity, navrat
  k pribalenej db), `checkForUpdate()`.
- `signature_verifier.dart` + `trusted_keys.dart`: Ed25519 obalka `.sig`
  (docs/06 B.2), poradie kontrol ako `prosoche-content/pipeline/sign.py`.
- `content_documents.dart`: manifest v1 (`sections_sha256`, `dev_content`;
  bez `packs`). `RemoteConfig` je len tvar pre buduci kill-switch, v1 sa
  nestahuje (ani `revocations.json`).
- `db_archive.dart`: overenie `gz_sha256` a `sha256`, rozbalenie.
- `content_providers.dart`: `contentDatabaseProvider`, `contentPackStateProvider`,
  `disabledContentIdsProvider`, `remoteConfigPolicyProvider` (defaulty).
- Subory v `<app support>/content/`: `content.db`, `state.json`.
- Pribalenie db: `tool/bundle_content.sh` (assets/content je gitignored),
  pribaluje sa `content.db.gz` + `manifest.json` (gz_sha256, sha256).
- Integrita (`lib/data/db/content_integrity.dart`): `schema_version`,
  `dev_content` (prod), neprazdne sekcie a karty, `section.sha256` kazdej
  sekcie a `meta.sections_sha256` (aj proti manifestu).
- Testovacie vektory: `test/fixtures/content_vectors/` (kopia
  `prosoche-content/tests/vectors/`, len verejne kluce).
