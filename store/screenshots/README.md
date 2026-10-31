# Store screenshots

> **DRAFT (I-01) na kontrolu majitelom.** Obsah je z dev `content.db`
> (`dev_content=1`, vsetky karty `draft`); pred releasom zopakovat s finalnou
> schvalenou `content.db`.

## Play requirements (phone)

- 2 to 8 screenshots per language; we use 8.
- JPEG or **24-bit PNG without alpha**, each side 320-3840 px, long side at most 2x the
  short side. Target **1080 x 1920** (9:16).
- Also needed (owner): icon 512 x 512, feature graphic 1024 x 500.
- No DEBUG banner, no captions with "best"/"#1", no "Project Gutenberg" anywhere.

## The 8 screenshots (`en-US/`)

| # | File | Screen | State |
|---|---|---|---|
| 1 | `01_today.png` | Today | before the set, intention, quests |
| 2 | `02_card_quote.png` | Feed: quote card | short quote, reference and translator |
| 3 | `03_card_passage.png` | Feed: passage card | longer passage |
| 4 | `04_card_concept.png` | Feed: concept card | Greek term and explanation |
| 5 | `05_library_reader.png` | Library reader | Meditations, section with reference |
| 6 | `06_practice.png` | Practice | morning and evening, journal, memento mori |
| 7 | `07_evening_review.png` | Evening review | Seneca, On Anger 3.36 with questions |
| 8 | `08_journey.png` | Journey | streak and calendar |

Copies: `/home/aladix/prosoche/screenshots/i01/`.

## How to make them (no DEBUG banner)

Release build (local debug signing fallback, nothing committed):

```
tool/bundle_content.sh
flutter build apk --release --flavor devFull --dart-define=FEATURE_GATE=true
adb install -r build/app/outputs/flutter-apk/app-devfull-release.apk
```

Device setup (emulator `sakina_pixel`):

```
adb shell wm size 1080x1920
adb shell wm density 420
adb shell settings put global sysui_demo_allowed 1
adb shell am broadcast -a com.android.systemui.demo -e command enter
adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0930
adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false
adb shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4
adb shell am broadcast -a com.android.systemui.demo -e command notifications -e visible false
adb exec-out screencap -p > 01_today.png
# reset
adb shell am broadcast -a com.android.systemui.demo -e command exit
adb shell wm size reset
adb shell wm density reset
```

Remove alpha before upload (PIL from Python is enough):
`python3 -c "from PIL import Image; Image.open('a.png').convert('RGB').save('a.png')"`.
