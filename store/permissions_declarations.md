# Permissions: Play Console justifications and prominent disclosure

> **DRAFT (I-01) na kontrolu majitelom.** Overene na release manifeste
> `prodFull` (vetva feat/I-01, `tool/check_manifest.sh`). Texty disclosure su
> z `lib/l10n/app_en.arb` (`perm*`).

Nikdy nepouzivat: `USE_EXACT_ALARM`, `SCHEDULE_EXACT_ALARM` (F-01: ranna
a vecerna pripomienka su nepresne, `inexactAllowWhileIdle`), `QUERY_ALL_PACKAGES`,
`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, `AccessibilityService`, polohu.
`tool/check_manifest.sh` blokuje povolenia brany v `lite`.

## v1.0 (`prodLite`)

Povolenia v release manifeste `prodLiteRelease` (overene I-01, 2026-10-31):
`POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `INTERNET`,
`ACCESS_NETWORK_STATE` (aktualizacie obsahu, opt-in analytika a crash),
`VIBRATE`, `WAKE_LOCK`, `FOREGROUND_SERVICE` a
`FOREGROUND_SERVICE_SHORT_SERVICE` (oboje z `workmanager_android`, expedited
praca ako `shortService`), `app.prosoche.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`
(AndroidX, interne). [OVERIT: `shortService` podla dokumentacie kniznice
nepotrebuje FGS deklaraciu v Play Console; potvrdit pri prvom uploade.]

### POST_NOTIFICATIONS (runtime, Android 13+)

Opt-in reminders: an optional morning reminder (daily set) and an optional
evening reminder (evening reflection). Both are inexact; the app does not
request exact alarms. Asked in onboarding after an explanation, can be turned
off in Settings > Notifications.

### RECEIVE_BOOT_COMPLETED (normal)

Restores the scheduled (inexact) reminders after a device restart
(`ScheduledNotificationBootReceiver` of flutter_local_notifications).

## v1.1 (`prodFull`, app gate) - prepare now, submit with B-03

Navyse k v1.0 (overene na `prodFullRelease`): `FOREGROUND_SERVICE_SPECIAL_USE`,
`PACKAGE_USAGE_STATS`, `SYSTEM_ALERT_WINDOW`. Prominent disclosure je v appke
(onboarding O6 a Settings > The gate > Permissions) pred systemovou obrazovkou,
s aktivnym tlacidlom "Allow in settings" a "Not now".

### FOREGROUND_SERVICE_SPECIAL_USE (`BlockerService`, `foregroundServiceType="specialUse"`)

Manifest subtype (`PROPERTY_SPECIAL_USE_FGS_SUBTYPE`): "User-enabled app gate: detects
when an app the user chose to limit is opened (UsageStatsManager) and shows a short
reflection screen before it."

**Play Console > App content > Foreground service permissions > Other (special use):**
- Feature description:
  > Prosoche has an optional "app gate" that the user turns on and configures. The user
  > picks apps (for example social media) that should show a short reading first. While the
  > gate is on, a foreground service with a persistent, silent notification checks which app
  > is in the foreground using UsageStatsManager, only while the screen is on. When a
  > user-selected app is opened, Prosoche shows its own screen with a few cards, then lets
  > the app open for a set number of minutes. An "Emergency" button always opens the app.
  > Usage data is not sent anywhere. The user can turn the gate off at any time in the app.
- Impact if the system defers or stops the task:
  > The gate stops working: the selected apps open without the reflection screen, so the
  > user's own limit is silently bypassed. The check must run immediately when the app is
  > opened.
- Why other FGS types/APIs do not fit:
  > No standard type covers watching the foreground app on the user's request. WorkManager
  > and alarms cannot react within a second. We do not use AccessibilityService.
- Video link: [MAJITEL: unlisted video URL]

Video script (30-60 s, release `prodFull`): onboarding gate step, choose 1-2 apps, Usage
access disclosure and system screen, overlay disclosure and system screen, silent
notification "App gate is on", open a chosen app (gate appears), finish cards (app opens),
"Emergency" button, non-chosen app opens directly, turn the gate off in Settings.

### PACKAGE_USAGE_STATS (special access)

- No dedicated Play form; covered by the FGS declaration, listing text and disclosure.
- Used **only on the device**: the service compares the foreground package with the
  user's chosen list. Local history (`gate_session`, `unlock_event` in `user.db`) holds only
  the chosen apps. Nothing about app use is sent (no analytics event carries package names).
- Disclosure (arb): `permUsageTitle` "Usage access"; `permUsageBody` "Prosoche uses Usage
  Access to notice when you open one of the apps you chose for the gate, so it can show your
  cards first."; `permUsageDoes`; `permUsageNever` "... it doesn't store or send your app
  history, time spent, or anything you do inside other apps."; `permLocal` "This stays on
  your phone and is not shared with anyone."

### SYSTEM_ALERT_WINDOW (special access)

- Use: exemption to start `GateActivity` from the background on top of the opened app.
  It does not draw over or read other apps' content.
- Disclosure (arb): `permOverlayTitle` "Display over other apps"; `permOverlayBody` "This
  lets Prosoche open its gate screen on top of the app you just opened."; `permOverlayNever`.

### FGS notification text (native, `android/app/src/full/res/values/strings.xml`)

"App gate is on" / "Chosen apps open after a few cards." Channel "App gate". Explained in
app by `permNotifBody`.

### Listing addition for v1.1

Add to `listing/en-US/full_description.txt` (only for the `full` release):

> THE GATE (optional)
> Choose apps that should wait for a few cards first. The gate uses Usage access to notice
> when you open one of them and "Display over other apps" to show its screen on top. It runs
> only on your phone; your app use is not sent anywhere. An Emergency button always lets
> you through.
