# Permissions: Play Console justifications and prominent disclosure

> S-01: obsah po Murse odstraneny, kostra ostava. Vyplnit pre Prosoche pred
> prvym releasom (texty len z `lib/l10n/app_en.arb` a manifestov).

Nikdy nepouzivat: `USE_EXACT_ALARM`, `SCHEDULE_EXACT_ALARM` (F-01: ranna
a vecerna pripomienka su nepresne, `inexactAllowWhileIdle`), `QUERY_ALL_PACKAGES`,
`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, `AccessibilityService`, polohu.
`tool/check_manifest.sh` blokuje povolenia brany v `lite`.

## v1.0 (`prodLite`)

TODO

### POST_NOTIFICATIONS (runtime, Android 13+)

Opt-in reminders: an optional morning reminder (daily set) and an optional
evening reminder (evening reflection). Both are inexact; the app does not
request exact alarms. Asked in onboarding after an explanation, can be turned
off in Settings > Notifications.

### RECEIVE_BOOT_COMPLETED (normal)

Restores the scheduled (inexact) reminders after a device restart
(`ScheduledNotificationBootReceiver` of flutter_local_notifications).

## v1.1 (`prodFull`, app gate) - prepare now, submit with B-03

TODO

### FOREGROUND_SERVICE_SPECIAL_USE (`BlockerService`, `foregroundServiceType="specialUse"`)

TODO

### PACKAGE_USAGE_STATS (special access)

TODO

### SYSTEM_ALERT_WINDOW (special access)

TODO

### FGS notification text (native, `android/app/src/full/res/values/strings.xml`)

TODO

### Listing addition for v1.1

TODO
