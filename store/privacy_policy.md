> **DRAFT (I-01) for review by the owner and a lawyer. Not legal advice. Do not publish before review.**
> Placeholders: [MAJITEL] = controller name and address, [EMAIL] = contact e-mail,
> [DATE] = effective date, [URL] = policy URL. Open questions are marked [OVERIT].
> Based on the code of `prosoche-app` (branch feat/I-01): `lib/data/observability/`,
> `android/app/src/main/res/xml/data_extraction_rules.xml`, manifests.

# Prosoche privacy policy

Effective date: [DATE]

Prosoche is an app for a short daily reading of Stoic philosophy, a private journal and
optional reminders. It is built to work on your phone, without an account.

## 1. Who we are

Controller: [MAJITEL], [address], [EMAIL].
We have not appointed a data protection officer. [OVERIT: not required for this size?]

## 2. Summary

- No account. No ads. No advertising or data-broker SDKs.
- Your journal (morning and evening answers, notes) never leaves your phone through the app:
  it is not sent to us, not included in usage statistics, crash reports, logs or Android
  backups.
- Saved cards, bookmarks, reading position, streak, intention and settings are stored only
  on your phone. We do not receive them.
- Anonymous usage statistics and crash reports are **off by default**. They are sent only if
  you turn them on, and only if you confirm you are 16 or older.
- The app does not use your location.

## 3. Data that stays on your phone

| Data | Purpose |
|---|---|
| Journal entries (answers to morning and evening questions, notes) | Show them to you |
| Saved cards, bookmarks, reading position, streak, daily intention | Show your progress to you |
| Birth year for "Memento mori" (optional) | Draw your life in weeks |
| Settings, random install ID (used to vary daily content) | Run the app |
| Edition with the app gate only: the apps you chose to gate, history of gate sessions and unlocks, your optional answer to "Why are you opening this app?" (one of five fixed choices, never free text), which apps "Practice first" locks in the morning | Show the gate before those apps, count how often you opened an app today, show your progress |

We have no access to this data. [OVERIT: whether the developer is a controller of purely
local data.]

**Backups.** Your journal is kept in a separate file that is **never** included in Android
backups: not in your Google backup and not in a transfer to a new phone. If you change
phones, export your journal first (see Export below). Other app data (saved cards,
bookmarks, reading position, streak, settings) may be included in your own Google backup or
in a transfer to a new phone, on Android 9 and newer and only if the backup can be
encrypted. This is between you and Google; we cannot read it. You can turn backup off in
Android settings.

**Export.** You can export your journal yourself (Practice > Journal). The file goes only
where you send it.

**Deletion.** Settings > Privacy > "Delete all my data" deletes all of it from your phone.
Uninstalling the app also deletes it.

## 4. Data sent only with your consent

You give consent separately for each of the two purposes below (Art. 6(1)(a) GDPR). You can
withdraw it at any time in Settings > Privacy, as easily as you gave it. Withdrawal does not
affect processing before it.

### 4.1 Anonymous usage statistics (PostHog)
- What: events such as "onboarding step finished", "screen viewed" (screen name only),
  "permission granted or not", "daily set started/completed" with the number of cards and
  duration, "card saved or shared" (card type only); app version, content version, app
  language, app edition; a random ID created by the analytics library.
- Never: your journal, what you wrote, which texts you read, your intention, your birth year,
  which other apps you use or gate, your name or e-mail.
- No person profiles, no session recording, no automatic tap tracking, location lookup from
  IP turned off.
- Processor: PostHog Inc., EU Cloud (Frankfurt, Germany). [OVERIT: DPA signed, IP discarding on]
- When you turn it off, sending stops at once and the random ID and unsent events are
  deleted from your phone.

### 4.2 Crash reports (Sentry)
- What: technical details of an error (error type and stack trace, app version, Android
  version, device model), whether the app session ended normally, and a short technical log
  filtered to remove e-mails, web addresses and app names; a random installation ID.
- Never: your journal or other content, name, IP-based user ID, screenshots or screen
  recordings.
- Processor: Functional Software Inc. (Sentry), EU data region (Germany). [OVERIT: region
  of the DSN, DPA, transfer basis for the US company]
- When you turn it off, reporting stops and unsent reports are deleted from your phone.

### 4.3 Age
You can give these consents only if you confirm that you are 16 or older. Otherwise both
stay off. [OVERIT: Art. 8 GDPR]

### 4.4 Retention
PostHog events: [N] months. Sentry events: [N] days (plan maximum). Then deleted.

## 5. Other network requests

- **Content updates.** The app may download signed text packs (the same public domain texts)
  from public servers (jsDelivr, GitHub). These requests contain no personal data; the
  servers see your IP address as for any web request. [OVERIT: mention jsDelivr/GitHub as
  recipients?]
- **Links.** Links to sources, licenses, this policy or the feedback form open in your
  browser and are governed by those sites' policies.
- **Report a problem.** The app shows you the full text of the report and you send it
  yourself (for example by e-mail). The app sends nothing on its own.

## 6. Permissions

- **Notifications:** an optional morning reminder and an optional evening reflection
  reminder (off unless you turn it on). Reminders are approximate; the app does not use
  exact alarms.
- **Start at boot:** to restore your reminders after the phone restarts.
- **Edition with the app gate only:** Usage access (`PACKAGE_USAGE_STATS`), Display over
  other apps and a foreground service. They are used only on your phone to notice when you
  open an app you chose and to show the gate before it. The app reads usage only for the
  apps you chose. It keeps a local history of gate sessions and unlocks (which chosen app,
  when, how many cards, the reason you tapped if any) for your progress; it stays on your phone and is never sent to us
  or anyone else.
- The app does not request location, contacts, accessibility services or a list of all
  installed apps.

## 7. Your rights

Under the GDPR you have the right to access, rectification, erasure, restriction, data
portability and objection, and the right to withdraw consent at any time. Because we only
hold random IDs, we may need the ID from your phone to find your data [OVERIT: how the user
obtains it]. Write to [EMAIL]. We answer within one month.

You can also complain to a supervisory authority, in Slovakia: Urad na ochranu osobnych
udajov SR, Hranicna 12, 820 07 Bratislava, https://dataprotection.gov.sk.

## 8. Children

Prosoche is not directed at children under 13. Usage statistics and crash reports are
available only to users who confirm they are 16 or older.

## 9. Security

All network traffic uses HTTPS. Text packs are verified with a digital signature before use.
Your local data is protected by Android app sandboxing.

## 10. Disclaimers

Prosoche offers texts of ancient philosophy and simple reflective exercises. It is not
medical or psychological advice or therapy. The texts are public domain translations quoted
word for word; short questions, exercises and notes are written for Prosoche.

## 11. Changes

We will publish changes here and update the effective date. If a change needs new consent,
the app will ask you again.

Contact: [EMAIL]
