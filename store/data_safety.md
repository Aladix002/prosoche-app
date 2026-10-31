# Play Console: Data safety (Mursa, app.mursa, v1.0 `prodLite`)

State of code: `main` at tag `rc0` (fe6da4e), 2026-10-30. Re-check this file whenever
`lib/data/observability/analytics.dart` (event allowlist), the PostHog/Sentry config or
`pubspec.yaml` changes (TECHNICKY_PLAN 19: new events must be reflected here).

Rule used (docs/08 A, Play help 10787469): data that never leaves the device is not
"collected". Optional (opt-in) collection is declared as optional. Data processed by a
service provider on our behalf (PostHog, Sentry) is "collected", not "shared".

## 1. Data collection and security

| Question | Answer | Evidence |
|---|---|---|
| Does your app collect or share any of the required user data types? | **Yes** | PostHog + Sentry after opt-in (below) |
| Is all of the user data collected by your app encrypted in transit? | **Yes** | HTTPS only: `android/app/src/main/res/xml/network_security_config.xml` (`cleartextTrafficPermitted="false"`), `AndroidManifest.xml` `usesCleartextTraffic="false"`; PostHog host `https://eu.i.posthog.com` (`lib/data/observability/posthog_transport.dart`); Sentry SDK uses the HTTPS DSN |
| Do you provide a way for users to request that their data is deleted? | **Yes** | In app: turning off "Anonymous usage" / "Crash reports" or "Delete all my data" stops collection and wipes local queues and the anonymous IDs (`ObservabilityController._apply`, `PostHogTransport.stop(wipe: true)`, `SentryCrashReporter.stop(wipe: true)`, `lib/app/data_deletion_wiring.dart`). Server copies: request by e-mail [MAJITEL kontakt] (privacy policy section 7). |
| Account creation | **My app does not allow users to create an account** | No login anywhere in `lib/` (TECHNICKY_PLAN 13) |
| Independent security review (MASA) | No | - |
| UPI / financial | Not applicable | - |

Owner decision: the "deletion request" answer may be **No** if the owner does not want to
handle e-mail requests. Because the IDs are random and the in-app switch already wipes them,
"Yes" with the e-mail route is the recommended, honest answer. PostHog/Sentry retention
must be set short in their dashboards (see CHECKLIST).

## 2. Data types

Only these rows get a tick. Everything else: **not collected**.

| Play category > type | Collected | Shared | Processed ephemerally | Required or optional | Purposes | Source in code |
|---|---|---|---|---|---|---|
| App activity > **App interactions** | Yes | No | No | **Optional** (user can choose) | **Analytics** | PostHog, after "Anonymous usage" opt-in. Events actually sent in rc0: `onboarding_step`, `onboarding_completed`, `screen_view`, `permission_result`, `daily_set_started`, `daily_set_completed` (`lib/features/onboarding/onboarding_controller.dart`, `lib/app/observability_wiring.dart`, `lib/features/feed/feed_screen.dart`). Allowlist: `AnalyticsSchema.events` in `lib/data/observability/analytics.dart`. |
| App info and performance > **Crash logs** | Yes | No | No | **Optional** | **App functionality**, **Analytics** | Sentry, after "Crash reports" opt-in (`lib/data/observability/sentry_crash_reporter.dart`) |
| App info and performance > **Diagnostics** | Yes | No | No | **Optional** | **App functionality**, **Analytics** | Sentry release health sessions (`enableAutoSessionTracking = true`), OS/device model context, scrubbed log breadcrumbs (`filterBreadcrumb`, `scrubEvent`) |
| Device or other IDs > **Device or other IDs** | Yes | No | No | **Optional** | **Analytics**, **App functionality** | Random anonymous ID created by the PostHog SDK and Sentry installation ID for sessions. Both are deleted when the user opts out (`reset()`, `deleteSentryCache`). Not the Android ID, not advertising ID, not our `install_id`. |

Super properties on every PostHog event: only `app_version`, `content_version`, `locale`,
`flavor` (`AnalyticsSchema.superProperties`). `locale` is the app language, not location.

## 3. Declared as NOT collected (and why)

| Data | Why not | Evidence |
|---|---|---|
| Location (approximate/precise) | Used only on device for prayer times and Qibla; rounded to about 1 km; never sent. GeoIP disabled on PostHog events (`$geoip_disable`). Sentry timezone and `locale_city` tag removed. | `lib/features/onboarding/onboarding_platform.dart` (`LocationAccuracy.low`), `posthogGuard`, `scrubEvent` |
| Personal info > Religious or political beliefs | Prayer log, fasting, intentions (niyyah), saved cards, reading progress live only in local `user.db`. Analytics events carry no content IDs, no prayer status, no surah. | `lib/data/db/`, `AnalyticsSchema` doc comment, docs/02 0.6 |
| Personal info (name, e-mail, user IDs) | No account, no form in app. `sendDefaultPii=false`, `user=null` in Sentry. | `configureSentry`, `scrubEvent` |
| Installed apps / app activity in other apps | v1.0 lite has no gate. (v1.1 `full`: usage data is read on device only, never stored or sent; re-check before v1.1.) | `android/app/src/full/AndroidManifest.xml`, `tool/check_manifest.sh` |
| Messages, photos, files, contacts, calendar, health, financial, audio | Not accessed. | Manifest has no such permissions |
| Web browsing | No in-app browser; links open externally (`LaunchMode.externalApplication`). | `lib/features/settings/settings_providers.dart` |

Notes for the owner:
- **Content downloads** (`manifest.json`, `content.db`, `hadith_extra.db` from jsDelivr / GitHub,
  `lib/data/content/content_pack_service.dart`) send no user data; the CDN sees only the IP like
  any web request. Not declared. Note: the release workflow currently passes no `CONTENT_REPO`,
  so release builds make no content requests at all until it is added.
- **Backups**: Android Auto Backup goes to the user's own Google account
  (`data_extraction_rules.xml`), not to us. Not declared; mentioned in the privacy policy.
- **Share / copy / "Show source"**: user-initiated, user picks the target app. Not collected.
- **"Report a problem" on a card** only writes a local log entry today (`card_view.dart`
  `report()`); nothing is sent. If D-04 later sends feedback, add "App activity > Other
  user-generated content" or "Other actions" here.
- Unknown: whether PostHog stores the client IP. Turn on "Discard client IP data" in the
  PostHog project settings; otherwise Play may treat IP as collected.
- Sentry region must be EU (DSN host `*.de.sentry.io`), otherwise update the privacy policy.

## 4. Consistency checks

- Privacy policy (`store/privacy_policy.md`) lists the same three processors and the same data.
- Onboarding text `onbWhatWeCollectBody` and `onbAnalyticsBody` (`lib/l10n/app_en.arb`) match
  section 2: "anonymous events ... the app version and the language. Never what you read or
  pray, your location, or which apps you use."
- Both opt-ins default to off and require "I am 16 or older" (`ObservabilityConsent.read`).
