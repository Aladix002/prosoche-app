# Countries / regions (Play Console > Production / Closed testing > Countries/regions)

Source: docs/11 kap. 11, TECHNICKY_PLAN 24.2, PLAN_VYVOJA M-18. Not legal advice.
Set the same list for closed testing and production. Language is not country: AR, ID, UR,
TR stay in the app for the diaspora; only distribution in the country is limited.

## Must be OFF

| Country | Code | Reason | Turn on when |
|---|---|---|---|
| Pakistan | PK | PPC 295-B/C, PTA blocks, Quran Board approval (docs/11 5) | After Punjab Quran Board / MoRA check and lawyer (M-17, M-18) |
| Indonesia | ID | LPMQ tanda tashih, PSE registration (docs/11 3) | After written LPMQ reply and PSE check |
| Malaysia | MY | Act 326, KDN certification, Muslim-ownership condition (docs/11 4) | Not planned |
| Turkey | TR | Law 7549, Kurul approval (docs/11 6) | v2+ after Kurul approval or TR lawyer |
| China | CN | Precedent of forced removal (Quran Majeed 2021) | Not planned |
| Iran | IR | Sanctions | Not planned |
| Russia | RU | Sanctions (simplification) | Not planned |
| Bangladesh | BD | Bengali hidden in app until QuranEnc confirms `bengali_zakaria` | When BN is enabled in the app and the BN listing is ready |
| Other sanctioned: Belarus, North Korea, Syria, Cuba | BY, KP, SY, CU | Sanctions (docs/11 11 "krajiny pod sankciami") | Not planned. Some are not offered by Play anyway. |

## Recommended ON (release)

| Group | Countries |
|---|---|
| EU (27) | AT, BE, BG, HR, CY, CZ, DK, EE, FI, FR, DE, GR, HU, IE, IT, LV, LT, LU, MT, NL, PL, PT, RO, SK, SI, ES, SE |
| Rest of EEA + CH | IS, LI, NO, CH |
| UK | GB |
| North America, Oceania | US, CA, AU, NZ |
| Balkans | BA, AL, XK (Kosovo, if listed by Play), RS, ME, MK |
| Gulf (AR) | SA, AE, QA, KW, BH, OM |
| Egypt (AR) | EG |

Condition for Gulf and Egypt (docs/11 11): unmodified Tanzil text, no KFGQPC font, no own
tafsir; if an authority makes contact, withdraw from that country first.

## Owner decision (not covered by docs/11)

| Country | Note |
|---|---|
| India (IN) | TECHNICKY_PLAN 24.2 names India as Urdu diaspora, but docs/11 has no legal check for IN. Recommended: OFF for the closed test, decide with the lawyer (M-17). |
| Other Muslim-majority or Arabic-speaking countries (JO, MA, DZ, TN, LB, IQ, NG, SN, KZ, UZ, AZ, ...) | Not assessed. Keep OFF until checked. |
| Everything else not listed | Not assessed. Recommended OFF in v1.0 to keep review simple; can be added later without a new build. |

## Closed test

Testers can be anywhere, but the app is only installable in enabled countries. Make sure
the 12+ testers live in the ON list (most are EU/UK per M-07).
