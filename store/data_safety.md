# Play Console: Data safety (Prosoche, app.prosoche, v1.0 `prodLite`)

> **DRAFT (I-01) na kontrolu majitelom.** Stav kodu: vetva `feat/I-01`, 2026-10-31.
> Znova skontrolovat pri kazdej zmene `lib/data/observability/analytics.dart`
> (allowlist eventov), konfiguracie PostHog/Sentry alebo `pubspec.yaml`.

Rule used (Play help 10787469): data that never leaves the device is not "collected".
Optional (opt-in) collection is declared as optional. Data processed by a service provider
on our behalf (PostHog, Sentry) is "collected", not "shared".

## 1. Data collection and security

| Question | Answer | Evidence |
|---|---|---|
| Does your app collect or share any of the required user data types? | **Yes** | PostHog + Sentry, only after opt-in (below) |
| Is all of the user data collected by your app encrypted in transit? | **Yes** | HTTPS only: `network_security_config.xml` (cleartext off); PostHog host `https://eu.i.posthog.com` (`lib/data/observability/posthog_transport.dart`); Sentry HTTPS DSN |
| Do you provide a way for users to request that their data is deleted? | **Yes** | In app: turning off "Anonymous usage" / "Crash reports" or "Delete all my data" stops collection and wipes local queues and anonymous IDs (`lib/app/data_deletion_wiring.dart`, `lib/app/observability_wiring.dart`). Server copies: e-mail [EMAIL] (privacy policy 7). |
| Account creation | **My app does not allow users to create an account** | No login in `lib/` |
| Independent security review (MASA) | No | - |

## 2. Data types

Only these rows get a tick. Everything else: **not collected**.

| Play category > type | Collected | Shared | Ephemeral | Required or optional | Purposes | Source in code |
|---|---|---|---|---|---|---|
| App activity > **App interactions** | Yes | No | No | **Optional** | **Analytics** | PostHog after "Anonymous usage" opt-in. Events sent: `onboarding_step`, `onboarding_completed`, `screen_view` (route name only), `permission_result`, `daily_set_started`, `daily_set_completed`, `gate_apps_selected` (count only, `full`). Allowlist `AnalyticsSchema.events`. |
| App info and performance > **Crash logs** | Yes | No | No | **Optional** | **App functionality**, **Analytics** | Sentry after "Crash reports" opt-in (`lib/data/observability/sentry_crash_reporter.dart`) |
| App info and performance > **Diagnostics** | Yes | No | No | **Optional** | **App functionality**, **Analytics** | Sentry session health, OS/device model, scrubbed breadcrumbs (`scrubEvent`) |
| Device or other IDs > **Device or other IDs** | Yes | No | No | **Optional** | **Analytics**, **App functionality** | Random ID of the PostHog SDK and Sentry installation ID; deleted on opt-out. Not Android ID, not advertising ID, not our `install_id`. |

Super properties on every PostHog event: only `app_version`, `content_version`, `locale`
(app language), `flavor`.

## 3. Declared as NOT collected (and why)

| Data | Why not | Evidence |
|---|---|---|
| Personal info > Other info, **journal** (evening/morning answers, notes) | Stored only in local `journal.db`, which is excluded from Android cloud backup and device transfer; never in analytics, crash reports or logs. Export is user-initiated via the share sheet. | `lib/data/db/journal_db.dart`, `lib/data/db/daos/journal_dao.dart`, `data_extraction_rules.xml`, `AnalyticsSchema`, `scrubEvent` |
| Saved cards, bookmarks, reading position, intention, birth year (memento mori) | Local only. Analytics carries no content IDs or text. | `lib/data/db/` |
| Location | Not used. No location permission in any flavor (`tool/check_manifest.sh`). GeoIP disabled on PostHog events. | manifests, `posthogGuard` |
| Personal info (name, e-mail, user IDs) | No account, no form. `sendDefaultPii=false` in Sentry. | `configureSentry` |
| Installed apps / app activity in other apps | v1.0 `lite` has no gate. v1.1 `full`: usage access is read on device only for the apps the user chose; gate history stays in local `user.db`; nothing sent. No `QUERY_ALL_PACKAGES`. | `android/app/src/full/AndroidManifest.xml` |
| Messages, photos, files, contacts, calendar, health, financial, audio, web browsing | Not accessed. Links open in the external browser. | manifests |

Notes for the owner:
- **Content updates** (signed `manifest.json` and `content.db` from jsDelivr/GitHub,
  `lib/data/content/content_pack_service.dart`) send no user data. Not declared.
- **Backups** (C-02): the journal is in a separate `journal.db` that Android backup never
  includes (cloud backup and device-to-device transfer, all API levels). Only `user.db`
  (saved cards, bookmarks, reading position, streak, settings) and preferences go to the
  user's own Google backup, only when encrypted (`data_extraction_rules.xml` for Android 12+,
  `xml-v28/backup_rules_legacy.xml` for 9-11, nothing on 8.x). Not "collected" by us;
  mentioned in the privacy policy. Checked by `tool/check_manifest.sh --rules` and
  `test/android/backup_rules_test.dart`.
- **Report a problem**: user sees the report and sends it via the share sheet; the app sends
  nothing.
- Turn on "Discard client IP data" in PostHog; Sentry region must be EU.

## 4. Consistency checks

- Privacy policy (`store/privacy_policy.md`) names the same two processors and the same data.
- Onboarding texts `onbWhatWeCollectBody` and `onbAnalyticsBody` (`lib/l10n/app_en.arb`):
  "Never what you read or write, or which apps you use." Matches section 2.
- Both opt-ins default to off and require "I am 16 or older".
