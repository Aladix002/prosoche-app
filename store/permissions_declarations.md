# Permissions: Play Console justifications and prominent disclosure

> S-01: obsah po Murse odstraneny, kostra ostava. Vyplnit pre Prosoche pred
> prvym releasom (texty len z `lib/l10n/app_en.arb` a manifestov).

Nikdy nepouzivat: `USE_EXACT_ALARM`, `QUERY_ALL_PACKAGES`,
`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, `AccessibilityService`, polohu.
`tool/check_manifest.sh` blokuje povolenia brany v `lite`.

## v1.0 (`prodLite`)

TODO

### POST_NOTIFICATIONS (runtime, Android 13+)

TODO

### SCHEDULE_EXACT_ALARM (special access, not granted by default on Android 14+)

TODO

### RECEIVE_BOOT_COMPLETED (normal)

TODO

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
