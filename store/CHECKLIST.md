# Checklist before the closed test (Google Play)

> **DRAFT (I-01) na kontrolu majitelom.**

## A. Done in code (verify once on the release AAB)

- [x] No exact alarms, no location, no `QUERY_ALL_PACKAGES`, no
      `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, no AccessibilityService
      (`tool/check_manifest.sh` on the release manifest, I-01).
- [x] Analytics and crash reports opt-in, default off, 16+ confirmation.
- [x] Journal never in analytics, crash reports or logs.
- [x] Reminders inexact; evening reflection reminder opt-in (default off).
- [x] No "Project Gutenberg" text in the app or store texts.

### Release build (I-01, lokalne)

- `flutter build appbundle --release --flavor prodFull` aj `prodLite` s
  `--obfuscate --split-debug-info=build/symbols` a dart-defines ako v
  `.github/workflows/release-android.yml` (hodnoty zastupne) prejde
  kompilaciou. Bez `android/key.properties` je AAB podpisany **debug** klucom
  (len lokalne, do Play nejde; CI ma `PROSOCHE_REQUIRE_RELEASE_SIGNING=true`).
- `tool/check_manifest.sh` OK pre `full` aj `lite`.
- Ocakavane: prod flavor odmietne dev `content.db` (`meta.dev_content=1`,
  `ContentIntegrityChecker(allowDevContent: false)`, podpis len
  `kTrustedKeys` bez dev kluca). Pribalena dev db sa v prod builde
  nenainstaluje, appka ukaze chybu obsahu. Pred releasom treba finalnu
  podpisanu db bez `dev_content`.
- Flutter hlasi "unobfuscated DWARF debugging information ... use --strip";
  zvazit `--strip` (alebo overit, ze symboly v `build/symbols` staci).

## B. Fix before the first closed-test build

- [ ] Final reviewed `content.db` (today `dev_content=1`, all cards `draft`; prod
      build refuses dev content by design).
- [ ] Screenshots again with the final `content.db` (`store/screenshots/README.md`).
- [x] Cloud backup of the journal: excluded (C-02, separate `journal.db`) - see `data_safety.md`.

## C. Owner (Play Console and outside)

- [ ] Upload key and Play App Signing; `android/key.properties` only locally / CI secrets.
- [ ] Variables `PRIVACY_POLICY_URL`, `FEEDBACK_URL`, `CONTENT_REPO` in the
      `play-release` environment.
- [ ] Publish the privacy policy after legal review; fill [MAJITEL], [EMAIL], retention.
- [ ] PostHog: EU project, "Discard client IP data"; Sentry: EU region, short retention.
- [ ] Listing texts (`listing/en-US/`), icon 512, feature graphic 1024 x 500.
- [ ] Data safety form from `data_safety.md`; content rating; target audience 13+.

## D. v1.1 only (`prodFull`, app gate)

- [ ] FGS special use declaration and video (`permissions_declarations.md`).
- [ ] Listing addition about Usage access and Display over other apps.
