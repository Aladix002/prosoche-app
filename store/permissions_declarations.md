# Permissions: Play Console justifications and prominent disclosure

Sources: manifests `android/app/src/main/AndroidManifest.xml` (both editions) and
`android/app/src/full/AndroidManifest.xml` (only `full`, v1.1); UI texts from
`lib/l10n/app_en.arb` (checked 2026-10-30, tag `rc0`); docs/01 7.2-7.3; docs/08 A.

Not used, never add: `USE_EXACT_ALARM`, `QUERY_ALL_PACKAGES`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`,
`AccessibilityService`, `ACCESS_FINE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`.
`tool/check_manifest.sh` blocks gate permissions in `lite`.

## v1.0 (`prodLite`)

### POST_NOTIFICATIONS (runtime, Android 13+)
- **Use:** prayer-time reminders and one optional morning reminder. Scheduled locally
  (`flutter_local_notifications`), no push server.
- **Asked:** onboarding step "Gentle reminders", only after tapping "Allow notifications";
  "Skip" has equal weight. Settings > Notifications.
- **UI text (matches arb):** `onbNotifTitle` "Gentle reminders"; `onbNotifBody` "Get a quiet
  notice at each prayer time and one in the morning when your cards are ready. Nothing else."
  Denied: `onbNotifDenied`.
- No Play declaration form; nothing to fill.

### SCHEDULE_EXACT_ALARM (special access, not granted by default on Android 14+)
- **Play Console:** no declaration form exists for `SCHEDULE_EXACT_ALARM` (only for
  `USE_EXACT_ALARM`, which we do not use). If asked in review, use this text:
  > Mursa schedules local reminders at the five daily Islamic prayer times, which the user
  > enables. Prayer times are minute-specific, and a reminder that arrives 10+ minutes late
  > can miss the prayer window. The app asks for "Alarms & reminders" through
  > ACTION_REQUEST_SCHEDULE_EXACT_ALARM only after explaining why, and works without it:
  > reminders are then scheduled inexactly and the app tells the user they may be late.
- **Fallback in code:** `AndroidScheduleMode.exactAllowWhileIdle` only when
  `canScheduleExact` is true (`lib/data/notifications/local_notifications_platform.dart`),
  otherwise inexact; banner `notifInexactNote`; switch in Settings > Notifications ("Exact reminders").
- **UI text (matches arb):** `onbExactTitle` "On-time prayer reminders"; `onbExactBody`
  "To remind you at the exact minute, Android needs "Alarms & reminders" to be allowed.
  Without it, reminders can arrive a few minutes late."; `onbExactCta` "Allow in settings".
- Mismatch to fix (not ours): docs/08 A says inexact alarms can be 10+ minutes late; UI says
  "a few minutes". Consider "can arrive late" in `onbExactBody` / `setExactHelp`.

### ACCESS_COARSE_LOCATION (runtime)
- **Use:** one-time approximate position (`LocationAccuracy.low`, 10 s timeout,
  `lib/features/onboarding/onboarding_platform.dart`) to pick the nearest city for prayer
  times and Qibla. Not in background, not sent anywhere.
- **Asked:** onboarding "Prayer times for where you are" after tapping "Use my location", or
  in Prayer settings. "Choose a city instead" always available (offline GeoNames list).
- **UI text (matches arb):** `onbLocationTitle`, `onbLocationBody` "Prayer times are
  calculated on your phone. Your location is rounded to about 1 km and never leaves your device."
- No Play declaration (foreground, approximate). Data safety: not collected.

### RECEIVE_BOOT_COMPLETED (normal)
Re-schedules reminders after reboot/update (`ScheduledNotificationBootReceiver`). No declaration.

## v1.1 (`prodFull`, app gate) - prepare now, submit with B-03

**Prominent disclosure status:** the disclosure screens from docs/01 7.3 (`perm_usage_*`,
`perm_overlay_*`, `perm_fgs_explain`) are **not yet in `lib/l10n`**. rc0 has only the generic
`onbPermissionsTitle` "Permissions for the gate" / `onbPermissionsBody` "The gate needs a few
permissions. You can turn them on later in Settings." That is **not enough** for Play
(must say what data, how used, whether shared, before the system screen, with an active
button). B-03 must add the texts below to its arb part. Do not submit `full` before that.

### FOREGROUND_SERVICE_SPECIAL_USE (`BlockerService`, `foregroundServiceType="specialUse"`)
Manifest subtype already present (`PROPERTY_SPECIAL_USE_FGS_SUBTYPE`): "User-enabled app gate:
detects when an app the user chose to limit is opened (UsageStatsManager) and shows a short
reflection screen before it."

**Play Console > App content > Foreground service permissions > Other (special use):**
- Feature description:
  > Mursa has an optional "app gate" that the user turns on and configures. The user picks
  > apps (for example social media) that should show a short reflection screen first. While
  > the gate is on, a foreground service with a persistent, silent notification checks which
  > app is in the foreground using UsageStatsManager, only while the screen is on. When a
  > user-selected app is opened, Mursa shows its own screen with a few cards, then lets the
  > app open for a set number of minutes. An "Emergency" button always opens the app. No
  > usage data is stored or sent. The user can turn the gate off at any time in the app.
- Impact if the system defers or stops the task:
  > The gate stops working: the selected apps open without the reflection screen, so the
  > user's own limit is silently bypassed. The check must run immediately when the app is
  > opened; deferring it by even a few seconds makes the feature useless.
- Why other FGS types/APIs do not fit:
  > No standard type covers watching the foreground app on the user's request. WorkManager
  > and alarms cannot react within a second. We do not use AccessibilityService.
- Video link: [MAJITEL: unlisted YouTube URL]

**Video script (30-60 s, one take, screen recording of a release `prodFull` build):**
1. Open Mursa on a clean install. Show the onboarding step "A pause before social apps"; tap to set up.
2. Choose 1-2 apps (e.g. a social app) in the app picker (final screen title from B-03).
3. Show the Usage Access disclosure screen; tap "Allow in settings"; system list; enable "Permit usage access" for Mursa; return.
4. Show the "Display over other apps" disclosure; enable it in system settings; return.
5. Pull down the shade: show the silent "App gate is on" notification (FGS running).
6. Go home, open the chosen app: the Mursa gate appears with "A pause before <app>".
7. Read the cards, tap through; the app opens and stays open for the set minutes.
8. Open the app again, show the "Emergency" button opens it (countdown).
9. Open a non-selected app: nothing happens.
10. Back in Mursa: Settings > The gate > turn off; notification disappears; chosen app opens directly.
Captions in English on each step. No personal accounts visible in the target app.

### PACKAGE_USAGE_STATS (special access)
- No dedicated Play declaration form found (docs/08 A: NEZISTENE). Covered by the FGS
  declaration, the listing text and prominent disclosure.
- Disclosure texts (docs/01 7.3, to be added by B-03):
  - "Allow Usage Access"
  - "Mursa uses Usage Access to notice when you open one of the apps you chose for the gate,
    so it can show your cards first."
  - "What Mursa does: checks which app is on screen, only while your screen is on."
  - "What Mursa never does: it doesn't store or send your app history, time spent, or
    anything you do inside other apps."
  - "This stays on your phone and is not shared with anyone."
  - Buttons: "Allow in settings" / "Not now".
- docs/01 uses the name "Sakina"; replace with "Mursa" when adding to arb.

### SYSTEM_ALERT_WINDOW (special access)
- Use: exemption to start `GateActivity` from the background on top of the opened app
  (docs/08 A). It does not draw or read other apps' content.
- Disclosure texts (docs/01 7.3, to be added by B-03):
  - "Allow Mursa to appear over other apps"
  - "This lets Mursa open its gate screen on top of the app you just opened."
  - "What Mursa does: shows its own gate screen, only for the apps you chose."
  - "What Mursa never does: read, record or change what's on your screen."
  - Buttons: "Allow in settings" / "Not now".
- If Play asks: same reasoning as the FGS declaration, plus "only launches Mursa's own
  activity; no overlay window is drawn on other apps."

### FGS notification text (native, `android/app/src/full/res/values/strings.xml`)
"App gate is on" / "Chosen apps open after a few cards." Channel "App gate". Matches the
declaration. docs/01 `perm_fgs_explain` (explaining the notification) is still missing in arb.

### Listing addition for v1.1
Add to `full_description.txt` a section that names Usage Access and "Display over other
apps", what they are used for, and that nothing is stored or sent (Play requires the use to
be described in the listing).
