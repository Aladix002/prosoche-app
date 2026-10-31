> **DRAFT for review by a lawyer (M-17). Not legal advice. Do not publish before review.**
> Placeholders: [MAJITEL] = controller name and address, [EMAIL] = contact e-mail,
> [DATE] = effective date, [URL] = policy URL (Cloudflare Pages).
> Open questions for the lawyer are marked [OVERIT]. Based on TECHNICKY_PLAN 13, 24 and
> docs/11 (8, 12.4), and on the code at tag `rc0`.

# Mursa privacy policy

Effective date: [DATE]

Mursa is an app for daily Quran reading, prayer times and reminders. We built it so that
your personal and religious data stays on your phone.

## 1. Who we are

Controller: [MAJITEL], [address], [EMAIL].
We have not appointed a data protection officer. [OVERIT: not required for this size?]

## 2. Summary

- No account. No ads. No advertising or data-broker SDKs.
- Your prayer log, fasting log, intentions, saved cards, reading progress and settings are
  stored only on your phone. We do not receive them.
- Your location is used only on your phone to calculate prayer times and the Qibla direction.
- Anonymous usage statistics and crash reports are **off by default**. They are sent only if
  you turn them on, and only if you confirm you are 16 or older.

## 3. Data that stays on your phone

| Data | Purpose |
|---|---|
| Prayer, fasting and other logs, intentions, saved cards, reading progress, streak | Show your progress to you |
| Approximate location (rounded to about 1 km) or the city you chose | Calculate prayer times and Qibla |
| Settings, random install ID (used to vary daily content) | Run the app |

We have no access to this data. [OVERIT: whether the developer is a controller of purely local
data, docs/11 8.1.]

**Backups.** Android may back up your logs and settings to your own Google account
(Android Auto Backup), only if the backup can be encrypted. This backup is between you and
Google; we cannot read it. You can turn it off in Android settings.

**Deletion.** Settings > Privacy > "Delete all my data" deletes all of it from your phone.
Uninstalling the app also deletes it.

## 4. Data sent only with your consent

Some data from a religious app can reveal your religion, even if it is only technical. For
that reason we use it only with your explicit consent (Art. 9(2)(a) and Art. 6(1)(a) GDPR),
and you give it separately for each of the two purposes below. You can withdraw it at any
time in Settings > Privacy, as easily as you gave it. Withdrawal does not affect processing
before it.

### 4.1 Anonymous usage statistics (PostHog)
- What: events such as "onboarding step finished", "screen viewed" (screen name only),
  "permission granted or not", "daily cards started/completed" with number of cards and
  duration; app version, content version, app language, app edition; a random ID created
  by the analytics library.
- Never: what you read, which verses or hadith, your prayers, your location, which other apps
  you use, your name or e-mail.
- No person profiles, no session recording, no automatic tap tracking, location lookup from
  IP turned off.
- Processor: PostHog Inc., EU Cloud (Frankfurt, Germany). [OVERIT: DPA signed, IP discarding on]
- When you turn it off, sending stops at once and the random ID and unsent events are
  deleted from your phone.

### 4.2 Crash reports (Sentry)
- What: technical details of an error (error type and stack trace, app version, Android
  version, device model), whether the app session ended normally, and a short technical log
  filtered to remove locations, e-mails, web addresses and app names; a random installation ID.
- Never: your content, name, IP-based user ID, screenshots or screen recordings.
- Processor: Functional Software Inc. (Sentry), EU data region (Germany). [OVERIT: region
  of the DSN, DPA, transfer basis for the US company]
- When you turn it off, reporting stops and unsent reports are deleted from your phone.

### 4.3 Age
You can give these consents only if you confirm that you are 16 or older. Otherwise both
stay off. [OVERIT: Art. 8 GDPR and consent of minors under Art. 9, docs/11 8.3]

### 4.4 Retention
PostHog events: [N] months. Sentry events: [N] days (plan maximum). Then deleted.

## 5. Other network requests

- **Content updates.** The app downloads signed Quran, translation and hadith data packs
  from public servers (jsDelivr, GitHub). These requests contain no personal data; the
  servers see your IP address as for any web request. [OVERIT: mention jsDelivr/GitHub
  as recipients?]
- **Links.** Links to sources, licenses, this policy or the feedback form open in your
  browser and are governed by those sites' policies.
- [ONLY IF audio via Quran Foundation API is enabled: Recitation audio is streamed from
  Quran Foundation (quran.foundation). Their privacy policy applies to these requests.
  Remove this paragraph if the feature is not released.]

## 6. Permissions

- Notifications and "Alarms & reminders": prayer and morning reminders on your phone.
- Approximate location: once, to calculate prayer times. You can choose a city instead.
- [v1.1 only, edition with the app gate: Usage access, Display over other apps and a
  foreground service, used on your phone to show the gate before apps you choose. Nothing
  about your app use is stored or sent.]

## 7. Your rights

Under the GDPR you have the right to access, rectification, erasure, restriction, data
portability and objection, and the right to withdraw consent at any time. Because we only
hold random IDs, we may need the ID from your phone to find your data [OVERIT: how the user
obtains it]. Write to [EMAIL]. We answer within one month.

You can also complain to a supervisory authority, in Slovakia: Urad na ochranu osobnych
udajov SR, Hranicna 12, 820 07 Bratislava, https://dataprotection.gov.sk.

## 8. Children

Mursa is not directed at children under 13. Usage statistics and crash reports are available
only to users who confirm they are 16 or older.

## 9. Security

All network traffic uses HTTPS. Content packs are verified with a digital signature before
use. Your local data is protected by Android app sandboxing.

## 10. Disclaimers

Prayer times are calculated on your device and can differ from your local mosque by several
minutes; please confirm them locally. Translations convey the meanings of the Quran; they
are not the Quran itself. Mursa does not issue religious rulings.

## 11. Changes

We will publish changes here and update the effective date. If a change needs new consent,
the app will ask you again.

Contact: [EMAIL]
