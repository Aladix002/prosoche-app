# src/full

Zdrojovy set len pre edition `full` (devFull, prodFull). Vlastnik: B-01.
Gradle ho zluci so `src/main`.

- `AndroidManifest.xml`: FGS specialUse, PACKAGE_USAGE_STATS,
  SYSTEM_ALERT_WINDOW, `<queries>` MAIN/LAUNCHER, GateActivity, BootReceiver.
- `kotlin/app/mursa/blocker/`: BlockerService, ForegroundAppMonitor,
  GateDecider, UnlockStore, GateLauncher, GateActivity, BootReceiver,
  InstalledAppsProvider, BlockerHostApiImpl.
- `BlockerApi.g.kt` generuje Pigeon (`dart run pigeon --input pigeons/blocker_api.dart`).

Diagnostika monitora (len debuggable build, tag `MursaGateDbg`):
`adb logcat -s MursaGateDbg MursaGate` ukaze okno dotazu, typy udalosti,
appku v popredi a rozhodnutie (napr. `Skip(reason=UNLOCKED)`).
Usage access na emulatore: `adb shell appops set app.mursa.dev GET_USAGE_STATS allow`.

Testy: `src/testFull/`, `cd android && ./gradlew :app:testDevFullDebugUnitTest`.

V `lite` nic z toho nesmie byt. Kontrola: `tool/check_manifest.sh`.
Nepouzivat AccessibilityService, QUERY_ALL_PACKAGES,
REQUEST_IGNORE_BATTERY_OPTIMIZATIONS.
