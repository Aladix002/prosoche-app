# Store screenshots: plan

## Play requirements (phone)

- 2 to 8 screenshots per language; we use 8.
- JPEG or **24-bit PNG without alpha**, each side 320-3840 px, long side at most **2x** the short side.
- For recommendation surfaces: at least 4 screenshots, min 1080 px, **9:16**. Target: **1080 x 1920**.
- Also needed: app icon 512 x 512 (32-bit PNG), feature graphic **1024 x 500** (JPEG or 24-bit PNG, no alpha).
- No DEBUG banner, no fake reviews, no "best"/"#1", no religious quotes in captions.
  Quran text may appear inside the app screen, never cropped (docs/01 1.3).

## Existing screenshots in `/home/aladix/sakina/screenshots/rc0` - not usable as is

All 47 files are 1080 x 2400 (ratio 2.22 > 2, Play rejects), RGBA PNG (alpha), and
show the red **DEBUG** banner. In AR/UR shots the UI is still English (`app_ar.arb` etc. are
empty at rc0), so they cannot serve the AR/UR listings. Use them only as a reference for
which state to reproduce:

| Plan # | Reference file in rc0 |
|---|---|
| 1 | `06_today.png` |
| 2 | `08_feed_card2.png` |
| 3 | `14_feed_card7.png` (hadith; pick a short, neutral hadith for the store) |
| 4 | `17_feed_done.png` |
| 5 | `20_quran_reader_baqara.png` |
| 6 | `21_prayer.png` (needs exact alarms allowed, so the "may arrive late" banner is gone) |
| 7 | `23_journey.png` |
| 8 | `28_settings_sources.png` or `05_onboarding_privacy.png` |

Do not use: anything with the gate (`37_`, `40_`-`45_`, v1.1 only), `22_calendar.png`
with dev events, `35_today_ur_fixed.png` / `31_today_ar_dark.png` (RTL bugs fixed in I-02,
untranslated UI).

## Plan: 8 screenshots

Caption = short line above the phone frame (optional; plain text, sentence case, no emoji).

| # | Screen | State | Caption (EN) |
|---|---|---|---|
| 1 | Today | before the set, 2 intentions, next prayer chip | A few quiet minutes each day |
| 2 | Feed: verse card | Al-Fatiha 1:1 or a short verse, translation and translator visible | Verses with a translation of the meaning |
| 3 | Feed: hadith card | short hadith, full text visible, source line visible | Hadith from HadeethEnc |
| 4 | Feed: done | closing card of the day | A daily set that ends |
| 5 | Quran reader | a surah opened, Arabic + translation | Read the whole Quran, offline |
| 6 | Prayer | five times, method line, no warning banner, neutral city (e.g. London) | Prayer times calculated on your phone |
| 7 | Journey | streak, calendar with a few completed days, surah map | Your progress stays private |
| 8 | Settings > Privacy (or Sources & licenses) | both switches off, "Delete all my data" visible | No account. No ads. |

Languages:
- **EN**: now (closed test).
- **AR, UR (RTL), ID, TR**: after UI translations are merged (K-04). Same 8 states, app
  language switched in Settings > Language & translation. Captions translated by the
  same translator as the listing.
- **BN**: only after Bengali is enabled in the app.
- Light theme for all 8; optionally replace #7 with a dark-theme shot.

Feature graphic (1024 x 500): app name "Mursa" and the short tagline on the brand color
(`lib/ui` tokens), no Arabic calligraphy of the name of Allah (docs/01 1.3), no phone mockup
with readable verse cut off. Owner/designer makes it.

## How to make them (no DEBUG banner)

The DEBUG banner shows only in debug builds. Use a **release** (or profile) build:

```
# physical device (profile works only on a real device)
flutter run --profile --flavor devLite
# or release APK, also works on an x86_64 emulator
flutter build apk --release --flavor devLite
adb install -r build/app/outputs/flutter-apk/app-devlite-release.apk
```

(Release signing falls back to debug keys locally unless `SAKINA_REQUIRE_RELEASE_SIGNING=true`.
Verify the APK name in `build/app/outputs/flutter-apk/`.)

Device setup for 9:16 and a clean status bar:

```
adb shell wm size 1080x1920
adb shell wm density 420
adb shell settings put global sysui_demo_allowed 1
adb shell am broadcast -a com.android.systemui.demo -e command enter
adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0930
adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false
adb shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4
adb shell am broadcast -a com.android.systemui.demo -e command notifications -e visible false
# capture
adb exec-out screencap -p > 01_today_en.png
# reset afterwards
adb shell am broadcast -a com.android.systemui.demo -e command exit
adb shell wm size reset
adb shell wm density reset
```

Remove alpha before upload (Play wants 24-bit PNG):

```
magick 01_today_en.png -alpha off -strip 01_today_en.png
```

App state:
- Fresh install, onboarding: language, location by city (London), notifications on,
  exact alarms allowed, analytics and crash reports off.
- Complete a set on two or three days for the Journey shot (or use a test build with seed
  data; do not fake features that do not exist).
- Content: final reviewed `content.db` (not `dev_content=1`).

File naming: `store/screenshots/<lang>/<nn>_<screen>.png`, e.g. `en-US/01_today.png`.
Do not commit raw 2400-px captures here.

Alternative later: generate from golden/integration tests (Q-03 harness) at 1080 x 1920 to
get all 6 languages in one run. Not available at rc0.
