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

## B. Fix before the first closed-test build

- [ ] Final reviewed `content.db` (today `dev_content=1`, all cards `draft`; prod
      build refuses dev content by design).
- [ ] Screenshots again with the final `content.db` (`store/screenshots/README.md`).
- [ ] Decide on cloud backup of `user.db` (journal) - see `data_safety.md`.

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
