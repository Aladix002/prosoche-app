# Store listing (Google Play)

One folder per Play language code. `en-US` is the source; other folders are
templates for human translators (PLAN_VYVOJA 2.1, K-04, M-14).

| File | Play field | Limit |
|---|---|---|
| `title.txt` | App name | 30 chars |
| `short_description.txt` | Short description | 80 chars |
| `full_description.txt` | Full description | 4000 chars |
| `release_notes_rc0.txt` | Release notes ("What's new") | 500 chars per language |

Play language codes: `ar`, `id`, `ur`, `bn-BD`, `tr-TR`, `en-US`. Folder names
here are short; map them when pasting.

Rules for all languages (docs/01 7.1, Play metadata policy):
- Calm tone, short sentences, no emoji, no exclamation marks, no "best"/"#1"/"free".
- No religious quotes (verse, hadith, dua) in the listing. Religious text is
  reviewed content, not marketing copy.
- No promise the app does not keep. Gate (app blocker), words, audio and
  Ramadan features are NOT in v1.0 lite; do not mention them until enabled.
- Duas are not in content.db yet (table `dua` is empty, 2026-10-30). Add "dua"
  back to the description only when curated duas ship.
- "Translation of the meanings", never "the Quran in <language>".
- Keep source names exactly as on the "Sources & licenses" screen.
