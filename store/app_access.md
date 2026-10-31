# App access (instructions for the Play reviewer)

## v1.0 (`prodLite`)

Play Console > App content > App access: select
**"All functionality in my app is available without any access restrictions"**.

There is no login, no paywall, no invite code, no region lock. Onboarding has a Skip/Not now
on every permission step. No credentials needed.

If Play asks for notes anyway (e.g. after a rejection), paste:

> Mursa has no account or login. On first start a short setup asks for language, an
> optional intention, location for prayer times (you can tap "Choose a city instead" and
> type e.g. "London"), notifications (optional) and privacy choices (analytics and crash
> reports are off by default). After "Finish" you land on Today. "Begin today's cards"
> opens the daily set of about 10 cards (swipe up). The Quran, Prayer and Journey tabs are
> in the bottom bar; Settings is the gear icon on Today. Everything works offline.

## v1.1 (`prodFull`, app gate)

Still no login, so keep "no access restrictions". Add these notes to the foreground
service declaration and, if Play asks, to App access:

> The app gate is optional and off by default. To test it: Settings (gear on Today) >
> The gate > choose an app such as YouTube > allow Usage Access and "Display over other
> apps" when Mursa explains why (each opens Android settings; enable Mursa and come back).
> A silent notification "App gate is on" appears. Open the chosen app: Mursa shows a few
> cards first, then the app opens. "Emergency" opens the app at once after a short
> countdown. Turn it off in Settings > The gate. Video: [MAJITEL: URL].

Check the exact navigation labels against the B-03 build before submitting.
