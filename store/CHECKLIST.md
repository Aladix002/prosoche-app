# Checklist before the closed test (Google Play)

Base: TECHNICKY_PLAN 18.1 (+ 13, 18.3, 24.3), PLAN_VYVOJA M-11, M-14, M-18.
State: tag `rc0` (fe6da4e), 2026-10-30. [x] = done in code/repo, [ ] = open.
Owner = MAJITEL, Int = integration (shared files), Agent = a future task.

## A. Done in code (verify once on the release AAB)

- [x] targetSdk 36, compileSdk 36, minSdk 26 (`android/app/build.gradle.kts`)
- [x] No `QUERY_ALL_PACKAGES`, `USE_EXACT_ALARM`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`,
      AccessibilityService; `tool/check_manifest.sh` enforces it in CI
- [x] `lite` without FGS, usage access and overlay (`check_manifest.sh --edition lite` in `release-android.yml`)
- [x] Exact alarm: asked via settings with explanation, inexact fallback + banner (P-02)
- [x] PostHog and Sentry start only after explicit opt-in, both default off, 16+ required;
      opt-out wipes queues and IDs (`lib/data/observability/`)
- [x] Only HTTPS (`network_security_config.xml`)
- [x] "Delete all my data" in Settings > Privacy
- [x] Backup rules: only user.db and settings, only encrypted (`data_extraction_rules.xml`)
- [x] "Sources & licenses" screen from content.db `source` (Tanzil, QuranEnc, HadeethEnc,
      GeoNames CC BY 4.0) and open-source licenses incl. font OFL
- [x] Disclaimers (prayer times, translations, no fatwas) in Settings > About (docs/11 12)
- [x] Release workflow builds signed, obfuscated AAB `prodLite` and uploads to Play
- [x] Store texts EN, Data safety, privacy policy draft, IARC answers, countries, App access,
      permission texts: this folder (Q-04)

## B. Fix before the first closed-test build (Int / Agent)

- [x] Int (I-03): `release-android.yml` passes `PRIVACY_POLICY_URL`, `FEEDBACK_URL` and
      `CONTENT_REPO` as `--dart-define` from environment variables (`play-release`); the
      build fails while they are missing. `APP_VERSION` not needed (`FLUTTER_BUILD_NAME`).
- [ ] Owner: set the three variables in the `play-release` environment.
- [ ] Content: final reviewed `content.db` (rc0 has `dev_content=1`, 0 duas, 3 events).
- [x] I-03: "Report a problem" (card and Settings > About) shows the exact report text and
      the user shares a .txt via the share sheet; nothing is sent automatically (Data safety
      unchanged).
- [x] I-03: reminder texts say "may arrive up to 10 minutes late or more".
- [x] I-03: release APK has no `com.google.android.gms.permission.AD_ID` (`aapt2 dump
      permissions`, 2026-10-30).
- [x] I-03: `version: 0.9.0+2` (RC1). [ ] Release notes for RC1 (owner).
- [x] I-03: hadith card shows "Source: HadeethEnc.com ..., version ..." (docs/09), also in
      shared text and image.

## C. Owner (Play Console and outside)

Account and setup
- [ ] Developer account verified (M-01), **DSA trader/non-trader** declared (non-trader for v1)
- [ ] App created: name from `listing/en-US/title_options.md`, default language en-US,
      App/Free, category (suggest **Lifestyle**), contact e-mail
- [ ] Play App Signing on; upload key backed up outside the repo (M-12)
- [ ] Service account for `release-android.yml` (`PLAY_SERVICE_ACCOUNT_JSON`)

Privacy and services
- [ ] PostHog EU project (eu.posthog.com), turn on "Discard client IP data", set retention,
      sign DPA (M-10)
- [ ] Sentry project in **EU region** (DSN `*.de.sentry.io`), data scrubbing on, retention, DPA
- [ ] Short DPIA before enabling analytics (TECHNICKY_PLAN 24.3)
- [ ] Lawyer reviews `privacy_policy.md` (M-17); fill [MAJITEL], [EMAIL], retention; publish on
      Cloudflare Pages; URL into Play Console and into the workflow (B above)

App content forms (Policy > App content)
- [ ] Privacy policy URL
- [ ] Ads: No
- [ ] App access: `app_access.md`
- [ ] Content rating: `content_rating.md`
- [ ] Target audience: 16-17 and 18+
- [ ] Data safety: `data_safety.md` (required already for closed testing)
- [ ] News, Government, Financial, Health: No / none
- [ ] Advertising ID: No

Store listing
- [ ] EN texts from `listing/en-US/` (approve wording, M-14)
- [ ] App icon 512x512, feature graphic 1024x500
- [x] 8 EN screenshots per `screenshots/README.md` in `screenshots/en-US/` (I-03: devLite
      release, 1080x1920, RGB without alpha). Retake with the final reviewed content.db.
- [ ] AR, ID, UR, TR listings and screenshots after translators (K-04) - needed for
      production (M-14), not for the closed test. BN later.

Countries (M-18)
- [ ] Set per `countries.md` for closed testing and production: PK, ID, MY, TR, CN, IR, RU,
      BD and sanctioned countries OFF

Closed test (M-13)
- [ ] Google group with testers, 12+ opted in (aim 20+) living in enabled countries
- [ ] Closed track created, testers list attached, opt-in link sent
- [ ] Upload first AAB (`release-android.yml`), roll out to closed track; start date 14. 12.
- [ ] 14 days continuous with 12+ testers, then apply for production (29. 12.)
- [ ] Checklist 17.8 (notifications) on 2 physical devices for each build (M-16)

## D. v1.1 only (`prodFull`, app gate)

- [ ] B-03 adds prominent disclosure texts (usage access, overlay, FGS) to arb - missing at rc0
- [ ] FGS `specialUse` declaration + video (`permissions_declarations.md`)
- [ ] Listing section about Usage Access and overlay; Data safety re-check
- [ ] Checklist 17.7 (blocking) on the device matrix
