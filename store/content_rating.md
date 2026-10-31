# Content rating (IARC questionnaire) and related App content forms

Answers for v1.0 `prodLite` (tag `rc0`). Re-answer when ads, purchases, user content or
social features appear (v2/v3).

## IARC questionnaire

- E-mail for IARC: [MAJITEL]
- Category: **All Other App Types** (not a game, not social, not news, not a browser).

| Question (short) | Answer | Why |
|---|---|---|
| Violence (realistic, fantasy, blood, gore) | No | No images or video. Religious texts are text only, no depiction. |
| Fear / horror | No | - |
| Sexuality, nudity | No | - |
| Language (profanity, crude humor) | No | - |
| Controlled substances (drugs, alcohol, tobacco) | No | - |
| Gambling (simulated or real) | No | No points, no rewards, no chance mechanics. |
| Discrimination / hate | No | Content is unmodified Quran text and translations from QuranEnc, hadith from HadeethEnc, reviewed (docs/03). |
| Does the app allow users to interact or exchange content? | No | No chat, no accounts, no user posts. Sharing a card goes through the Android share sheet to apps the user picks. |
| Does the app share the user's current physical location with other users? | No | Location never leaves the device. |
| Digital purchases | No | None in v1.0 (supporter IAP is v2). |
| Unrestricted internet access / web browser | No | Links open in the external browser. |
| Is the app a news or educational app? (if asked) | No | - |
| Ads | No | - |

Expected result: Everyone / PEGI 3 / USK 0 / ESRB E. If a region returns a higher rating
(religious content is not an IARC criterion), accept it, do not change answers to lower it.

## Other App content forms (Play Console > Policy > App content)

| Form | Answer |
|---|---|
| Ads | **No, my app does not contain ads** |
| Target audience and content | Age groups **16-17** and **18 and over**. Not 13-15 (analytics consent needs 16+, docs/11 8.3). Not under 13, so the Families policy does not apply. "Appeals to children": No. |
| News app | No |
| COVID-19 contact tracing / status | No |
| Data safety | see `store/data_safety.md` |
| Government app | No |
| Financial features | None |
| Health apps | None (prayer and fasting logs are religious, not health features) |
| Privacy policy | URL from `store/privacy_policy.md` after lawyer review |
| App access | see `store/app_access.md` |
| Foreground service permissions | v1.0: none. v1.1: see `store/permissions_declarations.md` |
| Advertising ID | **No** (no SDK reads it; `AD_ID` permission must not appear in the merged manifest - check with `aapt dump permissions` on the release AAB/APK) |
